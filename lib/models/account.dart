class Account {
  final String id;
  String name;
  final List<Map<String, dynamic>> transactions;

  Account({
    required this.id,
    required this.name,
    required this.transactions,
  });
}
