import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/app_user.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Login inputs
  final _identifierController = TextEditingController();
  final _signInPasswordController = TextEditingController(); // separate from registration

  // Registration inputs — kept separate so sign-in never sees registration data
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Registration inputs
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Student specific
  String _selectedDepartment = 'Computer Science & Engineering (CSE)';
  String _selectedYear = '3rd Year';

  // Staff specific
  String _selectedStaffSection = 'Examination Section';

  // State flags
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isRegistering = false;
  UserRole _registerRole = UserRole.student;

  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  /// Clears all registration form fields and resets dropdowns.
  void _clearRegistrationFields() {
    _nameController.clear();
    _regNoController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _selectedDepartment = 'Computer Science & Engineering (CSE)';
    _selectedYear = '3rd Year';
    _selectedStaffSection = 'Examination Section';
  }

  /// Clears the sign-in form fields.
  void _clearSignInFields() {
    _identifierController.clear();
    _signInPasswordController.clear();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _signInPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _regNoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegistering &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final AppUser user;

      if (_isRegistering) {
        if (_registerRole == UserRole.student) {
          user = await repo.registerStudent(
            registrationNumber: _regNoController.text.trim(),
            fullName: _nameController.text.trim(),
            department: _selectedDepartment,
            yearOfStudy: _selectedYear,
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          user = await repo.registerStaff(
            staffId: _regNoController.text.trim(),
            fullName: _nameController.text.trim(),
            department: _selectedStaffSection,
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );
        }
      } else {
        user = await repo.signIn(
          registrationNumber: _identifierController.text.trim(),
          password: _signInPasswordController.text,
        );
      }

      if (mounted) {
        context.go(AppRoutes.roleHome(user.role));
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.background, Color(0xFF0D2137)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildForm(),
                      const SizedBox(height: 16),
                      if (_errorMessage != null) _buildError(),
                      const SizedBox(height: 8),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                      _buildToggle(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.queue, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 18),
        const Text(
          'SmartQueue',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isRegistering
              ? 'Create your ${_registerRole == UserRole.student ? 'student' : 'staff'} account'
              : 'Sign in with your ID number or College Email',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Registration Role Toggle (Student vs Staff)
            if (_isRegistering) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (_registerRole != UserRole.student) {
                            _clearRegistrationFields();
                            _errorMessage = null;
                          }
                          _registerRole = UserRole.student;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _registerRole == UserRole.student
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'Student Account',
                              style: TextStyle(
                                color: _registerRole == UserRole.student
                                    ? Colors.black
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (_registerRole != UserRole.staff) {
                            _clearRegistrationFields();
                            _errorMessage = null;
                          }
                          _registerRole = UserRole.staff;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _registerRole == UserRole.staff
                                ? AppColors.staffColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'Staff Account',
                              style: TextStyle(
                                color: _registerRole == UserRole.staff
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ── SIGN IN FIELDS ──────────────────────────────────────────────
            if (!_isRegistering) ...[
              _buildField(
                controller: _identifierController,
                label: 'Student ID, Staff ID, or Email',
                icon: Icons.badge_outlined,
                hint: 'e.g. 22A61A0501, STAFF001, or name@bvcec.edu.in',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter your ID or Email' : null,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _signInPasswordController,
                label: 'Password',
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ],

            // ── REGISTRATION FIELDS ──────────────────────────────────────────
            if (_isRegistering) ...[
              // Full Name
              _buildField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                hint: 'Enter your full legal name',
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 14),

              // Student / Staff ID
              _buildField(
                controller: _regNoController,
                label: _registerRole == UserRole.student ? 'Student ID / Reg No.' : 'Staff ID',
                icon: Icons.credit_card,
                hint: _registerRole == UserRole.student ? 'e.g. 22A61A0501' : 'e.g. STAFF001',
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Department / Section
              if (_registerRole == UserRole.student) ...[
                _buildDropdownField<String>(
                  label: 'Department / Branch',
                  icon: Icons.school_outlined,
                  value: _selectedDepartment,
                  items: _studentDepartments,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDepartment = val);
                  },
                ),
                const SizedBox(height: 14),

                _buildDropdownField<String>(
                  label: 'Year of Study',
                  icon: Icons.calendar_today_outlined,
                  value: _selectedYear,
                  items: _studyYears,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedYear = val);
                  },
                ),
              ] else ...[
                _buildDropdownField<String>(
                  label: 'Assigned Department / Section',
                  icon: Icons.business_outlined,
                  value: _selectedStaffSection,
                  items: _staffSections,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStaffSection = val);
                  },
                ),
              ],
              const SizedBox(height: 14),

              // College Email
              _buildField(
                controller: _emailController,
                label: 'College Mail ID / Email',
                icon: Icons.email_outlined,
                hint: _registerRole == UserRole.student
                    ? 'e.g. 22a61a0501@bvcec.edu.in'
                    : 'e.g. staff.office@bvcec.edu.in',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email address';
                  if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Phone (Optional)
              _buildField(
                controller: _phoneController,
                label: 'Phone Number (Optional)',
                icon: Icons.phone_outlined,
                hint: 'e.g. 9876543210',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // Password
              _buildPasswordField(
                controller: _passwordController,
                label: 'Password',
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
              ),
              const SizedBox(height: 14),

              // Confirm Password
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                obscure: _obscureConfirmPassword,
                onToggle: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.surfaceElevated,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.surfaceElevated,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.surfaceElevated,
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item.toString(),
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textMuted,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.surfaceElevated,
      ),
      validator: validator ??
          (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cancelled.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cancelled.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.cancelled, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.cancelled, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isRegistering && _registerRole == UserRole.staff
              ? AppColors.staffColor
              : AppColors.accent,
          foregroundColor: _isRegistering && _registerRole == UserRole.staff
              ? Colors.white
              : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isRegistering ? 'Create Account' : 'Sign In',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegistering ? 'Already have an account?' : "Don't have an account?",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        TextButton(
          onPressed: () => setState(() {
            _isRegistering = !_isRegistering;
            _errorMessage = null;
            // Clear all fields when switching between Sign In and Register
            // so no data leaks between the two forms
            if (_isRegistering) {
              _clearRegistrationFields();
            } else {
              _clearSignInFields();
            }
          }),
          child: Text(
            _isRegistering ? 'Sign In' : 'Register Now',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
