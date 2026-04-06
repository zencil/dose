import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:dose/db/cabinet_db.dart';
import 'package:dose/models/cabinet_model.dart';
import 'package:dose/models/intake_model.dart';
import 'package:dose/db/intake_log_db.dart' as log_db;
import 'package:dose/services/widget_service.dart';
import 'package:dose/services/snooze_service.dart';
import 'package:dose/services/notification_service.dart';
import 'package:dose/services/alarm_service.dart';

class AlarmRingData {
  final int id;
  final String title;

  AlarmRingData({required this.id, required this.title});
}

class AlarmRingScreen extends StatefulWidget {
  final AlarmRingData alarmData;

  const AlarmRingScreen({super.key, required this.alarmData});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  bool _canSnooze = true;
  int _snoozeCount = 0;
  Timer? _autoSnoozeTimer;
  bool _isProcessing = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Lock to portrait and set immersive overlay style
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadSnoozeState();
    _startAutoSnoozeTimer();
  }

  void _startAutoSnoozeTimer() {
    _autoSnoozeTimer = Timer(const Duration(seconds: 50), () {
      if (_canSnooze) {
        _handleSnooze();
      } else {
        _handleQuietDone();
      }
    });
  }

  @override
  void dispose() {
    _autoSnoozeTimer?.cancel();
    _pulseController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Future<void> _loadSnoozeState() async {
    final count = await SnoozeService.getSnoozeCount(widget.alarmData.id);
    if (mounted) {
      setState(() {
        _snoozeCount = count;
        _canSnooze = count < SnoozeService.maxSnoozes;
      });
    }
  }

  /// Quietly dismiss: stops alarm & pops without logging intake.
  Future<void> _handleQuietDone() async {
    if (_isProcessing) return;
    _isProcessing = true;
    _autoSnoozeTimer?.cancel();
    await AlarmService().stopRinging(widget.alarmData.id);
    await AlarmService().minimizeIfLocked();
    if (mounted) Navigator.pop(context);
  }

  /// Done: stops alarm, logs intake, decrements stock, then pops.
  Future<void> _handleDone() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _autoSnoozeTimer?.cancel();

    // Stop the alarm sound first
    await AlarmService().stopRinging(widget.alarmData.id);

    // Update stock and log intake
    final med = await DatabaseHelper.instance.readMedicine(widget.alarmData.id);
    if (med != null && med.currstock > 0) {
      final updatedMed = Cabinet(
        id: med.id,
        name: med.name,
        dosage: med.dosage,
        time: med.time,
        initstock: med.initstock,
        currstock: med.currstock - 1,
        priority: med.priority,
        category: med.category,
        unit: med.unit,
      );
      await DatabaseHelper.instance.updateMedicine(updatedMed);

      final now = DateTime.now();
      final timeString =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dateString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final intake = Intake(
        id: med.id,
        name: med.name,
        ttime: med.time,
        time: timeString,
        date: dateString,
        currstock: med.currstock - 1,
      );
      await log_db.DatabaseHelper.instance.createlog(intake);
      await WidgetService.updateWidgetState();

      if (updatedMed.currstock < 3) {
        await NotificationHelper().showLowStockNotification(updatedMed);
      }
    }
    await SnoozeService.resetSnooze(widget.alarmData.id);

    // Pop only after all operations are complete
    await AlarmService().minimizeIfLocked();
    if (mounted) Navigator.pop(context);
  }

  /// Snooze: stops current alarm, schedules a new one in 5 min, then pops.
  Future<void> _handleSnooze() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _autoSnoozeTimer?.cancel();

    final result = await SnoozeService.incrementSnooze(widget.alarmData.id);

    // If snooze limit reached, treat as quiet dismiss
    if (result == -1) {
      await AlarmService().stopRinging(widget.alarmData.id);
      await AlarmService().minimizeIfLocked();
      if (mounted) Navigator.pop(context);
      return;
    }

    await AlarmService().stopRinging(widget.alarmData.id);

    await AlarmService().scheduleSnoozeAlarm(
      widget.alarmData.id,
      widget.alarmData.title,
    );

    await AlarmService().minimizeIfLocked();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = widget.alarmData.title;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [cs.primaryContainer, cs.surface],
              stops: const [0.0, 0.6],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Pulsing alarm icon
                _buildPulsingIcon(cs),
                const SizedBox(height: 40),
                // Medicine name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Time for your dose',
                  style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                ),
                if (_snoozeCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Snoozed $_snoozeCount/${SnoozeService.maxSnoozes}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                // Action buttons
                _buildActionButtons(cs),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingIcon(ColorScheme cs) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _pulseAnimation.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25 * scale),
                  blurRadius: 40 * scale,
                  spreadRadius: 10 * scale,
                ),
              ],
            ),
            child: Icon(
              Icons.alarm_rounded,
              size: 64,
              color: cs.onPrimaryContainer,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          if (_canSnooze) ...[
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _handleSnooze,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.outline, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.snooze_rounded),
                  label: const Text(
                    'Snooze',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _handleDone,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _isProcessing ? 'Saving...' : 'Done',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
