import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/trust_case.dart';

abstract interface class TrustModelAdapter {
  String get modelName;
  String get modelVersion;

  Future<TrustAssessmentResult> analyze(TrustCase trustCase);
}

class TemporaryTrustFallbackAdapter implements TrustModelAdapter {
  const TemporaryTrustFallbackAdapter();

  @override
  String get modelName => 'TrustCircle Temporary Fallback Engine';

  @override
  String get modelVersion => '0.1.0-fallback';

  @override
  Future<TrustAssessmentResult> analyze(TrustCase trustCase) async {
    final statement = trustCase.statement.trim();
    final evidence = trustCase.evidence
        .where((item) => item.text.trim().isNotEmpty)
        .toList(growable: false);

    if (statement.isEmpty || evidence.isEmpty) {
      return TrustAssessmentResult(
        caseId: trustCase.id,
        verdict: TrustVerdict.inconclusive,
        evidenceStrength: EvidenceStrength.unavailable,
        reasons: const [
          'Temporary fallback requires a statement and supporting evidence.',
        ],
        supportingEvidence: const [],
        contradictoryEvidence: const [],
        riskSignals: const [
          'No evidence is available for a temporary trust signal.',
        ],
        missingInformation: const [
          'A statement is required for a provisional assessment.',
          'Add at least one evidence item before running the fallback engine.',
        ],
        recommendedVerification: const [
          'Verify the original statement with an independent source.',
          'Collect evidence from a trusted document, transaction, or witness.',
        ],
        createdAt: DateTime.now(),
        originalStatement: trustCase.statement,
        originalLanguage: trustCase.caseLanguage,
        errorCodes: const [
          AnalysisErrorCode.modelUnavailable,
          AnalysisErrorCode.evidenceNotFound,
        ],
      );
    }

    final supportCount = evidence
        .where((item) => item.relation == EvidenceRelation.supports)
        .length;
    final contradictionCount = evidence
        .where((item) => item.relation == EvidenceRelation.contradicts)
        .length;
    final unresolvedCount = evidence
        .where((item) => item.relation == EvidenceRelation.unresolved)
        .length;
    final effect = supportCount * 2 - contradictionCount * 3 - unresolvedCount;

    final riskSignals = <String>[];
    if (contradictionCount > 0) {
      riskSignals.add(
        'Evidence contradicts the statement in $contradictionCount source item(s).',
      );
    }
    if (unresolvedCount > 0) {
      riskSignals.add(
        'Some evidence remains unresolved and may affect confidence.',
      );
    }
    if (statement.toLowerCase().contains('not') &&
        statement.toLowerCase().contains('know')) {
      riskSignals.add('The statement contains uncertainty language.');
    }

    final reasons = <String>[];
    if (supportCount > 0) {
      reasons.add(
        'Consistent supporting evidence was recorded for the person-level claim.',
      );
    }
    if (contradictionCount > 0) {
      reasons.add(
        'Contradictory evidence reduces trust confidence and requires verification.',
      );
    }
    if (riskSignals.isEmpty) {
      reasons.add(
        'The fallback analysis found no strong risk pattern in the available evidence.',
      );
    }

    TrustVerdict verdict;
    EvidenceStrength strength;
    String deceptionAssessment;

    if (effect >= 4) {
      verdict = TrustVerdict.trustworthy;
      strength = EvidenceStrength.high;
      deceptionAssessment = 'LOW';
    } else if (effect >= 1) {
      verdict = TrustVerdict.mostlyTrustworthy;
      strength = EvidenceStrength.moderate;
      deceptionAssessment = 'LOW TO MODERATE';
    } else if (effect >= -2) {
      verdict = TrustVerdict.suspicious;
      strength = EvidenceStrength.moderate;
      deceptionAssessment = 'MODERATE';
    } else if (effect >= -5) {
      verdict = TrustVerdict.notTrustworthy;
      strength = EvidenceStrength.moderate;
      deceptionAssessment = 'HIGH';
    } else {
      verdict = TrustVerdict.deceptive;
      strength = EvidenceStrength.high;
      deceptionAssessment = 'HIGH';
    }

    final supporting = evidence
        .where((item) => item.relation == EvidenceRelation.supports)
        .map((item) => item.text)
        .toList(growable: false);
    final contradictory = evidence
        .where((item) => item.relation == EvidenceRelation.contradicts)
        .map((item) => item.text)
        .toList(growable: false);

    return TrustAssessmentResult(
      caseId: trustCase.id,
      verdict: verdict,
      evidenceStrength: strength,
      deceptionAssessment: deceptionAssessment,
      reasons: reasons,
      supportingEvidence: supporting,
      contradictoryEvidence: contradictory,
      riskSignals: riskSignals,
      missingInformation: const [
        'This is a temporary fallback assessment while model adapters are not connected.',
      ],
      recommendedVerification: const [
        'Verify the claim with independent evidence.',
        'Check the source timeline and relationship context.',
        'Request a second witness or document before decision-making.',
      ],
      createdAt: DateTime.now(),
      originalStatement: trustCase.statement,
      originalLanguage: trustCase.caseLanguage,
      errorCodes: const [
        AnalysisErrorCode.modelUnavailable,
        AnalysisErrorCode.analysisFailed,
      ],
      isProvisional: true,
      inputHash: sha256
          .convert(
            utf8.encode(
              jsonEncode({
                'statement': trustCase.statement,
                'evidence': evidence.map((item) => item.toJson()).toList(),
              }),
            ),
          )
          .toString(),
    );
  }
}

