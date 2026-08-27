import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/attachment_picker.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<DocumentItem> _docs = [];
  bool _loading = true;
  StreamSubscription<String>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSub = realtime.listen({'documents'}, _load);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await api.get('/api/documents');
      if (!mounted) return;
      setState(() {
        _docs = ((data['documents'] ?? []) as List)
            .map((d) => DocumentItem.fromJson(d))
            .toList();
        _loading = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(DocumentItem doc) async {
    try {
      final res = await api.post('/api/files/signed-url', {
        'bucket': 'documents',
        'path': doc.filePath,
      });
      final url = Uri.parse(res['url']);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw ApiException(0, mounted ? context.l10n.cantOpenDocument : '');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  /// Vaad: upload one or more documents (camera scan, gallery, files).
  Future<void> _upload() async {
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _UploadDocSheet(),
    );
    if (uploaded == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.documentsUploaded)),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isVaad = context.watch<SessionController>().user?.isVaad ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.documents,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: isVaad
          ? FloatingActionButton.extended(
              heroTag: 'docs-fab',
              backgroundColor: DiraColors.brick,
              foregroundColor: DiraColors.creamCard,
              onPressed: _upload,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(l10n.uploadDocument),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: DiraColors.brick,
              child: _docs.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.noDocuments,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: DiraColors.inkSoft),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final d = _docs[i];
                        final isPdf = d.fileType == 'application/pdf';
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              isPdf
                                  ? Icons.picture_as_pdf
                                  : Icons.insert_drive_file,
                              color: DiraColors.brick,
                            ),
                            title: Text(d.title),
                            subtitle: Text(
                              '${d.apartmentNumber != null ? '${l10n.apartmentShort('${d.apartmentNumber}')} · ' : '${l10n.buildingWide} · '}'
                              '${DateFormat('d MMM yyyy', locale).format(d.createdAt.toLocal())}',
                            ),
                            trailing: const Icon(Icons.open_in_new, size: 18),
                            onTap: () => _open(d),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

/// Upload composer: a title plus any number of attachments gathered
/// from the camera (scan), the photo library or the file browser.
class _UploadDocSheet extends StatefulWidget {
  const _UploadDocSheet();

  @override
  State<_UploadDocSheet> createState() => _UploadDocSheetState();
}

class _UploadDocSheetState extends State<_UploadDocSheet> {
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
    setState(() {
      _busy = true;
      _error = null;
    });
    final title = _title.text.trim();
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
