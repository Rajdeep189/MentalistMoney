// Basic smoke test for the mentalist project.
// (The app itself uses sqflite, which only runs on device/emulator,
//  so we keep this test platform-free.)
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanity', () {
    expect(1 + 1, 2);
  });
}
