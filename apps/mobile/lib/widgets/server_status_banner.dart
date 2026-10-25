import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/planner_repository.dart';

/// Thin strip showing whether the backend `/health` endpoint is reachable.
class ServerStatusBanner extends StatefulWidget {
  const ServerStatusBanner({super.key});

  @override
  State<ServerStatusBanner> createState() => _ServerStatusBannerState();
}

class _ServerStatusBannerState extends State<ServerStatusBanner> {
  late Future<String> _status = _check();

  Future<String> _check() async {
    final health = await context.read<PlannerRepository>().health();
    return 'Server: ${health.status} (uptime ${health.uptimeSeconds}s)';
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
