import 'package:flutter/material.dart';

import 'package:uniandes_food/models/peak_hours.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/viewmodels/peak_hours_view_model.dart';
import 'package:uniandes_food/widgets/status_tag.dart';
import 'package:uniandes_food/widgets/wait_time_style.dart';

class BestTimeScreen extends StatefulWidget {
  const BestTimeScreen({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<BestTimeScreen> createState() => _BestTimeScreenState();
}

class _BestTimeScreenState extends State<BestTimeScreen> {
  late final PeakHoursViewModel _viewModel = PeakHoursViewModel(
    restaurant: widget.restaurant,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: const Text('Best time to go', style: AppText.h2),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final peakHours = _viewModel.peakHours;

          if (peakHours == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(widget.restaurant.name, style: AppText.h1),
              const SizedBox(height: 4),
              Text(
                'Wait time reported by students at each hour of the day',
                style: AppText.caption,
              ),
              const SizedBox(height: 16),
              if (peakHours.slots.isEmpty)
                const _NoReports()
              else ...[
                _BestSlotCard(
                  slot: _viewModel.bestSlot!,
                  isNow: _viewModel.bestSlot!.hour == _viewModel.currentHour,
                ),
                const SizedBox(height: 16),
                _HourChart(
                  peakHours: peakHours,
                  currentHour: _viewModel.currentHour,
                ),
                const SizedBox(height: 12),
                Text(
                  'Based on ${peakHours.totalReports} '
                  '${peakHours.totalReports == 1 ? 'report' : 'reports'} '
                  'from students who ate here.',
                  style: AppText.caption,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

class _BestSlotCard extends StatelessWidget {
  const _BestSlotCard({required this.slot, required this.isNow});

  final HourSlot slot;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final style = WaitTimeStyle.of(slot.waitTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.text, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNow ? 'Go now' : 'Best time today',
                  style: AppText.caption.copyWith(color: style.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_hourLabel(slot.hour)} - ${_hourLabel(slot.hour + 1)}',
                  style: AppText.h2.copyWith(color: style.text),
                ),
                const SizedBox(height: 2),
                Text(
                  'Usually ${slot.waitTime.shortLabel} · ${slot.reports} '
                  '${slot.reports == 1 ? 'report' : 'reports'}',
                  style: AppText.caption.copyWith(color: AppColors.shadowGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HourChart extends StatelessWidget {
  const _HourChart({required this.peakHours, required this.currentHour});

  static const _maxMinutes = 20.0;

  final PeakHours peakHours;
  final int currentHour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final hour in PeakHours.hours)
                  Expanded(
                    child: _HourBar(
                      hour: hour,
                      slot: peakHours.slotAt(hour),
                      isCurrent: hour == currentHour,
                      maxMinutes: _maxMinutes,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final wait in WaitTime.values) StatusTag.wait(wait)],
          ),
        ],
      ),
    );
  }
}

class _HourBar extends StatelessWidget {
  const _HourBar({
    required this.hour,
    required this.slot,
    required this.isCurrent,
    required this.maxMinutes,
  });

  final int hour;
  final HourSlot? slot;
  final bool isCurrent;
  final double maxMinutes;

  @override
  Widget build(BuildContext context) {
    final slot = this.slot;
    final fill = slot == null
        ? 0.03
        : (slot.averageMinutes / maxMinutes).clamp(0.1, 1.0);

    return Semantics(
      label: slot == null
          ? '${_hourLabel(hour)}: no reports'
          : '${_hourLabel(hour)}: ${slot.waitTime.spokenLabel}',
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: FractionallySizedBox(
              heightFactor: fill,
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: slot == null
                      ? AppColors.border
                      : WaitTimeStyle.of(slot.waitTime).accent,
                  borderRadius: BorderRadius.circular(4),
                  border: isCurrent
                      ? Border.all(color: AppColors.shadowGrey, width: 2)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$hour',
            style: AppText.caption.copyWith(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
              color: isCurrent ? AppColors.shadowGrey : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoReports extends StatelessWidget {
  const _NoReports();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No wait time reports yet. Scan the QR code after eating here '
              'to add the first one.',
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }
}
