import 'package:intl/intl.dart';

class DateTimeUtils {
  static String getDateHeader() {
    return DateFormat('EEEE, d MMMM').format(DateTime.now());
  }
}
