import 'package:flutter/material.dart';

import '../i18n/translation_dictionary.dart';
import '../models/trust_case.dart';
import '../theme/trustcircle_theme.dart';

class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({
    required this.trustCase,
    required this.onAdd,
    super.key,
  });

  final TrustCase? trustCase;
  final ValueChanged<EvidenceItem> onAdd;

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final _text = TextEditingController();
  final _source = TextEditingController();
  final _sourceType = TextEditingController(text: 'Document');
  EvidenceRelation _relation = EvidenceRelation.unresolved;

  @override
  void dispose() {
    _text.dispose();
    _source.dispose();
    _sourceType.dispose();
    super.dispose();
  }

  String _t(String key) => TranslationDictionary.translate(
    key,
    Localizations.localeOf(context).languageCode,
  );

  void _submit() {
    if (_text.text.trim().isEmpty ||
        _source.text.trim().isEmpty ||
        widget.trustCase == null) {
      return;
    }
    widget.onAdd(
      EvidenceItem(
        id: '${widget.trustCase!.id}-E${widget.trustCase!.evidence.length + 1}',
        text: _text.text,
        source: _source.text.trim(),
        sourceType: _sourceType.text.trim().isEmpty
            ? 'Unspecified'
            : _sourceType.text.trim(),
        relation: _relation,
        createdAt: DateTime.now(),
      ),
    );
    _text.clear();
    _source.clear();
    setState(() => _relation = EvidenceRelation.unresolved);
  }

  @override
  Widget build(BuildContext context) {
    final trustCase = widget.trustCase;
    return ListView(
      padding: const EdgeInsets.all(TrustCircleSpacing.lg),
      children: [
        Text(
          _t('nav.evidence'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: TrustCircleSpacing.md),
        if (trustCase == null)
          _emptyState(
            _t('evidence.empty'),
            'Create or select a case before adding evidence.',
          )
        else ...[
          Text(
            '${_t('case.id')}: ${trustCase.id}  •  ${trustCase.personName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: TrustCircleSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TrustCircleSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('evidence.add'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: TrustCircleSpacing.md),
                  TextField(
                    controller: _text,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(labelText: _t('evidence.text')),
                  ),
                  const SizedBox(height: TrustCircleSpacing.md),
                  TextField(
                    controller: _source,
                    decoration: InputDecoration(
                      labelText: _t('evidence.source'),
                    ),
                  ),
                  const SizedBox(height: TrustCircleSpacing.md),
                  TextField(
                    controller: _sourceType,
                    decoration: InputDecoration(labelText: _t('evidence.type')),
                  ),
                  const SizedBox(height: TrustCircleSpacing.md),
                  DropdownButtonFormField<EvidenceRelation>(
                    initialValue: _relation,
                    decoration: InputDecoration(
                      labelText: _t('evidence.relation'),
                    ),
                    items: EvidenceRelation.values
                        .map(
                          (relation) => DropdownMenuItem(
                            value: relation,
                            child: Text(_relationLabel(relation)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => _relation = value ?? EvidenceRelation.unresolved,
                    ),
                  ),
                  const SizedBox(height: TrustCircleSpacing.md),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add),
                    label: Text(_t('evidence.add')),
                  ),
                ],
              ),
            ),
          ),
          if (trustCase.evidence.isEmpty)
            _emptyState(_t('evidence.empty'), _t('evidence.emptyHint'))
          else
            ...trustCase.evidence.map(_evidenceCard),
        ],
      ],
    );
  }

  Widget _evidenceCard(EvidenceItem item) {
    final color = switch (item.relation) {
      EvidenceRelation.supports => TrustCircleColors.success,
      EvidenceRelation.contradicts => TrustCircleColors.danger,
      EvidenceRelation.unresolved => TrustCircleColors.neutral,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(TrustCircleSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(_relationLabel(item.relation)),
                  side: BorderSide(color: color),
                ),
                Chip(label: Text(item.sourceType)),
              ],
            ),
            Text(item.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Source: ${item.source}  •  ${item.createdAt.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _relationLabel(EvidenceRelation relation) => switch (relation) {
    EvidenceRelation.supports => _t('evidence.supports'),
    EvidenceRelation.contradicts => _t('evidence.contradicts'),
    EvidenceRelation.unresolved => _t('evidence.unresolved'),
  };

  Widget _emptyState(String title, String subtitle) => Card(
    child: Padding(
      padding: const EdgeInsets.all(TrustCircleSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 32),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
