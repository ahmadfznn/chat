import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatTimeTo12Hour(Timestamp? timestamp) {
  if (timestamp == null) return "";

  DateTime date = DateTime.fromMillisecondsSinceEpoch(
      timestamp.seconds * 1000 + timestamp.nanoseconds ~/ 1000000);

  return DateFormat('hh:mm a').format(date);
}

String formatTimeTo24Hour(dynamic timestamp) {
  if (timestamp == null) return "";

  DateTime date;

  if (timestamp is int) {
    date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  } else if (timestamp is Timestamp) {
    date = timestamp.toDate();
  } else {
    return "";
  }

  return DateFormat('HH:mm').format(date);
}

String formatDateWithTimeIndo(String timestamp) {
  DateTime date = DateTime.parse(timestamp);

  final List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  int day = date.day;
  String month = months[date.month - 1];
  int year = date.year;

  String formattedTime = DateFormat('hh:mm a').format(date);

  return '$month $day, $year : $formattedTime';
}

String formatDateWithDayAndMonth(dynamic time) {
  DateTime dateTime;

  if (time is String) {
    dateTime = DateTime.parse(time);
  } else if (time is DateTime) {
    dateTime = time.toLocal();
  } else {
    throw ArgumentError('Unsupported type for time parameter');
  }

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  String dayOfWeek = days[dateTime.weekday - 1];
  String month = months[dateTime.month - 1];
  int day = dateTime.day;
  int year = dateTime.year;

  return '$dayOfWeek, $month $day, $year';
}

String formatOrdinalDate(DateTime time) {
  String date = getOrdinalNumber(time.day);

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  String month = months[time.month - 1];

  return '$date, $month';
}

String getOrdinalNumber(int day) {
  if (day >= 11 && day <= 13) {
    return '$day';
  } else {
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}
