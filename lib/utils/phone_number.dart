final RegExp _nonDigits = RegExp(r'[^0-9]');
final RegExp _digitsOnly = RegExp(r'^\d+$');

String normalizeRecipient(String raw) {
  var value = raw.trim();
  if (value.startsWith('+')) {
    value = value.replaceFirst('+', '00');
  }
  if (value.startsWith('0') && !value.startsWith('00')) {
    value = value.replaceFirst('0', '0043');
  }
  return value.replaceAll(_nonDigits, '');
}

String? normalizeSenderId(String? raw) {
  if (raw == null) {
    return null;
  }
  var value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  if (value.startsWith('+')) {
    value = '00${value.substring(1).replaceAll(_nonDigits, '')}';
  }
  final compact = value.replaceAll(' ', '');
  if (_digitsOnly.hasMatch(compact) &&
      compact.startsWith('0') &&
      !compact.startsWith('00')) {
    return compact.replaceFirst('0', '0043');
  }
  return value;
}
