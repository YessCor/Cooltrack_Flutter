import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../core/theme.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({super.key});

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  final SyncService _syncService = SyncService();
  late SyncStatus _currentStatus;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _currentStatus = _syncService.status;
    _pendingCount = _syncService.getPendingCount();
    _syncService.addListener(_handleSyncChange);
  }

  @override
  void dispose() {
    _syncService.removeListener(_handleSyncChange);
    super.dispose();
  }

  void _handleSyncChange(SyncStatus status) {
    if (mounted) {
      setState(() {
        _currentStatus = status;
        _pendingCount = _syncService.getPendingCount();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingCount == 0 && _currentStatus != SyncStatus.syncing) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: _currentStatus == SyncStatus.syncing ? null : () => _syncService.syncAll(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentStatus == SyncStatus.syncing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary,
                ),
              )
            else
              Icon(
                _currentStatus == SyncStatus.error ? Icons.sync_problem : Icons.sync,
                size: 18,
                color: _currentStatus == SyncStatus.error ? AppColors.error : AppColors.secondary,
              ),
            const SizedBox(width: 6),
            Text(
              _currentStatus == SyncStatus.syncing 
                ? 'Sincronizando...' 
                : '$_pendingCount pendientes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _currentStatus == SyncStatus.error ? AppColors.error : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
