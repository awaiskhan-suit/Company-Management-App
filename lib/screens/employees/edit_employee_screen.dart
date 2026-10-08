import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/employee_list_provider.dart';

class EditEmployeeScreen extends ConsumerStatefulWidget {
  const EditEmployeeScreen({super.key, required this.employee});

  final Employee employee;

  @override
  ConsumerState<EditEmployeeScreen> createState() =>
      _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends ConsumerState<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _fatherName;
  late final TextEditingController _dateOfBirth;
  late final TextEditingController _cnic;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _department;
  late final TextEditingController _designation;
  late final TextEditingController _manager;
  late final TextEditingController _joiningDate;
  late final TextEditingController _branch;
  late final TextEditingController _employeeCode;
  late final TextEditingController _workLocation;
  late final TextEditingController _shift;
  late final TextEditingController _reportingManager;
  late final TextEditingController _basicSalary;
  late final TextEditingController _allowances;
  late final TextEditingController _bankAccount;

  // Dropdown values
  late String _gender;
  late String _role;
  late String _employmentType;
  late String _status;
  late String _salaryType;
  late String _paymentMethod;

  // Option lists (same as Add Employee)
  static const _genderOptions = ['Male', 'Female', 'Other'];
  static const _roleOptions = [
    'Super Admin',
    'Admin',
    'HR',
    'Manager',
    'Employee',
  ];
  static const _employmentTypeOptions = [
    'Full Time',
    'Part Time',
    'Contract',
    'Intern',
  ];
  static const _statusOptions = ['Active', 'Inactive', 'On Leave'];
  static const _salaryTypeOptions = ['Monthly', 'Hourly'];
  static const _paymentMethodOptions = ['Bank Transfer', 'Cash', 'Cheque'];

  String _safeOption(String value, List<String> options, String fallback) {
    return options.contains(value) ? value : fallback;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.employee;

    _name = TextEditingController(text: e.name);
    _fatherName = TextEditingController(text: e.fatherName);
    _dateOfBirth = TextEditingController(text: e.dateOfBirth);
    _cnic = TextEditingController(text: e.cnic);
    _phone = TextEditingController(text: e.phone);
    _email = TextEditingController(text: e.email);
    _address = TextEditingController(text: e.address);
    _city = TextEditingController(text: e.city);
    _department = TextEditingController(text: e.department);
    _designation = TextEditingController(text: e.designation);
    _manager = TextEditingController(text: e.manager);
    _joiningDate = TextEditingController(text: e.joiningDate);
    _branch = TextEditingController(text: e.branch);
    _employeeCode = TextEditingController(text: e.employeeCode);
    _workLocation = TextEditingController(text: e.workLocation);
    _shift = TextEditingController(text: e.shift);
    _reportingManager = TextEditingController(text: e.reportingManager);
    _basicSalary = TextEditingController(text: e.basicSalary);
    _allowances = TextEditingController(text: e.allowances);
    _bankAccount = TextEditingController(text: e.bankAccount);

    _gender = _safeOption(e.gender, _genderOptions, 'Male');
    _role = _safeOption(e.role, _roleOptions, 'Employee');
    _employmentType =
        _safeOption(e.employmentType, _employmentTypeOptions, 'Full Time');
    _status = _safeOption(e.status, _statusOptions, 'Active');
    _salaryType = _safeOption(e.salaryType, _salaryTypeOptions, 'Monthly');
    _paymentMethod =
        _safeOption(e.paymentMethod, _paymentMethodOptions, 'Bank Transfer');
  }

