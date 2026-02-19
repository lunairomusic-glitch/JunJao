import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../app_state.dart';
import '../services/ai_service.dart';
import '../utils/format.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  final AiService ai = AiService();

  DateTime selectedDay = DateTime.now();
  String? insight;
  bool loading = false;

  final Map<String, String> _cache = {};

  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..value = 1;
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInsight();
  }

  // =============================
  // 🧠 Monthly insight (logic only)
  // =============================
  Future<void> _loadInsight() async {
    final state = AppStateProvider.of(context);

    // 👉 รวม transaction ทั้งเดือน
    final txs = state.transactions.where((t) {
      final d = t['date'] as DateTime;
      return d.year == selectedDay.year && d.month == selectedDay.month;
    }).toList();

    // 👉 cache รายเดือน
    final signature =
        '${selectedDay.year}-${selectedDay.month}-${state.txVersion}';

    if (_cache.containsKey(signature)) {
      setState(() => insight = _cache[signature]);
      return;
    }

    if (txs.isEmpty) {
      setState(() => insight = 'เดือนนี้ยังไม่มีข้อมูลให้ลูน่าวิเคราะห์นะคะ 🌙');
      return;
    }

    double income = 0;
    double expense = 0;

    for (final tx in txs) {
      final amount = (tx['amount'] as num).toDouble();
      tx['type'] == 'income' ? income += amount : expense += amount;
    }

    // 👉 context รวมทั้งเดือน + มีวันที่ให้เห็น pattern
    final contextText = txs.map((t) {
      final d = t['date'] as DateTime;
      final type = t['type'] == 'income' ? 'รายรับ' : 'รายจ่าย';
      final category = t['category'] ?? 'ไม่ระบุหมวด';
      final note = t['note'] ?? '';
      return '${d.day}/${d.month} $type ${t['amount']} บาท | หมวด: $category | รายการ: $note';
    }).join('\n');

    setState(() => loading = true);

    try {
      final res = await ai.generateInsight(
        income: income,
        expense: expense,
        transactionContext: contextText,
      );

      _cache[signature] = res;
      setState(() => insight = res);
    } catch (_) {
      setState(() => insight = 'Luna วิเคราะห์ไม่สำเร็จ 😅');
    } finally {
      setState(() => loading = false);
    }
  }

  void _changeDay(int diff) {
    setState(() {
      selectedDay = selectedDay.add(Duration(days: diff));
    });

    _anim
      ..stop()
      ..value = 0
      ..forward();

    _loadInsight();
  }

  String _thaiDate(DateTime d) {
    const months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];

    return 'วันที่ ${d.day} ${months[d.month - 1]} ${d.year + 543}';
  }

  // =============================
  // 📊 UI BELOW = UNCHANGED
  // =============================

  Widget _barRow({
    required List<MapEntry<String, double>> data,
    required double maxY,
    required double animFactor,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    final double bgY = maxY <= 0 ? 1.0 : (maxY * 1.2).toDouble();

    final double total =
        data.fold<double>(0, (s, e) => s + e.value);

    return SizedBox(
      height: 220,
      child: LayoutBuilder(
        builder: (context, c) {
          final double usableW = c.maxWidth - 20;
          final double groupW = usableW / data.length;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: BarChart(
                  BarChartData(
                    maxY: bgY,
                    barTouchData: BarTouchData(enabled: false),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= data.length) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[i].key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(
                      data.length,
                      (i) {
                        final double y =
                            (data[i].value * animFactor).toDouble();

                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: y,
                              width: 28,
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xFF37BFA4),
                                  Color(0xFF7DE2D1),
                                ],
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: bgY,
                                color: Colors.grey.withOpacity(0.08),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              ...List.generate(data.length, (i) {
                final double value = data[i].value;
                final double percent =
                    total == 0 ? 0 : (value / total) * 100;

                final double y =
                    (value * animFactor).toDouble();

                final double ratio =
                    (y / bgY).clamp(0.0, 1.0).toDouble();

                final double barAreaH = 220 - 44;
                final double barTop = barAreaH * ratio;

                final double centerX =
                    10 + groupW * i + groupW / 2;

                return Positioned(
                  left: centerX - 16,
                  bottom: barTop - 6,
                  child: Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryTextList(List<MapEntry<String, double>> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      children: data.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  e.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${formatMoney(e.value)} บาท',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.72),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    // 📊 กราฟยังเป็นรายวันเหมือนเดิม
    final txs = state.transactionsOn(selectedDay);

    final expenses = txs.where((t) => t['type'] == 'expense').toList();

    final Map<String, double> grouped = {};
    for (final tx in expenses) {
      final category = tx['category'] ?? 'อื่น ๆ';
      grouped[category] =
          (grouped[category] ?? 0) + (tx['amount'] as num).toDouble();
    }

    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const totalBars = 10;
    final top10 = sorted.take(totalBars).toList();

    final row1 = top10.take(5).toList();
    final row2 = top10.skip(5).take(5).toList();

    final double maxY = top10.isEmpty ? 0.0 : top10.first.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Insight')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeDay(-1),
              ),
              Text(
                _thaiDate(selectedDay),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeDay(1),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (sorted.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) {
                  final double factor =
                      Curves.easeOutCubic.transform(_anim.value);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'รายจ่ายตามหมวดหมู่ (Top 10)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _barRow(
                        data: row1,
                        maxY: maxY,
                        animFactor: factor,
                      ),
                      const SizedBox(height: 10),
                      _categoryTextList(row1),

                      if (row2.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _barRow(
                          data: row2,
                          maxY: maxY,
                          animFactor: factor,
                        ),
                        const SizedBox(height: 10),
                        _categoryTextList(row2),
                      ],
                    ],
                  );
                },
              ),
            )
          else
            const Center(child: Text('ไม่มีรายจ่ายในวันนี้')),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              loading ? 'Luna กำลังวิเคราะห์ให้นะคะ ✨' : (insight ?? ''),
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
