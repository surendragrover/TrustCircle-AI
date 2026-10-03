import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/trust_case.dart';

class ReportService {
  Future<File> export(
    TrustCase trustCase,
    TrustAssessmentResult? result,
  ) async {
    final reportTimestamp = DateTime.now().toUtc();
    final canonicalContent = [
      trustCase.id,
      trustCase.personName,
      trustCase.statement,
      trustCase.evidence.map((item) => '${item.id}:${item.text}').join('|'),
      result?.verdict.name ?? 'not_run',
      reportTimestamp.toIso8601String(),
    ].join('\n');
    final integrityId = sha256
        .convert(utf8.encode(canonicalContent))
        .toString();
    final report = pw.Document();

    report.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.blueGrey300),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PRIVATE & CONFIDENTIAL',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                ),
              ),
              pw.Text('AUTHORIZED USER ONLY  |  DO NOT DISCLOSE OR DISTRIBUTE'),
            ],
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 18),
          pw.Text(
            'TRUSTCIRCLE AI',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.Text('Catch the Lie. Test the Trust.'),
          pw.SizedBox(height: 18),
          _section('1. CASE INFORMATION', [
            'Case ID: ${trustCase.id}',
            'Case title: ${trustCase.title}',
            'Created: ${trustCase.createdAt.toUtc().toIso8601String()}',
            'Report generated: ${reportTimestamp.toIso8601String()}',
          ]),
          _section('2. PERSON INFORMATION', [
            'Person: ${trustCase.personName}',
            'Alias / identifier: ${trustCase.alias ?? 'Not provided'}',
            'Relationship: ${trustCase.relationship ?? 'Not provided'}',
          ]),
          _section('3. ASSESSMENT PURPOSE', [
            trustCase.purpose ?? 'Not provided',
          ]),
          _section('4. EXECUTIVE PERSON TRUST VERDICT', [
            'Verdict: ${result == null ? 'NOT RUN' : _verdictLabel(result.verdict)}',
            'Assessment confidence: ${result?.isProvisional == true || result?.confidence == null ? 'Unavailable' : '${result!.confidence}%'}',
            if (result?.isProvisional == true)
              'PROVISIONAL HEURISTIC: this is not a verified model assessment; the verdict and evidence strength are not calibrated.',
            'Evidence strength: ${result == null ? 'Unavailable' : result.evidenceStrength.name}',
            if (result?.isProvisional == true)
              'Risk and deception signals are temporary heuristic outputs and are not calibrated.'
            else
              'Model-derived risk and deception assessments are unavailable in this prototype.',
          ]),
          _section('5. CLAIMS ANALYZED', [
            'Original statement (${trustCase.caseLanguage}): ${trustCase.statement}',
            if (trustCase.translatedStatement != null)
              'Translated statement (${trustCase.translationLanguage ?? 'language not set'}): ${trustCase.translatedStatement}',
          ]),
          _section(
            '6. SUPPORTING EVIDENCE',
            _evidenceFor(trustCase, EvidenceRelation.supports),
          ),
          _section(
            '7. CONTRADICTORY EVIDENCE',
            _evidenceFor(trustCase, EvidenceRelation.contradicts),
          ),
          _section('8. NLI ANALYSIS', [
            'Not available: TrustCircle NLI model artifacts are not configured.',
          ]),
          _section('9. RISK ANALYSIS', [
            'Not available: Investigator and TrustCircle risk models are not configured.',
          ]),
          _section('10. MULTIMODAL SIGNALS', [
            'OCR, audio, face and video models are not configured; attachments have not been processed.',
            if (trustCase.attachments.isEmpty)
              'No file attachments recorded.'
            else
              ...trustCase.attachments.map(
                (attachment) =>
                    '${attachment.kind.name}: ${attachment.name} (${attachment.sizeBytes == null ? 'size unavailable' : '${attachment.sizeBytes} bytes'})',
              ),
          ]),
          _section(
            '11. TIMELINE AND CONTRADICTIONS',
            _evidenceFor(trustCase, EvidenceRelation.contradicts),
          ),
          _section(
            '12. MISSING INFORMATION',
            result?.missingInformation.isNotEmpty == true
                ? result!.missingInformation
                : ['No model-derived missing-information analysis is available.'],
          ),
          _section(
            '13. VERIFICATION RECOMMENDATIONS',
            result?.recommendedVerification.isNotEmpty == true
                ? result!.recommendedVerification
                : [
                    'Connect verified model adapters and corroborate evidence with independent sources.',
                  ],
          ),
          _section('14. FINAL PERSON TRUST ASSESSMENT', [
            result == null
                ? 'No assessment was run.'
                : _verdictLabel(result.verdict),
            'This report records inputs and system availability; it does not establish truth, guilt, or deception.',
          ]),
          _section('15. METHODOLOGY AND LIMITATIONS', [
            'Signals are not proof. Patterns are not verdicts. Risk is not guilt. AI is not a decision maker.',
            'No production model inference, identity verification, external evidence lookup, or translation was performed.',
          ]),
          _section('16. CONFIDENTIALITY AND DATA HANDLING', [
            'This report is intended for authorized users only. Handle and share it only with appropriate consent and authorization.',
            'An NDA does not by itself make an AI assessment legally valid. Follow applicable privacy and legal requirements.',
            'This prototype stores cases in memory for this app session only; it does not provide encrypted persistent storage.',
          ]),
          _section('17. REPORT INTEGRITY', [
            'Content integrity identifier (SHA-256): $integrityId',
          ]),
          _section('18. INPUT AUDIT', [
            'Input/evidence integrity identifier (SHA-256): ${result?.inputHash ?? 'Not available'}',
          ]),
          pw.SizedBox(height: 20),
          pw.Text(
            'Original statement (preserved):',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(trustCase.statement),
          if (trustCase.translatedStatement != null) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Translated text (${trustCase.translationLanguage ?? 'language not set'}):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(trustCase.translatedStatement!),
          ],
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${trustCase.id}_trust_report.pdf');
    await file.writeAsBytes(await report.save(), flush: true);
    return file;
  }

  pw.Widget _section(String title, List<String> lines) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 14),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 5),
        ...lines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(line),
          ),
        ),
      ],
    ),
  );

  List<String> _evidenceFor(TrustCase trustCase, EvidenceRelation relation) {
    final items = trustCase.evidence.where((item) => item.relation == relation);
    if (items.isEmpty) return ['None recorded.'];
    return items
        .map(
          (item) =>
              '[${item.sourceType}] ${item.text} (Source: ${item.source})',
        )
        .toList();
  }

  String _verdictLabel(TrustVerdict verdict) => switch (verdict) {
    TrustVerdict.trustworthy => 'TRUSTWORTHY',
    TrustVerdict.mostlyTrustworthy => 'MOSTLY TRUSTWORTHY',
    TrustVerdict.suspicious => 'SUSPICIOUS',
    TrustVerdict.notTrustworthy => 'NOT TRUSTWORTHY',
    TrustVerdict.deceptive => 'DECEPTIVE',
    TrustVerdict.inconclusive => 'INCONCLUSIVE',
  };
}
