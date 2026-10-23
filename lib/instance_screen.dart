import 'dart:convert';

import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

class InstanceScreen extends StatefulWidget {
  const InstanceScreen({super.key, required this.initialStatus});

  final bool initialStatus;

  @override
  State<InstanceScreen> createState() => _InstanceScreenState();
}

class _InstanceScreenState extends State<InstanceScreen> {
  late bool instanceOn;
  bool isLoading = false;
  String? error;
  bool initialFetchDone = false;

  @override
  void initState() {
    super.initState();
    instanceOn = widget.initialStatus;
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Hand the current status back to the dashboard on system back too.
        if (!didPop) Navigator.of(context).pop(instanceOn);
      },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('Instance Control', style: TextStyle(color: ThemeColors.deepNavy)),
        iconTheme: const IconThemeData(color: ThemeColors.deepNavy),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(instanceOn),
            child: CircleAvatar(
              backgroundColor: ThemeColors.pokeYellow,
              child: const Icon(Icons.arrow_back, color: ThemeColors.deepNavy),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: ThemeColors.pokeYellow,
              child: const Icon(Icons.power_settings_new, color: ThemeColors.deepNavy),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5FAF4), Color(0xFFE8F1E6)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toggle the instance to enable or pause catching and detection flows.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                if (!initialFetchDone && isLoading)
                  Row(
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading instance status...'),
                    ],
                  ),
                if (initialFetchDone)
                  Center(
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final size = (constraints.maxWidth < 600) ? constraints.maxWidth * 0.9 : 520.0;
                        final containerWidth = (size < 420) ? size * 0.9 : 420.0;
                        return Container(
                          width: containerWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Instance Status',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ThemeColors.deepNavy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (instanceOn) ...[
                                    Icon(Icons.flash_on, color: ThemeColors.pokeYellow, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Online', style: TextStyle(color: ThemeColors.deepNavy, fontWeight: FontWeight.w700, fontSize: 16)),
                                  ] else ...[
                                    Text('Offline', style: TextStyle(color: ThemeColors.pokeRed, fontWeight: FontWeight.w700, fontSize: 16)),
                                  ]
                                ],
                              ),
                              const SizedBox(height: 18),
                              // Standard left-right Switch inside a Pokemon-themed container
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: ThemeColors.pokeBlue.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.power_settings_new, color: instanceOn ? ThemeColors.pokeYellow : ThemeColors.pokeRed),
                                    const SizedBox(width: 8),
                                    Switch.adaptive(
                                      value: instanceOn,
                                      onChanged: (v) => _updateInstance(v, ThemeColors.pokeBlue),
                                      activeThumbColor: ThemeColors.pokeYellow,
                                      activeTrackColor: ThemeColors.pokeBlue.withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                instanceOn ? 'All systems nominal' : 'Paused for maintenance',
                                style: TextStyle(color: ThemeColors.deepNavy.withValues(alpha: 0.72), fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (isLoading && initialFetchDone)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Updating instance...'),
                      ],
                    ),
                  ),
                if (error != null && !isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.pokeYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(instanceOn),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.black),
                    label: const Text('Save status'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> _refreshStatus() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final resp = await _callApi('status');
      if (!mounted) return;
      final body = resp.body.toLowerCase();
      final running = body.contains('running') || body.contains('online') || body.contains('started');
      // A stopping instance is going down, so it counts as offline.
      final stopping = body.contains('stopping') || body.contains('shutting');
      final stopped = body.contains('stopped') || body.contains('offline');
      final newState = stopping ? false : running ? true : stopped ? false : instanceOn;
      setState(() {
        instanceOn = newState;
        initialFetchDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Error: $e';
        initialFetchDone = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateInstance(bool targetState, Color baseGreen) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      error = null;
    });

    final action = targetState ? 'start' : 'stop';
    try {
      await _callApi(action);
      if (!mounted) return;

      setState(() {
        instanceOn = targetState;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Instance ${action == 'start' ? 'started' : 'stopped'}'),
          backgroundColor: baseGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<http.Response> _callApi(String action) async {
    final uri = Uri.parse(instanceApi).replace(queryParameters: {'action': action});
    http.Response? lastResponse;

    // Try POST first (include action in both body and query to handle non-proxy integrations)
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );
      if (resp.statusCode == 200) return resp;
      lastResponse = resp;
    } catch (e) {
      // swallow and attempt GET below
      lastResponse = null;
    }

    // Fallback to GET with query param
    final getResp = await http.get(uri);
    if (getResp.statusCode == 200) return getResp;

    final msg = lastResponse != null
      ? 'POST failed: ${lastResponse.statusCode} ${lastResponse.body} | GET failed: ${getResp.statusCode} ${getResp.body}'
      : 'POST error then GET failed: ${getResp.statusCode} ${getResp.body}';
    throw Exception(msg);
  }
}
