String formatDateTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.day)}.${two(time.month)}.${time.year} ${two(time.hour)}:${two(time.minute)}';
}
