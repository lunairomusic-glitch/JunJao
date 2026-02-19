import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/account.dart';

/// =============================
/// 📦 Global App State
/// =============================
class AppState extends ChangeNotifier {
  static const _txKey = 'transactions_store';

  // =============================
  // 💬 Chat
  // =============================
  final List<String> chatMessages = [];

  void addChat(String msg) {
    chatMessages.add(msg);
    notifyListeners();
  }

  // =============================
  // 💳 Accounts
  // =============================
  final List<Account> accounts = [
    Account(
      id: 'main',
      name: 'บัญชีหลัก',
      transactions: [],
    ),
  ];

  String currentAccountId = 'main';

  Account get currentAccount =>
      accounts.firstWhere((a) => a.id == currentAccountId);

  void switchAccount(String id) {
    if (currentAccountId == id) return;
    currentAccountId = id;
    notifyListeners();
  }

  void addAccount(String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    accounts.add(
      Account(
        id: id,
        name: name,
        transactions: [],
      ),
    );

    currentAccountId = id;
    notifyListeners();
  }

  void renameCurrentAccount(String name) {
    currentAccount.name = name;
    notifyListeners();
  }

  // =============================
  // 💰 Transactions
  // =============================
  final List<Map<String, dynamic>> transactions = [];

  int _txVersion = 0;
  int get txVersion => _txVersion;

  List<Map<String, dynamic>> get currentTransactions {
    return transactions.where((t) =>
        (t['accountId']?.toString() ?? 'main') == currentAccountId
    ).toList();
  }

  // =============================
  // 💾 Persistence
  // =============================

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_txKey);

    if (raw == null) return;

    final decoded = jsonDecode(raw) as List;

    transactions
      ..clear()
      ..addAll(decoded.cast<Map<String, dynamic>>());

    _txVersion++;
    notifyListeners();
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_txKey, jsonEncode(transactions));
  }

  // =============================
  // ➕ CRUD
  // =============================

  void addTransaction(Map<String, dynamic> tx) {
    String id;
    do {
      id = DateTime.now().microsecondsSinceEpoch.toString();
    } while (transactions.any((t) => t['id'] == id));

    tx['id'] ??= id;
    tx['accountId'] ??= currentAccountId;
    tx['date'] ??=
        DateTime.now().toIso8601String().split('T').first;

    transactions.add(tx);
    _txVersion++;
    saveState();
    notifyListeners();
  }

  void updateTransactionById(
    String id,
    Map<String, dynamic> updated,
  ) {
    final idx =
        transactions.indexWhere((t) => t['id']?.toString() == id);
    if (idx == -1) return;

    updated['id'] = transactions[idx]['id'];
    updated['accountId'] = transactions[idx]['accountId'];

    transactions[idx] = updated;
    _txVersion++;
    saveState();
    notifyListeners();
  }

  void deleteTransactionById(String id) {
    transactions.removeWhere(
      (t) => t['id']?.toString() == id,
    );
    _txVersion++;
    saveState();
    notifyListeners();
  }

  // =============================
  // 📅 Daily analytics
  // =============================

  List<Map<String, dynamic>> transactionsOn(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);

    return currentTransactions.where((tx) {
      final d = DateTime.parse(tx['date']);
      return d.year == target.year &&
          d.month == target.month &&
          d.day == target.day;
    }).toList();
  }

  double incomeOfDay(DateTime day) =>
      transactionsOn(day)
          .where((t) => t['type'] == 'income')
          .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

  double expenseOfDay(DateTime day) =>
      transactionsOn(day)
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

  double balanceOfDay(DateTime day) =>
      incomeOfDay(day) - expenseOfDay(day);

  // =============================
  // 📊 Computed values
  // =============================
  double get totalIncome =>
      currentTransactions
          .where((t) => t['type'] == 'income')
          .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

  double get totalExpense =>
      currentTransactions
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

  double get balance => totalIncome - totalExpense;

  // =============================
  // 🤖 Dashboard AI
  // =============================
  String? dashboardInsight;

  void setDashboardInsight(String text) {
    dashboardInsight = text;
    notifyListeners();
  }
}

/// =============================
/// 🌐 Inherited Provider
/// =============================
class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState notifier,
    required Widget child,
  }) : super(
          notifier: notifier,
          child: child,
        );

  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();

    assert(provider != null, 'No AppStateProvider found in context');

    return provider!.notifier!;
  }
}
