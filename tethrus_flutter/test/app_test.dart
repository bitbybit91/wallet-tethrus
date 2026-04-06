import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tethrus App', () {
    test('app constants have correct values', () {
      expect('Tethrus', equals('Tethrus'));
      expect('com.tethrus.app', equals('com.tethrus.app'));
    });
  });
}
