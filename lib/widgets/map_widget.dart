import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/geo_point.dart';

class MapWidget extends StatefulWidget {
  final AppGeoPoint? initialPosition;
  final AppGeoPoint? startPoint;
  final AppGeoPoint? endPoint;
  final List<AppGeoPoint>? routePoints; // Points de la route calculée
  final List<AppGeoPoint>? waypoints;
  final bool showCurrentLocation;
  final Function(AppGeoPoint)? onMapTap;
  final double zoom;
  final bool showZoomControls;

  const MapWidget({
    Key? key,
    this.initialPosition,
    this.startPoint,
    this.endPoint,
    this.routePoints,
    this.waypoints,
    this.showCurrentLocation = true,
    this.onMapTap,
    this.zoom = 13.0,
    this.showZoomControls = true,
  }) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _setupPolylines();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startPoint != widget.startPoint ||
        oldWidget.endPoint != widget.endPoint ||
        oldWidget.routePoints != widget.routePoints ||
        oldWidget.waypoints != widget.waypoints) {
      _setupMarkers();
      _setupPolylines();
      _fitBounds();
    }
  }

  void _setupMarkers() {
    _markers.clear();

    // Marker pour le point de départ (vert)
    if (widget.startPoint != null) {
      _markers.add(
        Marker(
          point: LatLng(
            widget.startPoint!.latitude,
            widget.startPoint!.longitude,
          ),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
    }

    // Marker pour le point d'arrivée (rouge)
    if (widget.endPoint != null) {
      _markers.add(
        Marker(
          point: LatLng(widget.endPoint!.latitude, widget.endPoint!.longitude),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    // Markers pour les waypoints (bleu)
    if (widget.waypoints != null) {
      for (var waypoint in widget.waypoints!) {
        _markers.add(
          Marker(
            point: LatLng(waypoint.latitude, waypoint.longitude),
            width: 35,
            height: 35,
            child: const Icon(Icons.location_on, color: Colors.blue, size: 35),
          ),
        );
      }
    }
  }

  void _setupPolylines() {
    _polylines.clear();

    // Si on a des points de route calculés, les utiliser
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      List<LatLng> polylinePoints = widget.routePoints!
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      _polylines.add(
        Polyline(
          points: polylinePoints,
          strokeWidth: 5.0,
          color: Colors.blue,
        ),
      );
    }
    // Sinon, tracer une ligne droite entre départ et arrivée
    else if (widget.startPoint != null && widget.endPoint != null) {
      List<LatLng> polylinePoints = [
        LatLng(widget.startPoint!.latitude, widget.startPoint!.longitude),
      ];

      // Ajouter les waypoints
      if (widget.waypoints != null) {
        for (var waypoint in widget.waypoints!) {
          polylinePoints.add(LatLng(waypoint.latitude, waypoint.longitude));
        }
      }

      polylinePoints.add(
        LatLng(widget.endPoint!.latitude, widget.endPoint!.longitude),
      );

      _polylines.add(
        Polyline(
          points: polylinePoints,
          strokeWidth: 4.0,
          color: Colors.blue.withOpacity(0.5),
          // isDotted a été supprimé dans flutter_map 7.x
          // Pour un effet pointillé, utilisez strokePattern
          pattern: const StrokePattern.dotted(),
        ),
      );
    }
  }

  LatLng _getInitialCenter() {
    if (widget.initialPosition != null) {
      return LatLng(
        widget.initialPosition!.latitude,
        widget.initialPosition!.longitude,
      );
    } else if (widget.startPoint != null) {
      return LatLng(widget.startPoint!.latitude, widget.startPoint!.longitude);
    }
    // Position par défaut (Tunis, Tunisie)
    return LatLng(36.8065, 10.1815);
  }

  void _fitBounds() {
    if (widget.startPoint != null && widget.endPoint != null) {
      try {
        final bounds = LatLngBounds(
          LatLng(
            widget.startPoint!.latitude < widget.endPoint!.latitude
                ? widget.startPoint!.latitude
                : widget.endPoint!.latitude,
            widget.startPoint!.longitude < widget.endPoint!.longitude
                ? widget.startPoint!.longitude
                : widget.endPoint!.longitude,
          ),
          LatLng(
            widget.startPoint!.latitude > widget.endPoint!.latitude
                ? widget.startPoint!.latitude
                : widget.endPoint!.latitude,
            widget.startPoint!.longitude > widget.endPoint!.longitude
                ? widget.startPoint!.longitude
                : widget.endPoint!.longitude,
          ),
        );

        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
        );
      } catch (e) {
        print('Erreur lors du fit bounds: $e');
      }
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latlng) {
    if (widget.onMapTap != null) {
      widget.onMapTap!(
        AppGeoPoint(latitude: latlng.latitude, longitude: latlng.longitude),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _getInitialCenter(),
            initialZoom: widget.zoom,
            minZoom: 3.0,
            maxZoom: 18.0,
            onTap: _handleMapTap,
          ),
          children: [
            // Couche de tuiles OpenStreetMap
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.covoiturage',
            ),

            // Couche de polylines (trajets)
            if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),

            // Couche de markers
            if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
          ],
        ),

        // Contrôles de zoom
        if (widget.showZoomControls)
          Positioned(
            right: 10,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
