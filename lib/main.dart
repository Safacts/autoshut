import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  runApp(const AutoShutApp());
}

class AutoShutApp extends StatelessWidget {
  const AutoShutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
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
  int _idleLimit = 30; // Default value if none is saved
  bool _showCountdown = false;
  int _countdownTime = 5;
  Process? _pythonProcess;

  @override
  void initState() {
    super.initState();
    _loadIdleLimit();
    startPythonServer();
    startMonitoring();
  }

  Future<void> _loadIdleLimit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _idleLimit = prefs.getInt('idle_limit') ?? 30;
    });
  }

  Future<void> _saveIdleLimit(int limit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('idle_limit', limit);
  }

  Future<void> startPythonServer() async {
    try {
      print("Starting Python server...");
      _pythonProcess = await Process.start('python', ['idle_server.py'],
          workingDirectory: Directory.current.path);

      _pythonProcess?.stdout.transform(utf8.decoder).listen((data) {
        print("Python server output: $data");
      });
      _pythonProcess?.stderr.transform(utf8.decoder).listen((data) {
        print("Python server error: $data");
      });
      print("Python server started successfully.");
    } catch (e) {
      print("Error starting Python server: $e");
    }
  }

  void startMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      int idleTime = await _fetchIdleTime();
      setState(() {
        _idleTime = idleTime;
      });

      if (_idleTime >= _idleLimit - _countdownTime) {
        setState(() {
          _showCountdown = true;
        });
      } else {
        setState(() {
          _showCountdown = false;
        });
      }

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
    setState(() {
      _idleLimit = limit;
    });
    _saveIdleLimit(limit);
  }

  void _resetIdleTime() async {
    setState(() {
      _idleTime = 0;
      _showCountdown = false;
    });
    await http.post(Uri.parse('http://localhost:5000/reset_idle_time'));
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pythonProcess?.kill();
    super.dispose();
  }

  Future<void> _authenticateAndOpenSettings() async {
    showDialog(
      context: context,
      builder: (context) {
        String inputPassword = '';
        return AlertDialog(
          title: const Text("Enter Password"),
          content: TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              inputPassword = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (inputPassword == '4321') {
                  Navigator.of(context).pop();
                  _openSettingsDialog();
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Incorrect password"),
                  ));
                }
              },
              child: const Text("Enter"),
            ),
          ],
        );
      },
    );
  }
void _openSettingsDialog() {
  showDialog(
    context: context,
    builder: (context) {
      int newLimit = _idleLimit;
      return AlertDialog(
        title: const Text("Set Idle Limit"),
        content: DropdownButton<int>(
          value: newLimit,
          items: List.generate(60, (index) {
            return DropdownMenuItem(
              value: index,
              child: Text("$index seconds"),
            );
          }),
          onChanged: (int? newValue) {
            setState(() {
              newLimit = newValue ?? _idleLimit;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _setIdleLimit(newLimit);
              Navigator.of(context).pop();
            },
            child: const Text("Set"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AutoShut Inactivity Monitor'),
          automaticallyImplyLeading: false, // Remove back button in AppBar
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _authenticateAndOpenSettings,
            ),
          ],
        ),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Idle time: $_idleTime seconds",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  AnimatedGradientText(
                    text: "Made with 💖 by Aadi",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (_showCountdown) _buildCountdownOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    int remainingTime = _idleLimit - _idleTime;
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Text(
          "Shutting down in $remainingTime seconds",
          style: const TextStyle(fontSize: 48, color: Colors.red, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class AnimatedGradientText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const AnimatedGradientText({Key? key, required this.text, required this.style}) : super(key: key);

  @override
  _AnimatedGradientTextState createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 3), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [Colors.pink, Colors.blue, Colors.purple],
              stops: [0.0, _controller.value, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}