class TrustIntelligenceEngine {
  const TrustIntelligenceEngine({this.adapter});

  final TrustModelAdapter? adapter;

  Future<TrustAssessmentResult> analyze(TrustCase trustCase) async {
    final statement = trustCase.statement.trim();
    final evidence = trustCase.evidence
        .where((item) => item.text.trim().isNotEmpty)
        .toList(growable: false);
    final inputHash = sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'statement': trustCase.statement,
              'evidence': evidence.map((item) => item.toJson()).toList(),
            }),
          ),
        )
        .toString();
    final missingInformation = <String>[];
    final errorCodes = <AnalysisErrorCode>[];

    if (statement.isEmpty) {
      errorCodes.add(AnalysisErrorCode.emptyInput);
      missingInformation.add('A statement is required for analysis.');
    }
    if (evidence.isEmpty) {
      errorCodes.add(AnalysisErrorCode.evidenceNotFound);
      missingInformation.add('No evidence has been attached to this case.');
    }
    if (adapter == null) {
      errorCodes.add(AnalysisErrorCode.modelUnavailable);
      missingInformation.add(
        'The analysis model is not configured in this project.',
      );
    }

    if (adapter != null && statement.isNotEmpty && evidence.isNotEmpty) {
      try {
        final result = await adapter!.analyze(trustCase);
        return result.copyWith(
          inputHash: inputHash,
          errorCodes: result.errorCodes.toList()..addAll(errorCodes),
        );
      } on Object {
        return TrustAssessmentResult(
          caseId: trustCase.id,
          verdict: TrustVerdict.inconclusive,
          evidenceStrength: EvidenceStrength.unavailable,
          reasons: const [],
          supportingEvidence: const [],
          contradictoryEvidence: const [],
          riskSignals: const [],
          missingInformation: const ['Analysis could not be completed.'],
          recommendedVerification: const [],
          createdAt: DateTime.now(),
          originalStatement: trustCase.statement,
          originalLanguage: trustCase.caseLanguage,
          errorCodes: const [AnalysisErrorCode.analysisFailed],
          inputHash: inputHash,
        );
      }
    }

    if (statement.isNotEmpty && evidence.isNotEmpty) {
      final fallback = await const TemporaryTrustFallbackAdapter().analyze(
        trustCase,
      );
      return fallback.copyWith(
        inputHash: inputHash,
        errorCodes: [...fallback.errorCodes, ...errorCodes],
      );
    }

    return TrustAssessmentResult(
      caseId: trustCase.id,
      verdict: TrustVerdict.inconclusive,
      evidenceStrength: EvidenceStrength.unavailable,
      reasons: const [],
      supportingEvidence: evidence
          .where((item) => item.relation == EvidenceRelation.supports)
          .map((item) => item.text)
          .toList(growable: false),
      contradictoryEvidence: evidence
          .where((item) => item.relation == EvidenceRelation.contradicts)
          .map((item) => item.text)
          .toList(growable: false),
      riskSignals: const [],
      missingInformation: missingInformation,
      recommendedVerification: const [],
      createdAt: DateTime.now(),
      originalStatement: trustCase.statement,
      originalLanguage: trustCase.caseLanguage,
      errorCodes: errorCodes,
      inputHash: inputHash,
    );
  }
}
