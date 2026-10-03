import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../i18n/translation_dictionary.dart';
import '../models/trust_case.dart';
import '../services/local_case_repository.dart';
import '../theme/trustcircle_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({
    required this.destination,
    required this.trustCase,
    required this.cases,
    required this.auditTrail,
    required this.displayLanguage,
    required this.onOpenNewCase,
    required this.onExportReport,
    required this.onSelectCase,
    required this.onAddAttachment,
    super.key,
  });

  final String destination;
  final TrustCase? trustCase;
  final List<TrustCase> cases;
  final List<CaseAuditEvent> auditTrail;
  final String displayLanguage;
  final VoidCallback onOpenNewCase;
  final VoidCallback onExportReport;
  final ValueChanged<TrustCase> onSelectCase;
  final ValueChanged<CaseAttachment> onAddAttachment;

  String _t(String key) =>
      TranslationDictionary.translate(key, displayLanguage);

  @override
  Widget build(BuildContext context) {
    final title = _t(destination);
    return ListView(
      padding: const EdgeInsets.all(TrustCircleSpacing.lg),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: TrustCircleSpacing.md),
        if (destination == 'nav.person') _person(context),
        if (destination == 'nav.claims') _claims(context),
        if (destination == 'nav.documents' ||
            destination == 'nav.audio' ||
            destination == 'nav.image' ||
            destination == 'nav.ocr')
          _mediaInput(context),
        if (destination == 'nav.text') _textAnalysis(context),
        if (destination == 'nav.verify') _verification(context),
        if (destination == 'nav.timeline') _timeline(context),
        if (destination == 'nav.report') _report(context),
        if (destination == 'nav.history') _history(context),
        if (destination == 'nav.settings') _settings(context),
        if (destination == 'nav.faq') _faq(context),
        if (destination == 'nav.terms') _terms(context),
        if (destination == 'nav.privacy') _privacy(context),
        if (destination == 'nav.about') _about(context),
      ],
    );
  }

  Widget _person(BuildContext context) {
    final item = trustCase;
    if (item == null) {
      return _empty(context, 'Select a case to view its person profile.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(context, 'PERSON', [
          item.personName,
          'Alias: ${item.alias ?? 'Not provided'}',
          'Relationship: ${item.relationship ?? 'Not provided'}',
        ]),
        _card(context, 'CASE', [
          item.id,
          item.title,
          'Language: ${item.caseLanguage}',
        ]),
        _card(context, 'STATEMENT', [item.statement]),
        _card(context, 'RECORDED EVIDENCE', [
          '${item.evidence.length} evidence item(s)',
        ]),
        _card(context, 'ATTACHMENTS', [
          '${item.attachments.length} file(s) attached; none have been processed.',
        ]),
      ],
    );
  }

  Widget _claims(BuildContext context) {
    final item = trustCase;
    if (item == null) {
      return _empty(
        context,
        'Select a case. No claim extraction has been run.',
      );
    }
    return _card(context, 'USER-PROVIDED STATEMENT', [
      item.statement,
      'Automated claim extraction is not configured.',
    ]);
  }

  Widget _mediaInput(BuildContext context) {
    final currentCase = trustCase;
    if (currentCase == null) {
      return _empty(context, 'Create or select a case before attaching files.');
    }
    final available = currentCase.attachments
        .where((attachment) => _matchesDestination(attachment.kind))
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(TrustCircleSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.upload_file_outlined,
                  color: TrustCircleColors.trustBlue,
                ),
                const SizedBox(height: 8),
                Text(
                  _t('media.select'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(_t('media.pending')),
                const SizedBox(height: TrustCircleSpacing.md),
                FilledButton.icon(
                  onPressed: () => _pickFiles(context),
                  icon: const Icon(Icons.attach_file),
                  label: Text(_t('media.choose')),
                ),
              ],
            ),
          ),
        ),
        if (available.isEmpty)
          _empty(context, 'No files attached to this case in this category.')
        else ...[
          Text(
            _t('media.attachments'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...available.map(
            (attachment) => Card(
              child: ListTile(
                leading: Icon(_attachmentIcon(attachment.kind)),
                title: Text(attachment.name),
                subtitle: Text(
                  '${_formatSize(attachment.sizeBytes)} • ${_t('common.unavailable')}',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFiles(BuildContext context) async {
    final currentCase = trustCase;
    if (currentCase == null) return;
    final files = await FilePicker.pickFiles(
      dialogTitle: _t('media.select'),
      type: FileType.custom,
      allowedExtensions: _extensionsForDestination(),
    );
    for (final file in files) {
      final extension = (file.extension ?? file.name.split('.').last)
          .toLowerCase();
      final kind = _kindForExtension(extension);
      onAddAttachment(
        CaseAttachment(
          id: '${currentCase.id}-A${currentCase.attachments.length + 1}',
          name: file.name,
          kind: kind,
          sizeBytes: file.lengthSync(),
          addedAt: DateTime.now(),
          localPath: file.path,
        ),
      );
    }
  }

  List<String> _extensionsForDestination() => switch (destination) {
    'nav.audio' => ['wav', 'mp3', 'm4a', 'aac', 'flac', 'ogg'],
    'nav.image' => ['png', 'jpg', 'jpeg', 'webp', 'mp4', 'mov'],
    'nav.ocr' => ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    _ => ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
  };

  CaseAttachmentKind _kindForExtension(String extension) {
    if (['wav', 'mp3', 'm4a', 'aac', 'flac', 'ogg'].contains(extension)) {
      return CaseAttachmentKind.audio;
    }
    if (['png', 'jpg', 'jpeg', 'webp'].contains(extension)) {
      return CaseAttachmentKind.image;
    }
    if (['mp4', 'mov'].contains(extension)) return CaseAttachmentKind.video;
    if (['pdf', 'doc', 'docx', 'txt'].contains(extension)) {
      return CaseAttachmentKind.document;
    }
    return CaseAttachmentKind.other;
  }

  bool _matchesDestination(CaseAttachmentKind kind) => switch (destination) {
    'nav.audio' => kind == CaseAttachmentKind.audio,
    'nav.image' =>
      kind == CaseAttachmentKind.image || kind == CaseAttachmentKind.video,
    'nav.ocr' || 'nav.documents' =>
      kind == CaseAttachmentKind.document || kind == CaseAttachmentKind.image,
    _ => false,
  };

  IconData _attachmentIcon(CaseAttachmentKind kind) => switch (kind) {
    CaseAttachmentKind.document => Icons.description_outlined,
    CaseAttachmentKind.image => Icons.image_outlined,
    CaseAttachmentKind.audio => Icons.audio_file_outlined,
    CaseAttachmentKind.video => Icons.video_file_outlined,
    CaseAttachmentKind.other => Icons.attach_file,
  };

  String _formatSize(int? bytes) => bytes == null
      ? 'Size unavailable'
      : bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  Widget _textAnalysis(BuildContext context) {
    if (trustCase == null) {
      return _empty(context, 'Select a case to review its original text.');
    }
    return _card(context, 'ORIGINAL STATEMENT (${trustCase!.caseLanguage})', [
      trustCase!.statement,
      'No translation or model normalization has been performed.',
    ]);
  }

  Widget _verification(BuildContext context) {
    if (trustCase == null) {
      return _empty(
        context,
        'Create a case before reviewing verification steps.',
      );
    }
    final hasEvidence = trustCase!.evidence.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(context, _t('verification.title'), [
          if (!hasEvidence)
            'Add source-linked evidence for the recorded statement.',
          if (hasEvidence)
            'Review ${trustCase!.evidence.length} recorded evidence item(s) and confirm their sources independently.',
          _t('verification.model'),
        ]),
      ],
    );
  }

  Widget _timeline(BuildContext context) {
    final item = trustCase;
    if (item == null) {
      return _empty(context, 'Select a case to view its timeline.');
    }
    final events = <({DateTime at, String title, String detail})>[
      (at: item.createdAt, title: 'Case created', detail: item.id),
      ...item.evidence.map(
        (evidence) => (
          at: evidence.createdAt,
          title: 'Evidence added',
          detail: evidence.source,
        ),
      ),
      ...item.attachments.map(
        (attachment) => (
          at: attachment.addedAt,
          title: 'File attached',
          detail: attachment.name,
        ),
      ),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return Column(
      children: events
          .map(
            (event) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.circle,
                  color: TrustCircleColors.intelligenceTeal,
                  size: 14,
                ),
                title: Text(event.title),
                subtitle: Text('${event.at.toLocal()}  •  ${event.detail}'),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _report(BuildContext context) {
    if (trustCase == null) return _empty(context, _t('report.unavailable'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(context, 'PRIVATE & CONFIDENTIAL', [
          'AUTHORIZED USER ONLY',
          'DO NOT DISCLOSE OR DISTRIBUTE',
          'Case ${trustCase!.id}  •  ${trustCase!.personName}',
          'The report records only information provided in this session.',
        ]),
        FilledButton.icon(
          onPressed: onExportReport,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(_t('report.export')),
        ),
      ],
    );
  }

  Widget _history(BuildContext context) {
    if (cases.isEmpty && auditTrail.isEmpty) {
      return _empty(context, _t('home.emptyHint'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cases.reversed.map(
          (item) => Card(
            child: ListTile(
              title: Text(item.title),
              subtitle: Text('${item.id} • ${item.personName}'),
              onTap: () => onSelectCase(item),
            ),
          ),
        ),
        if (auditTrail.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'CASE AUDIT TRAIL',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...auditTrail.reversed.map(
            (event) => Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(event.action.replaceAll('_', ' ')),
                subtitle: Text(
                  '${event.caseId} • ${event.timestamp.toLocal()}',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _settings(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _card(context, 'LANGUAGE', [
        TranslationDictionary.languages
            .map((language) => language.nativeLabel)
            .join('  •  '),
      ]),
      _card(context, 'STORAGE AND SECURITY', [
        'Case data is held in memory and removed when the app session ends.',
        'Authentication, encryption at rest, server-side access control and retention controls are not configured.',
      ]),
      _card(context, 'MODEL INFORMATION', [
        _t('common.unavailable'),
        'No model manifest or model binaries were found in this repository.',
      ]),
    ],
  );

  Widget _faq(BuildContext context) {
    const questions = <(String, String)>[
      (
        'What is TrustCircle AI?',
        'A prototype for recording private cases, statements, and evidence. Production model inference is not connected.',
      ),
      (
        'What does “Catch the Lie. Test the Trust.” mean?',
        'It describes an evidence-review workflow, not a guarantee that the app detects lies.',
      ),
      (
        'What is a Trust Verdict?',
        'A human-readable assessment category. It is not proof of truth, intent, guilt, or deception.',
      ),
      (
        'How is a verdict generated?',
        'This repository currently has no model binaries or model service; the app therefore reports an inconclusive result.',
      ),
      (
        'What is NLI?',
        'Natural-language inference compares a claim with evidence as support, neutral, or contradiction. No NLI model is connected here.',
      ),
      (
        'What is risk analysis?',
        'Risk analysis identifies patterns for review; risk is not guilt. No risk model is connected here.',
      ),
      (
        'What is evidence fusion?',
        'It combines evidence and model outputs while preserving provenance. Fusion is not implemented without the required models.',
      ),
      (
        'Can TrustCircle make mistakes?',
        'Yes. AI systems can be incomplete or wrong; independent human verification is essential.',
      ),
      (
        'What does DECEPTIVE or NOT TRUSTWORTHY mean?',
        'These are assessment labels, not findings of criminality or proof that a person lied.',
      ),
      (
        'What does INCONCLUSIVE mean?',
        'The available configured system cannot responsibly generate a supported assessment.',
      ),
      (
        'Does a verdict prove that someone lied?',
        'No. An assessment cannot establish truth, intent, guilt, or deception.',
      ),
      (
        'Why use multiple signals?',
        'Independent evidence can reveal disagreement and limitations. This prototype does not produce model signals.',
      ),
      (
        'What should I verify?',
        'Check the source and context of each evidence item independently. The app does not verify identities or documents.',
      ),
      (
        'Is my report private?',
        'It contains a confidentiality notice, but the prototype has no authentication or access-control service.',
      ),
      (
        'Who can access my case?',
        'Cases stay in process memory on this device during the active session; there are no accounts or server permissions.',
      ),
      (
        'Does an NDA make an assessment legally valid?',
        'No. An NDA does not establish legal validity. Authorization, privacy, and applicable law remain separate.',
      ),
      (
        'Can I share the report?',
        'Share only with appropriate authorization and consent; the report is marked do not disclose or distribute.',
      ),
      (
        'How is data stored and retained?',
        'Case data is held in memory until the app session ends. Exported PDFs remain in the device documents folder.',
      ),
      (
        'Can I delete my data?',
        'The active case can be deleted in the app. Exported PDF files must be deleted separately from the device.',
      ),
      (
        'Which languages are supported?',
        'Controlled verdict terminology covers English, Hindi, Bengali, Marathi, Tamil, Telugu, Gujarati, Kannada, Malayalam, Punjabi, and Urdu. Other interface copy falls back to English.',
      ),
      (
        'How are translations handled?',
        'Critical verdict terms use a controlled dictionary. Statements are preserved and are not automatically translated.',
      ),
      (
        'What if evidence is insufficient or models disagree?',
        'The case remains inconclusive; this app does not have models to compare or resolve disagreement.',
      ),
      (
        'What if audio or image quality is poor?',
        'No audio or image model is connected. This app does not evaluate quality or infer voice/face signals.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions
          .map((item) => _qa(context, item.$1, item.$2))
          .toList(),
    );
  }

  Widget _terms(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _card(context, 'DRAFT TERMS AND CONDITIONS', [
        'Service description: this repository provides a demonstration interface, not a production trust assessment service.',
        'User responsibilities: provide accurate information and source attribution; obtain required authorization and consent before entering another person’s data.',
        'Authorized use and prohibited misuse: do not use the prototype to harass, discriminate, unlawfully surveil, or make consequential decisions about another person.',
        'Evidence responsibility: users are responsible for the legality, authenticity, context, and accuracy of uploaded or recorded evidence.',
        'Model limitations: no NER, NLI, OCR, face, voice, XGBoost, external source, or production verification service is configured.',
        'Confidentiality and reports: reports contain private information and are intended for authorized users. Protect exported copies and share only when permitted.',
        'NDA and legal validity: an NDA does not make an assessment legally valid. This prototype is not legal advice; consult qualified counsel.',
        'Account security: the demo login is not authentication. Do not use it to protect real confidential information.',
        'Intellectual property: product names and user-submitted materials remain subject to their respective rights; no rights are granted beyond evaluation of this prototype.',
        'Availability: no uptime, service-level, or model-availability commitment is provided.',
        'Retention and deletion: cases exist only in app memory; exported reports must be deleted separately by the device owner.',
        'Applicable law and disputes: users are responsible for following applicable legal requirements. No governing-law or dispute terms are established by this prototype.',
      ]),
      Text(_t('legal.notice'), style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _privacy(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _card(context, 'DRAFT PRIVACY NOTICE', [
        'Information collected: person names, aliases, relationships, case purpose, original statements, notes, source-linked evidence, attachment names and local paths, timestamps, and generated PDF report content.',
        'Purpose: data is used only to display and organize the current case, evidence, audit events, and user-requested report in this prototype.',
        'Consent and authorization: do not enter another person’s information unless you have the required authority and consent.',
        'Storage: case records and audit events are held in process memory for the app session. No server or local case database is configured.',
        'Security and access: there is no production authentication, case-level account access control, encryption at rest, or audit server. The demo login is not security.',
        'Uploads: selected file names, sizes, and paths are retained in memory; no file content is processed by a model or transmitted by the current app.',
        'Reports: when requested, PDFs are written to the platform documents folder. They may contain personal information; device users must protect and delete exported copies.',
        'Retention and deletion: in-memory data is discarded when the app session ends. The active case can be deleted in the app; exported reports require separate deletion.',
        'Third parties and international processing: no external evidence API, analytics provider, model host, or third-party processing service is configured.',
        'User rights and contact: this prototype has no account service or privacy-request workflow. No privacy contact channel is configured.',
        'Security incidents: no breach-detection or notification process is implemented for this standalone prototype.',
        'This draft is not legal advice and does not claim regulatory certification or compliance.',
      ]),
    ],
  );

  Widget _about(BuildContext context) => _card(context, 'TRUSTCIRCLE AI', [
    _t('app.tagline'),
    'A private, evidence-centered human decision-support prototype.',
    'Signal is not proof. Pattern is not verdict. Risk is not guilt. AI is not the decision maker.',
  ]);

  Widget _qa(BuildContext context, String question, String answer) => Card(
    child: ExpansionTile(
      title: Text(question),
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(answer)),
      ],
    ),
  );

  Widget _card(BuildContext context, String title, List<String> lines) => Card(
    child: Padding(
      padding: const EdgeInsets.all(TrustCircleSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _empty(BuildContext context, String message) => Card(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}
