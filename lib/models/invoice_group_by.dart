enum InvoiceGroupBy {
  none,
  customer,
  date,
  status,
  month,
  amount
}

extension StringX on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
