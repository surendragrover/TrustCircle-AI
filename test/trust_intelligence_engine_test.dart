import 'package:flutter_test/flutter_test.dart';
import 'package:trustcircleai/models/trust_case.dart';
import 'package:trustcircleai/services/trust_intelligence_engine.dart';

void main() {
  group('TrustCase', () {
    test('generates a dated case id and preserves original statement', () {
      final trustCase = TrustCase.create(
        title: 'Payment review',
        personName: 'Asha',
        statement: 'मुझे भुगतान मिल गया',
        caseLanguage: 'hi-IN',
        displayLanguage: 'en',
        confidentialityLevel: 'private',
        authorizationConfirmed: true,
        confidentialityConfirmed: true,
        createdAt: DateTime(2026, 9, 30),
        sequence: 7,
      );

      expect(trustCase.id, 'TC-2026-000007');
      expect(trustCase.statement, 'मुझे भुगतान मिल गया');
      expect(
        TrustCase.fromJson(trustCase.toJson()).statement,
        trustCase.statement,
      );
    });
  });

  group('TrustIntelligenceEngine', () {
    test(
      'does not invent a verdict when model artifacts are unavailable',
      () async {
        final trustCase = TrustCase.create(
          title: 'Payment review',
          personName: 'Asha',
          statement: 'The payment was made.',
          caseLanguage: 'en',
          displayLanguage: 'en',
          confidentialityLevel: 'private',
          authorizationConfirmed: true,
          confidentialityConfirmed: true,
          sequence: 1,
        );

        final result = await const TrustIntelligenceEngine().analyze(trustCase);

        expect(result.verdict, TrustVerdict.inconclusive);
        expect(result.confidence, isNull);
        expect(result.errorCodes, contains(AnalysisErrorCode.modelUnavailable));
        expect(result.errorCodes, contains(AnalysisErrorCode.evidenceNotFound));
      },
    );

    test(
      'marks temporary fallback verdicts provisional without confidence',
      () async {
        final trustCase =
            TrustCase.create(
              title: 'Payment review',
              personName: 'Asha',
              statement: 'The payment was made.',
              caseLanguage: 'en',
              displayLanguage: 'en',
              confidentialityLevel: 'private',
              authorizationConfirmed: true,
              confidentialityConfirmed: true,
              sequence: 2,
            ).copyWith(
              evidence: [
                EvidenceItem(
                  id: 'evidence-1',
                  text: 'A bank entry records the payment.',
                  source: 'Bank statement',
                  sourceType: 'document',
                  relation: EvidenceRelation.supports,
                  createdAt: DateTime(2026, 9, 30),
                ),
              ],
            );

        final result = await const TrustIntelligenceEngine().analyze(trustCase);

        expect(result.isProvisional, isTrue);
        expect(result.confidence, isNull);
        expect(result.errorCodes, contains(AnalysisErrorCode.modelUnavailable));
      },
    );
  });
}
