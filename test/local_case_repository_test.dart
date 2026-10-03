import 'package:flutter_test/flutter_test.dart';
import 'package:trustcircleai/models/trust_case.dart';
import 'package:trustcircleai/services/local_case_repository.dart';

void main() {
  test('round-trips case attachments without losing source metadata', () {
    final trustCase =
        TrustCase.create(
          title: 'Document review',
          personName: 'Asha',
          statement: 'The record is accurate.',
          caseLanguage: 'en',
          displayLanguage: 'en',
          confidentialityLevel: 'Private',
          authorizationConfirmed: true,
          confidentialityConfirmed: true,
          sequence: 101,
          createdAt: DateTime(2026, 9, 30),
        ).copyWith(
          attachments: [
            CaseAttachment(
              id: 'TC-2026-000101-A1',
              name: 'record.pdf',
              kind: CaseAttachmentKind.document,
              sizeBytes: 2048,
              addedAt: DateTime(2026, 9, 30, 12),
              localPath: r'C:\private\record.pdf',
            ),
          ],
        );

    final restored = TrustCase.fromJson(trustCase.toJson());

    expect(restored.attachments, hasLength(1));
    expect(restored.attachments.single.name, 'record.pdf');
    expect(restored.attachments.single.localPath, r'C:\private\record.pdf');
  });

  test(
    'records hashed audit events and removes cases from the session store',
    () {
      final repository = LocalCaseRepository();
      final trustCase = TrustCase.create(
        title: 'Payment review',
        personName: 'Asha',
        statement: 'Private statement text',
        caseLanguage: 'en',
        displayLanguage: 'en',
        confidentialityLevel: 'Private',
        authorizationConfirmed: true,
        confidentialityConfirmed: true,
        sequence: 102,
      );

      repository.saveCase(trustCase);

      expect(repository.cases, hasLength(1));
      expect(repository.auditTrail.single.inputSummary, 'statement_length:22');
      expect(repository.auditTrail.single.inputHash, hasLength(64));
      expect(
        repository.auditTrail.single.inputSummary,
        isNot(contains('Private statement text')),
      );

      repository.removeCase(trustCase.id);

      expect(repository.cases, isEmpty);
      expect(repository.auditTrail.last.action, 'case_deleted');
    },
  );
}
