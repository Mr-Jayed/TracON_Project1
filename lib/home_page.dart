import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import 'event_page.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'history_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();


  int _currentIndex = 0;
  bool _loading = true;
  bool _isVehicleOnline = false;
  bool _isAlertActive = false;
  DateTime? _lastSeen;


  String _engineStatus = 'OFF';
  String _doorStatus = 'LOCKED';
  String _distance = '--';


  bool _isEnginePending = false;
  bool _isDoorPending = false;


  StreamSubscription? _telemetrySub, _commandSub, _securitySub;
  Timer? _heartbeatTimer;
  List<Map<String, dynamic>> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _initializeData();

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _updateOnlineStatus(),
    );
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _commandSub?.cancel();
    _securitySub?.cancel();
    _heartbeatTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }



  void _initializeData() async {
    await _fetchInitialState();
    _setupRealtimeStreams();
  }

  void _setupRealtimeStreams() {

    _commandSub = supabase
        .from('device_commands')
        .stream(primaryKey: ['id'])
        .eq('device_id', 'car_001')
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        final last = data.last;
        if (last['executed'] == true) {
          String cmd = last['command'];
          setState(() {
            if (cmd.contains('engine')) {
              _engineStatus = cmd == 'engine_on' ? 'ON' : 'OFF';
              _isEnginePending = false;
              _showNotification("ENGINE STATUS: $_engineStatus");
            } else {
              _doorStatus = cmd == 'lock' ? 'LOCKED' : 'UNLOCKED';
              _isDoorPending = false;
              _showNotification("DOORS: $_doorStatus");
            }
          });
        }
      }
    });


    _telemetrySub = supabase
        .from('ultrasonic_data')
        .stream(primaryKey: ['id'])
        .eq('device_id', 'car_001')
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        setState(() {
          _distance = data.last['distance_cm'].toString();
          _lastSeen = DateTime.parse(data.last['created_at']).toLocal();
        });
      }
    });


    _securitySub = supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('device_id', 'car_001')
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        final sorted = List<Map<String, dynamic>>.from(data)
          ..sort((a, b) => a['created_at'].compareTo(b['created_at']));

        setState(() {
          _recentEvents = sorted.reversed.take(3).toList();
        });

        final lastEvent = sorted.last;
        final eventTime = DateTime.parse(lastEvent['created_at']).toLocal();

        if (DateTime.now().difference(eventTime).inSeconds < 10) {
          String type = lastEvent['event_type'].toString().toUpperCase();
          if (type.contains("VIBRATION") || type.contains("INTRUSION")) {
            _triggerAlarm(type);
          }
        }
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardBody(),
          const HistoryTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }



  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: _isVehicleOnline ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Text(
            _isVehicleOnline ? "SYSTEM ACTIVE" : "LINK LOST",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (val) {
            if (val == 'profile') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'profile', child: Text("Commander Profile")),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildStatusHeader(),
          const SizedBox(height: 20),
          _buildRadarDisplay(),
          const SizedBox(height: 20),
          _buildMapLink(),
          const SizedBox(height: 40),
          _buildControlSection("IGNITION", "on", "off", Icons.power_settings_new_rounded, Colors.greenAccent, Colors.redAccent, "engine", _isEnginePending),
          const SizedBox(height: 20),
          _buildControlSection("SECURITY", "unlock", "lock", Icons.security_rounded, Colors.tealAccent, Colors.orangeAccent, "door", _isDoorPending),
          const SizedBox(height: 40),
          _buildLiveFeedList(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: const Color(0xFF0A0A0A),
      selectedItemColor: Colors.tealAccent,
      unselectedItemColor: Colors.white24,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.terminal_rounded), label: "TERMINAL"),
        BottomNavigationBarItem(icon: Icon(Icons.history_edu_rounded), label: "HISTORY"),
      ],
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      children: [
        _statusCard("ENGINE", _engineStatus, _engineStatus == 'ON' ? Colors.greenAccent : Colors.white12, Icons.bolt_rounded, _isEnginePending),
        const SizedBox(width: 15),
        _statusCard("DOORS", _doorStatus, _doorStatus == 'LOCKED' ? Colors.redAccent : Colors.tealAccent, Icons.lock_rounded, _isDoorPending),
      ],
    );
  }

  Widget _statusCard(String label, String value, Color color, IconData icon, bool pending) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9)),
                if (pending)
                  const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24))
                else
                  Icon(icon, size: 12, color: color.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text("PROXIMITY RADAR", style: TextStyle(color: Colors.white30, fontSize: 9)),
          const SizedBox(height: 10),
          Text("$_distance CM", style: const TextStyle(color: Colors.tealAccent, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildMapLink() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.tealAccent.withOpacity(0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_rounded, color: Colors.tealAccent, size: 16),
            const SizedBox(width: 10),
            Text("ENGAGE LIVE MAP", style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlSection(String title, String act1, String act2, IconData icon, Color c1, Color c2, String type, bool pending) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 14, color: Colors.white24), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5))]),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionBtn(type, act1, c1, pending),
            const SizedBox(width: 15),
            _actionBtn(type, act2, c2, pending),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(String type, String action, Color col, bool pending) {
    return Expanded(
      child: InkWell(
        onTap: pending ? null : () => _sendCommand(type, action),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: col.withOpacity(0.4)),
          ),
          child: Text(
            action.toUpperCase(),
            style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveFeedList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("SYSTEM LOGS", style: TextStyle(color: Colors.white24, fontSize: 10)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventPage())),
              child: const Text("FULL LOG", style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20)),
          child: _recentEvents.isEmpty
              ? const Center(child: Text("NO DATA", style: TextStyle(color: Colors.white12, fontSize: 10)))
              : Column(
            children: _recentEvents.map((e) {
              final isDanger = e['event_type'].toString().contains('VIBRATION');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: isDanger ? Colors.redAccent : Colors.tealAccent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e['event_type'].toString().toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11))),
                    Text(e['created_at'].toString().substring(11, 16), style: const TextStyle(color: Colors.white10, fontSize: 10))
                  ],
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }



  Future<void> _sendCommand(String type, String action) async {
    setState(() {
      if (type == 'engine') _isEnginePending = true;
      else _isDoorPending = true;
    });

    try {
      await supabase.from('device_commands').insert({
        'device_id': 'car_001',
        'command': type == 'engine' ? 'engine_$action' : action,
        'executed': false
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEnginePending = false;
          _isDoorPending = false;
        });
      }
    }
  }

  void _showNotification(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
        backgroundColor: Colors.tealAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _triggerAlarm(String type) async {
    if (_isAlertActive) return;
    setState(() => _isAlertActive = true);
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('siren.mp3'));
    } catch (e) { debugPrint("Audio error: $e"); }
    _showSecurityAlert(type);
  }

  void _showSecurityAlert(String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A0000),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent)
        ),
        title: const Text("SECURITY BREACH", style: TextStyle(color: Colors.redAccent, fontSize: 14)),
        content: Text("$type detected at car_001. Respond immediately.", style: const TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _audioPlayer.stop();
              setState(() => _isAlertActive = false);
            },
            child: const Text("SILENCE ALARM", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _updateOnlineStatus() {
    if (_lastSeen != null && mounted) {
      setState(() {
        _isVehicleOnline = DateTime.now().difference(_lastSeen!).inSeconds < 35;
      });
    }
  }

  Future<void> _fetchInitialState() async {
    try {
      final last = await supabase
          .from('ultrasonic_data')
          .select()
          .eq('device_id', 'car_001')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (last != null && mounted) {
        setState(() {
          _distance = last['distance_cm'].toString();
          _lastSeen = DateTime.parse(last['created_at']).toLocal();
        });
      }
    } catch (e) { debugPrint("Initial fetch error: $e"); }
    if (mounted) setState(() => _loading = false);
  }
}