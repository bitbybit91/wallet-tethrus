import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/trade.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/trade/trade_bloc.dart';

class TradeChatScreen extends StatefulWidget {
  final String tradeId;

  const TradeChatScreen({super.key, required this.tradeId});

  @override
  State<TradeChatScreen> createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const _currentUserId = 'current_user';

  @override
  void initState() {
    super.initState();
    context
        .read<ChatBloc>()
        .add(ChatLoadMessages(tradeId: widget.tradeId));
    context.read<TradeBloc>().add(const TradeLoadRequested());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(
          ChatSendMessage(tradeId: widget.tradeId, content: text),
        );
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Trade? _findTrade(TradeState state) {
    final all = [...state.activeTrades, ...state.tradeHistory];
    for (final t in all) {
      if (t.id == widget.tradeId) return t;
    }
    return state.currentTrade;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TradeBloc, TradeState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.buyAccent,
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<TradeBloc, TradeState>(
        builder: (context, tradeState) {
          final trade = _findTrade(tradeState);

          return Scaffold(
            backgroundColor: AppColors.darkBackground,
            appBar: AppBar(
              backgroundColor: AppColors.darkSurface,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              title: Column(
                children: [
                  Text(
                    'Trade Chat',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (trade != null)
                    Text(
                      '${trade.amount.toStringAsFixed(2)} USDT',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              centerTitle: true,
              elevation: 0,
            ),
            body: Column(
              children: [
                if (trade != null) _buildStatusTimeline(trade),
                Expanded(child: _buildMessageList()),
                if (trade != null) _buildActionButtons(trade),
                _buildMessageInput(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTimeline(Trade trade) {
    final stages = [
      TradeStatus.initiated,
      TradeStatus.escrowLocked,
      TradeStatus.paymentSent,
      TradeStatus.paymentConfirmed,
      TradeStatus.completed,
    ];

    final currentIndex = stages.indexOf(trade.status);
    final isTerminal = trade.status == TradeStatus.cancelled ||
        trade.status == TradeStatus.disputed ||
        trade.status == TradeStatus.disputeResolved;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.darkSurface,
      child: Column(
        children: [
          Row(
            children: List.generate(stages.length, (i) {
              final isComplete = !isTerminal && i <= currentIndex;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isComplete
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < stages.length - 1) const SizedBox(width: 3),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _stageLabel(stages.first),
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textMuted),
              ),
              if (isTerminal)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _terminalColor(trade.status).withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _stageLabel(trade.status),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _terminalColor(trade.status),
                    ),
                  ),
                ),
              Text(
                _stageLabel(stages.last),
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _stageLabel(TradeStatus s) {
    switch (s) {
      case TradeStatus.initiated:
        return 'Initiated';
      case TradeStatus.escrowLocked:
        return 'Escrow';
      case TradeStatus.paymentSent:
        return 'Paid';
      case TradeStatus.paymentConfirmed:
        return 'Confirmed';
      case TradeStatus.completed:
        return 'Done';
      case TradeStatus.cancelled:
        return 'Cancelled';
      case TradeStatus.disputed:
        return 'Disputed';
      case TradeStatus.disputeResolved:
        return 'Resolved';
    }
  }

  Color _terminalColor(TradeStatus s) {
    switch (s) {
      case TradeStatus.cancelled:
        return AppColors.offline;
      case TradeStatus.disputed:
        return AppColors.error;
      case TradeStatus.disputeResolved:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildMessageList() {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) _scrollToBottom();
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state.messages.isEmpty) {
          return Center(
            child: Text(
              'No messages yet.\nSay hello!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: state.messages.length,
          itemBuilder: (context, i) {
            final msg = state.messages[i];
            final isMine = msg.senderId == _currentUserId;
            return _MessageBubble(
              message: msg,
              isMine: isMine,
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(Trade trade) {
    final buttons = <Widget>[];

    switch (trade.status) {
      case TradeStatus.initiated:
      case TradeStatus.escrowLocked:
        buttons.addAll([
          _actionButton(
            label: 'Mark Payment Sent',
            color: AppColors.primary,
            onPressed: () => context.read<TradeBloc>().add(
                  TradePaymentMarkedSent(tradeId: widget.tradeId),
                ),
          ),
          _actionButton(
            label: 'Cancel Trade',
            color: AppColors.error,
            onPressed: () => _confirmCancel(),
          ),
        ]);
        break;
      case TradeStatus.paymentSent:
        buttons.addAll([
          _actionButton(
            label: 'Confirm Received',
            color: AppColors.buyAccent,
            onPressed: () => context.read<TradeBloc>().add(
                  TradePaymentConfirmed(tradeId: widget.tradeId),
                ),
          ),
          _actionButton(
            label: 'Open Dispute',
            color: AppColors.warning,
            onPressed: () => _showDisputeDialog(),
          ),
        ]);
        break;
      case TradeStatus.paymentConfirmed:
        buttons.add(
          _actionButton(
            label: 'Open Dispute',
            color: AppColors.warning,
            onPressed: () => _showDisputeDialog(),
          ),
        );
        break;
      case TradeStatus.completed:
        buttons.add(
          _actionButton(
            label: 'Leave Feedback',
            color: AppColors.primary,
            onPressed: () =>
                context.go('/trades/${widget.tradeId}/feedback'),
          ),
        );
        break;
      default:
        break;
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: buttons,
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withAlpha(25),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withAlpha(60)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Trade?',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to cancel this trade?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('No',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<TradeBloc>()
                  .add(TradeCancelled(tradeId: widget.tradeId));
            },
            child: Text('Cancel Trade',
                style: GoogleFonts.inter(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Open Dispute',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Describe the issue with this trade.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Reason...',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.darkSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              if (reason.isNotEmpty) {
                context.read<TradeBloc>().add(TradeDisputeOpened(
                      tradeId: widget.tradeId,
                      reason: reason,
                    ));
              }
            },
            child: Text('Submit',
                style: GoogleFonts.inter(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.darkSurfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: IconButton(
                  onPressed: state.isSending ? null : _sendMessage,
                  icon: state.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              );
            },
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
    if (message.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.decryptedContent ?? message.encryptedContent,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final bubbleColor =
        isMine ? AppColors.primary : const Color(0xFF252542);
    final alignment =
        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMine ? const Radius.circular(16) : Radius.zero,
      bottomRight: isMine ? Radius.zero : const Radius.circular(16),
    );

    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                message.senderNickname,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.decryptedContent ?? message.encryptedContent,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock,
                        size: 10, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
