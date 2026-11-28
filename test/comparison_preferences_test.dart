import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/services/comparison_preferences_service.dart';
import 'package:uniandes_food/viewmodels/comparison_view_model.dart';

import 'comparison_view_model_test.dart' show restaurant;

class FakeComparisonPreferencesService extends ComparisonPreferencesService {
  String? firstId;
  String? secondId;

  @override
  Future<void> saveSelection(String? firstId, String? secondId) async {
    this.firstId = firstId;
    this.secondId = secondId;
  }

  @override
  Future<({String? firstId, String? secondId})> loadSelection() async {
    return (firstId: firstId, secondId: secondId);
  }

  @override
  Future<void> clearSelection() async {
    firstId = null;
    secondId = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeComparisonPreferencesService storage;
  late ComparisonViewModel viewModel;

  final first = restaurant('first');
  final second = restaurant('second');

  setUp(() {
    storage = FakeComparisonPreferencesService();

    viewModel = ComparisonViewModel(preferencesService: storage);

    viewModel.updateRestaurants([first, second], isFromCache: false);
  });

  tearDown(() async {
    await viewModel.waitForPendingSaves();
    viewModel.dispose();
  });

  test('Selected restaurant IDs are saved locally', () async {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    await viewModel.waitForPendingSaves();

    expect(storage.firstId, first.id);
    expect(storage.secondId, second.id);
  });

  test('Saved selection is restored in a new ViewModel', () async {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    await viewModel.waitForPendingSaves();

    final reopenedViewModel = ComparisonViewModel(preferencesService: storage);

    reopenedViewModel.updateRestaurants([first, second], isFromCache: false);

    await reopenedViewModel.restoreSelection();

    expect(reopenedViewModel.firstRestaurant?.id, first.id);
    expect(reopenedViewModel.secondRestaurant?.id, second.id);
    expect(reopenedViewModel.canCompare, isTrue);

    reopenedViewModel.dispose();
  });

  test('Clearing comparison removes saved IDs', () async {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);
    viewModel.clearSelection();

    await viewModel.waitForPendingSaves();

    expect(storage.firstId, isNull);
    expect(storage.secondId, isNull);
  });

  test('Saved restaurants can be restored offline', () async {
    await storage.saveSelection(first.id, second.id);

    viewModel.updateRestaurants([first, second], isFromCache: true);

    await viewModel.restoreSelection();

    expect(viewModel.isFromCache, isTrue);
    expect(viewModel.canCompare, isTrue);
  });

  test('Unavailable saved restaurants are not selected', () async {
    await storage.saveSelection(first.id, 'unavailable');

    await viewModel.restoreSelection();

    expect(viewModel.firstRestaurant?.id, first.id);
    expect(viewModel.secondRestaurant, isNull);
    expect(viewModel.canCompare, isFalse);
  });

  test('Selections are restored when restaurant data arrives', () async {
    await storage.saveSelection(first.id, second.id);

    viewModel.updateRestaurants([], isFromCache: true);

    await viewModel.restoreSelection();

    expect(viewModel.canCompare, isFalse);

    viewModel.updateRestaurants([first, second], isFromCache: false);

    expect(viewModel.canCompare, isTrue);
  });

  test('Restoration does not overwrite a new selection', () async {
    await storage.saveSelection(first.id, second.id);

    final restoration = viewModel.restoreSelection();

    viewModel.selectFirstRestaurant(second);

    await restoration;
    await viewModel.waitForPendingSaves();

    expect(viewModel.firstRestaurant?.id, second.id);
    expect(storage.firstId, second.id);
  });

  test('Rapid selection changes preserve the latest choice', () async {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    viewModel.clearSelection();
    viewModel.selectFirstRestaurant(second);

    await viewModel.waitForPendingSaves();

    expect(storage.firstId, second.id);
    expect(storage.secondId, isNull);
  });
}
