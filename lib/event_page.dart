import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventPage extends StatelessWidget {
  const EventPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "ENCRYPTED SYSTEM LOGS",
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('events')
            .stream(primaryKey: ['id'])
            .eq('device_id', 'car_001')
            .order('id', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "TERMINAL IDLE: NO RECENT EVENTS",
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            );
          }

          final events = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final String type = event['event_type'].toString().toUpperCase();
              final String value = event['event_value'] ?? "Data Ping Received";

              // Date formatting for the log
              final String createdAt = event['created_at'].toString();
              final String timestamp = createdAt.length > 16
                  ? createdAt.substring(11, 19)
                  : "--:--:--";

              final bool isAlert = type.contains("VIBRATION") || type.contains("INTRUSION");
              final Color themeColor = isAlert ? Colors.redAccent : Colors.tealAccent;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isAlert ? Colors.redAccent.withOpacity(0.02) : Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: themeColor.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAlert ? Icons.gpp_maybe : Icons.terminal_rounded,
                        color: themeColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timestamp,
                          style: const TextStyle(
                            color: Colors.white12,
                            fontSize: 9,
                            fontFamily: 'Courier',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.check_circle_outline, size: 10, color: Colors.white10),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}