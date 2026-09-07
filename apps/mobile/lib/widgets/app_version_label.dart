import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme.dart';

/// Small muted "v1.0.0 (10)" label for login / settings.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, this.alignment = Alignment.center});

  final AlignmentGeometry alignment;

  static Future<PackageInfo>? _infoFuture;

  static Future<PackageInfo> _load() =>
      _infoFuture ??= PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _load(),
      builder: (context, snap) {
        final info = snap.data;
        if (info == null) return const SizedBox.shrink();
        final label = 'v${info.version} (${info.buildNumber})';
        return Align(
          alignment: alignment,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.2,
              color: DiraColors.inkSoft,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        );
      },
    );
  }
}
