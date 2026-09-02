import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import 'attachment_picker.dart';

/// Upload composer: a title plus any number of attachments gathered
/// from the camera (scan), the photo library or the file browser.
/// When [apartmentId] is set, documents are scoped to that unit's vault.
class UploadDocumentSheet extends StatefulWidget {
  final String? apartmentId;

  const UploadDocumentSheet({super.key, this.apartmentId});

  @override
  State<UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<UploadDocumentSheet> {
  final _title = TextEditingController();
  final List<PickedAttachment> _files = [];
  bool _busy = false;
  String? _error;

  bool get _valid => _title.text.trim().length >= 2 && _files.isNotEmpty;

  Future<void> _addFiles() async {
    final picked = await pickAttachments(
      context,
      multiple: true,
      allowPdf: true,
    );
    if (picked.isNotEmpty) setState(() => _files.addAll(picked));
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final title = _title.text.trim();
    final aptId = widget.apartmentId;
    try {
      for (final (i, f) in _files.indexed) {
        await api.uploadFile(
          '/api/documents',
          bytes: f.bytes,
          filename: f.name,
          fields: {
            'title': _files.length == 1
                ? title
                : '$title · ${i + 1}/${_files.length}',
            'apartmentId': ?aptId,
          },
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.uploadDocument,
                textAlign: TextAlign.center,
                style: heading(fontSize: 18),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _title,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l10n.titleLabel),
              ),
              const SizedBox(height: 12),
              for (final (i, f) in _files.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: f.name.toLowerCase().endsWith('.pdf')
                            ? Container(
                                width: 44,
                                height: 44,
                                color: DiraColors.creamDeep,
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 20,
                                  color: DiraColors.brick,
                                ),
                              )
                            : Image.memory(
                                f.bytes,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: DiraColors.inkSoft,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close,
                          size: 17,
                          color: DiraColors.inkSoft,
                        ),
                        onPressed: () => setState(() => _files.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _addFiles,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(
                  _files.isEmpty ? l10n.addAttachment : l10n.addMoreFiles,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _busy || !_valid ? null : _send,
                child: Text(
                  _busy
                      ? l10n.pleaseWait
                      : _files.length > 1
                      ? l10n.uploadNFiles('${_files.length}')
                      : l10n.uploadDocument,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: DiraColors.brick),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
