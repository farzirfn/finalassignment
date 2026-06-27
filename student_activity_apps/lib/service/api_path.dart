import 'package:flutter/foundation.dart';

class ApiPath {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost/studentactivity/api";
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://10.144.0.252/studentactivity";
      default:
        return "http://localhost/studentactivity";
    }
  }

  static String endpoint(String fileName) {
    return "$baseUrl/$fileName";
  }
}
