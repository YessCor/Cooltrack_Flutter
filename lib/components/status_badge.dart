import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool large;

  const AppStatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        border: Border.all(color: _getColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: large ? 18 : 14, color: _getColor()),
          const SizedBox(width: 6),
          Text(
            orderStatusLabels[status] ?? 'Desconocido',
            style: TextStyle(
              color: _getColor(),
              fontWeight: FontWeight.w600,
              fontSize: large ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.assigned:
        return Colors.blue;
      case OrderStatus.accepted:
        return Colors.cyan;
      case OrderStatus.inTransit:
        return Colors.purple;
      case OrderStatus.inProgress:
        return Colors.indigo;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.assigned:
        return Icons.person;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.inTransit:
        return Icons.directions_car;
      case OrderStatus.inProgress:
        return Icons.build;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class AppQuoteStatusBadge extends StatelessWidget {
  final QuoteStatus status;
  final bool large;

  const AppQuoteStatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        border: Border.all(color: _getColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: large ? 18 : 14, color: _getColor()),
          const SizedBox(width: 6),
          Text(
            quoteStatusLabels[status] ?? 'Desconocido',
            style: TextStyle(
              color: _getColor(),
              fontWeight: FontWeight.w600,
              fontSize: large ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case QuoteStatus.draft:
        return Colors.grey;
      case QuoteStatus.sent:
        return Colors.blue;
      case QuoteStatus.approved:
        return Colors.green;
      case QuoteStatus.rejected:
        return Colors.red;
      case QuoteStatus.expired:
        return Colors.orange;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case QuoteStatus.draft:
        return Icons.edit;
      case QuoteStatus.sent:
        return Icons.send;
      case QuoteStatus.approved:
        return Icons.check_circle;
      case QuoteStatus.rejected:
        return Icons.cancel;
      case QuoteStatus.expired:
        return Icons.timer_off;
    }
  }
}