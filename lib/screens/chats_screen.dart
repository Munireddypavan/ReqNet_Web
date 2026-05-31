import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../providers/chat_provider.dart';
import '../services/mesh_router.dart';
import '../providers/mesh_provider.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadAllMessages();
    });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    
    MeshRouter.instance.sendMessage('BROADCAST', text, isBroadcast: true);
    _msgController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final meshProvider = context.watch<MeshProvider>();

    return SafeArea(
      child: Column(
        children: [
          // Minimalist Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.forum_rounded, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'MESH CHAT', 
                      style: TextStyle(
                        fontFamily: 'Inter', 
                        fontWeight: FontWeight.w600, 
                        fontSize: 14, 
                        color: AppTheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${meshProvider.connectedNodesCount} PEERS', 
                  style: const TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w600, 
                    color: AppTheme.outline,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final msg = chatProvider.messages[index];
                final isMe = msg['senderId'] == MeshRouter.instance.localDeviceId;
                final dt = DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] as int);
                final timeStr = DateFormat('HH:mm').format(dt);
                
                return _buildMessage(
                  isMe ? 'Self' : (msg['senderId'] as String).substring(0, 8),
                  timeStr,
                  msg['content'],
                  isMe,
                  status: msg['status'] ?? 'Sent',
                  hops: msg['hops'] as int? ?? 0,
                );
              },
            ),
          ),
          
          // Modern Pill Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.surfaceContainerHighest, width: 1),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w400),
                      decoration: const InputDecoration(
                        hintText: 'Message mesh network...',
                        hintStyle: TextStyle(color: AppTheme.outline, fontWeight: FontWeight.w300),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.background, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String sender, String time, String text, bool isSent, {String status = 'Sent', int hops = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSent ? AppTheme.primary : AppTheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isSent ? 16 : 4),
              bottomRight: Radius.circular(isSent ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSent) ...[
                Text(
                  sender,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.outline.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                text,
                style: TextStyle(
                  color: isSent ? AppTheme.background : AppTheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSent ? AppTheme.background.withValues(alpha: 0.7) : AppTheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isSent && hops > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '$hops hops',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.outline,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  if (isSent) ...[
                    const SizedBox(width: 4),
                    Icon(
                      status == 'Relayed' ? Icons.done_all : Icons.check,
                      size: 14,
                      color: AppTheme.background.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
