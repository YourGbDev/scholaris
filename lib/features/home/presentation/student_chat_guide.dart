import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/mascot_pose_view.dart';

// Chat is the other companion: the Home/tour identity stays unchanged.
String chatCompanionName(String? gender) => getMascotName(
  gender: gender?.trim().toLowerCase() == 'female' ? 'male' : 'female',
);

class ChatCompanionArtwork extends StatelessWidget {
  const ChatCompanionArtwork({
    super.key,
    this.gender,
    this.pose = 'welcome',
    this.size = 96,
  });
  final String? gender;
  final String pose;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/mascots/chat/${chatCompanionName(gender).toLowerCase()}_$pose.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: .6,
          child: Image.asset(
            getMascotGreetingAssetPath(
              gender: chatCompanionName(gender) == 'Ari' ? 'female' : 'male',
            ),
            width: size,
            height: size / .6,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
    ),
  );
}

class StudentChatGuide extends StatefulWidget {
  const StudentChatGuide({super.key, this.gender, required this.onFinish});
  final String? gender;
  final VoidCallback onFinish;

  @override
  State<StudentChatGuide> createState() => _StudentChatGuideState();
}

class _StudentChatGuideState extends State<StudentChatGuide> {
  int _step = 0;
  final _scroll = ScrollController();
  void _move(int step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companion = chatCompanionName(widget.gender);
    final guide = getMascotName(gender: widget.gender);
    final titles = [
      'Meet $companion',
      'Find your next opportunity',
      'Tools for your next step',
    ];
    final descriptions = [
      'Hi, I’m $companion! $guide showed you around Scholaris. I’ll show you how chat can help with your next step.',
      'Use Find scholarships to explore Discover and check eligibility, requirements, and deadlines. Scholarship explanations in chat are coming soon.',
      'Scan a Scholaris QR code to open a scholarship. Upload a document to an existing application. These tools are ready to use outside AI chat.',
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              if (_step > 0)
                IconButton(
                  tooltip: 'Previous guide step',
                  onPressed: () => _move(_step - 1),
                  icon: const Icon(Icons.arrow_back_rounded, color: kPrimary),
                ),
              Expanded(
                child: Text(
                  '${_step + 1} of 3',
                  style: geist(fontSize: 13, color: kTextSupporting),
                ),
              ),
              TextButton(
                onPressed: widget.onFinish,
                child: Text(
                  'Skip',
                  style: geist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: index <= _step ? kPrimary : kStudentDivider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChatCompanionArtwork(
                  gender: widget.gender,
                  pose: ['welcome', 'explain', 'tools'][_step],
                  size: 144,
                ),
                const SizedBox(height: 16),
                Text(
                  titles[_step],
                  style: geist(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  descriptions[_step],
                  style: geist(
                    fontSize: 14,
                    height: 1.5,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                if (_step == 1) ...[
                  _example(
                    Icons.search_rounded,
                    'Find scholarships',
                    'Browse opportunities in Discover.',
                  ),
                  _example(
                    Icons.chat_bubble_outline_rounded,
                    'Understand the details',
                    'AI explanations are coming soon. Check each provider’s requirements.',
                  ),
                ],
                if (_step == 2) ...[
                  _example(
                    Icons.qr_code_scanner_rounded,
                    'Scan QR',
                    'Open a scholarship from its Scholaris code.',
                  ),
                  _example(
                    Icons.upload_file_outlined,
                    'Upload document',
                    'Choose an application and attach its required files.',
                  ),
                ],
                if (_step == 0)
                  Text(
                    'AI chat · Coming soon',
                    style: geist(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kTextSupporting,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                minimumSize: const Size(44, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onPressed: _step == 2 ? widget.onFinish : () => _move(_step + 1),
              child: Text(
                _step == 2 ? 'Start chat' : 'Continue',
                style: geist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _example(IconData icon, String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: kPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: geist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kOnSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: geist(fontSize: 13, height: 1.45, color: kTextSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
