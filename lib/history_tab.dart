import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Stores coordinates grouped by date
  Map<String, List<LatLng>> _routes = {};

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await supabase
          .from('gps_data')
          .select()
          .order('created_at', ascending: true);

      Map<String, List<LatLng>> tempRoutes = {};

      for (var row in data) {
        String timestamp = row['created_at'].toString();
        String date = timestamp.substring(0, 10);

        // Safe Casting
        double lat = (row['latitude'] as num).toDouble();
        double lon = (row['longitude'] as num).toDouble();

        if (!tempRoutes.containsKey(date)) {
          tempRoutes[date] = [];
        }
        tempRoutes[date]!.add(LatLng(lat, lon));
      }

      if (mounted) {
        setState(() {
          _routes = tempRoutes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("History Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : _routes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _routes.keys.length,
        itemBuilder: (context, index) {
          String date = _routes.keys.elementAt(_routes.keys.length - 1 - index);
          List<LatLng> points = _routes[date]!;
          return _buildRouteCard(date, points);
        },
      ),
    );
  }

  Widget _buildRouteCard(String date, List<LatLng> points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.route_rounded, size: 18, color: Colors.tealAccent),
            title: Text(date, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            trailing: Text("${points.length} POINTS", style: const TextStyle(color: Colors.white24, fontSize: 9)),
          ),
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: points.isNotEmpty ? points.first : const LatLng(0, 0),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.jayed.trackon',
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
                  PolylineLayer(
                    // FIX: Explicitly typed Polyline<Object> to match flutter_map 8.x requirements
                    polylines: [
                      Polyline<Object>(
                        points: points,
                        color: Colors.tealAccent,
                        strokeWidth: 3,
                        // FIX: Removed 'isDotted' as it is handled via strokePattern in newer versions
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("NO MOVEMENT DATA", style: TextStyle(color: Colors.white24, fontSize: 10)),
    );
  }
}