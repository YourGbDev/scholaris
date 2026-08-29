// lib/features/scholarships/presentation/discovery_filter_sheet.dart
//
// Self-contained bottom sheet for the discovery filters. Reads and writes the
// shared discoveryFilterProvider directly — no local persistent state — so the
// Discover screen stays reactive while the sheet is open. Text controllers only
// bind text input; the authoritative values always live in the provider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../profile/models/student_profile.dart';
import '../providers/discovery_provider.dart';
import '../providers/scholarships_provider.dart';
import '../services/discovery_filters.dart';

/// Canonical coverage types offered in the coverage filter.
const List<String> kCoverageOptions = ['full', 'partial', 'stipend'];

/// Human label for a coverage type.
String coverageLabel(String coverage) {
  switch (coverage) {
    case 'full':
      return 'Full coverage';
    case 'partial':
      return 'Partial coverage';
    case 'stipend':
      return 'Stipend';
    default:
      return coverage;
  }
}

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
  void initState() {
    super.initState();
    final state = ref.read(discoveryFilterProvider);
    _minController.text = state.minAmount?.toStringAsFixed(0) ?? '';
    _maxController.text = state.maxAmount?.toStringAsFixed(0) ?? '';
  }

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
    final catalog = ref.watch(scholarshipsProvider).valueOrNull ?? const [];
    final availableTags = DiscoveryFilters.availableTags(catalog).toList()
      ..sort();

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
                const SizedBox(height: 16),
                _sectionTitle('Deadline'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Closing soon'),
                  subtitle: const Text('Within 14 days of the deadline'),
                  value: state.closingSoonOnly,
                  activeThumbColor: kPrimary,
                  onChanged: notifier.setClosingSoonOnly,
                ),
                const SizedBox(height: 8),
                _sectionTitle('Amount'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => notifier.setMinAmount(
                          DiscoveryFilters.parseAmount(value),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Min amount',
                          prefixText: '₱',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => notifier.setMaxAmount(
                          DiscoveryFilters.parseAmount(value),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Max amount',
                          prefixText: '₱',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('Coverage'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: kCoverageOptions.map((coverage) {
                    return FilterChip(
                      label: Text(coverageLabel(coverage)),
                      selected: state.coverageTypes.contains(coverage),
                      onSelected: (_) => notifier.toggleCoverage(coverage),
                    );
                  }).toList(),
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
                if (availableTags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionTitle('Tags'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      return FilterChip(
                        label: Text(tag),
                        selected: state.tags.contains(tag),
                        onSelected: (_) => notifier.toggleTag(tag),
                      );
                    }).toList(),
                  ),
                ],
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
