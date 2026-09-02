import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Opens a private storage object inside the app (image zoom, or PDF WebView).
///
/// Set [asPopup] to show a dismissible overlay (good for receipts) instead of
/// pushing a full-screen route.
Future<void> openVaultFile(
  BuildContext context, {
  required String bucket,
  required String path,
  String? title,
  String? fileType,
  bool asPopup = false,
}) async {
  if (!context.mounted) return;
  if (asPopup) {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, anim, secondary) {
        return _VaultFilePopup(
          bucket: bucket,
          path: path,
          title: title,
          fileType: fileType,
        );
      },
      transitionBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _VaultFileViewerPage(
        bucket: bucket,
        path: path,
        title: title,
        fileType: fileType,
      ),
    ),
  );
}

bool _looksLikePdf(String? fileType, String path) {
  final t = (fileType ?? '').toLowerCase();
  if (t.contains('pdf')) return true;
  return path.toLowerCase().endsWith('.pdf');
}

bool _looksLikeImage(String? fileType, String path) {
  final t = (fileType ?? '').toLowerCase();
  if (t.startsWith('image/')) return true;
  final p = path.toLowerCase();
  return p.endsWith('.png') ||
      p.endsWith('.jpg') ||
      p.endsWith('.jpeg') ||
      p.endsWith('.webp') ||
      p.endsWith('.gif') ||
      p.endsWith('.heic') ||
      p.endsWith('.heif');
}

Future<({List<int> bytes, String contentType})> _fetchVaultBytes({
  required String bucket,
  required String path,
}) {
  return api.getBytes(
    '/api/files/content?bucket=${Uri.encodeQueryComponent(bucket)}'
    '&path=${Uri.encodeQueryComponent(path)}',
  );
}

/// Centered overlay card: title + close, image (zoomable) or PDF.
class _VaultFilePopup extends StatefulWidget {
  final String bucket;
  final String path;
  final String? title;
  final String? fileType;

  const _VaultFilePopup({
    required this.bucket,
    required this.path,
    this.title,
    this.fileType,
  });

  @override
  State<_VaultFilePopup> createState() => _VaultFilePopupState();
}

class _VaultFilePopupState extends State<_VaultFilePopup> {
  late final Future<({List<int> bytes, String contentType})> _future =
      _fetchVaultBytes(bucket: widget.bucket, path: widget.path);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = (widget.title?.trim().isNotEmpty ?? false)
        ? widget.title!.trim()
        : l10n.documents;
    final size = MediaQuery.sizeOf(context);
    final maxW = size.width - 32;
    final maxH = size.height * 0.82;

    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
            child: Container(
              decoration: BoxDecoration(
                color: DiraColors.creamCard,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: DiraColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: DiraColors.inkSoft,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: DiraColors.sageLight),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH - 64),
                    child: FutureBuilder<({List<int> bytes, String contentType})>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const SizedBox(
                            height: 220,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: DiraColors.brick,
                              ),
                            ),
                          );
                        }
                        if (snap.hasError) {
                          final msg = snap.error is ApiException
                              ? (snap.error as ApiException).message
                              : l10n.cantOpenDocument;
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              msg,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: DiraColors.inkSoft),
                            ),
                          );
                        }
                        final data = snap.data!;
                        final contentType =
                            data.contentType.split(';').first.trim();
                        final typeHint = widget.fileType ?? contentType;
                        final isPdf = _looksLikePdf(typeHint, widget.path);
                        final isImage = _looksLikeImage(typeHint, widget.path);

                        if (isImage) {
                          return InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 5,
                            child: Image.memory(
                              Uint8List.fromList(data.bytes),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  l10n.cantOpenDocument,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: DiraColors.inkSoft,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        if (isPdf) {
                          return SizedBox(
                            height: maxH - 64,
                            child: _PdfWebView(bytes: data.bytes),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.cantOpenDocument,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: DiraColors.inkSoft),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VaultFileViewerPage extends StatefulWidget {
  final String bucket;
  final String path;
  final String? title;
  final String? fileType;

  const _VaultFileViewerPage({
    required this.bucket,
    required this.path,
    this.title,
    this.fileType,
  });

  @override
  State<_VaultFileViewerPage> createState() => _VaultFileViewerPageState();
}

class _VaultFileViewerPageState extends State<_VaultFileViewerPage> {
  late final Future<({List<int> bytes, String contentType})> _future =
      _fetchVaultBytes(bucket: widget.bucket, path: widget.path);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = (widget.title?.trim().isNotEmpty ?? false)
        ? widget.title!.trim()
        : l10n.documents;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<({List<int> bytes, String contentType})>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            );
          }
          if (snap.hasError) {
            final msg = snap.error is ApiException
                ? (snap.error as ApiException).message
                : l10n.cantOpenDocument;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }
          final data = snap.data!;
          final contentType = data.contentType.split(';').first.trim();
          final isPdf =
              _looksLikePdf(widget.fileType ?? contentType, widget.path);
          final isImage =
              _looksLikeImage(widget.fileType ?? contentType, widget.path);

          if (isImage) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  Uint8List.fromList(data.bytes),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Text(
                    l10n.cantOpenDocument,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            );
          }

          if (isPdf) {
            return _PdfWebView(bytes: data.bytes);
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.cantOpenDocument,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PdfWebView extends StatefulWidget {
  final List<int> bytes;
  const _PdfWebView({required this.bytes});

  @override
  State<_PdfWebView> createState() => _PdfWebViewState();
}

class _PdfWebViewState extends State<_PdfWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final b64 = base64Encode(widget.bytes);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString('''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=4"/>
<style>
  html, body { margin: 0; padding: 0; height: 100%; background: #111; }
  embed, iframe, object { width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
  <embed src="data:application/pdf;base64,$b64" type="application/pdf"/>
</body>
</html>
''');
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
