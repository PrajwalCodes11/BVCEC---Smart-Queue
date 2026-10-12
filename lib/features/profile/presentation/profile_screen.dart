import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/extensions.dart';
import '../../../data/models/app_user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  String? _selectedDepartment;
  String? _selectedYear;

  static const _studentDepartments = [
    'Computer Science & Engineering (CSE)',
    'CSE (Artificial Intelligence & ML)',
    'CSE (Data Science)',
    'Information Technology (IT)',
    'Electronics & Communication (ECE)',
    'Electrical & Electronics (EEE)',
    'Mechanical Engineering',
    'Civil Engineering',
  ];

  static const _studyYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  static const _staffSections = [
    'Examination Section',
    'Accounts & Fees',
    'Library',
    'Department Office',
    'Administration',
    'Student Affairs',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user.fullName);
    _emailCtrl = TextEditingController(text: user.email ?? '');
    _phoneCtrl = TextEditingController(text: user.phone ?? '');
    _selectedDepartment = user.department ??
        (user.role == UserRole.student
            ? _studentDepartments.first
            : _staffSections.first);
    _selectedYear = user.yearOfStudy ?? _studyYears[2];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _resetControllers(AppUser user) {
    _nameCtrl.text = user.fullName;
    _emailCtrl.text = user.email ?? '';
    _phoneCtrl.text = user.phone ?? '';
    _selectedDepartment = user.department ??
        (user.role == UserRole.student
            ? _studentDepartments.first
            : _staffSections.first);
    _selectedYear = user.yearOfStudy ?? _studyYears[2];
  }

  Future<void> _saveChanges(AppUser user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
        userId: user.id,
        fullName: _nameCtrl.text.trim(),
        department: _selectedDepartment,
        yearOfStudy: user.role == UserRole.student ? _selectedYear : null,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      // Invalidate auth provider to refresh state everywhere
      ref.invalidate(authStateProvider);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.available,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.cancelled,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    final roleColor = switch (user.role) {
      UserRole.student => AppColors.accent,
      UserRole.staff => AppColors.staffColor,
      UserRole.admin => AppColors.adminColor,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: const BackButton(),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _resetControllers(user);
                  _isEditing = false;
                } else {
                  _isEditing = true;
                }
              });
            },
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit_outlined,
              size: 16,
              color: _isEditing ? Colors.redAccent : AppColors.accent,
            ),
            label: Text(
              _isEditing ? 'Cancel' : 'Edit',
              style: TextStyle(
                color: _isEditing ? Colors.redAccent : AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Header Avatar Card
            _buildProfileHeader(user, roleColor),
            const SizedBox(height: 20),

            // Profile Fields Form (View or Edit mode)
            if (_isEditing)
              _buildEditForm(user)
            else
              _buildDetailsCard(user, roleColor),

            const SizedBox(height: 24),

            // Account Actions
            if (!_isEditing) ...[
              if (user.role == UserRole.student)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.history),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('View Queue History'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cancelled,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user, Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [roleColor, roleColor.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: roleColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.fullName.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor),
                ),
                child: Text(
                  user.role.name.toUpperCase(),
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ${user.registrationNumber}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(AppUser user, Color roleColor) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal & Academic Details',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _ProfileRow(
            icon: Icons.badge_outlined,
            label: user.role == UserRole.student ? 'Student ID' : 'Staff ID',
            value: user.registrationNumber,
            isLocked: true,
          ),
          const Divider(height: 24),
          _ProfileRow(
            icon: user.role == UserRole.student ? Icons.school_outlined : Icons.business_outlined,
            label: user.role == UserRole.student ? 'Department / Branch' : 'Section / Dept',
            value: user.department ?? 'Not set (Tap Edit)',
          ),
          if (user.role == UserRole.student) ...[
            const Divider(height: 24),
            _ProfileRow(
              icon: Icons.calendar_today_outlined,
              label: 'Year of Study',
              value: user.yearOfStudy ?? 'Not set',
            ),
          ],
          const Divider(height: 24),
          _ProfileRow(
            icon: Icons.email_outlined,
            label: 'College Mail ID',
            value: user.email ?? '${user.registrationNumber.toLowerCase()}@bvcec.internal',
          ),
          const Divider(height: 24),
          _ProfileRow(
            icon: Icons.phone_outlined,
            label: 'Contact Number',
            value: (user.phone != null && user.phone!.isNotEmpty) ? user.phone! : 'Not provided',
          ),
          const Divider(height: 24),
          _ProfileRow(
            icon: Icons.access_time_outlined,
            label: 'Member Since',
            value: dateFormat.format(user.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent, width: 1.5),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.edit_note, color: AppColors.accent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Edit Your Profile Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Full Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline, size: 20),
                filled: true,
                fillColor: AppColors.surfaceElevated,
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),

            // Department
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartment,
              isExpanded: true,
              dropdownColor: AppColors.surfaceElevated,
              decoration: InputDecoration(
                labelText: user.role == UserRole.student ? 'Department / Branch' : 'Section / Dept',
                prefixIcon: const Icon(Icons.school_outlined, size: 20),
                filled: true,
                fillColor: AppColors.surfaceElevated,
              ),
              items: (user.role == UserRole.student ? _studentDepartments : _staffSections)
                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDepartment = val);
              },
            ),
            const SizedBox(height: 14),

            // Year of Study (students only)
            if (user.role == UserRole.student) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedYear,
                isExpanded: true,
                dropdownColor: AppColors.surfaceElevated,
                decoration: const InputDecoration(
                  labelText: 'Year of Study',
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                ),
                items: _studyYears
                    .map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedYear = val);
                },
              ),
              const SizedBox(height: 14),
            ],

            // Email
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'College Mail ID',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: AppColors.surfaceElevated,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                filled: true,
                fillColor: AppColors.surfaceElevated,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveChanges(user),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Save Profile Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLocked;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (isLocked)
          const Tooltip(
            message: 'Unique Identifier (Non-editable)',
            child: Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
          ),
      ],
    );
  }
}
