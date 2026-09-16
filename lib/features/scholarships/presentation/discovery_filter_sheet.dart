// lib/features/scholarships/presentation/discovery_filter_sheet.dart
//
// Self-contained bottom sheet for the discovery filters. Reads and writes the
// shared discoveryFilterProvider directly — no local persistent state — so the
// Discover screen stays reactive while the sheet is open.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../profile/models/student_profile.dart';
import '../providers/discovery_provider.dart';
import '../services/discovery_filters.dart';

/// Human label for an income bracket ('any' → "Any").
String incomeLabel(String? income) {
  switch (income) {
    case 'low':
      return 'Low';
    case 'mid':
      return 'Mid';
    case 'high':
      return 'High';
    default:
      return 'Any';
  }
}

Future<void> showDiscoveryFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const DiscoveryFilterSheet(),
  );
}

class DiscoveryFilterSheet extends ConsumerStatefulWidget {
  const DiscoveryFilterSheet({super.key});

  @override
  ConsumerState<DiscoveryFilterSheet> createState() =>
      _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends ConsumerState<DiscoveryFilterSheet> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryFilterProvider);
    final notifier = ref.read(discoveryFilterProvider.notifier);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: notifier.reset,
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    'Reset',
                    style: poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorderLight),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _sectionTitle('Sort'),
                const SizedBox(height: 10),
                SegmentedButton<DiscoverySort>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return kPrimary;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return kTextPrimary;
                    }),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: kBorderLight),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: DiscoverySort.defaultSort,
                      label: Text('Default'),
                    ),
                    ButtonSegment(
                      value: DiscoverySort.highestAmount,
                      label: Text('Highest amount'),
                    ),
                  ],
                  selected: {state.sort},
                  onSelectionChanged: (selection) =>
                      notifier.setSort(selection.first),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Income'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['any', 'low', 'mid', 'high'].map((bracket) {
                    final selected = bracket == 'any'
                        ? state.incomeBracket == null
                        : state.incomeBracket == bracket;
                    return ChoiceChip(
                      label: Text(
                        incomeLabel(bracket == 'any' ? null : bracket),
                        style: openSans(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? Colors.white : kTextPrimary,
                        ),
                      ),
                      selected: selected,
                      selectedColor: kPrimary,
                      backgroundColor: const Color(0xFFF1F3FF),
                      side: BorderSide(
                        color: selected ? kPrimary : kBorderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) => notifier.setIncomeBracket(
                        bracket == 'any' ? null : bracket,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Deadline'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Closing soon',
                    style: poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Within 14 days of the deadline',
                    style: openSans(fontSize: 12, color: kTextSecondary),
                  ),
                  value: state.closingSoonOnly,
                  activeThumbColor: kPrimary,
                  activeTrackColor: kPrimary.withValues(alpha: 0.35),
                  onChanged: notifier.setClosingSoonOnly,
                ),
                const SizedBox(height: 24),
                _sectionTitle('Region'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kPhilippineRegions.map((region) {
                    final isSelected = state.regions.contains(region);
                    return FilterChip(
                      label: Text(
                        region,
                        style: openSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : kTextPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: kPrimary,
                      backgroundColor: const Color(0xFFF1F3FF),
                      side: BorderSide(
                        color: isSelected ? kPrimary : kBorderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: false,
                      onSelected: (_) => notifier.toggleRegion(region),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Row(
        children: [
          Container(
            width: 3.5,
            height: 13,
            margin: const EdgeInsets.only(right: 7),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            title,
            style: poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
        ],
      );
}
