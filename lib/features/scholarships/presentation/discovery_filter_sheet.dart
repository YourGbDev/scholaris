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
                  style: outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF161C27),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: notifier.reset,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F4D2E),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    'Reset',
                    style: outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F4D2E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8E5)),
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
                        return const Color(0xFF0F4D2E);
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return const Color(0xFF161C27);
                    }),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: Color(0xFFE2E8E5)),
                    ),
                  ),
                  segments: [
                    ButtonSegment(
                      value: DiscoverySort.defaultSort,
                      label: Text(
                        'Default',
                        style: outfit(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    ButtonSegment(
                      value: DiscoverySort.highestAmount,
                      label: Text(
                        'Highest amount',
                        style: outfit(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
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
                        style: outfit(
                          fontSize: 12.5,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          color: selected ? Colors.white : const Color(0xFF161C27),
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFF0F4D2E),
                      backgroundColor: const Color(0xFFF1F3FF),
                      side: BorderSide(
                        color: selected ? const Color(0xFF0F4D2E) : const Color(0xFFDDE2F3),
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
                    style: outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF161C27)),
                  ),
                  subtitle: Text(
                    'Within 14 days of the deadline',
                    style: openSans(fontSize: 12, color: const Color(0xFF404942)),
                  ),
                  value: state.closingSoonOnly,
                  activeThumbColor: const Color(0xFF0F4D2E),
                  activeTrackColor: const Color(0xFFB3F1C6),
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
                        style: outfit(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF161C27),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0F4D2E),
                      backgroundColor: const Color(0xFFF1F3FF),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0F4D2E) : const Color(0xFFDDE2F3),
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
                  backgroundColor: const Color(0xFF0F4D2E), // primary-container
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
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
              color: const Color(0xFF0F4D2E),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            title,
            style: outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF161C27),
            ),
          ),
        ],
      );
}
