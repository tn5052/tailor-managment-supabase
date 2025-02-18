import 'package:flutter/material.dart';
import '../../models/invoice.dart';

class InvoiceStatusBadge extends StatelessWidget {
  final dynamic status;
  final bool showIcon;
  final bool animate;
  final double height;

  const InvoiceStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.animate = true,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: animate ? 300 : 0),
      builder: (context, value, child) => Transform.scale(
        scale: 0.8 + (0.2 * value),
        child: Opacity(
          opacity: value,
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: height * 0.5),
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(height * 0.5),
              border: Border.all(
                color: config.color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: config.color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon) ...[
                  Icon(config.icon, size: height * 0.6, color: config.color),
                  SizedBox(width: height * 0.3),
                ],
                Text(
                  config.label,
                  style: TextStyle(
                    color: config.color,
                    fontSize: height * 0.45,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(dynamic status) {
    if (status is InvoiceStatus) {
      switch (status) {
        case InvoiceStatus.pending:
          return _StatusConfig(
            color: Colors.orange,
            icon: Icons.pending_outlined,
            label: 'Pending',
          );
        case InvoiceStatus.delivered:
          return _StatusConfig(
            color: Colors.green,
            icon: Icons.check_circle_outline,
            label: 'Delivered',
          );
        case InvoiceStatus.cancelled:
          return _StatusConfig(
            color: Colors.red,
            icon: Icons.cancel_outlined,
            label: 'Cancelled',
          );
      }
    } else if (status is PaymentStatus) {
      switch (status) {
        case PaymentStatus.unpaid:
          return _StatusConfig(
            color: Colors.red,
            icon: Icons.money_off_outlined,
            label: 'Unpaid',
          );
        case PaymentStatus.partial:
          return _StatusConfig(
            color: Colors.orange,
            icon: Icons.payments_outlined,
            label: 'Partial',
          );
        case PaymentStatus.paid:
          return _StatusConfig(
            color: Colors.green,
            icon: Icons.paid_outlined,
            label: 'Paid',
          );
      }
    }
    throw ArgumentError('Invalid status type');
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
