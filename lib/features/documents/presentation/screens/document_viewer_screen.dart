import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/models/document_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_message.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/visibility_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/document_provider.dart';

class DocumentViewerScreen extends ConsumerWidget {
  final String documentId;
  const DocumentViewerScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(documentByIdProvider(documentId));
    if (doc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isOwner = ref.watch(authProvider).user?.id == doc.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (isOwner || doc.allowCopy)
            IconButton(
              tooltip: 'Download document',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _downloadToDevice(context, doc),
            ),
          if (isOwner)
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) async {
                if (v == 'visibility') {
                  final limit = await ref
                      .read(documentProvider.notifier)
                      .visibilityLimit(doc);
                  if (!context.mounted) return;
                  if (limit == null) {
                    AppMessage.error(
                      context,
                      ref.read(documentProvider).error ??
                          'Could not load parent visibility',
                    );
                    return;
                  }
                  final visibility = await _selectVisibility(
                    context,
                    current: doc.visibility,
                    limit: limit,
                  );
                  if (visibility == null || visibility == doc.visibility) {
                    return;
                  }
                  final updated = await ref
                      .read(documentProvider.notifier)
                      .updateVisibility(documentId, visibility);
                  if (!context.mounted) return;
                  if (updated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Visibility changed to ${visibility.label}'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    AppMessage.error(
                      context,
                      ref.read(documentProvider).error ??
                          'Could not change document visibility',
                    );
                  }
                }
                if (v == 'delete') {
                  final confirmed = await ConfirmDialog.show(context,
                      title: 'Delete Document',
                      message: 'This will permanently delete this document.',
                      confirmLabel: 'Delete',
                      isDestructive: true);
                  if (confirmed == true) {
                    final deleted = await ref
                        .read(documentProvider.notifier)
                        .deleteDocument(documentId);
                    if (!context.mounted) return;
                    if (deleted) {
                      context.pop();
                    } else {
                      AppMessage.error(
                        context,
                        ref.read(documentProvider).error ??
                            'Could not delete document',
                      );
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'visibility', child: Text('Change Visibility')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error))),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: doc.fileType.isImage
                ? _ImageViewer(documentId: doc.id)
                : _PdfViewer(documentId: doc.id),
          ),
          Container(
            padding: AppSpacing.page,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCardBg
                  : AppColors.cardBg,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                        label: Text(doc.subjectName),
                        avatar: const Icon(Icons.book_outlined, size: 14),
                        padding: EdgeInsets.zero),
                    if (doc.topicName != null) ...[
                      const SizedBox(width: 8),
                      Chip(
                          label: Text(doc.topicName!),
                          avatar: const Icon(Icons.topic_outlined, size: 14),
                          padding: EdgeInsets.zero),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    VisibilityBadge(visibility: doc.visibility),
                    const SizedBox(width: 12),
                    Text('Uploaded ${AppHelpers.formatDate(doc.uploadedAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                if (!isOwner && doc.allowCopy) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await ref
                            .read(documentProvider.notifier)
                            .copyDocument(documentId);
                        if (!context.mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Document copied to your library!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          AppMessage.error(context, 'Could not copy document');
                        }
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

Future<void> _downloadToDevice(
    BuildContext context, DocumentModel document) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Preparing document...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

  try {
    final bytes = await _downloadDocument(document.id);
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();

    final extension = document.fileType.name;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save document',
      fileName: _downloadFileName(document.title, extension),
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );
    if (!context.mounted || path == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document downloaded successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    AppMessage.error(context, _documentErrorMessage(error));
  }
}

String _downloadFileName(String title, String extension) {
  final sanitized = title
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final baseName = sanitized.isEmpty ? 'document' : sanitized;
  return baseName.toLowerCase().endsWith('.$extension')
      ? baseName
      : '$baseName.$extension';
}

Future<ContentVisibility?> _selectVisibility(
  BuildContext context, {
  required ContentVisibility current,
  required DocumentVisibilityLimit limit,
}) {
  return showModalBottomSheet<ContentVisibility>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppSpacing.pageHorizontal,
              child: Text(
                'Change visibility',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            for (final visibility in ContentVisibility.values)
              ListTile(
                enabled: _visibilityLevel(visibility) <=
                    _visibilityLevel(limit.maximum),
                leading: Icon(_visibilityIcon(visibility)),
                title: Text(visibility.label),
                subtitle: _visibilityLevel(visibility) >
                        _visibilityLevel(limit.maximum)
                    ? Text(
                        'Set the ${limit.limitingParent?.toLowerCase()} to ${visibility.label} first',
                      )
                    : null,
                trailing: visibility == current
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(visibility),
              ),
          ],
        ),
      ),
    ),
  );
}

IconData _visibilityIcon(ContentVisibility visibility) {
  switch (visibility) {
    case ContentVisibility.private:
      return Icons.lock_outline;
    case ContentVisibility.friendsOnly:
      return Icons.group_outlined;
    case ContentVisibility.public:
      return Icons.public_outlined;
  }
}

int _visibilityLevel(ContentVisibility visibility) {
  switch (visibility) {
    case ContentVisibility.private:
      return 0;
    case ContentVisibility.friendsOnly:
      return 1;
    case ContentVisibility.public:
      return 2;
  }
}

Future<Uint8List> _downloadDocument(String documentId) async {
  try {
    final response = await ApiClient().dio.get<List<int>>(
          '/documents/$documentId/file',
          options: Options(responseType: ResponseType.bytes),
        );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('The document is empty.');
    }
    return Uint8List.fromList(bytes);
  } on DioException catch (error) {
    final data = error.response?.data;
    if (data is List<int>) {
      try {
        final decoded = jsonDecode(utf8.decode(data));
        if (decoded is Map && decoded['error'] is String) {
          throw Exception(decoded['error'] as String);
        }
      } on FormatException {
        // Fall through to the standard API error below.
      }
    }
    if (error.response?.statusCode == 404) {
      throw Exception('The document file was not found on the server.');
    }
    throw Exception(apiErrorMessage(error));
  }
}

String _documentErrorMessage(Object error) => error is DioException
    ? apiErrorMessage(error)
    : error.toString().replaceFirst('Exception: ', '');

class _ImageViewer extends StatefulWidget {
  final String documentId;
  const _ImageViewer({required this.documentId});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late Future<Uint8List> _imageBytes;

  @override
  void initState() {
    super.initState();
    _imageBytes = _downloadDocument(widget.documentId);
  }

  void _retry() => setState(() {
        _imageBytes = _downloadDocument(widget.documentId);
      });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: FutureBuilder<Uint8List>(
        future: _imageBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DocumentLoadError(
              message: _documentErrorMessage(snapshot.error!),
              onRetry: _retry,
            );
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(
              child: Image.memory(snapshot.data!, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}

class _PdfViewer extends StatefulWidget {
  final String documentId;
  const _PdfViewer({required this.documentId});

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  late final PdfControllerPinch _controller;

  Future<PdfDocument> _openDocument() async {
    final bytes = await _downloadDocument(widget.documentId);
    return PdfDocument.openData(bytes);
  }

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(document: _openDocument());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(
      controller: _controller,
      scrollDirection: Axis.vertical,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) => _DocumentLoadError(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => _controller.loadDocument(_openDocument()),
        ),
      ),
    );
  }
}

class _DocumentLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DocumentLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Could not open this document',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}
