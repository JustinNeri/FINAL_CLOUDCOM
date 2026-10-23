import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'instance_status.dart';
import 'theme.dart';
import 'widgets.dart';

class InstanceScreen extends StatefulWidget {
  const InstanceScreen({
    super.key,
    required this.initialState,
    this.pollInterval = const Duration(seconds: 5),
  });

  final InstanceState initialState;

  /// How often to re-check the status while the server is starting or stopping.
  final Duration pollInterval;

  @override
  State<InstanceScreen> createState() => _InstanceScreenState();
}

class _InstanceScreenState extends State<InstanceScreen> {
  /// Give up polling after this many checks (about 3 minutes at 5 s).
  static const _maxPolls = 36;

  late InstanceState _state = widget.initialState;
  bool _checking = false;
  bool _sending = false;
  String? _error;
  DateTime? _lastChecked;
  Timer? _pollTimer;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final resp = await callInstanceApi('status');
      if (!mounted) return;
      final parsed = parseInstanceState(resp.body);
      setState(() {
        // While waiting for a start/stop, an unreadable reply keeps the transition shown.
        if (!(parsed == InstanceState.unknown && _state.isTransitioning)) _state = parsed;
        _lastChecked = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _error = requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }

    if (mounted && !_state.isTransitioning) _stopPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _polls = 0;
    _pollTimer = Timer.periodic(widget.pollInterval, (_) {
      _polls++;
      if (_polls > _maxPolls) {
        _stopPolling();
        setState(() => _error = 'The server is taking longer than expected. Refresh to check again.');
        return;
      }
      _refreshStatus();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _sendAction(String action) async {
    if (action == 'stop') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Stop the server?'),
          content: const Text('Players will not be able to detect or catch monsters until it is started again.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ThemeColors.pokeRed),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Stop server'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await callInstanceApi(action);
      if (!mounted) return;
      setState(() => _state = action == 'start' ? InstanceState.starting : InstanceState.stopping);
      _startPolling();
    } catch (e) {
      if (mounted) setState(() => _error = requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _sending || _state.isTransitioning;

    return PopScope<InstanceState>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Hand the latest state back to the dashboard on any back action.
        if (!didPop) Navigator.of(context).pop(_state);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Server Instance'),
          actions: [
            IconButton(
              tooltip: 'Refresh status',
              onPressed: _checking ? null : _refreshStatus,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ContentWidth(
              maxWidth: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              key: ValueKey(_state),
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _state.color.withValues(alpha: 0.12),
                                border: Border.all(color: _state.color.withValues(alpha: 0.4), width: 3),
                              ),
                              child: Icon(_state.icon, color: _state.color, size: 46),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _state.label,
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _state.color),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _state.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: ThemeColors.textMuted, height: 1.4),
                          ),
                          if (_state.isTransitioning) ...[
                            const SizedBox(height: 18),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(minHeight: 6, color: _state.color),
                            ),
                            const SizedBox(height: 8),
                            const Text('Checking every few seconds…', style: TextStyle(color: ThemeColors.textMuted, fontSize: 12)),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            _checking
                                ? 'Checking status…'
                                : _lastChecked == null
                                    ? 'Not checked yet'
                                    : 'Last checked at ${TimeOfDay.fromDateTime(_lastChecked!).format(context)}',
                            style: const TextStyle(color: ThemeColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    MessageBanner(message: _error!, onRetry: _refreshStatus),
                  ],
                  const SizedBox(height: 20),
                  if (_state != InstanceState.running)
                    FilledButton.icon(
                      onPressed: busy ? null : () => _sendAction('start'),
                      icon: _sending ? const ButtonSpinner() : const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start server'),
                    ),
                  if (_state != InstanceState.running && _state != InstanceState.stopped)
                    const SizedBox(height: 10),
                  if (_state != InstanceState.stopped)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: ThemeColors.pokeRed),
                      onPressed: busy ? null : () => _sendAction('stop'),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop server'),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_state),
                    child: const Text('Back to dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
