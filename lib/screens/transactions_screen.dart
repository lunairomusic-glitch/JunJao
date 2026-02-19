import 'package:flutter/material.dart';
import '../app_state.dart';
import '../utils/format.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  // =============================
  // ⭐ Smart Thai date formatter
  // =============================
  String formatDateThaiSmart(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final thatDay = DateTime(d.year, d.month, d.day);
      final diff = today.difference(thatDay).inDays;

      if (diff == 0) return 'วันนี้';
      if (diff == 1) return 'เมื่อวาน';

      const months = [
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ];

      return '${d.day} ${months[d.month - 1]} ${d.year + 543}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final transactions = state.currentTransactions;

    // =============================
    // 📦 Group by date
    // =============================
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final tx in transactions) {
      final date = tx['date'] as String;
      grouped.putIfAbsent(date, () => []).add(tx);
    }

    final dates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: false,
        elevation: 0,
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'ยังไม่มีรายการ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ลองบันทึกจาก Luna ดูนะ 🤖',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: dates.map((date) {
                final items = grouped[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formatDateThaiSmart(date),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...items.map((tx) {
                      final id = tx['id']?.toString(); // ✅ ใช้ id เสมอ
                      final type = tx['type']?.toString() ?? '';
                      final amount = tx['amount'];
                      final category = tx['category'] ?? 'อื่นๆ';
                      final note = tx['note'];
                      final isIncome = type == 'income';

                      final color =
                          isIncome ? Colors.green : Colors.red;
                      final sign = isIncome ? '+' : '-';

                      return Card(
                        // 🔑 unique จริง: accountId + transactionId
                        key: ValueKey(
                          '${tx['accountId']}-${tx['id']}',
                        ),
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    color.withOpacity(0.12),
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            color.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isIncome
                                            ? 'รายรับ'
                                            : 'รายจ่าย',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (note != null &&
                                        note
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          top: 4,
                                        ),
                                        child: Text(
                                          note.toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    Colors.grey[600],
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$sign${formatMoney(amount)}',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 18,
                                        ),
                                        onPressed: id == null
                                            ? null
                                            : () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled:
                                                      true,
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                      top: Radius
                                                          .circular(
                                                        20,
                                                      ),
                                                    ),
                                                  ),
                                                  builder: (_) =>
                                                      _EditTransactionSheet(
                                                    initial: Map<
                                                            String,
                                                            dynamic>.from(
                                                        tx),
                                                    onSave:
                                                        (updated) {
                                                      state
                                                          .updateTransactionById(
                                                        id,
                                                        updated,
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: id == null
                                            ? null
                                            : () async {
                                                final ok =
                                                    await showDialog<
                                                        bool>(
                                                  context: context,
                                                  builder: (_) =>
                                                      AlertDialog(
                                                    title:
                                                        const Text(
                                                            'ลบรายการนี้?'),
                                                    content:
                                                        const Text(
                                                            'การลบจะย้อนกลับไม่ได้'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  false,
                                                                ),
                                                        child:
                                                            const Text(
                                                                'ยกเลิก'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed:
                                                            () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                        child:
                                                            const Text(
                                                                'ลบ'),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (ok == true) {
                                                  state
                                                      .deleteTransactionById(
                                                    id,
                                                  );
                                                }
                                              },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

/// ===============================
/// 🔽 Edit Bottom Sheet
/// ===============================
class _EditTransactionSheet extends StatefulWidget {
  final Map<String, dynamic> initial;
  final ValueChanged<Map<String, dynamic>> onSave;

  const _EditTransactionSheet({
    required this.initial,
    required this.onSave,
  });

  @override
  State<_EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState
    extends State<_EditTransactionSheet> {
  late bool isIncome;
  late TextEditingController amountCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController noteCtrl;

  @override
  void initState() {
    super.initState();
    isIncome = widget.initial['type'] == 'income';

    amountCtrl = TextEditingController(
      text: widget.initial['amount'].toString(),
    );
    categoryCtrl = TextEditingController(
      text: widget.initial['category'] ?? 'อื่นๆ',
    );
    noteCtrl = TextEditingController(
      text: widget.initial['note'] ?? '',
    );
  }

  void save() {
    final raw =
        amountCtrl.text.replaceAll(',', '').trim();
    final amount = num.tryParse(raw);

    if (amount == null || amount <= 0) return;

    widget.onSave({
      ...widget.initial,
      'type': isIncome ? 'income' : 'expense',
      'amount': amount,
      'category': categoryCtrl.text.trim().isEmpty
          ? 'อื่นๆ'
          : categoryCtrl.text.trim(),
      'note': noteCtrl.text.trim(),
      'id': widget.initial['id'],
      'accountId': widget.initial['accountId'],
      'date': widget.initial['date'],
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'แก้ไขรายการ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('รายรับ'),
                selected: isIncome,
                onSelected: (_) =>
                    setState(() => isIncome = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('รายจ่าย'),
                selected: !isIncome,
                onSelected: (_) =>
                    setState(() => isIncome = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'จำนวนเงิน'),
          ),
          TextField(
            controller: categoryCtrl,
            decoration:
                const InputDecoration(labelText: 'หมวด'),
          ),
          TextField(
            controller: noteCtrl,
            decoration:
                const InputDecoration(labelText: 'โน้ต'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: save,
                  child: const Text('บันทึก'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
