import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/upload_document_sheet.dart';
import '../widgets/vault_file_viewer.dart';

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
    _realtimeSub = realtime.listen({'documents', 'payments'}, _load);
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

  String _docTitle(DocumentItem d, AppLocalizations l10n, String locale) {
    if (d.isPaymentReceipt && d.month != null && d.year != null) {
      final monthName =
          DateFormat('MMMM', locale).format(DateTime(d.year!, d.month!));
      return l10n.paymentReceiptTitle(monthName, '${d.year}');
    }
    if (d.title.trim().isNotEmpty) return d.title;
    return l10n.documents;
  }

  Future<void> _open(DocumentItem doc) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    await openVaultFile(
      context,
      bucket: doc.bucket,
      path: doc.filePath,
      title: _docTitle(doc, l10n, locale),
      fileType: doc.fileType,
    );
  }

  /// Upload one or more documents (camera scan, gallery, files).
  Future<void> _upload() async {
    final session = context.read<SessionController>();
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UploadDocumentSheet(
        apartmentId: session.user?.isVaad == true
            ? null
            : session.user?.apartmentId,
      ),
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
    final user = context.watch<SessionController>().user;
    final isVaad = user?.isVaad ?? false;
    final canUpload = isVaad || user?.apartmentId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.documents,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canUpload
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final d = _docs[i];
                        final title = _docTitle(d, l10n, locale);
                        final subtitleBits = <String>[
                          if (d.isPaymentReceipt)
                            l10n.paymentReceiptsSection
                          else if (d.apartmentNumber != null)
                            l10n.apartmentShort('${d.apartmentNumber}')
                          else
                            l10n.buildingWide,
                          DateFormat(
                            'd MMM yyyy',
                            locale,
                          ).format(d.createdAt.toLocal()),
                        ];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              d.isPaymentReceipt
                                  ? Icons.receipt_long_rounded
                                  : d.isPdf
                                  ? Icons.picture_as_pdf
                                  : Icons.insert_drive_file,
                              color: DiraColors.brick,
                            ),
                            title: Text(title),
                            subtitle: Text(subtitleBits.join(' · ')),
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: DiraColors.inkSoft,
                            ),
                            onTap: () => _open(d),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
