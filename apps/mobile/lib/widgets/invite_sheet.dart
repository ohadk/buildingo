import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Bottom sheet with the building's join link: copy to clipboard or share
/// on WhatsApp. Used from the residents screen and the Vaad home quick
/// action, so inviting is never WhatsApp-only.
Future<void> showInviteSheet(BuildContext context) async {
  final session = context.read<SessionController>();
  final code = session.building?.joinCode;
  if (code == null) return;
  final link = '${ApiClient.baseUrl}/join/$code';
  final message = context.l10n.shareJoinMessage(
    session.building?.name ?? '',
    link,
  );

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: DiraColors.creamCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final l10n = ctx.l10n;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DiraColors.inkSoft.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                l10n.inviteResidents,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DiraColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.inviteLinkExplain,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: DiraColors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: DiraColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DiraColors.inkSoft.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        link,
                        textDirection: TextDirection.ltr,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: DiraColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.copyLink,
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 20,
                        color: DiraColors.brick,
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: link));
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(l10n.joinLinkCopied)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(l10n.copyLink),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: link));
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.joinLinkCopied)),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: Text(l10n.shareOnWhatsapp),
                      onPressed: () {
                        Navigator.pop(ctx);
                        launchUrl(
                          Uri.parse(
                            'https://wa.me/?text=${Uri.encodeComponent(message)}',
                          ),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
