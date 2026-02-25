import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Supabase.initialize(
    url: 'https://bmynlzludgipzbunndrh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJteW5semx1ZGdpcHpidW5uZHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxODY0MTUsImV4cCI6MjA3MTc2MjQxNX0.EH3FlCPNVOGRKsMGqVC3jJ_uwrgiJAL5bxIiXQI2OtU',
  );
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("e81fbf1a-1e59-4bc3-8254-1f738607b947");
  OneSignal.Notifications.requestPermission(true);

  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    OneSignal.login(currentUser.id);
  }

  runApp(const TrackOnApp());
}