import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../i18n/translation_dictionary.dart';
import '../models/trust_case.dart';
import '../screens/assessment_screen.dart';
import '../screens/case_intake_screen.dart';
import '../screens/evidence_screen.dart';
import '../screens/home_screen.dart';
import '../screens/support_screen.dart';
import '../services/local_case_repository.dart';
import '../services/report_service.dart';
import '../services/trust_intelligence_engine.dart';
import '../theme/trustcircle_theme.dart';

class TrustCircleApp extends StatefulWidget {
  const TrustCircleApp({super.key});

  @override
  State<TrustCircleApp> createState() => _TrustCircleAppState();
}

class _TrustCircleAppState extends State<TrustCircleApp> {
  static const _demoEmail = 'admin@trustcircle.ai';
  static const _demoPassword = 'TrustCircle@123';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _workspaceScaffoldKey = GlobalKey<ScaffoldState>();
  final _repository = LocalCaseRepository();
  final _engine = const TrustIntelligenceEngine(
    adapter: TemporaryTrustFallbackAdapter(),
  );
  final _reportService = ReportService();

  String _language = 'en';
  String _page = 'nav.home';
  String? _activeCaseId;
  String _selectedPlan = 'freemium';
  bool _loggedIn = false;
  bool _showPlans = false;
  bool _showPricing = false;
  bool _isAnalyzing = false;
  TrustAssessmentResult? _assessment;

