import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/chat_message_model.dart';
import '../../../../shared/widgets/app_message.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/message_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String friendId;

  const ChatScreen({super.key, required this.friendId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageProvider.notifier).openConversation(widget.friendId);
    });
  }

  void _handleScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 180) {
      ref
          .read(messageProvider.notifier)
          .loadHistory(widget.friendId, loadMore: true);
    }
  }

  @override
  void dispose() {
    ref.read(messageProvider.notifier).closeConversation(widget.friendId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final sent = await ref.read(messageProvider.notifier).send(
          widget.friendId,
          text,
        );
    if (!mounted) return;
    if (sent) {
      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    } else {
      final error = ref.read(messageProvider).error;
      if (error != null) AppMessage.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageProvider);
    final friend = state.friends[widget.friendId];
    final messages = state.messages[widget.friendId] ?? const <ChatMessage>[];
    final userId = ref.watch(authProvider).user?.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(
              name: friend?.fullName ?? 'Friend',
              imageUrl: friend?.profileImageUrl,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend?.fullName ?? 'Chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (friend != null)
                    Text(
                      'Friend',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (state.error != null && messages.isNotEmpty)
            Material(
              color: AppColors.error.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        state.error!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: state.isLoadingHistory && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && messages.isEmpty
                    ? _ChatError(
                        message: state.error!,
                        onRetry: () => ref
                            .read(messageProvider.notifier)
                            .openConversation(widget.friendId),
                      )
                    : messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.waving_hand_outlined,
                                    size: 42,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Start the conversation',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Send a simple message to ${friend?.fullName ?? 'your friend'}.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                            itemCount:
                                messages.length + (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final message =
                                  messages[messages.length - 1 - index];
                              return _MessageBubble(
                                message: message,
                                isMine: message.senderId == userId,
                              );
                            },
                          ),
          ),
          _MessageComposer(
            controller: _messageController,
            isSending: state.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.fromLTRB(13, 9, 11, 7),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.primary
              : dark
                  ? AppColors.darkElevatedSurface
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(isMine ? 17 : 5),
            bottomRight: Radius.circular(isMine ? 5 : 17),
          ),
          border: isMine
              ? null
              : Border.all(
                  color: dark ? AppColors.darkDivider : AppColors.divider,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SelectableText(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMine ? Colors.white : null,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              DateFormat.jm().format(message.createdAt.toLocal()),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isMine ? Colors.white70 : AppColors.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.controller.text.trim().isNotEmpty &&
        widget.controller.text.length <= 2000 &&
        !widget.isSending;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCardBg : Colors.white,
          border: Border(
            top: BorderSide(
              color: dark ? AppColors.darkDivider : AppColors.divider,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send message',
              onPressed: canSend ? widget.onSend : null,
              icon: widget.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ChatError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            SelectableText(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
