import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// In-app assistant ("KodiBot"). Role-aware: the backend tailors behaviour and the
/// data it can access to the logged-in user's role, so this screen only needs to
/// pass the user's messages through and render the conversation.
class ChatbotScreen extends StatefulWidget {
  /// Display label for the user's role (e.g. "Landlord"). Used for the suggestions.
  final String role;

  /// Accent colour matching the dashboard the user came from.
  final Color accentColor;

  const ChatbotScreen({
    super.key,
    required this.role,
    this.accentColor = AppColors.kodiBlue,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage(this.text, {required this.isUser});
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _sending = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _suggestions {
    switch (widget.role.toLowerCase()) {
      case 'landlord':
      case 'agent':
        return const [
          'Who is behind on rent?',
          'How is my occupancy looking?',
          "What's my income this month?",
          'Draft a polite rent reminder',
        ];
      case 'caretaker':
        return const [
          'What maintenance is still open?',
          'Which property needs attention first?',
          'Draft a water interruption notice',
        ];
      default:
        return const [
          "What's my current balance?",
          'Show my recent payments',
          'How do I raise a repair issue?',
          'Can my landlord raise rent without notice?',
        ];
    }
  }

  Future<void> _loadHistory() async {
    try {
      final resp = await _api.get('/chatbot/history');
      if (resp.statusCode == 200) {
        final rows = (jsonDecode(resp.body) as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .reversed; // endpoint returns newest-first
        for (final row in rows) {
          final msg = row['message']?.toString() ?? '';
          final reply = row['response']?.toString() ?? '';
          if (msg.isNotEmpty) _messages.add(_ChatMessage(msg, isUser: true));
          if (reply.isNotEmpty) _messages.add(_ChatMessage(reply, isUser: false));
        }
      }
    } catch (_) {
      // History is best-effort; ignore failures.
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text, isUser: true));
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final resp = await _api.post('/chatbot/chat', {'message': text});
      String reply;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        reply = body['response']?.toString() ??
            "I'm sorry, I didn't get a response. Please try again.";
      } else {
        String serverMsg = '';
        try {
          serverMsg = (jsonDecode(resp.body) as Map<String, dynamic>)['error']
                  ?.toString() ??
              '';
        } catch (_) {/* non-JSON error body */}
        reply = serverMsg.isNotEmpty
            ? serverMsg
            : 'Something went wrong (code ${resp.statusCode}). Please try again.';
      }
      if (mounted) setState(() => _messages.add(_ChatMessage(reply, isUser: false)));
    } catch (_) {
      if (mounted) {
        setState(() => _messages.add(const _ChatMessage(
              'I could not reach the assistant. Please check your connection and try again.',
              isUser: false,
            )));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white24,
              child: Icon(Icons.smart_toy_outlined, size: 16, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text('KodiBot', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _messages.length) {
                            return _buildTypingBubble();
                          }
                          return _buildBubble(_messages[index]);
                        },
                      ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 40, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 30,
              backgroundColor: widget.accentColor.withValues(alpha: 0.12),
              child: Icon(Icons.smart_toy_outlined,
                  size: 30, color: widget.accentColor),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Hi, I\'m KodiBot',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Ask me about your account, reports, or your rights as a renter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Try asking',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => ActionChip(
                      label: Text(s),
                      backgroundColor: AppColors.card,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: const TextStyle(
                          fontSize: 13, color: AppColors.textDark),
                      onPressed: _sending ? null : () => _send(s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? widget.accentColor : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.35,
            color: isUser ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                maxLength: 1000,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Message KodiBot…',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: widget.accentColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: widget.accentColor,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending ? null : () => _send(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _sending ? Icons.hourglass_top_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