  static const _destinations = <({String group, String key, IconData icon})>[
    (group: 'HOME', key: 'nav.home', icon: Icons.home_outlined),
    (
      group: 'CASE MANAGEMENT',
      key: 'nav.newCase',
      icon: Icons.create_new_folder_outlined,
    ),
    (group: 'CASE MANAGEMENT', key: 'nav.person', icon: Icons.person_outline),
    (group: 'CASE MANAGEMENT', key: 'nav.history', icon: Icons.history),
    (group: 'ANALYSIS', key: 'nav.claims', icon: Icons.short_text),
    (group: 'ANALYSIS', key: 'nav.evidence', icon: Icons.fact_check_outlined),
    (group: 'ANALYSIS', key: 'nav.documents', icon: Icons.description_outlined),
    (group: 'ANALYSIS', key: 'nav.text', icon: Icons.notes_outlined),
    (group: 'ANALYSIS', key: 'nav.audio', icon: Icons.graphic_eq),
    (group: 'ANALYSIS', key: 'nav.image', icon: Icons.face_outlined),
    (group: 'ANALYSIS', key: 'nav.ocr', icon: Icons.document_scanner_outlined),
    (group: 'ANALYSIS', key: 'nav.analysis', icon: Icons.analytics_outlined),
    (group: 'ANALYSIS', key: 'nav.verify', icon: Icons.fact_check),
    (group: 'ANALYSIS', key: 'nav.timeline', icon: Icons.timeline),
    (
      group: 'REPORTING',
      key: 'nav.report',
      icon: Icons.picture_as_pdf_outlined,
    ),
    (group: 'SYSTEM', key: 'nav.settings', icon: Icons.settings_outlined),
    (group: 'SYSTEM', key: 'nav.faq', icon: Icons.help_outline),
    (group: 'SYSTEM', key: 'nav.terms', icon: Icons.gavel_outlined),
    (group: 'SYSTEM', key: 'nav.privacy', icon: Icons.privacy_tip_outlined),
    (group: 'SYSTEM', key: 'nav.about', icon: Icons.info_outline),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _t(String key) => TranslationDictionary.translate(key, _language);
  List<TrustCase> get _cases => _repository.cases;
  TrustCase? get _activeCase =>
      _activeCaseId == null ? null : _repository.getCase(_activeCaseId!);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustCircle AI',
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: TrustCircleTheme.light,
      locale: Locale(_language),
      supportedLocales: TranslationDictionary.languages.map(
        (language) => Locale(language.code),
      ),
      home: !_loggedIn
          ? _loginScreen()
          : _showPlans
          ? _planScreen()
          : _showPricing
          ? _pricingScreen()
          : _workspace(),
    );
  }

  Widget _loginScreen() => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: TrustCircleColors.trustNavy,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t('app.title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: TrustCircleColors.trustNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _t('login.title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _languageSelector(dark: false),
                  const SizedBox(height: 8),
                  _DemoNotice(
                    email: _demoEmail,
                    password: _demoPassword,
                    label: _t('login.demo'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('login_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: _t('login.email')),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('login_password_field'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _t('login.password'),
                    ),
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _handleLogin,
                      child: Text(_t('login.enter')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _planScreen() => Scaffold(
    appBar: AppBar(
      title: Text(_t('plan.title')),
      actions: [_languageSelector(dark: true), const SizedBox(width: 12)],
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Text(_t('plan.subtitle')),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _PlanOption(
                    title: _t('plan.free'),
                    features: const [
                      'Basic case review',
                      '1 PDF export per report',
                      'Core trust insights',
                    ],
                    buttonLabel: _t('plan.freeButton'),
                    onSelect: () => _selectPlan('freemium'),
                  ),
                  _PlanOption(
                    title: _t('plan.paid'),
                    features: const [
                      'Unlimited PDF exports',
                      'Advanced knowledge graph',
                      'Priority verification actions',
                    ],
                    buttonLabel: _t('plan.paidButton'),
                    onSelect: () => _selectPlan('paid'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(_t('plan.note')),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _pricingScreen() => Scaffold(
    appBar: AppBar(
      title: Text('Pricing & access'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => setState(() => _showPricing = false),
      ),
    ),
    body: Center(child: Text(_t('plan.note'))),
  );

  void _handleLogin() {
    if (_emailController.text.trim().toLowerCase() == _demoEmail &&
        _passwordController.text == _demoPassword) {
      setState(() {
        _loggedIn = true;
        _showPlans = true;
      });
    } else {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(_t('login.invalid'))),
      );
    }
  }

  void _selectPlan(String plan) {
    setState(() {
      _selectedPlan = plan;
      _showPlans = false;
      _page = 'nav.home';
    });
  }

  void _setPage(String page) {
    setState(() {
      _page = page;
      _showPricing = false;
    });
    _workspaceScaffoldKey.currentState?.closeDrawer();
  }

  void _createCase(TrustCase trustCase) {
    setState(() {
      _repository.saveCase(trustCase);
      _activeCaseId = trustCase.id;
      _assessment = null;
      _page = 'nav.evidence';
    });
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(_t('case.created'))),
    );
  }

  void _addEvidence(EvidenceItem evidence) {
    final caseId = _activeCaseId;
    if (caseId == null) return;
    setState(() {
      _repository.addEvidence(caseId, evidence);
      _assessment = null;
    });
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(_t('evidence.saved'))),
    );
  }

  void _addAttachment(CaseAttachment attachment) {
    final caseId = _activeCaseId;
    if (caseId == null) return;
    setState(() {
      _repository.addAttachment(caseId, attachment);
      _assessment = null;
    });
  }

  Future<void> _runAssessment() async {
    final trustCase = _activeCase;
    if (trustCase == null || _isAnalyzing) return;
    setState(() => _isAnalyzing = true);
    final result = await _engine.analyze(trustCase);
    if (!mounted) return;
    setState(() {
      _assessment = result;
      _isAnalyzing = false;
    });
  }

  Future<void> _exportReport() async {
    final trustCase = _activeCase;
    if (trustCase == null) return;
    try {
      final file = await _reportService.export(trustCase, _assessment);
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('${_t('report.exported')}${file.path}')),
      );
      await OpenFile.open(file.path);
    } on Object {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Unable to generate the report.')),
      );
    }
  }

  Future<void> _deleteActiveCase() async {
    final trustCase = _activeCase;
    if (trustCase == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('common.delete')),
        content: Text('${trustCase.id}  •  ${trustCase.personName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_t('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _repository.removeCase(trustCase.id);
      _activeCaseId = null;
      _assessment = null;
      _page = 'nav.home';
    });
  }

  Widget _workspace() {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final currentCase = _activeCase;
    return Scaffold(
      key: _workspaceScaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.verified_user_outlined),
            const SizedBox(width: 8),
            Flexible(
              child: Text(_t('app.title'), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        leading: isWide ? const SizedBox.shrink() : null,
        actions: [
          if (width >= 480)
            IconButton(
              tooltip: 'Pricing & access',
              onPressed: () => setState(() => _showPricing = true),
              icon: const Icon(Icons.workspace_premium_outlined),
            ),
          if (currentCase != null)
            IconButton(
              tooltip: _t('common.delete'),
              onPressed: _deleteActiveCase,
              icon: const Icon(Icons.delete_outline),
            ),
          _languageSelector(dark: true),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWide ? null : Drawer(child: SafeArea(child: _navigationMenu())),
      body: Row(
        children: [
          if (isWide) SizedBox(width: 248, child: _navigationMenu()),
          Expanded(child: _pageBody()),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _mobileIndex,
              onDestinationSelected: (index) => _setPage(
                [
                  'nav.home',
                  'nav.newCase',
                  'nav.evidence',
                  'nav.verify',
                ][index],
              ),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  label: _t('nav.home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: _t('nav.newCase'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: _t('nav.evidence'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.verified_outlined),
                  label: 'Verify',
                ),
              ],
            ),
    );
  }

  int get _mobileIndex => switch (_page) {
    'nav.newCase' => 1,
    'nav.evidence' => 2,
    'nav.verify' => 3,
    _ => 0,
  };

  Widget _navigationMenu() {
    String? lastGroup;
    final navigationItems = <Widget>[];
    for (final destination in _destinations) {
      if (lastGroup != destination.group) {
        navigationItems.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
            child: Text(
              destination.group,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TrustCircleColors.textSecondary,
              ),
            ),
          ),
        );
        lastGroup = destination.group;
      }
      navigationItems.add(
        ListTile(
          selected: _page == destination.key,
          selectedTileColor: TrustCircleColors.trustBlue,
          selectedColor: Colors.white,
          leading: Icon(destination.icon, size: 20),
          title: Text(
            _t(destination.key),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          dense: true,
          onTap: () => _setPage(destination.key),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(
            'PRIVATE WORKSPACE',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        ...navigationItems,
        const Divider(),
        ListTile(
          leading: const Icon(Icons.workspace_premium_outlined),
          title: Text(
            _selectedPlan == 'paid' ? _t('plan.paid') : _t('plan.free'),
          ),
          dense: true,
        ),
      ],
    );
  }

  Widget _pageBody() => switch (_page) {
    'nav.home' => HomeScreen(
      cases: _cases,
      displayLanguage: _language,
      onNewCase: () => _setPage('nav.newCase'),
      onOpenCase: _selectCase,
    ),
    'nav.newCase' => CaseIntakeScreen(
      displayLanguage: _language,
      onCreate: _createCase,
    ),
    'nav.evidence' => EvidenceScreen(
      trustCase: _activeCase,
      onAdd: _addEvidence,
    ),
    'nav.analysis' => AssessmentScreen(
      trustCase: _activeCase,
      result: _assessment,
      displayLanguage: _language,
      onRun: _runAssessment,
    ),
    _ => SupportScreen(
      destination: _page,
      trustCase: _activeCase,
      cases: _cases,
      auditTrail: _repository.auditTrail,
      displayLanguage: _language,
      onOpenNewCase: () => _setPage('nav.newCase'),
      onExportReport: _exportReport,
      onSelectCase: _selectCase,
      onAddAttachment: _addAttachment,
    ),
  };

  void _selectCase(TrustCase trustCase) {
    setState(() {
      _activeCaseId = trustCase.id;
      _assessment = null;
      _page = 'nav.person';
    });
  }

  Widget _languageSelector({required bool dark}) => DropdownButton<String>(
    value: _language,
    dropdownColor: dark
        ? TrustCircleColors.trustNavy
        : TrustCircleColors.surface,
    underline: const SizedBox.shrink(),
    style: TextStyle(
      color: dark ? Colors.white : TrustCircleColors.textPrimary,
    ),
    items: TranslationDictionary.languages
        .map(
          (language) => DropdownMenuItem(
            value: language.code,
            child: Text(language.nativeLabel),
          ),
        )
        .toList(),
    onChanged: (value) =>
        value == null ? null : setState(() => _language = value),
  );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice({
    required this.email,
    required this.password,
    required this.label,
  });

  final String email;
  final String password;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TrustCircleColors.secondarySurface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        SelectableText(email),
        SelectableText(password),
        const SizedBox(height: 4),
        const Text(
          'This is not production authentication.',
          style: TextStyle(
            color: TrustCircleColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.title,
    required this.features,
    required this.buttonLabel,
    required this.onSelect,
  });

  final String title;
  final List<String> features;
  final String buttonLabel;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSelect,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
