import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Pantalla de carga full-screen — BLUEPRINT.md FASE 6.
/// Reemplaza los azules hardcoded del LoadingScreen web (⚠️ FASE 2.2) por la paleta edu-*.
class LoadingScreenWidget extends StatelessWidget {
  const LoadingScreenWidget({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DoubleRingSpinner(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoubleRingSpinner extends StatelessWidget {
  const _DoubleRingSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryLight),
            ),
          ),
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
