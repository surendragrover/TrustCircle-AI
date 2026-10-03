import 'package:flutter/material.dart';

import '../i18n/translation_dictionary.dart';
import '../models/trust_case.dart';
import '../theme/trustcircle_theme.dart';

class CaseIntakeScreen extends StatefulWidget {
  const CaseIntakeScreen({
    required this.displayLanguage,
    required this.onCreate,
    super.key,
  });

  final String displayLanguage;
  final ValueChanged<TrustCase> onCreate;

  @override
  State<CaseIntakeScreen> createState() => _CaseIntakeScreenState();
}

class _CaseIntakeScreenState extends State<CaseIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _person = TextEditingController();
  final _alias = TextEditingController();
  final _relationship = TextEditingController();
  final _title = TextEditingController();
  final _purpose = TextEditingController();
  final _statement = TextEditingController();
  final _notes = TextEditingController();
  String _caseLanguage = 'en';
  String _confidentiality = 'Private';
  bool _authorized = false;
  bool _consent = false;

  @override
  void dispose() {
    _person.dispose();
    _alias.dispose();
    _relationship.dispose();
    _title.dispose();
    _purpose.dispose();
    _statement.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _t(String key) =>
      TranslationDictionary.translate(key, widget.displayLanguage);

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_authorized || !_consent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t('case.required'))));
      return;
    }
    widget.onCreate(
      TrustCase.create(
        title: _title.text.trim(),
        personName: _person.text.trim(),
        statement: _statement.text,
        caseLanguage: _caseLanguage,
        displayLanguage: widget.displayLanguage,
        confidentialityLevel: _confidentiality,
        authorizationConfirmed: _authorized,
        confidentialityConfirmed: _consent,
        alias: _alias.text.trim().isEmpty ? null : _alias.text.trim(),
        relationship: _relationship.text.trim().isEmpty
            ? null
            : _relationship.text.trim(),
        purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
    _formKey.currentState!.reset();
    for (final controller in [
      _person,
      _alias,
      _relationship,
      _title,
      _purpose,
      _statement,
      _notes,
    ]) {
      controller.clear();
    }
    setState(() {
      _authorized = false;
      _consent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TrustCircleSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t('case.title'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: TrustCircleSpacing.md),
              _section('PERSON INFORMATION', [
                _field(_person, _t('case.person'), required: true),
                _field(_alias, _t('case.alias')),
                _field(_relationship, _t('case.relationship')),
              ]),
              _section('CASE INFORMATION', [
                _field(_title, _t('case.caseTitle'), required: true),
                _field(_purpose, _t('case.purpose'), maxLines: 2),
                DropdownButtonFormField<String>(
                  initialValue: _caseLanguage,
                  decoration: InputDecoration(labelText: _t('case.language')),
                  items: TranslationDictionary.languages
                      .map(
                        (language) => DropdownMenuItem(
                          value: language.code,
                          child: Text(language.nativeLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _caseLanguage = value ?? 'en'),
                ),
                const SizedBox(height: TrustCircleSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _confidentiality,
                  decoration: InputDecoration(
                    labelText: _t('case.confidentiality'),
                  ),
                  items: const ['Private', 'Confidential', 'Restricted']
                      .map(
                        (level) =>
                            DropdownMenuItem(value: level, child: Text(level)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _confidentiality = value ?? 'Private'),
                ),
              ]),
              _section('STATEMENT AND NOTES', [
                _field(
                  _statement,
                  _t('case.statement'),
                  required: true,
                  maxLines: 5,
                ),
                _field(_notes, _t('case.notes'), maxLines: 3),
                const Text(
                  'Original text is retained. No automatic translation is performed.',
                  style: TextStyle(color: TrustCircleColors.textSecondary),
                ),
              ]),
              _section('AUTHORIZATION AND CONFIDENTIALITY', [
                CheckboxListTile(
                  key: const ValueKey('authorization_confirmation'),
                  contentPadding: EdgeInsets.zero,
                  value: _authorized,
                  onChanged: (value) =>
                      setState(() => _authorized = value ?? false),
                  title: Text(_t('case.authorization')),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  key: const ValueKey('confidentiality_confirmation'),
                  contentPadding: EdgeInsets.zero,
                  value: _consent,
                  onChanged: (value) =>
                      setState(() => _consent = value ?? false),
                  title: Text(_t('case.consent')),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                Text(
                  _t('legal.notice'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const ValueKey('create_case_button'),
                  onPressed: _submit,
                  icon: const Icon(Icons.folder_special_outlined),
                  label: Text(_t('case.create')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: TrustCircleSpacing.md),
    child: Padding(
      padding: const EdgeInsets.all(TrustCircleSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TrustCircleSpacing.md),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: TrustCircleSpacing.md),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) => TextFormField(
    key: ValueKey('case_field_$label'),
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (value) =>
              value == null || value.trim().isEmpty ? _t('case.required') : null
        : null,
  );
}
