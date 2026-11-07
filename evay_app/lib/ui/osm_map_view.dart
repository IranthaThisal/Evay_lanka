import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controller for [OsmMapView] providing camera movement and bounds fitting.
class OsmMapController {
  _OsmMapViewState? _state;

  void _attach(_OsmMapViewState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  Future<void> animateToLatLngZoom(LatLng target, double zoom) async {
    await _state?._animateTo(target, zoom);
  }

  Future<void> animateToBounds(
    LatLngBounds bounds, {
    double padding = 72,
  }) async {
    await _state?._animateToBounds(bounds, padding);
  }

  void dispose() {
    _detach();
  }
}

/// Pure-Flutter interactive OpenStreetMap slippy map widget.
/// Requires no API key or billing account and supports Light & Dark map styles,
/// markers, polylines, circles, pinch-to-zoom, pan, and smooth camera animations.
class OsmMapView extends StatefulWidget {
  const OsmMapView({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.markers = const <Marker>{},
    this.circles = const <Circle>{},
    this.polylines = const <Polyline>{},
    this.myLocationEnabled = false,
    this.isDarkMode = false,
    this.recommendedChargerIds = const <String>{},
  });

  final CameraPosition initialCameraPosition;
  final ValueChanged<OsmMapController>? onMapCreated;
  final Set<Marker> markers;
  final Set<Circle> circles;
  final Set<Polyline> polylines;
  final bool myLocationEnabled;
  final bool isDarkMode;
  final Set<String> recommendedChargerIds;

  @override
  State<OsmMapView> createState() => _OsmMapViewState();
}

class _OsmMapViewState extends State<OsmMapView>
    with SingleTickerProviderStateMixin {
  static const double _tileSize = 256.0;
  static const double _minZoom = 5.0;
  static const double _maxZoom = 18.5;

  final OsmMapController _controller = OsmMapController();
  late LatLng _center;
  late double _zoom;

  late final AnimationController _animController;
  LatLng? _animStartCenter;
  LatLng? _animEndCenter;
  double? _animStartZoom;
  double? _animEndZoom;

  // Gesture tracking state
  Offset? _lastFocalPoint;
  double? _scaleStartZoom;
  Offset? _doubleTapPosition;
  String? _selectedMarkerId;
  Size _viewportSize = const Size(400, 700);

  @override
  void initState() {
    super.initState();
    _center = widget.initialCameraPosition.target;
    _zoom = widget.initialCameraPosition.zoom.clamp(_minZoom, _maxZoom);
    _controller._attach(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(_onAnimationTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onMapCreated?.call(_controller);
      }
    });
  }

  @override
  void dispose() {
    _controller._detach();
    _animController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (_animStartCenter == null ||
        _animEndCenter == null ||
        _animStartZoom == null ||
        _animEndZoom == null) {
      return;
    }
    final t = Curves.easeInOutCubic.transform(_animController.value);
    setState(() {
      _center = LatLng(
        _animStartCenter!.latitude +
            (_animEndCenter!.latitude - _animStartCenter!.latitude) * t,
        _animStartCenter!.longitude +
            (_animEndCenter!.longitude - _animStartCenter!.longitude) * t,
      );
      _zoom = (_animStartZoom! + (_animEndZoom! - _animStartZoom!) * t).clamp(
        _minZoom,
        _maxZoom,
      );
    });
  }

  Future<void> _animateTo(LatLng target, double targetZoom) async {
    _animController.stop();
    _animStartCenter = _center;
    _animEndCenter = _clampLatLng(target);
    _animStartZoom = _zoom;
    _animEndZoom = targetZoom.clamp(_minZoom, _maxZoom);
    await _animController.forward(from: 0.0);
  }

  Future<void> _animateToBounds(LatLngBounds bounds, double padding) async {
    final sw = bounds.southwest;
    final ne = bounds.northeast;
    final centerLat = (sw.latitude + ne.latitude) / 2.0;
    final centerLng = (sw.longitude + ne.longitude) / 2.0;

    final availWidth = math.max(100.0, _viewportSize.width - padding * 2);
    final availHeight = math.max(100.0, _viewportSize.height - padding * 2);

    // Compute world coordinates at zoom 0
    final pSw = _latLngToWorld(sw, 0);
    final pNe = _latLngToWorld(ne, 0);
    final dx = (pNe.dx - pSw.dx).abs();
    final dy = (pSw.dy - pNe.dy).abs();

    double targetZoom = 12.5;
    if (dx > 1e-6 && dy > 1e-6) {
      final zoomX = math.log(availWidth / dx) / math.ln2;
      final zoomY = math.log(availHeight / dy) / math.ln2;
      targetZoom = math.min(zoomX, zoomY).clamp(_minZoom, 16.0);
    }

    await _animateTo(LatLng(centerLat, centerLng), targetZoom);
  }