  @override
  void dispose() {
    _name.dispose();
    _fatherName.dispose();
    _dateOfBirth.dispose();
    _cnic.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _department.dispose();
    _designation.dispose();
    _manager.dispose();
    _joiningDate.dispose();
    _branch.dispose();
    _employeeCode.dispose();
    _workLocation.dispose();
    _shift.dispose();
    _reportingManager.dispose();
    _basicSalary.dispose();
    _allowances.dispose();
    _bankAccount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final e = widget.employee;
    final updated = Employee(
      id: e.id,
      name: _name.text.trim(),
      fatherName: _fatherName.text.trim(),
      dateOfBirth: _dateOfBirth.text.trim(),
      gender: _gender,
      cnic: _cnic.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      department: _department.text.trim(),
      designation: _designation.text.trim(),
      role: _role,
      manager: _manager.text.trim(),
      joiningDate: _joiningDate.text.trim(),
      employmentType: _employmentType,
      status: _status,
      branch: _branch.text.trim(),
      employeeCode: _employeeCode.text.trim(),
      workLocation: _workLocation.text.trim(),
      shift: _shift.text.trim(),
      reportingManager: _reportingManager.text.trim(),
      basicSalary: _basicSalary.text.trim(),
      allowances: _allowances.text.trim(),
      salaryType: _salaryType,
      paymentMethod: _paymentMethod,
      bankAccount: _bankAccount.text.trim(),
      imagePath: e.imagePath,
      createdAt: e.createdAt,
    );

    try {
      await ref.read(employeeListProvider.notifier).updateEmployee(updated);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Employee updated successfully'),
          backgroundColor: AppColors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (err) {
      if (!mounted) return;
      final msg = err.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $msg'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.ctaGradient),
        ),
        leading: IconButton(
          icon:
          Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Employee',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // ==================== PERSONAL ====================
            _sectionTitle('Personal Information'),
            _editField('Full Name', _name, Icons.person_outline),
            SizedBox(height: 12.h),
            _editField(
                'Father / Guardian Name', _fatherName, Icons.family_restroom),
            SizedBox(height: 12.h),
            _editField('Date of Birth', _dateOfBirth, Icons.cake_outlined),
            SizedBox(height: 12.h),
            _dropdownField(
              label: 'Gender',
              value: _gender,
              items: _genderOptions,
              onChanged: (v) => setState(() => _gender = v!),
            ),
            SizedBox(height: 12.h),
            _editField('CNIC', _cnic, Icons.credit_card_outlined),
            SizedBox(height: 12.h),
            _editField('Phone', _phone, Icons.phone_outlined,
                keyboard: TextInputType.phone),
            SizedBox(height: 12.h),
            _editField('Email', _email, Icons.mail_outline,
                keyboard: TextInputType.emailAddress),
            SizedBox(height: 12.h),
            _editField('Address', _address, Icons.home_outlined),
            SizedBox(height: 12.h),
            _editField('City', _city, Icons.location_city_outlined),

            SizedBox(height: 24.h),

            // ==================== JOB ====================
            _sectionTitle('Job Information'),
            _editField('Department', _department, Icons.business_outlined),
            SizedBox(height: 12.h),
            _editField('Designation', _designation, Icons.badge_outlined),
            SizedBox(height: 12.h),
            _dropdownField(
              label: 'Role',
              value: _role,
              items: _roleOptions,
              onChanged: (v) => setState(() => _role = v!),
            ),
            SizedBox(height: 12.h),
            _editField('Manager', _manager, Icons.supervisor_account_outlined),
            SizedBox(height: 12.h),
            _editField(
                'Joining Date', _joiningDate, Icons.calendar_month_outlined),
            SizedBox(height: 12.h),
            _dropdownField(
              label: 'Employment Type',
              value: _employmentType,
              items: _employmentTypeOptions,
              onChanged: (v) => setState(() => _employmentType = v!),
            ),
            SizedBox(height: 12.h),
            _dropdownField(
              label: 'Status',
              value: _status,
              items: _statusOptions,
              onChanged: (v) => setState(() => _status = v!),
            ),

            SizedBox(height: 24.h),

            // ==================== COMPANY ====================
            _sectionTitle('Company Information'),
            _editField('Branch / Office', _branch, Icons.store_outlined),
            SizedBox(height: 12.h),
            _editField('Employee Code', _employeeCode, Icons.qr_code_outlined),
            SizedBox(height: 12.h),
            _editField('Work Location', _workLocation, Icons.place_outlined),
            SizedBox(height: 12.h),
            _editField('Shift', _shift, Icons.schedule_outlined),
            SizedBox(height: 12.h),
            _editField('Reporting Manager', _reportingManager,
                Icons.person_search_outlined),

            SizedBox(height: 24.h),

            // ==================== SALARY ====================
            _sectionTitle('Salary Information'),
            _editField('Basic Salary', _basicSalary, Icons.attach_money,
                keyboard: TextInputType.number),
            SizedBox(height: 12.h),
            _editField('Allowances', _allowances,
                Icons.account_balance_wallet_outlined),
            SizedBox(height: 12.h),
            _dropdownField(
              label: 'Salary Type',
              value: _salaryType,
              items: _salaryTypeOptions,
              onChanged: (v) => setState(() => _salaryType = v!),
            ),
            SizedBox(height: 12.h),
            _dropdownField(
              label: 'Payment Method',
              value: _paymentMethod,
              items: _paymentMethodOptions,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            SizedBox(height: 12.h),
            _editField('Bank Account / IBAN', _bankAccount,
                Icons.account_balance_outlined),

            SizedBox(height: 32.h),

            // Save button
            SizedBox(
              height: 52.h,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                  height: 22.w,
                  width: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'Save Changes',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),

            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _editField(
      String label,
      TextEditingController controller,
      IconData icon, {
        TextInputType? keyboard,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: (v) {
            if (label == 'Full Name' ||
                label == 'Phone' ||
                label == 'Email' ||
                label == 'Department') {
              return (v == null || v.trim().isEmpty)
                  ? '$label is required'
                  : null;
            }
            return null;
          },
          style: TextStyle(color: AppColors.navy, fontSize: 15.sp),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
            filled: true,
            fillColor: Colors.white,
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
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: AppColors.blue, width: 1.6.w),
            ),
          ),
        ),
      ],
    );
  }
}
