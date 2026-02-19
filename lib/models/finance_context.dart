class FinanceContext {
  final double balance;
  final double income;
  final double expense;

  FinanceContext({
    required this.balance,
    required this.income,
    required this.expense,
  });

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'income': income,
        'expense': expense,
      };
}
