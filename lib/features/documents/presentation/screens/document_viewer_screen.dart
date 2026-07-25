import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/document_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/visibility_badge.dart';
import '../providers/document_provider.dart';

class DocumentViewerScreen extends ConsumerWidget {
  final String documentId;
  const DocumentViewerScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(documentByIdProvider(documentId));
    if (doc == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await ConfirmDialog.show(context, title: 'Delete Document', message: 'This will permanently delete this document.', confirmLabel: 'Delete', isDestructive: true);
                if (ok == true) {
                  await ref.read(documentProvider.notifier).deleteDocument(documentId);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'visibility', child: Text('Change Visibility')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: doc.fileType.isImage
                ? _ImageViewer(url: doc.fileUrl)
                : _PdfPlaceholder(url: doc.fileUrl),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardBg : AppColors.cardBg,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(doc.subjectName), avatar: const Icon(Icons.book_outlined, size: 14), padding: EdgeInsets.zero),
                    if (doc.topicName != null) ...[
                      const SizedBox(width: 8),
                      Chip(label: Text(doc.topicName!), avatar: const Icon(Icons.topic_outlined, size: 14), padding: EdgeInsets.zero),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    VisibilityBadge(visibility: doc.visibility),
                    const SizedBox(width: 12),
                    Text('Uploaded ${AppHelpers.formatDate(doc.uploadedAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                if (doc.allowCopy) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await ref.read(documentProvider.notifier).copyDocument(documentId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Document copied to your library!' : 'Could not copy document'),
                          backgroundColor: ok ? AppColors.success : AppColors.error,
                        ));
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy to My Documents'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String url;
  const _ImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      child: Center(
        child: Container(
          width: double.infinity,
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 80, color: Colors.white54),
                SizedBox(height: 16),
                Text('Image Preview', style: TextStyle(color: Colors.white70)),
                Text('(Connect to real file URL)', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfPlaceholder extends StatelessWidget {
  final String url;
  const _PdfPlaceholder({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 80, color: AppColors.error),
            SizedBox(height: 16),
            Text('PDF Viewer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Connect flutter_pdfview or syncfusion_flutter_pdfviewer', style: TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
