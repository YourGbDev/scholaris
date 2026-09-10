import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

class AdminProvidersTab extends ConsumerStatefulWidget {
  const AdminProvidersTab({super.key});

  @override
  ConsumerState<AdminProvidersTab> createState() => _AdminProvidersTabState();
}

class _AdminProvidersTabState extends ConsumerState<AdminProvidersTab> {
  // Set of provider IDs that are approved/verified in-memory during presentation
  final Set<String> _verifiedProviders = {'CHED', 'DOST-SEI', 'Ayala Foundation'};

  @override
  Widget build(BuildContext context) {
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider Verification',
                  style: poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and verify scholarship provider applications.',
                  style: openSans(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: scholarshipsAsync.when(
              loading: () => const LoadingView(),
              error: (_, _) => const ErrorView(
                message: 'Failed to load provider listings.',
              ),
              data: (scholarships) {
                // Extract distinct provider names from scholarships, plus default pending demo provider
                final providerNames = <String>{
                  for (final s in scholarships)
                    if (s.provider != null && s.provider!.isNotEmpty) s.provider!,
                  'Metrobank Foundation',
                  'SM Foundation',
                }.toList();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  itemCount: providerNames.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final name = providerNames[i];
                    final isVerified = _verifiedProviders.contains(name);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(kRadiusCard),
                        boxShadow: const [
                          BoxShadow(
                            color: kCardShadow,
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: kPrimarySoft,
                                child: Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Scholarship Organization',
                                      style: openSans(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isVerified
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVerified
                                          ? Icons.verified_rounded
                                          : Icons.schedule_rounded,
                                      size: 13,
                                      color: isVerified
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF92400E),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isVerified ? 'Verified' : 'Under Review',
                                      style: poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isVerified
                                            ? const Color(0xFF166534)
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!isVerified) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('Verify & Approve Provider'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _verifiedProviders.add(name));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$name has been verified and approved.'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
