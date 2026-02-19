import 'package:intl/intl.dart';

final _intFmt = NumberFormat('#,##0');
final _decimalFmt = NumberFormat('#,##0.00');

String formatMoney(num value) {
  // ถ้าเป็นจำนวนเต็ม → ไม่โชว์ทศนิยม
  if (value % 1 == 0) {
    return _intFmt.format(value);
  }

  // ถ้ามีทศนิยม → แสดง 2 ตำแหน่งแบบการเงิน
  return _decimalFmt.format(value);
}
