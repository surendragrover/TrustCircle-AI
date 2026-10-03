import 'package:flutter/material.dart';

import '../i18n/translation_dictionary.dart';
import '../models/trust_case.dart';
import '../theme/trustcircle_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.cases,
    required this.displayLanguage,
    required this.onNewCase,
    required this.onOpenCase,
    super.key,
  });

  final List<TrustCase> cases;
  final String displayLanguage;
  final VoidCallback onNewCase;
  final ValueChanged<TrustCase> onOpenCase;

  String _t(String key) =>
      TranslationDictionary.translate(key, displayLanguage);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TrustCircleSpacing.lg),
      children: [
        Card(
          color: TrustCircleColors.trustNavy,
          child: Padding(
            padding: const EdgeInsets.all(TrustCircleSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final identity = Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.white,
                      size: 38,
                    ),
                    const SizedBox(width: TrustCircleSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('home.title'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t('app.tagline'),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final action = FilledButton.icon(
                  onPressed: onNewCase,
                  icon: const Icon(Icons.add),
                  label: Text(_t('home.newCase')),
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      identity,
                      const SizedBox(height: TrustCircleSpacing.md),
                      action,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: identity),
                    action,
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: TrustCircleSpacing.md),
        _PrivacyStrip(displayLanguage: displayLanguage),
        const SizedBox(height: TrustCircleSpacing.lg),
        Text(_t('home.recent'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: TrustCircleSpacing.sm),
        if (cases.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TrustCircleSpacing.xl),
              child: Column(
                children: [
                  const Icon(
                    Icons.folder_open_outlined,
                    size: 36,
                    color: TrustCircleColors.neutral,
                  ),
                  const SizedBox(height: TrustCircleSpacing.sm),
                  Text(
                    _t('home.empty'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: TrustCircleSpacing.xs),
                  Text(_t('home.emptyHint'), textAlign: TextAlign.center),
                  const SizedBox(height: TrustCircleSpacing.md),
                  OutlinedButton.icon(
                    onPressed: onNewCase,
                    icon: const Icon(Icons.add),
                    label: Text(_t('home.newCase')),
                  ),
                ],
              ),
            ),
          )
        else
          ...cases.reversed.map(
            (trustCase) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.folder_outlined,
                  color: TrustCircleColors.trustBlue,
                ),
                title: Text(trustCase.title),
                subtitle: Text(
                  '${trustCase.id}  •  ${trustCase.personName}  •  ${trustCase.createdAt.toLocal()}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenCase(trustCase),
              ),
            ),
          ),
        const SizedBox(height: TrustCircleSpacing.md),
        Text(
          _t('common.sessionOnly'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Text(_t('legal.notice'), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PrivacyStrip extends StatelessWidget {
  const _PrivacyStrip({required this.displayLanguage});

  final String displayLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TrustCircleSpacing.md),
      decoration: BoxDecoration(
        color: TrustCircleColors.secondarySurface,
        border: Border.all(color: TrustCircleColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PrivacyLabel(
            Icons.lock_outline,
            TranslationDictionary.translate('privacy.private', displayLanguage),
          ),
          _PrivacyLabel(
            Icons.person_outline,
            TranslationDictionary.translate(
              'privacy.authorized',
              displayLanguage,
            ),
          ),
          _PrivacyLabel(
            Icons.do_not_disturb_alt_outlined,
            TranslationDictionary.translate(
              'privacy.distribution',
              displayLanguage,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyLabel extends StatelessWidget {
  const _PrivacyLabel(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.max,
    children: [
      Icon(icon, size: 16, color: TrustCircleColors.trustNavy),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          softWrap: true,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    ],
  );
}
