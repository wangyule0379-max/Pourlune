import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    stdout.writeln('LY_NATIVE_DRIVER_REPORT=${jsonEncode(data)}');
  },
);
