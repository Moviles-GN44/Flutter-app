import 'package:flutter_test/flutter_test.dart';
import 'package:uniandes_food/services/bq7_analytics_service.dart';

void main() {
  Map<String, dynamic> featureEvent(String feature) {
    return {
      'eventName': 'feature_opened',
      'params': {'feature': feature},
    };
  }

  test('Counts feature interactions correctly', () {
    final result = BQ7AnalyticsService.aggregate([
      featureEvent('home'),
      featureEvent('home'),
      featureEvent('explore'),
      featureEvent('favorites'),
    ]);

    expect(result.totalInteractions, 4);
    expect(result.countFor('home'), 2);
    expect(result.countFor('explore'), 1);
    expect(result.countFor('favorites'), 1);
    expect(result.countFor('profile'), 0);
    expect(result.countFor('qr_scanner'), 0);
  });

  test('Calculates feature percentages', () {
    final result = BQ7AnalyticsService.aggregate([
      featureEvent('home'),
      featureEvent('home'),
      featureEvent('explore'),
      featureEvent('favorites'),
    ]);

    expect(result.percentageFor('home'), 50);
    expect(result.percentageFor('explore'), 25);
    expect(result.percentageFor('favorites'), 25);
  });

  test('Identifies the least used features including zero uses', () {
    final result = BQ7AnalyticsService.aggregate([
      featureEvent('home'),
      featureEvent('explore'),
      featureEvent('favorites'),
    ]);

    expect(result.leastUsedFeatures, ['profile', 'qr_scanner']);
  });

  test('Ignores unrelated and invalid events', () {
    final result = BQ7AnalyticsService.aggregate([
      featureEvent('home'),
      featureEvent('unknown'),
      {
        'eventName': 'filter_applied',
        'params': {'feature': 'explore'},
      },
      {'eventName': 'feature_opened', 'params': null},
    ]);

    expect(result.totalInteractions, 1);
    expect(result.countFor('home'), 1);
  });

  test('Returns no ranking when there are no interactions', () {
    final result = BQ7AnalyticsService.aggregate([]);

    expect(result.totalInteractions, 0);
    expect(result.mostUsedFeature, isNull);
    expect(result.leastUsedFeatures, isEmpty);
    expect(result.percentageFor('home'), 0);
  });
}
