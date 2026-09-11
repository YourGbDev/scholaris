import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import 'admin_theme.dart';

class AdminProvidersTab extends ConsumerStatefulWidget {
  const AdminProvidersTab({super.key});

  @override
  ConsumerState<AdminProvidersTab> createState() => _AdminProvidersTabState();
}

class _AdminProvidersTabState extends ConsumerState<AdminProvidersTab> {
  // Set of provider IDs that are approved/verified in-memory during presentation
  final Set<String> _verifiedProviders = {
    'CHED',
    'DOST-SEI',
    'Ayala Foundation',
  };

  @override
  Widget build(BuildContext context) {
    final scholarshipsAsync = ref.watch(scholarshipsProvider);

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider Verification',
                  style: adminHeaderStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kAdminNavyTrust,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and verify scholarship provider applications.',
                  style: adminLabelStyle(
                    fontSize: 13,
                    color: kAdminTextSecondary,
                  ),
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
                final providerNames = <String>{
                  for (final s in scholarships)
                    if (s.provider != null && s.provider!.isNotEmpty)
                      s.provider!,
                  'Metrobank Foundation',
                  'SM Foundation',
                }.toList();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: kAdminTableRadius,
                      border: Border.all(color: kAdminHairline, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Dense Table Header
                        Container(
                          color: const Color(0xFFF9FAFB),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Organization',
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Category',
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Verification status',
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Actions',
                                  textAlign: TextAlign.right,
                                  style: adminLabelStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kAdminNavyTrust,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: kAdminHairline),
                        // Dense Table Rows
                        Expanded(
                          child: ListView.separated(
                            itemCount: providerNames.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, color: kAdminHairline),
                            itemBuilder: (context, i) {
                              final name = providerNames[i];
                              final isVerified =
                                  _verifiedProviders.contains(name);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        name,
                                        style: adminHeaderStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kAdminNavyTrust,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Scholarship Organization',
                                        style: adminBodyStyle(
                                          fontSize: 13,
                                          color: kAdminTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: isVerified
                                                  ? kAdminBridgeGreen
                                                  : kAdminGoldenOpportunity,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              isVerified
                                                  ? 'Verified'
                                                  : 'Under review',
                                              style: adminLabelStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isVerified
                                                    ? kAdminBridgeGreen
                                                    : kAdminGoldenOpportunity,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: isVerified
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle_outline,
                                                    size: 15,
                                                    color: kAdminBridgeGreen,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Approved',
                                                    style: adminLabelStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: kAdminBridgeGreen,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : FilledButton.icon(
                                                icon: const Icon(
                                                  Icons.check_rounded,
                                                  size: 14,
                                                ),
                                                label: const Text(
                                                  'Verify & Approve Provider',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      kAdminBridgeGreen,
                                                  foregroundColor:
                                                      Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                    borderRadius:
                                                        kAdminCardRadius,
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  final confirmed =
                                                      await _confirmProviderApproval(
                                                    context,
                                                    name,
                                                  );
                                                  if (!confirmed) return;
                                                  if (!context.mounted) return;
                                                  setState(
                                                    () => _verifiedProviders
                                                        .add(name),
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '$name has been verified and approved.',
                                                        style: adminBodyStyle(
                                                          fontSize: 12,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmProviderApproval(
    BuildContext context,
    String providerName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: kAdminChromeRadius,
        ),
        title: Text(
          'Approve Provider',
          style: adminHeaderStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to verify and approve $providerName? They will be granted full access to publish scholarships and review student applications.',
          style: adminBodyStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: adminLabelStyle(
                 fontSize: 13,
                color: kAdminTextSecondary,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kAdminBridgeGreen,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: kAdminCardRadius,
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
