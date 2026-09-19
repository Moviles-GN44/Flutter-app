/// Formats an amount in Colombian pesos the way the app shows prices: a
/// leading `$` and a dot every three digits (e.g. `$24.900`).
String formatCop(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }

  return '${amount < 0 ? '-' : ''}\$$buffer';
}
