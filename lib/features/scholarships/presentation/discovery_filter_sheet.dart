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
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryFilterProvider);
    final notifier = ref.read(discoveryFilterProvider.notifier);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: notifier.reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _sectionTitle('Sort'),
                const SizedBox(height: 10),
                SegmentedButton<DiscoverySort>(
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
                      ),
                      selected: selected,
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
                  title: const Text('Closing soon'),
                  subtitle: const Text('Within 14 days of the deadline'),
                  value: state.closingSoonOnly,
                  activeThumbColor: kPrimary,
                  onChanged: notifier.setClosingSoonOnly,
                ),
                const SizedBox(height: 24),
                _sectionTitle('Region'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kPhilippineRegions.map((region) {
                    return FilterChip(
                      label: Text(region),
                      selected: state.regions.contains(region),
                      onSelected: (_) => notifier.toggleRegion(region),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: poppins(fontSize: 15, fontWeight: FontWeight.w600, color: kPrimary),
      );
}
