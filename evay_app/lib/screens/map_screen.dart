import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/charger.dart';
import '../models/charger_checkin.dart';
import '../models/range_anxiety.dart';
import '../models/smart_route.dart';
import '../services/charger_service.dart';
import '../services/checkin_service.dart';
import '../services/range_anxiety_service.dart';
import '../services/route_service.dart';
import '../services/smart_route_service.dart';
import '../theme/app_theme.dart';
import '../ui/osm_map_view.dart';
import 'booking_screen.dart';
import 'checkin_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double _minChargerPanelHeight = 124;
  static const double _contentChargerPanelHeight = 230;
  static const Color _routeBlue = Color(0xFF1E88E5);
  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  static const CameraPosition _initial = CameraPosition(
    target: _sriLankaCenter,
    zoom: 7,
  );

  Color get _bg => context.evayPalette.mapBackground;
  Color get _panel => context.evayPalette.mapPanel;
  Color get _panelSoft => context.evayPalette.mapPanelSoft;
  Color get _accent => context.evayPalette.mapAccent;
  Color get _good => context.evayPalette.mapGood;
  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _onPanel => _isLight ? const Color(0xFF102018) : Colors.white;
  Color get _onPanelMuted =>
      _isLight ? const Color(0xFF69786F) : Colors.white70;
  Color get _panelBorder => _isLight ? const Color(0xFFE1E9E4) : Colors.white10;
  Color get _buttonOnAccent =>
      _isLight ? const Color(0xFF12351F) : Colors.white;
  double get _collapsedChargerPanelHeight =>
      _activeRangeAnxiety == null ? _minChargerPanelHeight : 220;
  double get _detailChargerPanelThreshold =>
      _activeRangeAnxiety == null ? _contentChargerPanelHeight : 300;
  double get _maxChargerPanelHeight =>
      math.min(MediaQuery.sizeOf(context).height * 0.48, 390);

  DrivingMode _drivingMode = DrivingMode.normal;
  WeatherCondition _weatherCondition = WeatherCondition.dry;
  int _passengerCount = 1;
  double _cargoWeightKg = 0.0;

  EvTripConditions get _tripConditions => EvTripConditions(
    drivingMode: _drivingMode,
    weather: _weatherCondition,
    passengerCount: _passengerCount,
    cargoWeightKg: _cargoWeightKg,
  );

  final ChargerService _chargerService = ChargerService();
  final CheckInService _checkInService = CheckInService();
  final RouteService _routeService = RouteService();
  final SmartRouteService _smartRouteService = SmartRouteService();
  final RangeAnxietyService _rangeAnxietyService = const RangeAnxietyService();
  late final Stream<List<Charger>> _chargersStream;
  final ValueNotifier<double> _panelHeightNotifier = ValueNotifier<double>(
    _minChargerPanelHeight,
  );
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _batteryCapacityController =
      TextEditingController();
  final TextEditingController _batteryPercentController = TextEditingController(
    text: '65',
  );
  final TextEditingController _efficiencyController = TextEditingController(
    text: '6',
  );

  OsmMapController? _controller;
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  RouteDetails? _activeRoute;
  SmartRoute? _activeSmartRoute;
  RangeAnxietyReport? _activeRangeAnxiety;
  String _query = '';
  bool _loadingLocation = false;
  bool _buildingRoute = false;
  bool _loadingVehicleProfile = false;
  bool _showTripPlanner = false;
  bool _availableOnly = false;
  double _minPowerKw = 0;
  String _chargerMode = 'nearby';
  Set<String> _selectedConnectors = <String>{};
  String? _statusText;
  String? _vehicleSummary;

  @override
  void initState() {
    super.initState();
    _chargersStream = _chargerService.watchChargers();
    _resolveCurrentLocation(animateCamera: false);
    _loadVehicleProfile();
  }

  @override
  void dispose() {
    _panelHeightNotifier.dispose();
    _searchController.dispose();
    _destinationController.dispose();
    _batteryCapacityController.dispose();
    _batteryPercentController.dispose();
    _efficiencyController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<List<Charger>>(
          stream: _chargersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load chargers: ${snapshot.error}',
                    style: TextStyle(color: _onPanelMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final chargers = snapshot.data!;
            final visibleChargers = _visibleChargers(chargers);
            final featuredChargers =
                visibleChargers.take(6).toList(growable: false);
            final markers = _buildMarkers(visibleChargers);
            final circles = _buildCircles();
            final polylines = _buildPolylines();
            final recommendedIds = {
              for (final c in visibleChargers)
                if (_isRecommendedChargingStop(c)) c.id,
            };

            return Stack(
              children: [
                RepaintBoundary(
                  child: OsmMapView(
                    initialCameraPosition: _initial,
                    myLocationEnabled: _currentLocation != null,
                    isDarkMode: !_isLight,
                    onMapCreated: (controller) => _controller = controller,
                    markers: markers,
                    circles: circles,
                    polylines: polylines,
                    recommendedChargerIds: recommendedIds,
                  ),
                ),
                _buildTopControls(chargers),
                ValueListenableBuilder<double>(
                  valueListenable: _panelHeightNotifier,
                  builder: (context, panelHeight, _) {
                    return _buildMapActions(panelHeight);
                  },
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _panelHeightNotifier,
                  builder: (context, panelHeight, _) {
                    return _buildBottomPanel(featuredChargers, panelHeight);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopControls(List<Charger> chargers) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassPanel(
              child: Row(
                children: [
                  Icon(Icons.search, color: _onPanelMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: _onPanel),
                      decoration: InputDecoration(
                        hintText: l10n.t('searchChargersOrCity'),
                        hintStyle: TextStyle(color: _onPanelMuted),
                        border: InputBorder.none,
                      ),
                      onTap: () {
                        if (!_showTripPlanner) {
                          setState(() => _showTripPlanner = true);
                        }
                      },
                      onChanged: (value) {
                        final next = value.trim().toLowerCase();
                        if (_query != next) {
                          setState(() => _query = next);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    onPressed:
                        () => _openFilterSheet(_allConnectorTypes(chargers)),
                    icon: Icon(Icons.tune, color: _onPanel),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child:
                  _showTripPlanner
                      ? Padding(
                        key: const ValueKey('trip-planner'),
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildTripPlanner(chargers),
                      )
                      : const SizedBox.shrink(key: ValueKey('hidden-planner')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _modeChip(l10n.t('nearby'), 'nearby')),
                const SizedBox(width: 8),
                Expanded(child: _modeChip(l10n.t('onRoute'), 'route')),
                const SizedBox(width: 8),
                Expanded(child: _modeChip(l10n.t('allChargers'), 'all')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripPlanner(List<Charger> chargers) {
    return _glassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  autofocus: true,
                  style: TextStyle(color: _onPanel),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: context.l10n.t('whereDoYouWantToGo'),
                    hintStyle: TextStyle(color: _onPanelMuted),
                    prefixIcon: Icon(Icons.flag_outlined, color: _onPanelMuted),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _planTrip(chargers),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showTripPlanner = false),
                icon: Icon(Icons.close, color: _onPanelMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tripInputField(
                  controller: _batteryCapacityController,
                  label: 'Battery kWh',
                  hintText: 'e.g. 40',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tripInputField(
                  controller: _batteryPercentController,
                  label: 'Battery %',
                  hintText: 'e.g. 65',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tripInputField(
                  controller: _efficiencyController,
                  label: 'km / kWh',
                  hintText: 'e.g. 6',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _panelSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _panelBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DrivingMode>(
                      value: _drivingMode,
                      isDense: true,
                      dropdownColor: _panel,
                      style: TextStyle(
                        color: _onPanel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items:
                          DrivingMode.values.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text('${mode.label} Mode'),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _drivingMode = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _panelSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _panelBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<WeatherCondition>(
                      value: _weatherCondition,
                      isDense: true,
                      dropdownColor: _panel,
                      style: TextStyle(
                        color: _onPanel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items:
                          WeatherCondition.values.map((weather) {
                            return DropdownMenuItem(
                              value: weather,
                              child: Text(weather.label),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _weatherCondition = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _panelSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _panelBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _passengerCount,
                      isDense: true,
                      dropdownColor: _panel,
                      style: TextStyle(
                        color: _onPanel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items:
                          const [1, 2, 3, 4, 5].map((cnt) {
                            return DropdownMenuItem(
                              value: cnt,
                              child: Text(
                                cnt == 1 ? '1 Person' : '$cnt Passengers',
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _passengerCount = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _panelSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _panelBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: _cargoWeightKg,
                      isDense: true,
                      dropdownColor: _panel,
                      style: TextStyle(
                        color: _onPanel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items:
                          const [0.0, 30.0, 60.0, 100.0, 150.0].map((cargo) {
                            return DropdownMenuItem(
                              value: cargo,
                              child: Text(
                                cargo == 0
                                    ? 'No Cargo'
                                    : '+${cargo.toInt()}kg Cargo',
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _cargoWeightKg = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _vehicleSummary ??
                  (_loadingVehicleProfile
                      ? 'Loading saved vehicle details...'
                      : 'Add your vehicle in profile for faster RAI estimates.'),
              style: TextStyle(
                color: _onPanelMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _buildingRoute ? null : () => _planTrip(chargers),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _buttonOnAccent,
                  ),
                  icon:
                      _buildingRoute
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _buttonOnAccent,
                            ),
                          )
                          : const Icon(Icons.alt_route),
                  label: Text(
                    _buildingRoute
                        ? context.l10n.t('planning')
                        : context.l10n.t('planTrip'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _clearRoute,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _onPanel,
                  side: BorderSide(color: _panelBorder),
                ),
                icon: const Icon(Icons.layers_clear_outlined),
                label: Text(context.l10n.t('clear')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tripInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: _onPanel, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: _onPanelMuted),
      ),
    );
  }

  Widget _buildRaiCard(RangeAnxietyReport report) {
    final tone = _raiColor(report.score);
    final stop = report.recommendedStop;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'RAI ${report.score}%',
                  style: TextStyle(color: tone, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  report.label,
                  style: TextStyle(
                    color: _onPanel,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.summary,
            style: TextStyle(color: _onPanelMuted, height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip(
                'Range ${report.estimatedRangeKm.toStringAsFixed(0)} km',
              ),
              _metricChip(
                'Trip ${report.routeDistanceKm.toStringAsFixed(0)} km',
              ),
              _metricChip('Buffer ${report.bufferKm.toStringAsFixed(0)} km'),
              _metricChip('Safety ${report.safetyMargin.toStringAsFixed(2)}x'),
              if (report.totalElevationGainM > 100)
                _metricChip(
                  'Ascent +${report.totalElevationGainM.toStringAsFixed(0)}m',
                ),
              if (report.conditions.weather != WeatherCondition.dry)
                _metricChip(
                  '${report.conditions.weather.label} (+${((report.conditions.weather.rollingResistanceMultiplier - 1.0) * 100).toStringAsFixed(0)}%)',
                ),
              if (report.conditions.drivingMode != DrivingMode.normal)
                _metricChip('${report.conditions.drivingMode.label} Mode'),
              if (report.conditions.addedPayloadMassKg > 0)
                _metricChip(
                  '+${report.conditions.addedPayloadMassKg.toStringAsFixed(0)}kg Payload',
                ),
              if (report.chargingStops.length > 1)
                _metricChip('${report.chargingStops.length} Corridor Stops'),
            ],
          ),
          if (report.pointOfNoReturn case final pnr?) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    pnr.isSafeToReturn
                        ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                        : const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      pnr.isSafeToReturn
                          ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                          : const Color(0xFFDC2626).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    pnr.isSafeToReturn
                        ? Icons.replay_circle_filled_rounded
                        : Icons.warning_amber_rounded,
                    color:
                        pnr.isSafeToReturn
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pnr.isSafeToReturn
                              ? 'Round-Trip Return: Verified Safe'
                              : 'Point of No Return Alert (at ${pnr.pointOfNoReturnKmFromOrigin.toStringAsFixed(0)} km)',
                          style: TextStyle(
                            color:
                                pnr.isSafeToReturn
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pnr.warningMessage,
                          style: TextStyle(
                            color: _onPanel,
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (report.chargingStops.isEmpty)
            Text(
              'No charging stops required for this route.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _onPanel,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (report.chargingStops.length == 1 && stop != null)
            Text(
              'Stop 1: ${stop.charger.name} '
              '(${stop.distanceFromRouteKm.toStringAsFixed(1)} km detour • ~${stop.chargingTimeMinutes.toStringAsFixed(0)} min charge)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _onPanel,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in report.chargingStops)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'Stop ${s.stopOrder}: ${s.charger.name} (SoC ${s.arrivalSocPercent.toStringAsFixed(0)}% → ${s.targetSocPercent.toStringAsFixed(0)}%, ~${s.chargingTimeMinutes.toStringAsFixed(0)} min charge)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _onPanel,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRaiBottomSummary({
    required RangeAnxietyReport report,
    required bool expanded,
  }) {
    final tone = _raiColor(report.score);
    final routeMeta = [
      if (_activeRoute?.distanceText case final distance?) distance,
      if (_activeRoute?.durationText case final duration?) duration,
    ].join(' - ');

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        _panelHeightNotifier.value =
            expanded ? _minChargerPanelHeight : _maxChargerPanelHeight;
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'RAI ${report.score}%',
                style: TextStyle(color: tone, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.label,
                    style: TextStyle(
                      color: _onPanel,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (routeMeta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      routeMeta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _onPanelMuted),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: _onPanelMuted,
            ),
          ],
        ),
      ),
    );
  }

  Color _raiColor(int score) {
    if (score >= 80) return _good;
    if (score >= 50) return const Color(0xFFC99200);
    return const Color(0xFFD84343);
  }

  Widget _buildMapActions(double chargerPanelHeight) {
    final topInset = _showTripPlanner ? 430.0 : 160.0;
    final bottomInset =
        chargerPanelHeight.clamp(
          _collapsedChargerPanelHeight,
          _maxChargerPanelHeight,
        ) +
        24;

    return Positioned(
      top: topInset,
      right: 14,
      bottom: bottomInset,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'locate',
            backgroundColor: _panel,
            onPressed:
                _loadingLocation
                    ? null
                    : () => _resolveCurrentLocation(animateCamera: true),
            child:
                _loadingLocation
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'fit',
            backgroundColor: _panel,
            onPressed: _focusActiveContent,
            child: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(List<Charger> chargers, double chargerPanelHeight) {
    final report = _activeRangeAnxiety;
    final title = switch (_chargerMode) {
      'route' => 'Charging Stops On Your Route',
      'all' => 'All Chargers',
      _ => 'Nearby Chargers',
    };
    final minHeight = _collapsedChargerPanelHeight;
    final maxHeight = _maxChargerPanelHeight;
    final clampedHeight = chargerPanelHeight.clamp(minHeight, maxHeight);
    final contentVisible = clampedHeight >= _detailChargerPanelThreshold;

    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          _panelHeightNotifier.value =
              (clampedHeight - details.delta.dy)
                  .clamp(minHeight, maxHeight)
                  .toDouble();
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          final midpoint = (minHeight + maxHeight) / 2;
          final shouldExpand =
              velocity < -120 ||
              (velocity.abs() <= 120 && clampedHeight >= midpoint);
          _panelHeightNotifier.value = shouldExpand ? maxHeight : minHeight;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: clampedHeight,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  _panelHeightNotifier.value =
                      contentVisible ? minHeight : maxHeight;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 6,
                  ),
                  child: Container(
                    width: 58,
                    height: 18,
                    decoration: BoxDecoration(
                      color:
                          _isLight ? const Color(0xFFEAF4EE) : Colors.white10,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (index) => Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color:
                                _isLight
                                    ? const Color(0xFFB7CBBE)
                                    : Colors.white30,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (report != null) ...[
                _buildRaiBottomSummary(
                  report: report,
                  expanded: contentVisible,
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _onPanel,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_statusText != null)
                    Flexible(
                      child: Text(
                        _statusText!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _onPanelMuted),
                        textAlign: TextAlign.end,
                      ),
                    ),
                ],
              ),
              if (contentVisible) ...[
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (report != null) ...[
                        _buildRaiCard(report),
                        const SizedBox(height: 14),
                      ],
                      if (chargers.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _panel,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            context.l10n.t('noChargersMatch'),
                            style: TextStyle(color: _onPanelMuted),
                          ),
                        )
                      else
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: chargers.length,
                            separatorBuilder:
                                (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final charger = chargers[index];
                              final meta = _chargerMeta(charger);
                              return _chargerCard(charger, meta);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chargerCard(Charger charger, String meta) {
    return Container(
      width: 245,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    charger.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: _onPanel),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    charger.city.isEmpty
                        ? context.l10n.t('sriLanka')
                        : charger.city,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _onPanelMuted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metricChip(context.l10n.slotsCount(charger.slots)),
                      if (charger.powerKw != null)
                        _metricChip(
                          '${charger.powerKw!.toStringAsFixed(0)} kW',
                        ),
                      if (charger.connectorTypes.isNotEmpty)
                        _metricChip(charger.connectorTypes.first),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            meta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _good,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _showRouteToCharger(charger),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isLight ? _accent : Colors.white,
                    foregroundColor:
                        _isLight ? _buttonOnAccent : const Color(0xFF08141D),
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(context.l10n.t('directions')),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 42,
                height: 42,
                child: IconButton(
                  onPressed: () => _openChargerSheet(charger),
                  style: IconButton.styleFrom(
                    backgroundColor: _panelSoft,
                    foregroundColor: _onPanel,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.ev_station, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _panelSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: _onPanelMuted)),
    );
  }

  Widget _glassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 14),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: _isLight ? 0.98 : 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _modeChip(String label, String value) {
    final selected = _chargerMode == value;
    return GestureDetector(
      onTap: () {
        if (_chargerMode != value) {
          setState(() => _chargerMode = value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _accent : _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : _panelBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? _buttonOnAccent : _onPanel,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _resolveCurrentLocation({required bool animateCamera}) async {
    setState(() => _loadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are turned off.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required for directions.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final location = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _statusText = 'Live location ready';
      });

      if (animateCamera) {
        await _controller?.animateToLatLngZoom(location, 12.5);
      }
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _statusText = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _loadVehicleProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loadingVehicleProfile = true);

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data == null || !mounted) return;

      final batteryKwh = (data['batteryKwh'] as num?)?.toDouble();
      final make = (data['vehicleMake'] as String?)?.trim();
      final model = (data['vehicleModel'] as String?)?.trim();
      final parts = [
        if (make != null && make.isNotEmpty) make,
        if (model != null && model.isNotEmpty) model,
      ];

      setState(() {
        if (batteryKwh != null &&
            _batteryCapacityController.text.trim().isEmpty) {
          _batteryCapacityController.text = batteryKwh.toStringAsFixed(
            batteryKwh.truncateToDouble() == batteryKwh ? 0 : 1,
          );
        }
        _vehicleSummary =
            parts.isEmpty && batteryKwh == null
                ? null
                : '${parts.isEmpty ? 'Saved vehicle' : parts.join(' ')}${batteryKwh == null ? '' : ' - ${batteryKwh.toStringAsFixed(0)} kWh'}';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingVehicleProfile = false);
      }
    }
  }

  Future<LatLng> _resolveDestinationCoordinates(String destinationText) async {
    final osmResult = await _routeService.geocodeAddress(destinationText);
    if (osmResult != null) {
      return osmResult;
    }

    final locations = await locationFromAddress(destinationText);
    if (locations.isEmpty) {
      throw Exception('Destination was not found.');
    }

    return LatLng(locations.first.latitude, locations.first.longitude);
  }

  Future<void> _planTrip(List<Charger> chargers) async {
    final destinationText = _destinationController.text.trim();
    if (destinationText.isEmpty) {
      setState(() => _statusText = 'Enter a destination to plan the route.');
      return;
    }

    final batteryCapacity = double.tryParse(
      _batteryCapacityController.text.trim(),
    );
    final batteryPercent = double.tryParse(
      _batteryPercentController.text.trim(),
    );
    final efficiency = double.tryParse(_efficiencyController.text.trim());
    if (batteryCapacity == null ||
        batteryCapacity <= 0 ||
        batteryPercent == null ||
        batteryPercent < 0 ||
        batteryPercent > 100 ||
        efficiency == null ||
        efficiency <= 0) {
      setState(() {
        _statusText =
            'Enter battery capacity, battery %, and efficiency to calculate RAI.';
      });
      return;
    }

    if (_currentLocation == null) {
      await _resolveCurrentLocation(animateCamera: false);
      if (_currentLocation == null) return;
    }

    setState(() {
      _buildingRoute = true;
      _statusText = 'Searching destination and route...';
    });

    try {
      final destination = await _resolveDestinationCoordinates(destinationText);
      final reliabilityScores = await _checkInService.getReliabilityScores(
        chargers.map((c) => c.id).toList(growable: false),
      );
      final smartRoute = await _smartRouteService.planFastestRouteWithChargers(
        origin: _currentLocation!,
        destination: destination,
        chargers: chargers,
        batteryCapacityKwh: batteryCapacity,
        batteryPercent: batteryPercent,
        efficiencyKmPerKwh: efficiency,
        conditions: _tripConditions,
        reliabilityScores: reliabilityScores,
      );
      final route = RouteDetails(
        points: smartRoute.routePoints,
        bounds: smartRoute.bounds,
        distanceText: smartRoute.distanceText,
        durationText: smartRoute.durationText,
      );
      final raiReport = _rangeAnxietyService.buildReport(
        smartRoute: smartRoute,
        batteryCapacityKwh: batteryCapacity,
        batteryPercent: batteryPercent,
        efficiencyKmPerKwh: efficiency,
        conditions: _tripConditions,
        availableChargers: chargers,
      );

      if (!mounted) return;
      _panelHeightNotifier.value = _minChargerPanelHeight;
      setState(() {
        _destinationLocation = destination;
        _activeRoute = route;
        _activeSmartRoute = smartRoute;
        _activeRangeAnxiety = raiReport;
        _chargerMode = 'route';
        _showTripPlanner = true;
        _statusText = '${route.distanceText} - ${route.durationText}';
      });

      await _controller?.animateToBounds(route.bounds, padding: 72);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _statusText = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _buildingRoute = false);
      }
    }
  }

  Future<void> _showRouteToCharger(Charger charger) async {
    _destinationController.text = charger.name;
    if (_currentLocation == null) {
      await _resolveCurrentLocation(animateCamera: false);
      if (_currentLocation == null) return;
    }

    setState(() {
      _buildingRoute = true;
      _statusText = 'Building route to ${charger.name}...';
    });

    try {
      final route = await _routeService.fetchRoute(
        origin: _currentLocation!,
        destination: LatLng(charger.lat, charger.lng),
      );

      if (!mounted) return;
      _panelHeightNotifier.value = _minChargerPanelHeight;
      setState(() {
        _destinationLocation = LatLng(charger.lat, charger.lng);
        _activeRoute = route;
        _activeSmartRoute = null;
        _activeRangeAnxiety = null;
        _chargerMode = 'route';
        _showTripPlanner = false;
        _statusText = '${route.distanceText} - ${route.durationText}';
      });

      await _controller?.animateToBounds(route.bounds, padding: 72);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _statusText = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _buildingRoute = false);
      }
    }
  }

  void _clearRoute() {
    _panelHeightNotifier.value = _minChargerPanelHeight;
    setState(() {
      _destinationController.clear();
      _destinationLocation = null;
      _activeRoute = null;
      _activeSmartRoute = null;
      _activeRangeAnxiety = null;
      _chargerMode = 'nearby';
      _showTripPlanner = false;
      _statusText = _currentLocation == null ? null : 'Live location ready';
    });
    _focusActiveContent();
  }

  void _focusActiveContent() {
    if (_activeRoute != null) {
      _controller?.animateToBounds(_activeRoute!.bounds, padding: 72);
      return;
    }

    if (_currentLocation != null) {
      _controller?.animateToLatLngZoom(_currentLocation!, 12.5);
    }
  }

  void _openChargerSheet(Charger charger) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          charger.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _onPanel,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          charger.city.isEmpty ? 'Sri Lanka' : charger.city,
                          style: TextStyle(color: _onPanelMuted),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<ChargerReliabilitySummary>(
                    stream: _checkInService.watchReliability(charger.id),
                    builder: (context, snap) {
                      final summary =
                          snap.data ??
                          const ChargerReliabilitySummary(
                            score: 9.0,
                            totalCheckIns: 0,
                            successCount: 0,
                            failureCount: 0,
                          );

                      final isDown = summary.isReportedDownRecently;
                      final tone =
                          isDown
                              ? const Color(0xFFDC2626)
                              : summary.isHighReliability
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tone.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDown
                                  ? Icons.warning_amber_rounded
                                  : Icons.star_rounded,
                              color: tone,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDown
                                  ? 'Issue Reported'
                                  : '★ ${summary.score.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: tone,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sheetChip('Slots: ${charger.slots}'),
                  if (charger.powerKw != null)
                    _sheetChip('${charger.powerKw!.toStringAsFixed(0)} kW'),
                  for (final connector in charger.connectorTypes)
                    _sheetChip(connector),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(charger: charger),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _buttonOnAccent,
                      ),
                      icon: const Icon(Icons.book_online, size: 18),
                      label: const Text('Book'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRouteToCharger(charger);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _onPanel,
                        side: BorderSide(color: _panelBorder),
                      ),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Route'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        CheckInSheet.show(context, charger);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: BorderSide(
                          color: const Color(
                            0xFF16A34A,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                      icon: const Icon(Icons.how_to_reg, size: 18),
                      label: const Text('Check In'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Recent Community Reports',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _onPanel,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<ChargerCheckIn>>(
                stream: _checkInService.watchRecentCheckIns(
                  charger.id,
                  limit: 2,
                ),
                builder: (context, snap) {
                  final list = snap.data ?? const <ChargerCheckIn>[];
                  if (list.isEmpty) {
                    return Text(
                      'No recent driver reports. Be the first to check in!',
                      style: TextStyle(fontSize: 11.5, color: _onPanelMuted),
                    );
                  }

                  return Column(
                    children: [
                      for (final c in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                c.outcome == CheckInOutcome.success
                                    ? Icons.check_circle
                                    : c.outcome == CheckInOutcome.couldNotCharge
                                    ? Icons.error
                                    : Icons.comment,
                                color:
                                    c.outcome == CheckInOutcome.success
                                        ? const Color(0xFF16A34A)
                                        : c.outcome ==
                                            CheckInOutcome.couldNotCharge
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF0284C7),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${c.userName} (${c.vehicleModel ?? 'EV'}): ${c.outcome == CheckInOutcome.couldNotCharge ? c.issue.label : (c.comment.isNotEmpty ? c.comment : 'Charged successfully')}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: _onPanel,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetChip(String text) {
    return Chip(
      backgroundColor: _panelSoft,
      labelStyle: TextStyle(color: _onPanel),
      label: Text(text),
    );
  }

  Future<void> _openFilterSheet(List<String> connectors) async {
    final result = await showModalBottomSheet<_FilterDraft>(
      context: context,
      backgroundColor: _panel,
      showDragHandle: true,
      builder: (context) {
        bool availableOnly = _availableOnly;
        double minPower = _minPowerKw;
        final selected = {..._selectedConnectors};

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Chargers',
                    style: TextStyle(
                      color: _onPanel,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    value: availableOnly,
                    activeColor: _good,
                    title: Text(
                      'Available slots only',
                      style: TextStyle(color: _onPanel),
                    ),
                    onChanged: (value) {
                      setModalState(() => availableOnly = value);
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Minimum power: ${minPower.round()} kW',
                    style: TextStyle(color: _onPanelMuted),
                  ),
                  Slider(
                    value: minPower,
                    min: 0,
                    max: 350,
                    divisions: 14,
                    activeColor: _accent,
                    label: '${minPower.round()} kW',
                    onChanged: (value) {
                      setModalState(() => minPower = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connector Types',
                    style: TextStyle(color: _onPanelMuted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        connectors.map((connector) {
                          final selectedNow = selected.contains(connector);
                          return FilterChip(
                            selected: selectedNow,
                            label: Text(connector),
                            labelStyle: TextStyle(
                              color: selectedNow ? _buttonOnAccent : _onPanel,
                            ),
                            selectedColor: _accent,
                            backgroundColor: _panelSoft,
                            checkmarkColor: _buttonOnAccent,
                            onSelected: (value) {
                              setModalState(() {
                                if (value) {
                                  selected.add(connector);
                                } else {
                                  selected.remove(connector);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _FilterDraft(
                            availableOnly: availableOnly,
                            minPowerKw: minPower,
                            selectedConnectors: selected,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _buttonOnAccent,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _availableOnly = result.availableOnly;
      _minPowerKw = result.minPowerKw;
      _selectedConnectors = result.selectedConnectors;
    });
  }

  List<Charger> _visibleChargers(List<Charger> chargers) {
    final smartRoute = _activeSmartRoute;
    final scored = <(Charger, double)>[];

    for (final charger in chargers) {
      final searchMatch =
          _query.isEmpty ||
          charger.name.toLowerCase().contains(_query) ||
          charger.city.toLowerCase().contains(_query) ||
          charger.connectorTypes.any(
            (connector) => connector.toLowerCase().contains(_query),
          );
      if (!searchMatch) continue;

      if (_availableOnly && charger.slots <= 0) continue;
      if (_minPowerKw > 0 && (charger.powerKw ?? 0) < _minPowerKw) {
        continue;
      }
      if (_selectedConnectors.isNotEmpty &&
          !_selectedConnectors.any(charger.connectorTypes.contains)) {
        continue;
      }

      if (_chargerMode == 'route') {
        if (smartRoute != null) {
          final stop = smartRoute.stopForCharger(charger.id);
          if (stop == null) continue;
          scored.add((charger, stop.distanceFromOriginKm));
          continue;
        } else {
          final routeDist = _distanceFromRoute(charger);
          if (routeDist > 15) continue;
          scored.add((charger, routeDist));
          continue;
        }
      }

      scored.add((charger, _distanceForSorting(charger)));
    }

    scored.sort((a, b) => a.$2.compareTo(b.$2));

    final limit = _chargerMode == 'all' ? scored.length : math.min(20, scored.length);
    return [for (var i = 0; i < limit; i++) scored[i].$1];
  }

  Set<Marker> _buildMarkers(List<Charger> chargers) {
    final markers = <Marker>{
      for (final charger in chargers)
        Marker(
          markerId: MarkerId(charger.id),
          position: LatLng(charger.lat, charger.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _isRecommendedChargingStop(charger)
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: charger.name,
            snippet: _chargerMeta(charger),
            onTap: () => _openChargerSheet(charger),
          ),
          onTap: () {
            setState(() => _statusText = _chargerMeta(charger));
            _openChargerSheet(charger);
          },
        ),
    };

    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    final currentLocation = _currentLocation;
    if (currentLocation == null) return const <Circle>{};

    return {
      Circle(
        circleId: const CircleId('current-location'),
        center: currentLocation,
        radius: 18,
        strokeWidth: 3,
        strokeColor: const Color(0xFF1976D2),
        fillColor: const Color(0xFF1976D2).withValues(alpha: 0.24),
        zIndex: 10,
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    final route = _activeRoute;
    if (route == null || route.points.isEmpty) return const <Polyline>{};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: route.points,
        color: _routeBlue,
        width: 7,
        geodesic: true,
      ),
    };
  }

  List<String> _allConnectorTypes(List<Charger> chargers) {
    final types =
        chargers
            .expand((charger) => charger.connectorTypes)
            .map((type) => type.trim())
            .where((type) => type.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return types;
  }

  String _chargerMeta(Charger charger) {
    final stop = _chargingStopFor(charger);
    if (stop != null) {
      return 'Stop ${stop.stopOrder} • ${stop.distanceFromRouteKm.toStringAsFixed(1)} km detour • ~${stop.chargingTimeMinutes.toStringAsFixed(0)}m charge';
    }

    if (_chargerMode == 'route' && _activeRoute != null) {
      final routeDistance = _distanceFromRoute(charger);
      return routeDistance.isFinite
          ? '${routeDistance.toStringAsFixed(1)} km from route'
          : 'On selected trip';
    }

    if (_currentLocation != null) {
      final km = _distanceToLatLng(
        _currentLocation!,
        LatLng(charger.lat, charger.lng),
      );
      return '${km.toStringAsFixed(1)} km away';
    }

    return charger.city.isEmpty ? 'Charging station' : charger.city;
  }

  bool _isRecommendedChargingStop(Charger charger) {
    return _chargingStopFor(charger) != null;
  }

  ChargingStop? _chargingStopFor(Charger charger) {
    return _activeSmartRoute?.stopForCharger(charger.id);
  }

  double _distanceForSorting(Charger charger) {
    final stop = _chargingStopFor(charger);
    if (stop != null) {
      return stop.distanceFromOriginKm;
    }

    if (_chargerMode == 'route' && _activeRoute != null) {
      return _distanceFromRoute(charger);
    }

    if (_currentLocation != null) {
      return _distanceToLatLng(
        _currentLocation!,
        LatLng(charger.lat, charger.lng),
      );
    }

    return 0;
  }

  double _distanceFromRoute(Charger charger) {
    final route = _activeRoute;
    if (route == null || route.points.isEmpty) return double.infinity;

    double minKm = double.infinity;
    final target = LatLng(charger.lat, charger.lng);

    for (var i = 0; i < route.points.length; i += 4) {
      final km = _distanceToLatLng(route.points[i], target);
      if (km < minKm) minKm = km;
    }

    final lastKm = _distanceToLatLng(route.points.last, target);
    return math.min(minKm, lastKm);
  }

  double _distanceToLatLng(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
          a.latitude,
          a.longitude,
          b.latitude,
          b.longitude,
        ) /
        1000;
  }
}

class _FilterDraft {
  const _FilterDraft({
    required this.availableOnly,
    required this.minPowerKw,
    required this.selectedConnectors,
  });

  final bool availableOnly;
  final double minPowerKw;
  final Set<String> selectedConnectors;
}
