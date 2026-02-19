import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../app_state.dart';
import '../utils/format.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  bool loading = false;

  final AiService ai = AiService();

  AppState get state => AppStateProvider.of(context);

  // =============================
  // 📤 Send message (logic เดิม)
  // =============================
  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || loading) return;

    state.addChat('USER: $text');
    setState(() => loading = true);
    controller.clear();

    try {
      final results = await ai.parseFinanceMessage(text);

      for (final item in results) {
        // 🔒 ChatScreen ห้ามรู้เรื่อง id
        final tx = {
          ...item,
          'accountId': state.currentAccountId,
          'date': DateTime.now().toIso8601String().split('T').first,
        };

        // ✅ AppState เป็นคนสร้าง id เอง
        state.addTransaction(tx);

        // ✅ ต้องอยู่ใน method และอยู่ใน state.addChat เท่านั้น
        state.addChat(
          'BOT: บันทึก ${tx['note']} ${formatMoney(tx['amount'])} บาท แล้วนะ 📝',
        );
      }
    } catch (e) {
      state.addChat('BOT: เกิดข้อผิดพลาดนะคะ 😅\n$e');
    }

    setState(() => loading = false);
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // =============================
        // 💬 Chat messages
        // =============================
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 12),
            itemCount: state.chatMessages.length,
            itemBuilder: (context, index) {
              final msg = state.chatMessages[index];

              final isUser = msg.startsWith('USER:');
              final text = msg
                  .replaceFirst(isUser ? 'USER:' : 'BOT:', '')
                  .trim();

              return ChatBubble(
                text: text,
                isUser: isUser,
              );
            },
          ),
        ),

        // =============================
        // 🤖 Loading bubble
        // =============================
        if (loading)
          const ChatBubble(
            text: 'ลูน่ากำลังบันทึกให้นะคะ… ✨',
            isUser: false,
          ),

        // =============================
        // ⌨️ Input bar
        // =============================
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => send(),
                    decoration: InputDecoration(
                      hintText: 'พิมพ์รายรับหรือรายจ่าย...',
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: send,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================
// 💬 Chat Bubble Widget
// =============================
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 12,
        ),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
