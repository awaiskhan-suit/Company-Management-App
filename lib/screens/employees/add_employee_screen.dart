import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../colors/colors.dart';
import '../../providers/add_employee_provider.dart';
import '../../services/employee_storage.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? _profileImage;
  final Set<String> _usedEmployeeIds = {};

  // Track date errors (because date fields are not TextFormField)
  String? _dobError;
  String? _joiningDateError;

  @override
  void initState() {
    super.initState();
    _loadSavedEmployeeIds();
  }

  // ============================================================
  // SAVED IDS (duplicate check, works offline)
  // ============================================================

  /// Loads IDs of employees saved earlier so duplicates are caught
  /// even after the app is restarted.
  Future<void> _loadSavedEmployeeIds() async {
    final ids = await EmployeeStorage.loadEmployeeIds();
    if (!mounted) return;
    setState(() {
      _usedEmployeeIds.addAll(ids.map((e) => e.toString().toUpperCase()));
    });
  }

  /// Copies the picked image from the temporary cache into the app's
  /// documents folder so it is still there after restart.
  Future<String?> _persistProfileImage(String empId) async {
    final file = _profileImage;
    if (file == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${dir.path}/employee_images');
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }

    final dot = file.path.lastIndexOf('.');
    final ext = dot != -1 ? file.path.substring(dot) : '.jpg';
    final safeName = empId.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');

    final saved = await file.copy('${imgDir.path}/$safeName$ext');
    return saved.path;
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
    required bool isDob,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? (isDob ? DateTime(now.year - 20) : now),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navy,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onPicked(picked);
      setState(() {
        if (isDob) {
          _dobError = null;
        } else {
          _joiningDateError = null;
        }
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Choose Profile Picture',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _ImageSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _handleSubmit() async {
    final state = ref.read(addEmployeeProvider);

    // Validate dates manually
    bool datesValid = true;
    setState(() {
      _dobError =
      state.dateOfBirth == null ? 'Date of birth is required' : null;
      _joiningDateError =
      state.joiningDate == null ? 'Joining date is required' : null;
      datesValid = _dobError == null && _joiningDateError == null;
    });

    // Validate the form first so field errors are always visible
    final formValid = _formKey.currentState?.validate() ?? false;

    // Profile image required
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture is required'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!formValid || !datesValid) return;

    // ---------- Final safety check: CNIC / Phone / Email ----------
    final cnic = state.cnic.trim();
    final phone = state.phone.trim();
    final email = state.email.trim().toLowerCase();

    String? credentialError;
    if (!RegExp(r'^\d{13}$').hasMatch(cnic)) {
      credentialError = 'CNIC must be exactly 13 digits';
    } else if (!RegExp(r'^\d{11}$').hasMatch(phone)) {
      credentialError = 'Phone number must be exactly 11 digits';
    } else if (!RegExp(r'^[\w\.\-]+@gmail\.com$').hasMatch(email)) {
      credentialError = 'Email must be a valid @gmail.com address';
    }

    if (credentialError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(credentialError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final empId = state.employeeId.trim().toUpperCase();

    if (empId.startsWith('API-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee IDs starting with API- are reserved.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_usedEmployeeIds.contains(empId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee ID already exists. Please use a unique ID.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Copy the photo to permanent storage first, then submit once.
    // If copying fails, fall back to the original picked path
    // instead of losing all the data.
    String? imagePath;
    try {
      imagePath = await _persistProfileImage(empId);
    } catch (e) {
      debugPrint('Failed to copy profile image: $e');
      imagePath = _profileImage?.path;
    }
    if (!mounted) return;

    final notifier = ref.read(addEmployeeProvider.notifier);
    notifier.setImagePath(imagePath);

    // The provider saves the employee to local storage (works offline)
    final ok = await notifier.submit();
    if (!mounted) return;

    if (ok) {
      _usedEmployeeIds.add(empId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      final msg = ref.read(addEmployeeProvider).errorMessage;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addEmployeeProvider);
    final notifier = ref.read(addEmployeeProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.ctaGradient,
          ),
        ),
        leading: IconButton(
          icon:
          Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Employee',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
            children: [
              // ===================== Profile Picture =====================
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 48.r,
                          backgroundColor: AppColors.navy.withOpacity(0.12),
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? Icon(
                            Icons.person_rounded,
                            size: 48.sp,
                            color: AppColors.navy,
                          )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              height: 34.w,
                              width: 34.w,
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2.w,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Profile Picture *',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // ===== Personal =====
              const _SectionHeader(
                title: 'Personal Information',
                icon: Icons.person_outline_rounded,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Employee ID *'),
              _RoundedField(
                initialValue: state.employeeId,
                hint: 'e.g. EMP-001',
                icon: Icons.badge_outlined,
                onChanged: notifier.setEmployeeId,
                validator: (v) {
                  final id = v?.trim() ?? '';
                  if (id.isEmpty) return 'Employee ID is required';
                  if (id.length < 3) return 'ID must be at least 3 characters';
                  if (id.toUpperCase().startsWith('API-')) {
                    return 'IDs starting with API- are reserved';
                  }
                  if (_usedEmployeeIds.contains(id.toUpperCase())) {
                    return 'This Employee ID already exists';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Full Name *'),
              _RoundedField(
                initialValue: state.fullName,
                hint: 'Full name',
                icon: Icons.person_outline,
                onChanged: notifier.setFullName,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Full name is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Father / Guardian Name *'),
              _RoundedField(
                initialValue: state.fatherName,
                hint: 'Father or guardian name',
                icon: Icons.family_restroom_outlined,
                onChanged: notifier.setFatherName,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Father / Guardian name is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Date of Birth *'),
              _DateField(
                value: _formatDate(state.dateOfBirth),
                hint: 'Select date of birth',
                errorText: _dobError,
                onTap: () => _pickDate(
                  current: state.dateOfBirth,
                  onPicked: notifier.setDateOfBirth,
                  isDob: true,
                ),
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Gender *'),
              _DropdownField<String>(
                value: state.gender,
                hint: 'Select gender',
                icon: Icons.wc_outlined,
                items: const ['Male', 'Female', 'Other'],
                onChanged: notifier.setGender,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Gender is required' : null,
              ),
              SizedBox(height: 14.h),

              // ---------- CNIC (exactly 13 digits) ----------
              const _FieldLabel('CNIC / National ID *'),
              _RoundedField(
                initialValue: state.cnic,
                hint: '13 digits (without dashes)',
                icon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
                maxLength: 13,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: notifier.setCnic,
                validator: (v) {
                  final cnic = v?.trim() ?? '';
                  if (cnic.isEmpty) return 'CNIC is required';
                  if (!RegExp(r'^\d{13}$').hasMatch(cnic)) {
                    return 'CNIC must be exactly 13 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),

              // ---------- Phone (exactly 11 digits) ----------
              const _FieldLabel('Phone Number *'),
              _RoundedField(
                initialValue: state.phone,
                hint: '03XXXXXXXXX (11 digits)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: notifier.setPhone,
                validator: (v) {
                  final phone = v?.trim() ?? '';
                  if (phone.isEmpty) return 'Phone number is required';
                  if (!RegExp(r'^\d{11}$').hasMatch(phone)) {
                    return 'Phone number must be exactly 11 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),

              // ---------- Email (must contain @gmail.com) ----------
              const _FieldLabel('Email Address *'),
              _RoundedField(
                initialValue: state.email,
                hint: 'name@gmail.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                onChanged: notifier.setEmail,
                validator: (v) {
                  final email = v?.trim().toLowerCase() ?? '';
                  if (email.isEmpty) return 'Email is required';
                  if (!email.contains('@gmail.com')) {
                    return 'Email must contain @gmail.com';
                  }
                  if (!RegExp(r'^[\w\.\-]+@gmail\.com$').hasMatch(email)) {
                    return 'Enter a valid Gmail address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Address *'),
              _RoundedField(
                initialValue: state.address,
                hint: 'Street address',
                icon: Icons.home_outlined,
                maxLines: 2,
                onChanged: notifier.setAddress,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Address is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('City *'),
              _RoundedField(
                initialValue: state.city,
                hint: 'City',
                icon: Icons.location_city_outlined,
                onChanged: notifier.setCity,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'City is required' : null,
              ),

              SizedBox(height: 28.h),

              // ===== Job =====
              const _SectionHeader(
                title: 'Job Information',
                icon: Icons.work_outline_rounded,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Department *'),
              _RoundedField(
                initialValue: state.department,
                hint: 'e.g. Engineering',
                icon: Icons.account_tree_outlined,
                onChanged: notifier.setDepartment,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Department is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Designation *'),
              _RoundedField(
                initialValue: state.designation,
                hint: 'e.g. Software Engineer',
                icon: Icons.badge_outlined,
                onChanged: notifier.setDesignation,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Designation is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Role *'),
              _DropdownField<String>(
                value: state.role,
                hint: 'Select role',
                icon: Icons.admin_panel_settings_outlined,
                items: const [
                  'Super Admin',
                  'Admin',
                  'HR',
                  'Manager',
                  'Employee',
                ],
                onChanged: notifier.setRole,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Role is required' : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Manager *'),
              _RoundedField(
                initialValue: state.manager,
                hint: 'Manager name',
                icon: Icons.supervisor_account_outlined,
                onChanged: notifier.setManager,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Manager is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Joining Date *'),
              _DateField(
                value: _formatDate(state.joiningDate),
                hint: 'Select joining date',
                errorText: _joiningDateError,
                onTap: () => _pickDate(
                  current: state.joiningDate ?? DateTime.now(),
                  onPicked: notifier.setJoiningDate,
                  isDob: false,
                ),
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Employment Type *'),
              _DropdownField<String>(
                value: state.employmentType,
                hint: 'Select type',
                icon: Icons.business_center_outlined,
                items: const [
                  'Full Time',
                  'Part Time',
                  'Contract',
                  'Intern',
                ],
                onChanged: notifier.setEmploymentType,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Employment type is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Employee Status *'),
              _DropdownField<String>(
                value: state.employeeStatus,
                hint: 'Select status',
                icon: Icons.toggle_on_outlined,
                items: const ['Active', 'Inactive', 'On Leave'],
                onChanged: notifier.setEmployeeStatus,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Employee status is required'
                    : null,
              ),

              SizedBox(height: 28.h),

              // ===== Company =====
              const _SectionHeader(
                title: 'Company Information',
                icon: Icons.apartment_rounded,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Branch / Office *'),
              _RoundedField(
                initialValue: state.branch,
                hint: 'e.g. Head Office',
                icon: Icons.store_outlined,
                onChanged: notifier.setBranch,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Branch is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Employee Code *'),
              _RoundedField(
                initialValue: state.employeeCode,
                hint: 'Internal code',
                icon: Icons.qr_code_outlined,
                onChanged: notifier.setEmployeeCode,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Employee code is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Work Location *'),
              _RoundedField(
                initialValue: state.workLocation,
                hint: 'City / Office location',
                icon: Icons.place_outlined,
                onChanged: notifier.setWorkLocation,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Work location is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Shift *'),
              _RoundedField(
                initialValue: state.shift,
                hint: 'e.g. Morning / Night',
                icon: Icons.schedule_outlined,
                onChanged: notifier.setShift,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Shift is required' : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Reporting Manager *'),
              _RoundedField(
                initialValue: state.reportingManager,
                hint: 'Reporting manager name',
                icon: Icons.person_search_outlined,
                onChanged: notifier.setReportingManager,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Reporting manager is required'
                    : null,
              ),

              SizedBox(height: 28.h),

              // ===== Salary =====
              const _SectionHeader(
                title: 'Salary Information',
                icon: Icons.payments_outlined,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Basic Salary *'),
              _RoundedField(
                initialValue: state.basicSalary,
                hint: '0.00',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
                onChanged: notifier.setBasicSalary,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Basic salary is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Allowances *'),
              _RoundedField(
                initialValue: state.allowances,
                hint: '0.00',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                onChanged: notifier.setAllowances,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Allowances is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Salary Type *'),
              _DropdownField<String>(
                value: state.salaryType,
                hint: 'Select salary type',
                icon: Icons.calendar_month_outlined,
                items: const ['Monthly', 'Hourly'],
                onChanged: notifier.setSalaryType,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Salary type is required' : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Payment Method *'),
              _DropdownField<String>(
                value: state.paymentMethod,
                hint: 'Select payment method',
                icon: Icons.payment_outlined,
                items: const ['Bank Transfer', 'Cash', 'Cheque'],
                onChanged: notifier.setPaymentMethod,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Payment method is required'
                    : null,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Bank Account / IBAN *'),
              _RoundedField(
                initialValue: state.bankAccount,
                hint: 'PK00 XXXX XXXX XXXX XXXX',
                icon: Icons.account_balance_outlined,
                onChanged: notifier.setBankAccount,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Bank account is required'
                    : null,
              ),

              SizedBox(height: 32.h),

              // ===================== Submit Button =====================
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    gradient: AppColors.ctaGradient,
                  ),
                  child: ElevatedButton(
                    onPressed: state.isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: state.isSubmitting
                        ? SizedBox(
                      height: 22.w,
                      width: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                        AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Text(
                      'Add Employee',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                        letterSpacing: 0.3,
                      ),
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
}

// ============================================================
// UI HELPERS
// ============================================================

class _ImageSourceOption extends StatelessWidget {
  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.blue.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28.sp, color: AppColors.blue),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36.w,
          width: 36.w,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.blue, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.initialValue,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.inputFormatters,
    this.maxLength,
  });

  final String? initialValue;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.navy, fontSize: 15.sp),
      decoration: InputDecoration(
        counterText: '', // hides the "0/13" style counter
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.blue, width: 1.6.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.4.w),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.6.w),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.hint,
    required this.onTap,
    this.errorText,
  });

  final String value;
  final String hint;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: AppColors.textMuted,
                size: 20.sp,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: hasError ? Colors.redAccent : Colors.grey.shade200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: hasError ? Colors.redAccent : Colors.grey.shade200,
                  width: hasError ? 1.4.w : 1.w,
                ),
              ),
            ),
            child: Text(
              value.isEmpty ? hint : value,
              style: TextStyle(
                color: value.isEmpty ? AppColors.textMuted : AppColors.navy,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final T? value;
  final String hint;
  final IconData icon;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      validator: validator,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textMuted,
        size: 24.sp,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.blue, width: 1.6.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.4.w),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.6.w),
        ),
      ),
      hint: Text(
        hint,
        style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
          value: e,
          child: Text(
            e.toString(),
            style: TextStyle(color: AppColors.navy, fontSize: 15.sp),
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}


