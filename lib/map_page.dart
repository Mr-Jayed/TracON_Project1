import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();
  StreamSubscription? _locationSub;

  // Initial center position (e.g., Dhaka)
  LatLng _currentPos = const LatLng(23.8103, 90.4125);
  double _currentSpeed = 0.0;
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _listenToLocation();
  }

  void _listenToLocation() {
    _locationSub = supabase
        .from('gps_data')
        .stream(primaryKey: ['id'])
        .eq('device_id', 'car_001')
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        // --- SAFE CASTING LOGIC ---
        // Converts num to double to avoid "int is not a subtype of double" error
        final double lat = (data.last['latitude'] as num).toDouble();
        final double lng = (data.last['longitude'] as num).toDouble();
        final double speed = (data.last['speed'] as num? ?? 0.0).toDouble();

        setState(() {
          _currentPos = LatLng(lat, lng);
          _currentSpeed = speed;
          _hasLocation = true;
        });

        // Smoothly move camera to new location
        _mapController.move(_currentPos, 15.0);
      }
    }, onError: (error) {
      debugPrint("Map Stream Error: $error");
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("LIVE TELEMETRY MAP",
            style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPos,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jayed.trackon.car_tracker',
                // Optional: Invert tiles for Dark Mode look
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -1, 0, 0, 0, 255,
                      0, -1, 0, 0, 255,
                      0, 0, -1, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: tileWidget,
                  );
                },
              ),
              if (_hasLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPos,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                            child: const Icon(Icons.navigation, color: Colors.tealAccent, size: 30),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Speed & Status HUD
          if (_hasLocation)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHUDItem("SPEED", "${_currentSpeed.toStringAsFixed(1)} KM/H"),
                  _buildHUDItem("SIGNAL", "4G / GPS"),
                ],
              ),
            ),

          // Loading Overlay
          if (!_hasLocation)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.tealAccent),
                    SizedBox(height: 20),
                    Text("SYNCHRONIZING WITH CAR_001...",
                        style: TextStyle(color: Colors.tealAccent, fontSize: 10, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHUDItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 8)),
          Text(value, style: const TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}