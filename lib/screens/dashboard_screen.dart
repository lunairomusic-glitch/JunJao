import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/ai_service.dart';
import '../utils/format.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: null,
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _AccountHeader(),
          const SizedBox(height: 20),
          const _OverviewSection(),
          const SizedBox(height: 20),
          _BotHeroCard(),
          const SizedBox(height: 20),
          const _InsightCard(),
        ],
      ),
    );
  }
}

// =============================
// 🏦 Account Header
// =============================
class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Row(
      children: [
        const Icon(Icons.account_balance, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.currentAccountId,
              isExpanded: true,
              items: state.accounts.map((acc) {
                return DropdownMenuItem(
                  value: acc.id,
                  child: Text(
                    acc.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) {
                  state.switchAccount(id);
                }
              },
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'แก้ไขชื่อบัญชี',
          onPressed: () => showRenameAccountDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'เพิ่มบัญชี',
          onPressed: () => showAddAccountDialog(context),
        ),
      ],
    );
  }
}

// =============================
// 🤖 Bot Hero Card
// =============================
class _BotHeroCard extends StatefulWidget {
  const _BotHeroCard();

  @override
  State<_BotHeroCard> createState() => _BotHeroCardState();
}

class _BotHeroCardState extends State<_BotHeroCard> {
  final AiService ai = AiService();

  bool loading = false;
  int? _lastVersion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoadInsight();
  }

  Future<void> _maybeLoadInsight() async {
    final state = AppStateProvider.of(context);

    if (_lastVersion == state.txVersion) return;
    if (loading) return;

    _lastVersion = state.txVersion;
    loading = true;

    final balance = state.balance;
    final expense = state.totalExpense;

    try {
      final text = await ai.generateDashboardMessage(
        balance: balance,
        expense: expense,
      );
      state.setDashboardInsight(text);
    } catch (_) {}

    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = AppStateProvider.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 24,
            child: Icon(Icons.smart_toy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Luna • Finance Bot',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.dashboardInsight ??
                      'หนูกำลังดูภาพรวมการเงินให้พี่อยู่นะ 🌱',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================
// 📊 Overview Section
// =============================
class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'รายรับ',
            value: state.totalIncome,
            color: Colors.green,
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'รายจ่าย',
            value: state.totalExpense,
            color: Colors.red,
            icon: Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'คงเหลือ',
            value: state.balance,
            color: Colors.blue,
            icon: Icons.account_balance_wallet,
          ),
        ),
      ],
    );
  }
}

// =============================
// 📈 Small Stat Card
// =============================
class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${formatMoney(value)} THB',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================
// 💡 Insight Card
// =============================
class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'AI Insight',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ดูบทวิเคราะห์เชิงลึกจาก Luna',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 📥 Dialog helpers
// ============================================================

void showRenameAccountDialog(BuildContext context) {
  final state = AppStateProvider.of(context);
  final controller =
      TextEditingController(text: state.currentAccount.name);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('แก้ไขชื่อบัญชี'),
      content: TextField(controller: controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              state.renameCurrentAccount(name);
            }
            Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ],
    ),
  );
}

void showAddAccountDialog(BuildContext context) {
  final state = AppStateProvider.of(context);
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('เพิ่มบัญชี'),
      content: TextField(controller: controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              state.addAccount(name);
            }
            Navigator.pop(context);
          },
          child: const Text('เพิ่ม'),
        ),
      ],
    ),
  );
}