  /// Web Mercator projection: converts [LatLng] to global pixel coordinates at [zoom].
  static Offset _latLngToWorld(LatLng point, double zoom) {
    final scale = _tileSize * math.pow(2.0, zoom);
    final x = (point.longitude + 180.0) / 360.0 * scale;
    final latRad = point.latitude.clamp(-85.05112878, 85.05112878) * math.pi / 180.0;
    final sinLat = math.sin(latRad);
    final y =
        (0.5 - math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi)) *
        scale;
    return Offset(x, y);
  }

  /// Inverse Web Mercator projection: converts global pixel coordinates at [zoom] to [LatLng].
  static LatLng _worldToLatLng(Offset world, double zoom) {
    final scale = _tileSize * math.pow(2.0, zoom);
    final lng = (world.dx / scale) * 360.0 - 180.0;
    final n = math.pi - (2.0 * math.pi * world.dy) / scale;
    final lat = 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
    return _clampLatLng(LatLng(lat, lng));
  }

  static LatLng _clampLatLng(LatLng pt) {
    return LatLng(
      pt.latitude.clamp(-85.0, 85.0),
      pt.longitude.clamp(-180.0, 180.0),
    );
  }

  /// Converts a geographic [LatLng] to local widget viewport [Offset].
  Offset _latLngToScreen(LatLng point, Size size) {
    final centerWorld = _latLngToWorld(_center, _zoom);
    final ptWorld = _latLngToWorld(point, _zoom);
    return Offset(
      size.width / 2.0 + (ptWorld.dx - centerWorld.dx),
      size.height / 2.0 + (ptWorld.dy - centerWorld.dy),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _animController.stop();
    _lastFocalPoint = details.localFocalPoint;
    _scaleStartZoom = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size size) {
    final prevFocal = _lastFocalPoint ?? details.localFocalPoint;
    final delta = details.localFocalPoint - prevFocal;
    _lastFocalPoint = details.localFocalPoint;

    double nextZoom = _zoom;
    if ((details.scale - 1.0).abs() > 0.005 && _scaleStartZoom != null) {
      nextZoom = (_scaleStartZoom! + math.log(details.scale) / math.ln2).clamp(
        _minZoom,
        _maxZoom,
      );
    }

    // Keep the focal point anchored while panning and zooming
    final centerWorld = _latLngToWorld(_center, _zoom);
    final movedWorld = Offset(
      centerWorld.dx - delta.dx,
      centerWorld.dy - delta.dy,
    );
    final movedLatLng = _worldToLatLng(movedWorld, _zoom);

    setState(() {
      _center = movedLatLng;
      _zoom = nextZoom;
    });
  }

  void _onDoubleTap() {
    final tapPos = _doubleTapPosition;
    final targetZoom = (_zoom + 1.2).clamp(_minZoom, _maxZoom);
    if (tapPos != null) {
      final centerWorld = _latLngToWorld(_center, _zoom);
      final tapWorld = Offset(
        centerWorld.dx + (tapPos.dx - _viewportSize.width / 2.0) * 0.5,
        centerWorld.dy + (tapPos.dy - _viewportSize.height / 2.0) * 0.5,
      );
      _animateTo(_worldToLatLng(tapWorld, _zoom), targetZoom);
    } else {
      _animateTo(_center, targetZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _viewportSize = size;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_selectedMarkerId != null) {
              setState(() => _selectedMarkerId = null);
            }
          },
          onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
          onDoubleTap: _onDoubleTap,
          onScaleStart: _onScaleStart,
          onScaleUpdate: (details) => _onScaleUpdate(details, size),
          child: ClipRect(
            child: Container(
              color:
                  widget.isDarkMode
                      ? const Color(0xFF141D26)
                      : const Color(0xFFE8ECEF),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // 1. OpenStreetMap / Carto Tile Layer
                  _buildTileLayer(size),

                  // 2. Route Polylines & Current Location Circle Layer
                  IgnorePointer(
                    child: CustomPaint(
                      size: size,
                      painter: _MapVectorPainter(
                        polylines: widget.polylines,
                        circles: widget.circles,
                        latLngToScreen: (pt) => _latLngToScreen(pt, size),
                        zoom: _zoom,
                      ),
                    ),
                  ),

                  // 3. Charger & Destination Pin Markers Layer
                  ..._buildMarkerWidgets(size),

                  // 4. Selected Marker InfoWindow Callout
                  if (_selectedMarkerId != null)
                    _buildSelectedCallout(size),

                  // 5. OpenStreetMap Attribution Badge
                  Positioned(
                    left: 8,
                    bottom: 4,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              widget.isDarkMode
                                  ? Colors.black54
                                  : Colors.white70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '© OpenStreetMap • Carto',
                          style: TextStyle(
                            fontSize: 9.5,
                            color:
                                widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTileLayer(Size size) {
    final tileZoom = _zoom.floor().clamp(3, 18);
    final scale = math.pow(2.0, _zoom - tileZoom).toDouble();
    final maxTileIndex = (1 << tileZoom) - 1;

    final centerTileWorld = _latLngToWorld(_center, tileZoom.toDouble());
    final halfW = (size.width / 2.0) / scale;
    final halfH = (size.height / 2.0) / scale;

    final minTileX = ((centerTileWorld.dx - halfW) / _tileSize).floor() - 1;
    final maxTileX = ((centerTileWorld.dx + halfW) / _tileSize).ceil() + 1;
    final minTileY = ((centerTileWorld.dy - halfH) / _tileSize).floor() - 1;
    final maxTileY = ((centerTileWorld.dy + halfH) / _tileSize).ceil() + 1;

    final tiles = <Widget>[];
    final subdomains = const ['a', 'b', 'c'];

    for (var ty = minTileY; ty <= maxTileY; ty++) {
      if (ty < 0 || ty > maxTileIndex) continue;
      for (var tx = minTileX; tx <= maxTileX; tx++) {
        final wrappedX = ((tx % (maxTileIndex + 1)) + (maxTileIndex + 1)) %
            (maxTileIndex + 1);
        final screenX =
            size.width / 2.0 + (tx * _tileSize - centerTileWorld.dx) * scale;
        final screenY =
            size.height / 2.0 + (ty * _tileSize - centerTileWorld.dy) * scale;
        final scaledTileSize = _tileSize * scale + 0.75; // +0.75 avoids hairline seams

        final sub = subdomains[(wrappedX + ty).abs() % subdomains.length];
        final primaryUrl =
            widget.isDarkMode
                ? 'https://$sub.basemaps.cartocdn.com/dark_all/$tileZoom/$wrappedX/$ty@2x.png'
                : 'https://$sub.basemaps.cartocdn.com/rastertiles/voyager/$tileZoom/$wrappedX/$ty@2x.png';
        final fallbackUrl =
            'https://tile.openstreetmap.org/$tileZoom/$wrappedX/$ty.png';

        tiles.add(
          Positioned(
            key: ValueKey('tile_${widget.isDarkMode}_${tileZoom}_${tx}_$ty'),
            left: screenX,
            top: screenY,
            width: scaledTileSize,
            height: scaledTileSize,
            child: Image.network(
              primaryUrl,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              headers: const {'User-Agent': 'EVayLanka/1.0 (lk.evaylanka.app)'},
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  fallbackUrl,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  headers: const {
                    'User-Agent': 'EVayLanka/1.0 (lk.evaylanka.app)',
                  },
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                );
              },
            ),
          ),
        );
      }
    }

    return Stack(clipBehavior: Clip.none, children: tiles);
  }

  List<Widget> _buildMarkerWidgets(Size size) {
    final list = widget.markers.toList(growable: false);
    // Sort by latitude descending so southern markers overlap northern ones naturally
    list.sort((a, b) => b.position.latitude.compareTo(a.position.latitude));

    final widgets = <Widget>[];
    for (final marker in list) {
      final pos = _latLngToScreen(marker.position, size);
      // Skip markers far outside the screen
      if (pos.dx < -60 ||
          pos.dx > size.width + 60 ||
          pos.dy < -60 ||
          pos.dy > size.height + 60) {
        continue;
      }

      final id = marker.markerId.value;
      final isDestination = id == 'destination';
      final isRecommended = widget.recommendedChargerIds.contains(id);
      final isSelected = _selectedMarkerId == id;

      final Color pinColor =
          isDestination
              ? const Color(0xFFE11D48) // Rose red for destination
              : isRecommended
              ? const Color(0xFF16A34A) // Green for recommended stop
              : const Color(0xFF0284C7); // Azure blue for EV charger

      final double pinSize = isSelected ? 42.0 : 36.0;

      widgets.add(
        Positioned(
          key: ValueKey('marker_$id'),
          left: pos.dx - pinSize / 2.0,
          top: pos.dy - pinSize,
          width: pinSize,
          height: pinSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _selectedMarkerId = id);
              marker.onTap?.call();
            },
            child: _MapPinIcon(
              color: pinColor,
              isDestination: isDestination,
              isSelected: isSelected,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildSelectedCallout(Size size) {
    Marker? selected;
    for (final m in widget.markers) {
      if (m.markerId.value == _selectedMarkerId) {
        selected = m;
        break;
      }
    }
    if (selected == null) return const SizedBox.shrink();

    final title = selected.infoWindow.title;
    if (title == null || title.isEmpty) return const SizedBox.shrink();
    final snippet = selected.infoWindow.snippet;
    final pos = _latLngToScreen(selected.position, size);

    const calloutWidth = 210.0;
    final left =
        (pos.dx - calloutWidth / 2.0)
            .clamp(12.0, math.max(12.0, size.width - calloutWidth - 12.0))
            .toDouble();
    final top = math.max(90.0, pos.dy - 92.0);

    return Positioned(
      left: left,
      top: top,
      width: calloutWidth,
      child: GestureDetector(
        onTap: () => selected?.infoWindow.onTap?.call(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isDarkMode ? const Color(0xFF1A2820) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      widget.isDarkMode
                          ? Colors.white
                          : const Color(0xFF102018),
                ),
              ),
              if (snippet != null && snippet.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color:
                        widget.isDarkMode
                            ? Colors.white70
                            : const Color(0xFF69786F),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPinIcon extends StatelessWidget {
  const _MapPinIcon({
    required this.color,
    required this.isDestination,
    required this.isSelected,
  });

  final Color color;
  final bool isDestination;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Drop shadow at pin tip
        Positioned(
          bottom: 1,
          child: Container(
            width: 10,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0x44000000),
              borderRadius: BorderRadius.all(Radius.elliptical(10, 4)),
            ),
          ),
        ),
        // Pin body
        Icon(
          Icons.location_on,
          size: isSelected ? 40 : 34,
          color: color,
          shadows: const [
            Shadow(
              color: Color(0x55000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        // Inner badge icon
        Positioned(
          top: isSelected ? 7 : 6,
          child: Container(
            width: isSelected ? 16 : 14,
            height: isSelected ? 16 : 14,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDestination ? Icons.flag_rounded : Icons.bolt_rounded,
              size: isSelected ? 13 : 11,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapVectorPainter extends CustomPainter {
  _MapVectorPainter({
    required this.polylines,
    required this.circles,
    required this.latLngToScreen,
    required this.zoom,
  });

  final Set<Polyline> polylines;
  final Set<Circle> circles;
  final Offset Function(LatLng) latLngToScreen;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw route polylines
    for (final polyline in polylines) {
      final pts = polyline.points;
      if (pts.length < 2) continue;

      final path = Path();
      final first = latLngToScreen(pts.first);
      path.moveTo(first.dx, first.dy);

      for (var i = 1; i < pts.length; i++) {
        final p = latLngToScreen(pts[i]);
        path.lineTo(p.dx, p.dy);
      }

      // Outer casing for contrast
      final casingPaint =
          Paint()
            ..color = const Color(0xFF0D47A1).withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = polyline.width.toDouble() + 3.0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, casingPaint);

      // Primary route line
      final strokePaint =
          Paint()
            ..color = polyline.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = polyline.width.toDouble()
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
    }

    // 2. Draw current location circles
    for (final circle in circles) {
      final center = latLngToScreen(circle.center);
      final metersPerPixel =
          156543.03392 *
          math.cos(circle.center.latitude * math.pi / 180.0) /
          math.pow(2.0, zoom);
      final pixelRadius =
          (circle.radius / metersPerPixel).clamp(10.0, 48.0).toDouble();

      final fillPaint =
          Paint()
            ..color = circle.fillColor
            ..style = PaintingStyle.fill;
      canvas.drawCircle(center, pixelRadius, fillPaint);

      final borderPaint =
          Paint()
            ..color = circle.strokeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = circle.strokeWidth.toDouble();
      canvas.drawCircle(center, pixelRadius, borderPaint);

      // Crisp inner blue dot for user's live GPS location
      final whiteRingPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 7.0, whiteRingPaint);

      final dotPaint =
          Paint()
            ..color = const Color(0xFF1976D2)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 5.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapVectorPainter oldDelegate) {
    return true;
  }
}
