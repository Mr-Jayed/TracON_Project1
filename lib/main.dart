import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:'https://bmynlzludgipzbunndrh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJteW5semx1ZGdpcHpidW5uZHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxODY0MTUsImV4cCI6MjA3MTc2MjQxNX0.EH3FlCPNVOGRKsMGqVC3jJ_uwrgiJAL5bxIiXQI2OtU',
  );
  runApp(const TrackOnApp());
}
