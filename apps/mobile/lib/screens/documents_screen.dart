import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.documents,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
