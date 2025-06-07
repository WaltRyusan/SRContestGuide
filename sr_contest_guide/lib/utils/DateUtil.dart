import 'package:sr_contest_guide/importer.dart';

class DateUtil {
  static String formattedToday(List<String> existingTitles) {
    final formatter = DateFormat("yyyy/MM/dd");
    String todayTitle = formatter.format(DateTime.now());

    if (existingTitles.isEmpty) {
      return todayTitle;
    } else {
      int count = 2;
      String newTitle = "${todayTitle}_$count";
      while (existingTitles.contains(newTitle)) {
        count++;
        newTitle = "${todayTitle}_$count";
      }
      return newTitle;
    }
  }
}
