import 'package:flutter/material.dart';
import '../../models/invoice.dart';

enum BadgeType { delivery, payment }

class InvoiceStatusBadge extends StatelessWidget {
  final dynamic status;
  final BadgeType type;

  const InvoiceStatusBadge({
    super.key,
    required this.status,
    this.type = BadgeType.delivery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    if (type == BadgeType.delivery) {
      switch (status as InvoiceStatus) {
        case InvoiceStatus.pending:
          backgroundColor = Colors.orange.withOpacity(0.2);
          textColor = Colors.orange;
          text = 'Pending';
          icon = Icons.pending_outlined;
          break;
        case InvoiceStatus.delivered:
          backgroundColor = Colors.green.withOpacity(0.2);
          textColor = Colors.green;
          text = 'Delivered';
          icon = Icons.check_circle_outline;
          break;
        case InvoiceStatus.cancelled:
          backgroundColor = Colors.red.withOpacity(0.2);
          textColor = Colors.red;
          text = 'Cancelled';
          icon = Icons.cancel_outlined;
          break;
      }
    } else {
      switch (status as PaymentStatus) {
        case PaymentStatus.unpaid:
          backgroundColor = Colors.red.withOpacity(0.2);
          textColor = Colors.red;
          text = 'Unpaid';
          icon = Icons.money_off_outlined;
          break;
        case PaymentStatus.partial:
          backgroundColor = Colors.orange.withOpacity(0.2);
          textColor = Colors.orange;
          text = 'Partial';
          icon = Icons.payments_outlined;
          break;
        case PaymentStatus.paid:
          backgroundColor = Colors.green.withOpacity(0.2);
          textColor = Colors.green;
          text = 'Paid';
          icon = Icons.paid_outlined;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
