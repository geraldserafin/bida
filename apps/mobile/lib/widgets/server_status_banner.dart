import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Base URL of the backend. 10.0.2.2 is the host machine as seen from the
/// Android emulator; override with `--dart-define=API_URL=...`.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

/// Thin strip showing whether the backend `/health` endpoint is reachable.
class ServerStatusBanner extends StatefulWidget {
  const ServerStatusBanner({super.key});

  @override
  State<ServerStatusBanner> createState() => _ServerStatusBannerState();
}

class _ServerStatusBannerState extends State<ServerStatusBanner> {
  late Future<String> _status = _check();

  Future<String> _check() async {
    final res = await http
        .get(Uri.parse('$apiUrl/health'))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return 'Server: ${json['status']} (uptime ${json['uptimeSeconds']}s)';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _status,
      builder: (context, snap) {
        final (text, color) = switch (snap) {
          AsyncSnapshot(hasError: true) => ('Server: offline', Colors.red),
          AsyncSnapshot(hasData: true) => (snap.data!, Colors.green),
          _ => ('Server: checking…', Colors.orange),
        };
        return Material(
          color: color,
          child: InkWell(
            onTap: () => setState(() => _status = _check()),
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
