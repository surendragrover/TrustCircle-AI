import 'package:flutter/material.dart';

import '../i18n/translation_dictionary.dart';
import '../models/trust_case.dart';
import '../theme/trustcircle_theme.dart';

class AssessmentScreen extends StatelessWidget {
  const AssessmentScreen({
    required this.trustCase,
    required this.result,
    required this.displayLanguage,
    required this.onRun,
    super.key,
  });

  final TrustCase? trustCase;
  final TrustAssessmentResult? result;
  final String displayLanguage;
  final VoidCallback onRun;

  String _t(String key) =>
      TranslationDictionary.translate(key, displayLanguage);

  @override
  Widget build(BuildContext context) {
    final trustCase = this.trustCase;
    if (trustCase == null) {
      return _empty(
        context,
        'Create a case before running a person-level assessment.',
      );
    }
    final assessment = result?.caseId == trustCase.id ? result : null;
    final verdictLabel = assessment == null
        ? _t('trust.verdict.inconclusive')
        : _t('trust.verdict.${_verdictKey(assessment.verdict)}');
    final verdictColor =
        TrustCircleColors.verdicts[assessment?.verdict.name] ??
        TrustCircleColors.neutral;
    return ListView(
      padding: const EdgeInsets.all(TrustCircleSpacing.lg),
      children: [
        Text(
          _t('analysis.title'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: TrustCircleSpacing.sm),
        Text(
          '${trustCase.id}  •  ${trustCase.personName}  •  ${trustCase.createdAt.toLocal()}',
        ),
        const SizedBox(height: TrustCircleSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(TrustCircleSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('analysis.verdict'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(width: 4, height: 56, color: verdictColor),
                    const SizedBox(width: TrustCircleSpacing.md),
                    Expanded(
                      child: Text(
                        verdictLabel.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: verdictColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TrustCircleSpacing.md),
                if (assessment == null)
                  Text(
                    _t('analysis.unavailable'),
                    style: const TextStyle(
                      color: TrustCircleColors.textSecondary,
                    ),
                  )
                else ...[
                  if (assessment.isProvisional)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _t('analysis.provisional'),
                        style: const TextStyle(
                          color: TrustCircleColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _metric(
                    context,
                    _t('analysis.confidence'),
                    assessment.isProvisional || assessment.confidence == null
                        ? 'Unavailable'
                        : '${assessment.confidence}%',
                  ),
                  _metric(
                    context,
                    _t('analysis.strength'),
                    assessment.evidenceStrength.name,
                  ),
                  _metric(
                    context,
                    _t('analysis.risk'),
                    assessment.riskSignals.isEmpty
                        ? 'Unavailable'
                        : 'Signals recorded',
                  ),
                  _metric(
                    context,
                    _t('analysis.deception'),
                    assessment.deceptionAssessment ?? 'Unavailable',
                  ),
                ],
                const SizedBox(height: TrustCircleSpacing.md),
                FilledButton.icon(
                  onPressed: onRun,
                  icon: const Icon(Icons.analytics_outlined),
                  label: Text(_t('analysis.run')),
                ),
              ],
            ),
          ),
        ),
        Card(
          color: TrustCircleColors.secondarySurface,
          child: Padding(
            padding: const EdgeInsets.all(TrustCircleSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 10),
                Expanded(child: Text(_t('analysis.disclaimer'))),
              ],
            ),
          ),
        ),
        _listSection(
          context,
          _t('analysis.why'),
          assessment?.reasons ?? const [],
        ),
        _listSection(
          context,
          _t('trust.supporting'),
          assessment?.supportingEvidence ?? const [],
        ),
        _listSection(
          context,
          _t('trust.contradictory'),
          assessment?.contradictoryEvidence ?? const [],
        ),
        _listSection(
          context,
          _t('trust.risk'),
          assessment?.riskSignals ?? const [],
        ),
        _listSection(
          context,
          _t('trust.missing'),
          assessment?.missingInformation ??
              const ['Run the assessment to view missing inputs.'],
        ),
        _listSection(
          context,
          _t('verification.title'),
          assessment?.recommendedVerification ?? const [],
        ),
      ],
    );
  }

  String _verdictKey(TrustVerdict verdict) => switch (verdict) {
    TrustVerdict.trustworthy => 'trustworthy',
    TrustVerdict.mostlyTrustworthy => 'mostly_trustworthy',
    TrustVerdict.suspicious => 'suspicious',
    TrustVerdict.notTrustworthy => 'not_trustworthy',
    TrustVerdict.deceptive => 'deceptive',
    TrustVerdict.inconclusive => 'inconclusive',
  };

  Widget _metric(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _listSection(BuildContext context, String title, List<String> items) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(TrustCircleSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (items.isEmpty) const Text('No findings recorded.'),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 7,
                        color: TrustCircleColors.neutral,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _empty(BuildContext context, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
