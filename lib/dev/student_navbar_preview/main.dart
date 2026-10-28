import 'package:scholaris/features/home/presentation/widgets/student_tab_entrance.dart';
// lib/dev/student_navbar_preview/main.dart
//
// Standalone, isolated, local-only student navbar visual preview fixture.
// Renders actual StudentBottomNav over realistic, busy, scrolling content.
// Zero Supabase initialization, zero network requests, zero auth dependencies.
//
// Controls:
// - Viewport width: 320px, 360px, 440px
// - Dynamic Type scale: 1.0x, 2.0x, 3.0x (genuine TextScaler)
// - High-contrast mode: On / Off (solid opaque container fallback)
// - Reduced-motion mode: On / Off (static glass, scale = 1.0)

import 'package:flutter/material.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/home/presentation/widgets/student_action_sheet.dart';

void main() {
  runApp(const StudentNavbarPreviewApp());
}

class StudentNavbarPreviewApp extends StatelessWidget {
  const StudentNavbarPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scholaris Student Navbar Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Outfit',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1E242B), // Dark outer preview canvas
      ),
      home: const StudentNavbarPreviewScreen(),
    );
  }
}

class StudentNavbarPreviewScreen extends StatefulWidget {
  const StudentNavbarPreviewScreen({super.key});

  @override
  State<StudentNavbarPreviewScreen> createState() => _StudentNavbarPreviewScreenState();
}

class _StudentNavbarPreviewScreenState extends State<StudentNavbarPreviewScreen> {
  double _selectedWidth = 360.0;
  double _textScaleFactor = 1.0;
  bool _isHighContrast = false;
  bool _isReducedMotion = false;
  bool _isPaleBackground = false;
  bool _isVibrantBands = false;
  double? _dockBlur;
  double? _dockTintOpacity;
  String _selectedVariant = '1';
  late final StudentScrollDockController _scrollDockController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollDockController = StudentScrollDockController();
    _scrollDockController.addListener(_onDockStateChanged);

