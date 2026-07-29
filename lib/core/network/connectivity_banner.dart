import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Banner "Sin conexión a internet" — BLUEPRINT.md FASE 14 Sprint 8
/// (estados offline). Envuelve toda la app vía el `builder` de MaterialApp,
/// sin que cada pantalla tenga que manejarlo por su cuenta.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _offline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_onResult);
    _subscription = Connectivity().onConnectivityChanged.listen(_onResult);
  }

  void _onResult(List<ConnectivityResult> results) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (offline != _offline && mounted) setState(() => _offline = offline);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _offline
              ? Material(
                  color: AppColors.error,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Sin conexión a internet',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
