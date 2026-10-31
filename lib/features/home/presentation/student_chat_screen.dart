import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/mascot_pose_view.dart';
import '../../profile/providers/profile_setup_provider.dart';

class StudentChatScreen extends ConsumerWidget {
  const StudentChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final name = profile?.fullName.trim() ?? '';
    final firstName = name.isEmpty ? null : name.split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: kStudentCanvas,
      appBar: AppBar(
        backgroundColor: kStudentCanvas,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: kPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chat',
          style: geist(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: kOnSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Chat help',
            icon: const Icon(Icons.help_outline_rounded, color: kPrimary),
            onPressed: () => _showHelp(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (profile != null) ...[
                              ExcludeSemantics(
                                child: MascotPoseView(
                                  pose: MascotPose.celebrating,
                                  gender: profile.gender,
                                  height: 64,
                                  width: 64,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                firstName == null
                                    ? 'Hi there!'
                                    : 'Hi, $firstName!',
                                style: geist(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'I’m ${getMascotName(gender: profile?.gender)}. A little guidance for your next step.',
                          style: geist(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: kOnSurface,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scholarship chat is coming soon. It will be a place to ask about scholarships and your applications.',
                          style: geist(
                            fontSize: 16,
                            color: kOnSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'AI replies are not connected yet.',
                          style: geist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: kBorderLight),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  minLines: 2,
                                  maxLines:
                                      MediaQuery.viewInsetsOf(context).bottom >
                                          0
                                      ? 2
                                      : 4,
                                  style: geist(
                                    fontSize: 16,
                                    color: kOnSurface,
                                    height: 1.4,
                                  ),
                                  cursorColor: kPrimary,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: 'Write a scholarship question…',
                                    hintStyle: geist(
                                      fontSize: 16,
                                      color: kOnSurfaceVariant,
                                      height: 1.4,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                  ),
                                ),
                              ),
                              const IconButton(
                                tooltip: 'Send unavailable',
                                onPressed: null,
                                disabledColor: kOutline,
                                icon: Icon(Icons.arrow_upward_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coming soon · Your draft stays on this screen.',
                        textAlign: TextAlign.center,
                        style: geist(
                          fontSize: 12,
                          color: kOnSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          'About scholarship chat',
          style: geist(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: kOnSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Chat is being prepared to help you understand scholarship eligibility, document requirements, and application steps.\n\nAI replies are not connected yet. You can type a draft here, but it cannot be sent. Drafts are cleared when you leave Chat.\n\nAlways check deadlines and requirements with the scholarship provider.',
            style: geist(fontSize: 16, color: kOnSurfaceVariant, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: geist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
