import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/trust_case.dart';

class CaseAuditEvent {
  const CaseAuditEvent({
    required this.caseId,
    required this.action,
    required this.timestamp,
    required this.inputSummary,
    required this.inputHash,
  });

  final String caseId;
  final String action;
  final DateTime timestamp;
  final String inputSummary;
  final String inputHash;
}

class LocalCaseRepository {
  final Map<String, TrustCase> _cases = {};
  final List<CaseAuditEvent> _auditTrail = [];

  List<TrustCase> get cases => List.unmodifiable(_cases.values);
  List<CaseAuditEvent> get auditTrail => List.unmodifiable(_auditTrail);

  TrustCase? getCase(String caseId) => _cases[caseId];

  void saveCase(TrustCase trustCase) {
    _cases[trustCase.id] = trustCase;
    _record(
      trustCase.id,
      'case_saved',
      'statement_length:${trustCase.statement.length}',
      trustCase.statement,
    );
  }

  void addEvidence(String caseId, EvidenceItem evidence) {
    final trustCase = _cases[caseId];
    if (trustCase == null) return;
    _cases[caseId] = trustCase.copyWith(
      evidence: [...trustCase.evidence, evidence],
    );
    _record(caseId, 'evidence_added', evidence.id, evidence.text);
  }

  void addAttachment(String caseId, CaseAttachment attachment) {
    final trustCase = _cases[caseId];
    if (trustCase == null) return;
    _cases[caseId] = trustCase.copyWith(
      attachments: [...trustCase.attachments, attachment],
    );
    _record(caseId, 'attachment_added', attachment.id, attachment.name);
  }

  void removeCase(String caseId) {
    if (_cases.remove(caseId) != null) {
      _record(caseId, 'case_deleted', '');
    }
  }

  void _record(
    String caseId,
    String action,
    String inputSummary, [
    String input = '',
  ]) {
    _auditTrail.add(
      CaseAuditEvent(
        caseId: caseId,
        action: action,
        timestamp: DateTime.now(),
        inputSummary: inputSummary,
        inputHash: sha256.convert(utf8.encode(input)).toString(),
      ),
    );
  }
}
