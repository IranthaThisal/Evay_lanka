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
import '../models/ev_preset.dart';
import '../models/range_anxiety.dart';
import '../models/smart_route.dart';
import '../services/charger_service.dart';
import '../services/checkin_service.dart';
import '../services/range_anxiety_service.dart';
import '../services/route_service.dart';
import '../services/smart_route_service.dart';
import '../theme/app_theme.dart';
import '../ui/elevation_profile_hud.dart';
import '../ui/map/charger_card.dart';
import '../ui/map/charger_filter_sheet.dart';
import '../ui/map/map_mode_selector.dart';
import '../ui/osm_map_view.dart';
import '../ui/rai_safety_hud.dart';
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
  bool _includeReturnTrip = false;
  double _minPowerKw = 0;
  String _chargerMode = 'nearby';
  Set<String> _selectedConnectors = <String>{};
  Set<String> _vehicleConnectors = <String>{};
  String? _selectedPresetId;
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
                      : (_activeRoute != null
                          ? Padding(
                            key: const ValueKey('compact-route-pill'),
                            padding: const EdgeInsets.only(top: 10),
                            child: _buildCompactRoutePill(),
                          )
                          : const SizedBox.shrink(
                            key: ValueKey('hidden-planner'),
                          )),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MapModeSelector(
                    currentMode: _chargerMode,
                    onModeSelected:
                        (mode) => setState(() => _chargerMode = mode),
                    items: [
                      MapModeItem(label: l10n.t('nearby'), value: 'nearby'),
                      MapModeItem(label: l10n.t('onRoute'), value: 'route'),
                      MapModeItem(label: l10n.t('allChargers'), value: 'all'),
                    ],
                    accentColor: _accent,
                    panelColor: _panel,
                    panelBorderColor: _panelBorder,
                    selectedTextColor: _buttonOnAccent,
                    unselectedTextColor: _onPanel,
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<ChargerDataSourceStatus>(
                  valueListenable: _chargerService.statusNotifier,
                  builder: (context, status, _) {
                    final isLive =
                        status != ChargerDataSourceStatus.seedSnapshot;
                    final badgeColor =
                        isLive
                            ? const Color(0xFF00C853)
                            : const Color(0xFFFFB300);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _panel.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: badgeColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isLive ? 'Live' : 'Seed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _onPanel,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRoutePill() {
    final destName =
        _destinationController.text.trim().isEmpty
            ? 'Destination'
            : _destinationController.text.trim();
    final distText =
        _activeSmartRoute?.distanceText ?? _activeRoute?.distanceText ?? '';
    final durText =
        _activeSmartRoute?.durationText ?? _activeRoute?.durationText ?? '';
    final stopsCount = _activeSmartRoute?.stopsCount ?? 0;

    return _glassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.route_rounded, size: 18, color: _accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showTripPlanner = true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Origin → $destName',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _onPanel,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_includeReturnTrip) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Round-Trip',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00BFA5),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$distText • $durText${stopsCount > 0 ? " • $stopsCount stop${stopsCount > 1 ? 's' : ''}" : " • Non-stop"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _onPanelMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit Trip',
            onPressed: () => setState(() => _showTripPlanner = true),
            icon: Icon(Icons.edit_road_rounded, size: 19, color: _onPanel),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Clear Route',
            onPressed: _clearRoute,
            icon: Icon(Icons.close_rounded, size: 19, color: _onPanelMuted),
          ),
        ],
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
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kSriLankaEvPresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final preset = kSriLankaEvPresets[index];
                final isSelected = _selectedPresetId == preset.id;
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  backgroundColor:
                      isSelected
                          ? _accent.withValues(alpha: 0.22)
                          : _panelSoft,
                  side: BorderSide(
                    color: isSelected ? _accent : _panelBorder,
                  ),
                  label: Text(
                    '${preset.displayName} (${preset.batteryKwh.toStringAsFixed(0)}kWh)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: _onPanel,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedPresetId = preset.id;
                      _batteryCapacityController.text = preset.batteryKwh
                          .toStringAsFixed(1);
                      _efficiencyController.text = preset.efficiencyKmPerKwh
                          .toStringAsFixed(1);
                      _vehicleConnectors = preset.connectors.toSet();
                      _vehicleSummary =
                          '${preset.displayName} • ${preset.batteryKwh.toStringAsFixed(1)} kWh (${preset.connectors.take(2).join("/")})';
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  _vehicleSummary ??
                      (_loadingVehicleProfile
                          ? 'Loading saved vehicle details...'
                          : 'Select an EV preset or enter custom specs.'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _onPanelMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap:
                    () => setState(
                      () => _includeReturnTrip = !_includeReturnTrip,
                    ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _includeReturnTrip
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 16,
                        color: _includeReturnTrip ? _accent : _onPanelMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Return Trip',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _includeReturnTrip ? _onPanel : _onPanelMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
    if (_activeSmartRoute != null) {
      final startSoc =
          double.tryParse(_batteryPercentController.text.trim()) ?? 65.0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RaiSafetyHud(
            report: report,
            route: _activeSmartRoute!,
          ),
          ElevationProfileHud(
            routePoints: _activeSmartRoute!.routePoints,
            elevationGainM: _activeSmartRoute!.totalElevationGainM,
            elevationLossM: _activeSmartRoute!.totalElevationLossM,
            elevationEnergyPenaltyKwh:
                _activeSmartRoute!.elevationEnergyPenaltyKwh,
            totalDistanceKm: _activeSmartRoute!.totalDistanceKm,
            initialSocPercent: startSoc,
            arrivalSocPercent: _activeSmartRoute!.arrivalBatteryPercent,
            chargingStops: _activeSmartRoute!.chargingStops,
            pnrDistanceKm:
                report.pointOfNoReturn?.pointOfNoReturnKmFromOrigin,
          ),
        ],
      );
    }

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
                              final plannedStop = _chargingStopFor(charger);
                              return ChargerCard(
                                charger: charger,
                                meta: meta,
                                onDirections: () => _showRouteToCharger(charger),
                                onDetails: () => _openChargerSheet(charger),
                                onBookAtEta:
                                    plannedStop != null
                                        ? () => _openBookAtEta(plannedStop)
                                        : null,
                                onSwapAlternative:
                                    (plannedStop != null &&
                                            plannedStop.alternatives.isNotEmpty)
                                        ? () => _showAlternativeStopPicker(
                                          plannedStop,
                                          chargers,
                                        )
                                        : null,
                                alternativeCount:
                                    plannedStop?.alternatives.length ?? 0,
                                panelColor: _panel,
                                onPanelColor: _onPanel,
                                onPanelMutedColor: _onPanelMuted,
                                panelSoftColor: _panelSoft,
                                accentColor: _accent,
                                buttonOnAccentColor: _buttonOnAccent,
                                goodColor: _good,
                                isLight: _isLight,
                              );
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
      final efficiencyKmPerKwh =
          (data['efficiencyKmPerKwh'] as num?)?.toDouble();
      final storedConnectors =
          (data['connectorTypes'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet();
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
        if (efficiencyKmPerKwh != null && efficiencyKmPerKwh > 0) {
          _efficiencyController.text = efficiencyKmPerKwh.toStringAsFixed(1);
        }
        if (storedConnectors != null && storedConnectors.isNotEmpty) {
          _vehicleConnectors = storedConnectors;
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
        preferredConnectors: _vehicleConnectors,
        includeReturnTrip: _includeReturnTrip,
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

  void _openBookAtEta(ChargingStop stop) {
    final eta = DateTime.now().add(
      Duration(minutes: stop.estimatedDriveMinutesFromOrigin),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BookingScreen(
              charger: stop.charger,
              initialEta: eta,
              initialDurationMins: stop.chargingTimeMinutes.round(),
              initialArrivalSocPercent: stop.arrivalSocPercent,
            ),
      ),
    );
  }

  void _showAlternativeStopPicker(
    ChargingStop currentStop,
    List<Charger> allChargers,
  ) {
    final options = [currentStop, ...currentStop.alternatives];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stop ${currentStop.stopOrder}: Compare Corridor Chargers',
                style: TextStyle(
                  color: _onPanel,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a faster DC charger or closer station for this leg.',
                style: TextStyle(color: _onPanelMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < options.length; i++)
                Builder(
                  builder: (context) {
                    final opt = options[i];
                    final isCurrent = opt.charger.id == currentStop.charger.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color:
                            isCurrent
                                ? _accent.withValues(alpha: 0.14)
                                : _panelSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent ? _accent : _panelBorder,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          opt.charger.name,
                          style: TextStyle(
                            color: _onPanel,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${opt.charger.powerKw?.toStringAsFixed(0) ?? "30"} kW • ${opt.distanceFromRouteKm.toStringAsFixed(1)} km detour • ~${opt.chargingTimeMinutes.toStringAsFixed(0)} min charge',
                          style: TextStyle(color: _onPanelMuted, fontSize: 12),
                        ),
                        trailing:
                            isCurrent
                                ? Icon(Icons.check_circle, color: _accent)
                                : OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _swapPlannedStop(
                                      currentStop,
                                      opt,
                                      allChargers,
                                    );
                                  },
                                  child: const Text('Select'),
                                ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _swapPlannedStop(
    ChargingStop oldStop,
    ChargingStop chosenAlt,
    List<Charger> allChargers,
  ) {
    final activeSmart = _activeSmartRoute;
    if (activeSmart == null) return;

    // Preserve the full pool of alternatives when swapping
    final allPool = [oldStop, ...oldStop.alternatives];
    final nextAlternatives =
        allPool
            .where((s) => s.charger.id != chosenAlt.charger.id)
            .map(
              (s) => ChargingStop(
                charger: s.charger,
                distanceFromRouteKm: s.distanceFromRouteKm,
                distanceFromOriginKm: s.distanceFromOriginKm,
                score: s.score,
                stopOrder: s.stopOrder,
                arrivalSocPercent: s.arrivalSocPercent,
                targetSocPercent: s.targetSocPercent,
                chargingTimeMinutes: s.chargingTimeMinutes,
                energyAddedKwh: s.energyAddedKwh,
                elevationM: s.elevationM,
              ),
            )
            .toList(growable: false);

    final replacement = ChargingStop(
      charger: chosenAlt.charger,
      distanceFromRouteKm: chosenAlt.distanceFromRouteKm,
      distanceFromOriginKm: chosenAlt.distanceFromOriginKm,
      score: chosenAlt.score,
      stopOrder: oldStop.stopOrder,
      arrivalSocPercent: chosenAlt.arrivalSocPercent,
      targetSocPercent: chosenAlt.targetSocPercent,
      chargingTimeMinutes: chosenAlt.chargingTimeMinutes,
      energyAddedKwh: chosenAlt.energyAddedKwh,
      elevationM: chosenAlt.elevationM,
      alternatives: nextAlternatives,
    );

    final updatedSmartRoute = activeSmart.withSwappedStop(
      stopOrder: oldStop.stopOrder,
      replacement: replacement,
    );

    final batteryCapacity =
        double.tryParse(_batteryCapacityController.text.trim()) ?? 50.3;
    final batteryPercent =
        double.tryParse(_batteryPercentController.text.trim()) ?? 65.0;
    final efficiency =
        double.tryParse(_efficiencyController.text.trim()) ?? 6.0;

    final updatedReport = _rangeAnxietyService.buildReport(
      smartRoute: updatedSmartRoute,
      batteryCapacityKwh: batteryCapacity,
      batteryPercent: batteryPercent,
      efficiencyKmPerKwh: efficiency,
      conditions: _tripConditions,
      availableChargers: allChargers,
    );

    setState(() {
      _activeSmartRoute = updatedSmartRoute;
      _activeRangeAnxiety = updatedReport;
      _statusText =
          'Swapped Stop ${oldStop.stopOrder} to ${replacement.charger.name} (~${replacement.chargingTimeMinutes.toStringAsFixed(0)}m charge)';
    });
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
    final result = await ChargerFilterSheet.show(
      context: context,
      availableOnly: _availableOnly,
      minPowerKw: _minPowerKw,
      selectedConnectors: _selectedConnectors,
      allConnectors: connectors,
      panelColor: _panel,
      onPanelColor: _onPanel,
      onPanelMutedColor: _onPanelMuted,
      panelSoftColor: _panelSoft,
      accentColor: _accent,
      buttonOnAccentColor: _buttonOnAccent,
      goodColor: _good,
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
