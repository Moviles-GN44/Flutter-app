import 'package:uniandes_food/models/restaurant.dart';

class HourSlot {
  const HourSlot({
    required this.hour,
    required this.reports,
    required this.averageMinutes,
  });

  factory HourSlot.fromJson(Map<String, dynamic> json) {
    return HourSlot(
      hour: json['hour'] as int,
      reports: json['reports'] as int,
      averageMinutes: (json['averageMinutes'] as num).toDouble(),
    );
  }

  final int hour;
  final int reports;
  final double averageMinutes;

  WaitTime get waitTime => WaitTime.fromMinutes(averageMinutes);

  Map<String, dynamic> toJson() {
    return {'hour': hour, 'reports': reports, 'averageMinutes': averageMinutes};
  }
}

class PeakHours {
  const PeakHours({
    required this.restaurantId,
    required this.slots,
    required this.updatedAt,
  });

  factory PeakHours.fromReviews(
    String restaurantId,
    List<Review> reviews,
    DateTime updatedAt,
  ) {
    final minutes = List<int>.filled(hours.length, 0);
    final reports = List<int>.filled(hours.length, 0);

    for (final review in reviews) {
      final hour = review.createdAt?.hour;
      if (hour == null || hour < hours.first || hour > hours.last) continue;
      minutes[hour - hours.first] += review.waitTime.minutes;
      reports[hour - hours.first]++;
    }

    return PeakHours(
      restaurantId: restaurantId,
      updatedAt: updatedAt,
      slots: [
        for (var i = 0; i < hours.length; i++)
          if (reports[i] > 0)
            HourSlot(
              hour: hours[i],
              reports: reports[i],
              averageMinutes: minutes[i] / reports[i],
            ),
      ],
    );
  }

  factory PeakHours.fromJson(Map<String, dynamic> json) {
    return PeakHours(
      restaurantId: json['restaurantId'] as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      slots: [
        for (final slot in json['slots'] as List)
          HourSlot.fromJson(slot as Map<String, dynamic>),
      ],
    );
  }

  static final hours =[for (var hour = 7; hour <= 19; hour++) hour];

  final String restaurantId;
  final List<HourSlot> slots;
  final DateTime updatedAt;

  int get totalReports => slots.fold(0, (total, slot) => total + slot.reports);

  HourSlot? slotAt(int hour) {
    for (final slot in slots) {
      if (slot.hour == hour) return slot;
    }
    return null;
  }

  HourSlot? bestFrom(int hour) {
    final upcoming = slots.where((slot) => slot.hour >= hour);
    return _quietest(upcoming.isEmpty ? slots : upcoming);
  }

  HourSlot? _quietest(Iterable<HourSlot> candidates) {
    HourSlot? best;
    for (final slot in candidates) {
      if (best == null || slot.averageMinutes < best.averageMinutes) {
        best = slot;
      }
    }
    return best;
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'slots': [for (final slot in slots) slot.toJson()],
    };
  }
}
