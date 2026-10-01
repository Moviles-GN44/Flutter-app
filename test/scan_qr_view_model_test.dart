import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/viewmodels/scan_qr_view_model.dart';

void main() {
  test('A restaurant QR code verifies the visit', () {
    final viewModel = ScanQrViewModel();

    final verified = viewModel.onCodeDetected('uniandesfood:el-corral');

    expect(verified, isTrue);
    expect(viewModel.status, ScanStatus.verified);
    expect(viewModel.restaurant?.name, 'El Corral Uniandes');
    expect(viewModel.errorMessage, isNull);
  });

  test('A QR code from outside the app is rejected', () {
    final viewModel = ScanQrViewModel();

    final verified = viewModel.onCodeDetected('https://example.com');

    expect(verified, isFalse);
    expect(viewModel.status, ScanStatus.searching);
    expect(viewModel.restaurant, isNull);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('An unknown restaurant id is rejected', () {
    final viewModel = ScanQrViewModel();

    expect(viewModel.onCodeDetected('uniandesfood:does-not-exist'), isFalse);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('Codes detected after verification are ignored', () {
    final viewModel = ScanQrViewModel()
      ..onCodeDetected('uniandesfood:el-corral');

    expect(viewModel.onCodeDetected('uniandesfood:wok'), isFalse);
    expect(viewModel.restaurant?.id, 'el-corral');
  });

  test('Low light is detected and cleared by the light sensor', () {
    final viewModel = ScanQrViewModel()..onLightChanged(5);
    expect(viewModel.isDark, isTrue);

    viewModel.onLightChanged(200);
    expect(viewModel.isDark, isFalse);
  });

  test('Invalid light readings are ignored', () {
    final viewModel = ScanQrViewModel()..onLightChanged(-1);
    expect(viewModel.isDark, isFalse);
  });
}
