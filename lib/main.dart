import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AutoShutApp());
}

class AutoShutApp extends StatelessWidget {
  const AutoShutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idleTime = 0;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    startMonitoring();
  }

  void startMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      int idleTime = await _fetchIdleTime();
      setState(() {
        _idleTime = idleTime;
      });
    });
  }

  Future<int> _fetchIdleTime() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/idle_time'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['idle_time'];
      }
    } catch (e) {
      print("Error fetching idle time: $e");
    }
    return 0;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AutoShut Inactivity Monitor')),
      body: Center(
        child: Text(
          "Idle time: $_idleTime seconds",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
