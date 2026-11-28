import 'package:flutter/material.dart';

import 'package:uniandes_food/services/connectivity_status.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';

/// Offline notice for the screens that have no notice of their own.
///
/// Offline it says the screen shows what is saved on the phone; when the
/// connection comes back it says so for a few seconds and then hides.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final status = ConnectivityStatus.instance;
    return ListenableBuilder(
      listenable: status,
      builder: (context, _) {
        final Widget banner;
        if (!status.isOnline) {
          banner = const _Banner(
            icon: Icons.cloud_off_rounded,
            message: 'Offline · showing the information saved on this phone',
            background: AppColors.waitMediumTint,
            foreground: AppColors.waitMediumText,
          );
        } else if (status.justReconnected) {
          banner = const _Banner(
            icon: Icons.cloud_done_rounded,
            message: 'Back online · updating…',
            background: AppColors.tealTint,
            foreground: AppColors.tealText,
          );
        } else {
          banner = const SizedBox(width: double.infinity);
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: banner is SizedBox
              ? banner
              : Padding(padding: padding, child: banner),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.message,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String message;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppText.caption.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