    final params = Uri.base.queryParameters;
    if (params.containsKey('width')) {
      final w = double.tryParse(params['width']!);
      if (w != null && [320.0, 360.0, 440.0].contains(w)) {
        _selectedWidth = w;
      }
    }
    if (params.containsKey('scale')) {
      final s = double.tryParse(params['scale']!);
      if (s != null && [1.0, 2.0, 3.0].contains(s)) {
        _textScaleFactor = s;
      }
    }
    if (params.containsKey('highContrast')) {
      _isHighContrast = params['highContrast'] == 'true';
    }
    if (params.containsKey('reducedMotion')) {
      _isReducedMotion = params['reducedMotion'] == 'true';
    }
    if (params.containsKey('bg') || params.containsKey('background')) {
      _isPaleBackground = (params['bg'] ?? params['background']) == 'pale';
    }
    if (params.containsKey('bands') || params.containsKey('vibrant')) {
      _isVibrantBands = (params['bands'] ?? params['vibrant']) == 'true';
    }
    if (params.containsKey('variant')) {
      _selectedVariant = params['variant']!;
      if (_selectedVariant == '1') {
        _dockBlur = 2.5;
        _dockTintOpacity = 0.08;
      } else if (_selectedVariant == '2') {
        _dockBlur = 0.0;
        _dockTintOpacity = 0.08;
      } else if (_selectedVariant == '3') {
        _dockBlur = 0.0;
        _dockTintOpacity = 0.14;
      } else if (_selectedVariant == '3b') {
        _dockBlur = 0.5;
        _dockTintOpacity = 0.14;
      }
    }
    if (params.containsKey('blur')) {
      _dockBlur = double.tryParse(params['blur']!);
    }
    if (params.containsKey('tint')) {
      _dockTintOpacity = double.tryParse(params['tint']!);
    }
    if (params.containsKey('collapsed') && params['collapsed'] == 'true') {
      _scrollDockController.collapse();
    }
  }

  @override
  void dispose() {
    _scrollDockController.removeListener(_onDockStateChanged);
    _scrollDockController.dispose();
    super.dispose();
  }

  void _onDockStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161C24),
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Toolbar
            _buildControlsBar(),
            const Divider(color: Color(0xFF2B3440), height: 1),

            // Device Preview Canvas Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: _buildDeviceFrame(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsBar() {
    return Container(
      color: const Color(0xFF1F2633),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          // Viewport width selector
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Width: ', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 320.0, label: Text('320px')),
                  ButtonSegment(value: 360.0, label: Text('360px')),
                  ButtonSegment(value: 440.0, label: Text('440px')),
                ],
                selected: {_selectedWidth},
                onSelectionChanged: (set) => setState(() => _selectedWidth = set.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFF161C24),
                  selectedBackgroundColor: const Color(0xFF0F4D2E),
                  selectedForegroundColor: Colors.white,
                  foregroundColor: Colors.white70,
                ),
              ),
            ],
          ),

          // Material Variant selector (Tarsi glass comparison)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Glass Material: ', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '1', label: Text('V1: 2.5 blur / 8%')),
                  ButtonSegment(value: '2', label: Text('V2: 0 blur / 8%')),
                  ButtonSegment(value: '3', label: Text('V3: 0 blur / 14% veil')),
                  ButtonSegment(value: '3b', label: Text('V3b: 0.5 blur / 14% veil')),
                ],
                selected: {_selectedVariant},
                onSelectionChanged: (set) => setState(() {
                  _selectedVariant = set.first;
                  if (_selectedVariant == '1') {
                    _dockBlur = 2.5;
                    _dockTintOpacity = 0.08;
                  } else if (_selectedVariant == '2') {
                    _dockBlur = 0.0;
                    _dockTintOpacity = 0.08;
                  } else if (_selectedVariant == '3') {
                    _dockBlur = 0.0;
                    _dockTintOpacity = 0.14;
                  } else if (_selectedVariant == '3b') {
                    _dockBlur = 0.5;
                    _dockTintOpacity = 0.14;
                  }
                }),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFF161C24),
                  selectedBackgroundColor: const Color(0xFF0F4D2E),
                  selectedForegroundColor: Colors.white,
                  foregroundColor: Colors.white70,
                ),
              ),
            ],
            ),
          ),

          // Dynamic Type scale selector
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Text Scale: ', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 1.0, label: Text('1.0x')),
                  ButtonSegment(value: 2.0, label: Text('2.0x')),
                  ButtonSegment(value: 3.0, label: Text('3.0x')),
                ],
                selected: {_textScaleFactor},
                onSelectionChanged: (set) => setState(() => _textScaleFactor = set.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFF161C24),
                  selectedBackgroundColor: const Color(0xFF0F4D2E),
                  selectedForegroundColor: Colors.white,
                  foregroundColor: Colors.white70,
                ),
              ),
            ],
          ),

          // High Contrast Toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('High Contrast: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Switch(
                value: _isHighContrast,
                onChanged: (val) => setState(() => _isHighContrast = val),
                activeThumbColor: const Color(0xFF28C76F),
                activeTrackColor: const Color(0xFF0F4D2E),
              ),
            ],
          ),

          // Reduced Motion Toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reduced Motion: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Switch(
                value: _isReducedMotion,
                onChanged: (val) => setState(() => _isReducedMotion = val),
                activeThumbColor: const Color(0xFF28C76F),
                activeTrackColor: const Color(0xFF0F4D2E),
              ),
            ],
          ),

          // Pale Background Toggle (compare glass against pale surface vs busy cards)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pale BG: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Switch(
                value: _isPaleBackground,
                onChanged: (val) => setState(() => _isPaleBackground = val),
                activeThumbColor: const Color(0xFF28C76F),
                activeTrackColor: const Color(0xFF0F4D2E),
              ),
            ],
          ),

          // Vibrant Background Bands Toggle (compare transmission over vivid hues)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vibrant Bands: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Switch(
                key: const ValueKey('preview-vibrant-bands-switch'),
                value: _isVibrantBands,
                onChanged: (val) => setState(() => _isVibrantBands = val),
                activeThumbColor: const Color(0xFF28C76F),
                activeTrackColor: const Color(0xFF0F4D2E),
              ),
            ],
          ),

          // Collapsed Dock Toggle (manual control or scroll-triggered)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Collapsed: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Switch(
                key: const ValueKey('preview-collapsed-switch'),
                value: _scrollDockController.isCollapsed,
                onChanged: (val) {
                  _scrollDockController.setCollapsedManually(val);
                },
                activeThumbColor: const Color(0xFF28C76F),
                activeTrackColor: const Color(0xFF0F4D2E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _handlePreviewScrollNotification(ScrollNotification notification) {
    return _scrollDockController.handleScrollNotification(notification);
  }

  Widget _buildDeviceFrame() {
    const deviceHeight = 780.0;

    return Container(
      width: _selectedWidth,
      height: deviceHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFF4A5568), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(_selectedWidth, deviceHeight),
          textScaler: TextScaler.linear(_textScaleFactor),
          highContrast: _isHighContrast,
          disableAnimations: _isReducedMotion,
          padding: const EdgeInsets.only(top: 36, bottom: 20),
        ),
        child: Scaffold(
          extendBody: true,
          backgroundColor: _isPaleBackground ? const Color(0xFFFAF9F6) : const Color(0xFFF5F7F5),
          body: Stack(
            children: [
              // 1. Content layer (Busy colorful cards OR Pale surface)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final clearance = computeStudentContentClearance(context);
                    final Widget contentList;
                    if (_isVibrantBands) {
                      contentList = ListView(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, clearance),
                        children: [
                          StudentTabReveal(order: 0, child: _buildVibrantBandsHeader()),
                          const SizedBox(height: 16),
                          _buildVibrantBackgroundBands(),
                        ],
                      );
                    } else if (_isPaleBackground) {
                      contentList = ListView(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, clearance),
                        children: [
                          StudentTabReveal(order: 0, child: _buildPaleContentHeader()),
                          const SizedBox(height: 16),
                          _buildPaleContentBody(),
                          const SizedBox(height: 16),
                          for (int i = 5; i <= 20; i++) ...[
                            StudentTabReveal(order: 3, child: _buildScholarshipCard(
                              title: 'Official Academic Document #$i — Clearance Verification',
                              provider: 'Commission on Higher Education / State Universities',
                              matchScore: 'Verified',
                              amount: 'Requirement Complete',
                              deadline: 'Semester Validated',
                              badgeColor: const Color(0xFF1B6C42),
                              tag: 'Academic Archive',
                            )),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    } else {
                      contentList = ListView(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, clearance),
                        children: [
                          StudentTabReveal(order: 0, child: _buildFictionalHeader()),
                          const SizedBox(height: 16),
                          _buildFilterChips(),
                          const SizedBox(height: 16),
                          _buildVibrantBackgroundBands(),
                          const SizedBox(height: 16),
                          StudentTabReveal(order: 4, child: _buildScholarshipCard(
                            title: 'DOST-SEI Undergraduate Merit Scholarship',
                            provider: 'Department of Science and Technology',
                            matchScore: '98%',
                            amount: '₱85,000 / sem',
                            deadline: 'Nov 15, 2026',
                            badgeColor: const Color(0xFF0F4D2E),
                            tag: 'STEM Priority',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 5, child: _buildScholarshipCard(
                            title: 'CHED Tulong Dunong Tertiary Grant',
                            provider: 'Commission on Higher Education',
                            matchScore: '94%',
                            amount: '₱40,000 / year',
                            deadline: 'Dec 01, 2026',
                            badgeColor: const Color(0xFF1B6C42),
                            tag: 'State Grant',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 6, child: _buildScholarshipCard(
                            title: 'SM Foundation College Scholarship Program',
                            provider: 'SM Foundation Inc.',
                            matchScore: '91%',
                            amount: 'Full Tuition + ₱5k/mo',
                            deadline: 'Dec 15, 2026',
                            badgeColor: const Color(0xFFB45309),
                            tag: 'Corporate Foundation',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 7, child: _buildScholarshipCard(
                            title: 'Gokongwei Brothers STEM College Fellowship',
                            provider: 'GBF Philippine Education',
                            matchScore: '89%',
                            amount: '₱120,000 / year',
                            deadline: 'Jan 10, 2027',
                            badgeColor: const Color(0xFF2563EB),
                            tag: 'Engineering / IT',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 8, child: _buildScholarshipCard(
                            title: 'Metrobank Foundation EXCEL Grant',
                            provider: 'Metrobank Foundation',
                            matchScore: '86%',
                            amount: '₱60,000 / sem',
                            deadline: 'Jan 20, 2027',
                            badgeColor: const Color(0xFF7C3AED),
                            tag: 'Academic Excellence',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 9, child: _buildScholarshipCard(
                            title: 'Ayala Foundation Lead Program',
                            provider: 'Ayala Foundation Inc.',
                            matchScore: '85%',
                            amount: '₱75,000 / year',
                            deadline: 'Feb 05, 2027',
                            badgeColor: const Color(0xFFDC2626),
                            tag: 'Leadership',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 10, child: _buildScholarshipCard(
                            title: 'Security Bank Educational Assistance Program',
                            provider: 'Security Bank Foundation',
                            matchScore: '83%',
                            amount: '₱50,000 / sem',
                            deadline: 'Feb 15, 2027',
                            badgeColor: const Color(0xFF0F4D2E),
                            tag: 'Financial Aid',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 11, child: _buildScholarshipCard(
                            title: 'Megaworld Foundation Academic Scholarship',
                            provider: 'Megaworld Foundation',
                            matchScore: '82%',
                            amount: 'Full Tuition + Book Allowance',
                            deadline: 'Mar 01, 2027',
                            badgeColor: const Color(0xFFD97706),
                            tag: 'Real Estate / Architecture',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 12, child: _buildScholarshipCard(
                            title: 'Aboitiz College Scholarship Program',
                            provider: 'Aboitiz Foundation',
                            matchScore: '80%',
                            amount: '₱65,000 / sem',
                            deadline: 'Mar 15, 2027',
                            badgeColor: const Color(0xFF0284C7),
                            tag: 'STEM & Commerce',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 13, child: _buildScholarshipCard(
                            title: 'Jollibee Group Foundation HOPE Scholarship',
                            provider: 'Jollibee Group Foundation',
                            matchScore: '79%',
                            amount: '₱45,000 / sem',
                            deadline: 'Mar 30, 2027',
                            badgeColor: const Color(0xFFB91C1C),
                            tag: 'Culinary & Agri',
                          )),
                          const SizedBox(height: 12),
                          StudentTabReveal(order: 14, child: _buildScholarshipCard(
                            title: 'BDO Foundation College Assistance',
                            provider: 'BDO Foundation',
                            matchScore: '78%',
                            amount: '₱55,000 / year',
                            deadline: 'Apr 10, 2027',
                            badgeColor: const Color(0xFF1E40AF),
                            tag: 'Business & Finance',
                          )),
                        ],
                      );
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: _handlePreviewScrollNotification,
                      child: StudentTabEntrance(active: true, visit: _currentTabIndex, child: contentList),
                    );
                  },
                ),
              ),

              // 2. Actual Floating Student Bottom Navigation Component
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: StudentBottomNav(
                  enableRefraction: Uri.base.queryParameters['refraction'] == 'true',
                  tabIndex: _currentTabIndex,
                  dockBlur: _dockBlur,
                  dockTintOpacity: _dockTintOpacity,
                  onSelectTab: (index) {
                    setState(() => _currentTabIndex = index);
                    _scrollDockController.onTabChanged();
                  },
                  onQuickAction: () {
                    _scrollDockController.expand();
                    showStudentActionSheet(context);
                  },
                  isCollapsed: _scrollDockController.effectiveCollapsed,
                  onExpand: _scrollDockController.expand,
                  onNavFocusChange: _scrollDockController.setNavFocused,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFictionalHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4D2E), Color(0xFF1B6C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F4D2E),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF3E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active Matches',
                  style: TextStyle(
                    color: Color(0xFF0F4D2E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Explore 24 Matching Opportunities',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Curated for undergraduate STEM & academic scholars in Metro Manila.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = ['All (24)', 'STEM (14)', 'Tuition Free (8)', 'National (6)'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final label in chips)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: label.startsWith('All') ? const Color(0xFF0F4D2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: label.startsWith('All') ? Colors.white : const Color(0xFF2D3748),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScholarshipCard({
    required String title,
    required String provider,
    required String matchScore,
    required String amount,
    required String deadline,
    required Color badgeColor,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF3E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF0F4D2E)),
                    const SizedBox(width: 2),
                    Text(
                      matchScore,
                      style: const TextStyle(
                        color: Color(0xFF0F4D2E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF718096)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF0F4D2E)),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      amount,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F4D2E),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_outlined, size: 15, color: Color(0xFF718096)),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      'Due $deadline',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF718096)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaleContentHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Academic Documents & Requirements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pale background test surface: verify translucent dock color transmission, fine illuminated edge, and high-contrast text legibility.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF718096),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaleContentBody() {
    return Column(
      children: List.generate(4, (index) {
        return StudentTabReveal(order: 3 + index, child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined, size: 20, color: Color(0xFF4A5568)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official Document #${index + 1} — Verification Form',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Submitted on Oct 26, 2026 • Verified',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFFA0AEC0)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      }),
    );
  }

  Widget _buildVibrantBandsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Vibrant Multi-Spectrum Transmission Test',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Compare the floating navigation over bright and dark colors. Inspect background transmission, the fine rim, selection clarity, and labels while scrolling.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFFC7D2FE),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibrantBackgroundBands() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentTabReveal(order: 2, child: _buildVibrantBand(
          title: 'Cobalt & Electric Cyan Spectrum',
          subtitle: 'Compare color transmission over deep blue and cyan',
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        )),
        const SizedBox(height: 12),
        StudentTabReveal(order: 3, child: _buildVibrantBand(
          title: 'Scholaris Emerald & Vivid Mint',
          subtitle: 'Compare Scholaris green foreground against the moving backdrop',
          gradient: const LinearGradient(
            colors: [Color(0xFF0F4D2E), Color(0xFF10B981)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        )),
        const SizedBox(height: 12),
        StudentTabReveal(order: 4, child: _buildVibrantBand(
          title: 'Sunset Crimson & Electric Violet',
          subtitle: 'Validates warm-tone diffusion without milky white desaturation',
          gradient: const LinearGradient(
            colors: [Color(0xFFE11D48), Color(0xFF7C3AED)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        )),
        const SizedBox(height: 12),
        StudentTabReveal(order: 5, child: _buildVibrantBand(
          title: 'Golden Amber & Radiant Tangerine',
          subtitle: 'Validates specular top-left highlight against high-luminance background',
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        )),
        const SizedBox(height: 12),
        StudentTabReveal(order: 6, child: _buildVibrantBand(
          title: 'Neon Fuchsia & Deep Ultraviolet',
          subtitle: 'Validates subtle ambient occlusion depth shadow over vivid tones',
          gradient: const LinearGradient(
            colors: [Color(0xFFC026D3), Color(0xFF4F46E5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        )),
      ],
    );
  }

  Widget _buildVibrantBand({
    required String title,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 144),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xEEFFFFFF),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
