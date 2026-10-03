import 'package:flutter_test/flutter_test.dart';
import 'package:trustcircleai/i18n/translation_dictionary.dart';

void main() {
  test('every supported language has all six controlled verdict terms', () {
    for (final language in TranslationDictionary.languages) {
      expect(
        TranslationDictionary.hasAllVerdicts(language.code),
        isTrue,
        reason: 'Missing verdict terminology for ${language.code}',
      );
    }
  });

  test('unsupported UI keys fall back to safe English text', () {
    expect(
      TranslationDictionary.translate('case.title', 'ta-IN'),
      'Create a case',
    );
    expect(
      TranslationDictionary.translate('missing.key', 'en'),
      'Text unavailable',
    );
  });
}
