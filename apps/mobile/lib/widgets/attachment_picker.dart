import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// One picked attachment, source-agnostic (camera, gallery or file).
class PickedAttachment {
  final Uint8List bytes;
  final String name;
  PickedAttachment(this.bytes, this.name);
}

/// Bottom sheet asking where the attachment comes from: take a photo
/// with the camera, pick from the photo library (multi-select when
/// [multiple]), or browse files (images + PDF when [allowPdf]).
/// Returns an empty list when the user cancels.
Future<List<PickedAttachment>> pickAttachments(
  BuildContext context, {
  bool multiple = false,
  bool allowPdf = false,
}) async {
  final source = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: DiraColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final l10n = ctx.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _SourceTile(
              icon: Icons.photo_camera_outlined,
              color: DiraColors.brick,
              label: l10n.takePhoto,
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              color: DiraColors.sageDark,
              label: l10n.fromGallery,
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (allowPdf)
              _SourceTile(
                icon: Icons.folder_open_outlined,
                color: DiraColors.goldDark,
                label: l10n.chooseFile,
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
  if (source == null) return [];

  switch (source) {
    case 'camera':
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2400,
      );
      if (shot == null) return [];
      return [PickedAttachment(await shot.readAsBytes(), shot.name)];

    case 'gallery':
      final picker = ImagePicker();
      if (multiple) {
        final picked = await picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 2400,
        );
        return [
          for (final x in picked) PickedAttachment(await x.readAsBytes(), x.name),
        ];
      }
      final one = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2400,
      );
      if (one == null) return [];
      return [PickedAttachment(await one.readAsBytes(), one.name)];

    default: // file browser (pickFiles is multi-select by default)
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'heic', 'webp',
          if (allowPdf) 'pdf',
        ],
      );
      final files = multiple ? result : result.take(1);
      return [
        for (final f in files) PickedAttachment(await f.readAsBytes(), f.name),
      ];
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
    );
  }
}
