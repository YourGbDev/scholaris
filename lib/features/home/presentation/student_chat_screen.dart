import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../applications/presentation/widgets/document_upload_sheet.dart';
import '../../profile/providers/profile_setup_provider.dart';
import '../../scholarships/presentation/scholarship_qr_scanner_screen.dart';
import 'home_screen.dart' show homeTabIndexProvider;
import 'student_chat_guide.dart';

class StudentChatScreen extends ConsumerStatefulWidget {
  const StudentChatScreen({super.key});
  @override
  ConsumerState<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends ConsumerState<StudentChatScreen> {
  String? _dismissedUser;
  String? _replayUser;
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _finish(String user) => setState(() {
    _dismissedUser = user;
    _replayUser = null;
  });

  @override
  Widget build(BuildContext context) {
    ref.listen(currentProfileProvider, (previous, next) {
      if (previous?.valueOrNull?.id != next.valueOrNull?.id) _draft.clear();
    });
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final user = profile?.id;
    final guide =
        user != null && (_replayUser == user || _dismissedUser != user);
    final name = profile?.fullName.trim() ?? '';
    final first = name.isEmpty ? 'there' : name.split(RegExp(r'\s+')).first;
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
          guide ? 'Chat guide' : 'Chat',
          style: AppTypography.style(
            AppTextRole.screenTitle,
            fontSize: 20,
            color: kOnSurface,
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
        actions: [
          if (!guide && user != null)
            IconButton(
              tooltip: 'Chat help',
              icon: const Icon(Icons.help_outline_rounded, color: kPrimary),
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() => _replayUser = user);
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child:
                profile == null && ref.watch(currentProfileProvider).isLoading
                ? const Center(child: CircularProgressIndicator())
                : guide
                ? StudentChatGuide(
                    key: ValueKey(user),
                    gender: profile?.gender,
                    onFinish: () => _finish(user),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final keyboard =
                          MediaQuery.viewInsetsOf(context).bottom > 0;
                      return SingleChildScrollView(
                        reverse: true,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!keyboard)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    24,
                                    24,
                                    24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ChatCompanionArtwork(
                                            gender: profile?.gender,
                                            size: 56,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              chatCompanionName(
                                                profile?.gender,
                                              ),
                                              style: AppTypography.style(
                                                AppTextRole.cardTitle,
                                                fontSize: 17,
                                                color: kPrimary,
                                                height: 1.4,
                                                letterSpacing: 0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Hi, $first!',
                                        style: AppTypography.style(
                                          AppTextRole.screenTitle,
                                          fontSize: 20,
                                          height: 1.2,
                                          color: kOnSurface,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'A little guidance for your next step. Explore scholarships or get your documents ready with the tools below.',
                                        style: AppTypography.style(
                                          AppTextRole.body,
                                          fontSize: 14,
                                          height: 1.5,
                                          color: kTextSecondary,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'AI replies are not connected yet.',
                                        style: AppTypography.style(
                                          AppTextRole.caption,
                                          fontSize: 13,
                                          height: 1.4,
                                          color: kTextSupporting,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _tool(
                                          Icons.qr_code_scanner_rounded,
                                          'Scan QR',
                                          () => _explain(
                                            'Scan QR',
                                            'Scan a Scholaris scholarship QR code to open its details. Camera access may be requested.',
                                            () =>
                                                ScholarshipQrScannerScreen.show(
                                                  context,
                                                ),
                                          ),
                                        ),
                                        _tool(
                                          Icons.upload_file_outlined,
                                          'Upload document',
                                          () => _explain(
                                            'Upload document',
                                            'Choose an existing application, then attach a required document. Files are not sent to AI chat.',
                                            () => showDocumentUploadSheet(
                                              context,
                                            ),
                                          ),
                                        ),
                                        _tool(
                                          Icons.search_rounded,
                                          'Find scholarships',
                                          () => _explain('Find scholarships', 'Explore Discover to check scholarship eligibility, requirements, and deadlines.', () {
                                            ref
                                                .read(
                                                  homeTabIndexProvider.notifier,
                                                )
                                                .selectTab(1);
                                            context.go('/home');
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: kStudentDivider,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          8,
                                          4,
                                          8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _draft,
                                                minLines: 1,
                                                maxLines: keyboard ? 2 : 4,
                                                style: AppTypography.style(
                                                  AppTextRole.input,
                                                  fontSize: 14,
                                                  height: 1.4,
                                                  color: kOnSurface,
                                                  letterSpacing: 0,
                                                ),
                                                cursorColor: kPrimary,
                                                textCapitalization:
                                                    TextCapitalization
                                                        .sentences,
                                                decoration: InputDecoration(
                                                  hintText: 'Write a scholarship question…',
                                                  hintStyle:
                                                      AppTypography.style(
                                                        AppTextRole.placeholder,
                                                        fontSize: 14,
                                                        height: 1.4,
                                                        color: kTextSupporting,
                                                        letterSpacing: 0,
                                                      ),
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  filled: false,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const IconButton(
                                              tooltip: 'Send unavailable',
                                              onPressed: null,
                                              disabledColor: kOutline,
                                              icon: Icon(
                                                Icons.arrow_upward_rounded,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Coming soon · Your draft stays on this screen.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.style(
                                        AppTextRole.caption,
                                        fontSize: 12,
                                        height: 1.4,
                                        color: kTextSupporting,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _tool(IconData icon, String label, VoidCallback onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: kPrimary),
        label: Text(
          label,
          style: AppTypography.style(
            AppTextRole.cardTitle,
            fontSize: 13,
            color: kOnSurface,
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          side: const BorderSide(color: kStudentDivider),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Future<void> _explain(
    String title,
    String description,
    VoidCallback open,
  ) async {
    FocusScope.of(context).unfocus();
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          title,
          style: AppTypography.style(
            AppTextRole.sectionTitle,
            fontSize: 20,
            color: kOnSurface,
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            description,
            style: AppTypography.style(
              AppTextRole.body,
              fontSize: 14,
              height: 1.5,
              color: kTextSecondary,
              letterSpacing: 0,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.style(
                AppTextRole.button,
                fontSize: 13,
                color: kTextSecondary,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Open tool',
              style: AppTypography.style(
                AppTextRole.button,
                fontSize: 13,
                color: kPrimary,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
    if (mounted && proceed == true) open();
  }
}
