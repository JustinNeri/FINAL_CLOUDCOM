import 'dart:convert';

import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:http/http.dart' as http;

import 'instance_toggle.dart';

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

  static const _endpoint =
      'https://xfnttovxp5.execute-api.eu-west-3.amazonaws.com/default/STOP_AND_START';

  @override
  void initState() {
    super.initState();
    instanceOn = widget.initialStatus;
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    const baseGreen = ThemeColors.deepNavy;
    const accentGreen = Color(0xFFFFCB05);
    const borderGreen = Color(0xFFCADBC5);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(instanceOn);
        return false;
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
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 6)),
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
                                  color: ThemeColors.pokeBlue.withOpacity(0.06),
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
                                      activeColor: ThemeColors.pokeYellow,
                                      activeTrackColor: ThemeColors.pokeBlue.withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                instanceOn ? 'All systems nominal' : 'Paused for maintenance',
                                style: TextStyle(color: ThemeColors.deepNavy.withOpacity(0.72), fontSize: 13),
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
      final body = resp.body.toLowerCase();
      final running = body.contains('running') || body.contains('online') || body.contains('started');
      final stopping = body.contains('stopping') || body.contains('shutting');
      final stopped = body.contains('stopped') || body.contains('offline');
      final newState = running || stopping ? true : stopped ? false : instanceOn;
      setState(() {
        instanceOn = newState;
        initialFetchDone = true;
      });
    } catch (e) {
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

      setState(() {
        instanceOn = targetState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Instance ${action == 'start' ? 'started' : 'stopped'}'),
            backgroundColor: baseGreen,
          ),
        );
      }
    } catch (e) {
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
    final uri = Uri.parse(_endpoint).replace(queryParameters: {'action': action});
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

class _PowerToggle extends StatefulWidget {
  const _PowerToggle({
    required this.value,
    required this.onChanged,
    required this.size,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  State<_PowerToggle> createState() => _PowerToggleState();
}

class _PowerToggleState extends State<_PowerToggle> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    if (widget.value) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PowerToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.value && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moduleBg = ThemeColors.cardNavy;
    final neonGreen = const Color(0xFF39FF14);

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = widget.value ? (_pulseController.value * 0.6 + 0.4) : 1.0;
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.value
                  ? RadialGradient(colors: [neonGreen.withOpacity(0.98), neonGreen.withOpacity(0.22)])
                  : RadialGradient(colors: [ThemeColors.pokeRed.withOpacity(0.95), ThemeColors.pokeRed.withOpacity(0.24)]),
              boxShadow: [
                BoxShadow(
                  color: widget.value ? neonGreen.withOpacity(0.26 * pulse) : ThemeColors.pokeRed.withOpacity(0.16),
                  blurRadius: widget.value ? 28 * pulse : 10,
                  spreadRadius: widget.value ? 4 * pulse : 1,
                ),
              ],
            ),
            child: Center(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                alignment: widget.value ? Alignment.topCenter : Alignment.bottomCenter,
                curve: Curves.easeInOut,
                child: Container(
                  width: widget.size * 0.54,
                  height: widget.size * 0.54,
                  decoration: BoxDecoration(
                    color: moduleBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.06), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 4, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: Icon(Icons.power_settings_new, color: Colors.white, size: widget.size * 0.26),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
