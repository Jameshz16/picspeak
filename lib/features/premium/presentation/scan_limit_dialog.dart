import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/nb_animations.dart';
import '../../../app/theme.dart';
import '../data/premium_providers.dart';

/// Dialog shown when the user hits the daily scan limit.
///
/// Offers two paths:
///   1. Watch a rewarded ad → +3 bonus scans
///   2. Upgrade to Premium → unlimited scans
class ScanLimitDialog extends ConsumerStatefulWidget {
  final VoidCallback? onUpgrade;

  const ScanLimitDialog({
    super.key,
    this.onUpgrade,
  });

  /// Show the dialog. Returns the user's choice:
  ///   'ad'      — user watched ad and earned reward
  ///   'upgrade' — user tapped upgrade
  ///   'close'   — user dismissed
  static Future<String?> show(
    BuildContext context, {
    VoidCallback? onUpgrade,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScanLimitDialog(
        onUpgrade: onUpgrade,
      ),
    );
  }

  @override
  ConsumerState<ScanLimitDialog> createState() => _ScanLimitDialogState();
}

class _ScanLimitDialogState extends ConsumerState<ScanLimitDialog> {
  bool _isWatchingAd = false;
  bool _adNotReady = false;

  Future<void> _watchAd() async {
    setState(() {
      _isWatchingAd = true;
      _adNotReady = false;
    });

    try {
      final adMobService = ref.read(adMobServiceProvider);
      final earned = await adMobService.showRewardedAd();

      if (earned && mounted) {
        // Grant +3 bonus scans
        final scanLimitRepo = ref.read(scanLimitRepositoryProvider);
        await scanLimitRepo.grantBonusScans(3);

        if (mounted) {
          // Invalidate providers to update UI
          ref.invalidate(remainingScansProvider);
          ref.invalidate(todayScanCountProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 +3 bonus scans earned!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pop('ad');
        }
      } else if (mounted) {
        setState(() {
          _adNotReady = true;
          _isWatchingAd = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adNotReady = true;
          _isWatchingAd = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingScans = ref.watch(remainingScansProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NbRadius.xs),
      ),
      title: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            '¡Hoy descubriste 5 objetos!',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          remainingScans.when(
            data: (remaining) => Text(
              remaining == 0
                  ? 'Mañana tienes 5 miradas más esperándote. ¿Quieres seguir explorando ahora?'
                  : 'Lens tiene $remaining miradas más hoy.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Text(
              'Lens necesita descansar. Vuelve mañana.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Watch Ad button
          SizedBox(
            width: double.infinity,
            child: NbPressable(
              child: OutlinedButton.icon(
                onPressed: _isWatchingAd ? null : _watchAd,
                icon: _isWatchingAd
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(
                  _adNotReady
                      ? 'Ad not ready — try again'
                      : 'Ver anuncio por +3 miradas',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NbRadius.xs),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: NbPressable(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop('upgrade');
                  widget.onUpgrade?.call();
                },
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Premium — Miradas ilimitadas'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NbRadius.xs),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Close
          TextButton(
            onPressed: () => Navigator.of(context).pop('close'),
            child: const Text('Quizás después'),
          ),
        ],
      ),
    );
  }
}
