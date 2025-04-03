import 'package:dart_flux/extensions/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group('StringUtils.capitalize', () {
    test('Capitalize lower case text', () {
      expect('amr'.capitalize, 'Amr');
    });
    test('Capitalize upper case text', () {
      expect('AMR'.capitalize, 'Amr');
    });
    test('Capitalize full sentence', () {
      expect('hello amr'.capitalize, 'Hello amr');
    });

    group('StringUtils.strip', () {
      test('Stripping letter from start', () {
        expect(' strip the first'.strip(' ', all: false), 'strip the first');
      });
      test('Stripping letter from end', () {
        expect(' strip the first '.strip(' ', all: false), 'strip the first');
      });
      test('Stripping single letter from multiple', () {
        expect(
          '  strip the first  '.strip(' ', all: false),
          ' strip the first ',
        );
      });
      test('Stripping all letter from multiple', () {
        expect('  strip the first  '.strip(' ', all: true), 'strip the first');
      });
    });
  });
}
