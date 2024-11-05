import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
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
  int _idleLimit = 30;

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
      if (_idleTime >= _idleLimit) {
        _sendShutdownRequest();
      }
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

  Future<void> _sendShutdownRequest() async {
    await http.post(Uri.parse('http://localhost:5000/shutdown'));
  }

  Future<void> _setIdleLimit(int limit) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/set_idle_limit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"limit": limit}),
    );
    if (response.statusCode == 200) {
      setState(() {
        _idleLimit = limit;
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoShut Inactivity Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettingsDialog(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          "Idle time: $_idleTime seconds",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int _newLimit = _idleLimit;
        return AlertDialog(
          title: const Text("Set Idle Limit"),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _newLimit = int.tryParse(value) ?? _idleLimit;
            },
            decoration: InputDecoration(hintText: "$_idleLimit seconds"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _setIdleLimit(_newLimit);
                Navigator.of(context).pop();
              },
              child: const Text("Set"),
            ),
          ],
        );
      },
    );
  }
}
