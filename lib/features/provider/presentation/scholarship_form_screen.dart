// lib/features/provider/presentation/scholarship_form_screen.dart
//
// Dual-mode form for creating a new scholarship or editing an existing one.
// Providers configure criteria, deadlines, quotas, and special eligibility tags.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../scholarships/models/scholarship.dart';
import '../providers/provider_scholarships_provider.dart';

class ScholarshipFormScreen extends ConsumerStatefulWidget {
  const ScholarshipFormScreen({
    super.key,
    this.scholarshipId,
    this.initialScholarship,
  });

  final String? scholarshipId;
  final Scholarship? initialScholarship;

  bool get isEditing => scholarshipId != null || initialScholarship != null;

  @override
  ConsumerState<ScholarshipFormScreen> createState() =>
      _ScholarshipFormScreenState();
}

class _ScholarshipFormScreenState extends ConsumerState<ScholarshipFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _providerController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _minGpaController;
  late final TextEditingController _slotsController;
  late final TextEditingController _incomeController;
  late final TextEditingController _coursesController;
  late final TextEditingController _locationController;
  late final TextEditingController _urlController;

  DateTime? _deadline;
  late Set<int> _selectedYearLevels;
  late bool _forIndigenous;
  late bool _forPwd;
  late bool _isActive;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialScholarship;

    _titleController = TextEditingController(text: init?.title ?? '');
    _providerController = TextEditingController(text: init?.provider ?? '');
    _descriptionController =
        TextEditingController(text: init?.description ?? '');
    _minGpaController = TextEditingController(
      text: init != null ? init.minGpa.toString() : '2.0',
    );
    _slotsController = TextEditingController(
      text: init?.slots != null ? init!.slots.toString() : '',
    );
    _incomeController = TextEditingController(
      text: init?.maxMonthlyIncome != null
          ? init!.maxMonthlyIncome!.toStringAsFixed(0)
          : '',
    );
    _coursesController = TextEditingController(
      text: init?.requiredCourses != null ? init!.requiredCourses!.join(', ') : '',
    );
    _locationController =
        TextEditingController(text: init?.locationRestriction ?? '');
    _urlController = TextEditingController(text: init?.applicationUrl ?? '');

    _deadline = init?.deadline ?? DateTime.now().add(const Duration(days: 60));
    _selectedYearLevels = (init?.requiredYearLevels != null &&
            init!.requiredYearLevels!.isNotEmpty)
        ? init.requiredYearLevels!.toSet()
        : {1, 2, 3, 4, 5};
    _forIndigenous = init?.forIndigenous ?? false;
    _forPwd = init?.forPwd ?? false;
    _isActive = init?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _providerController.dispose();
    _descriptionController.dispose();
    _minGpaController.dispose();
    _slotsController.dispose();
    _incomeController.dispose();
    _coursesController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline != null && _deadline!.isAfter(now)
        ? _deadline!
        : now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
      helpText: 'Select Application Deadline',
    );

    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an application deadline.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final coursesRaw = _coursesController.text.trim();
      final List<String> courses = coursesRaw.isEmpty
          ? <String>[]
          : coursesRaw
              .split(',')
              .map((c) => c.trim())
              .where((c) => c.isNotEmpty)
              .toList();

      final minGpa = double.tryParse(_minGpaController.text.trim()) ?? 0.0;
      final slots = int.tryParse(_slotsController.text.trim());
      final income = double.tryParse(_incomeController.text.trim());

      final yearLevelsList = _selectedYearLevels.toList()..sort();

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'provider': _providerController.text.trim().isEmpty
            ? null
            : _providerController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'min_gpa': minGpa,
        'deadline':
            '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}',
        'slots': slots,
        'max_monthly_income': income,
        'required_year_levels':
            yearLevelsList.isEmpty ? [1, 2, 3, 4, 5] : yearLevelsList,
        'required_courses': courses,
        'location_restriction': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'for_indigenous': _forIndigenous,
        'for_pwd': _forPwd,
        'application_url': _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        'is_active': _isActive,
      };

      final notifier = ref.read(providerScholarshipsProvider.notifier);

      if (widget.isEditing) {
        final id = widget.scholarshipId ?? widget.initialScholarship!.id;
        await notifier.updateScholarship(id, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scholarship updated successfully.')),
        );
      } else {
        await notifier.createScholarship(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scholarship created successfully.')),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save scholarship: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isEditing ? 'Edit Scholarship' : 'New Scholarship';

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(
          titleText,
          style: poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kPrimary),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ResponsiveContainer(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              // Basic Information Section
              _buildSectionHeader(
                title: 'Basic Information',
                subtitle: 'Core details visible to students in discovery',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: 'Scholarship Title',
                hint: 'e.g. STEM Excellence Scholarship 2026',
                required: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (val.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _providerController,
                label: 'Provider / Organization Name',
                hint: 'e.g. Ayala Foundation',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Overview of the grant, benefits, and sponsor objectives...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _urlController,
                label: 'Application Link (Optional)',
                hint: 'https://organization.org/apply',
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 28),
              // Schedule & Quota
              _buildSectionHeader(
                title: 'Deadline & Quota',
                subtitle: 'Manage urgency and available capacity',
              ),
              const SizedBox(height: 12),
              _buildDateSelector(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _slotsController,
                      label: 'Available Slots',
                      hint: 'e.g. 50 (blank = open)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      controller: _minGpaController,
                      label: 'Minimum GPA',
                      hint: 'e.g. 2.0 or 3.0',
                      required: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Min GPA required';
                        }
                        final num = double.tryParse(val.trim());
                        if (num == null || num < 0 || num > 5.0) {
                          return 'Enter valid GPA (0.0 - 5.0)';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              // Eligibility & Matching Criteria
              _buildSectionHeader(
                title: 'Eligibility Criteria',
                subtitle: 'Rules evaluated by the Scholaris matching engine',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _incomeController,
                label: 'Max Monthly Household Income (₱)',
                hint: 'e.g. 25000 (blank = any income)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location / Region Restriction',
                hint: 'e.g. NCR, Region IV-A (blank = nationwide)',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _coursesController,
                label: 'Eligible Courses (comma-separated)',
                hint: 'e.g. Computer Science, Information Technology, Engineering',
                helperText: 'Leave empty to allow all undergraduate courses',
              ),
              const SizedBox(height: 16),
              Text(
                'Eligible Year Levels',
                style: poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [1, 2, 3, 4, 5].map((lvl) {
                  final isSelected = _selectedYearLevels.contains(lvl);
                  final label = switch (lvl) {
                    1 => '1st Year',
                    2 => '2nd Year',
                    3 => '3rd Year',
                    4 => '4th Year',
                    5 => '5th Year',
                    _ => 'Year $lvl',
                  };
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: kPrimary.withValues(alpha: 0.15),
                    checkmarkColor: kPrimary,
                    labelStyle: openSans(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? kPrimary : Colors.black87,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedYearLevels.add(lvl);
                        } else {
                          if (_selectedYearLevels.length > 1) {
                            _selectedYearLevels.remove(lvl);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              // Priority & Inclusivity Toggles
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Priority for Indigenous Students',
                        style: openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Boosts matching score for indigenous applicants',
                        style: openSans(fontSize: 12, color: Colors.black54),
                      ),
                      value: _forIndigenous,
                      activeThumbColor: kPrimary,
                      onChanged: (val) => setState(() => _forIndigenous = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        'Priority for PWD Students',
                        style: openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Boosts matching score for students with disabilities',
                        style: openSans(fontSize: 12, color: Colors.black54),
                      ),
                      value: _forPwd,
                      activeThumbColor: kPrimary,
                      onChanged: (val) => setState(() => _forPwd = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        'Active Listing',
                        style: openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _isActive
                            ? 'Visible and open to student applications'
                            : 'Closed — hidden from active discovery',
                        style: openSans(fontSize: 12, color: Colors.black54),
                      ),
                      value: _isActive,
                      activeThumbColor: kPrimary,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              // Action Buttons
              PrimaryButton(
                label: widget.isEditing ? 'Update Listing' : 'Publish Listing',
                loading: _isSaving,
                onPressed: _isSaving ? null : _handleSave,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: openSans(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: openSans(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: openSans(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: openSans(fontSize: 13, color: Colors.black54),
        hintText: hint,
        hintStyle: openSans(fontSize: 13, color: Colors.black38),
        helperText: helperText,
        helperStyle: openSans(fontSize: 11, color: Colors.black45),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _pickDeadline,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20, color: kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Deadline *',
                    style: openSans(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _deadline != null
                        ? _formatDate(_deadline!)
                        : 'Select deadline date',
                    style: openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _deadline != null ? Colors.black87 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
