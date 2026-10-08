import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/department_provider.dart';

class AddDepartmentScreen extends ConsumerStatefulWidget {
  final Department? department; // null = Add, not null = Edit

  const AddDepartmentScreen({super.key, this.department});

  @override
  ConsumerState<AddDepartmentScreen> createState() =>
      _AddDepartmentScreenState();
}

class _AddDepartmentScreenState extends ConsumerState<AddDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final branchController = TextEditingController();
  final floorController = TextEditingController();
  final managerController = TextEditingController();
  final employeeCountController = TextEditingController();

  String selectedType = 'HR';
  String selectedStatus = 'Active';
  String? selectedManagerId;
  String? selectedManagerName;

  final List<String> departmentTypes = [
    'HR',
    'IT',
    'Finance',
    'Operations',
    'Marketing',
    'Sales',
    'Support',
    'Other',
  ];

  final List<String> statusList = ['Active', 'Inactive'];

  bool get isEditing => widget.department != null;



  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final d = widget.department!;
      codeController.text = d.code;
      nameController.text = d.name;
      descriptionController.text = d.description;
      // guard: a dropdown value that is not in its list crashes the screen
      selectedType = departmentTypes.contains(d.type) ? d.type : 'Other';
      branchController.text = d.branch;
      floorController.text = d.floor ?? '';
      selectedStatus = statusList.contains(d.status) ? d.status : 'Active';
      selectedManagerId = d.managerId;
      selectedManagerName = d.managerName;
      managerController.text = d.managerName ?? '';
      employeeCountController.text = (d.employeeCount).toString();
    } else {
      // Optional: still generate a suggested code for new departments
      _generateCode();
      employeeCountController.text = '0';
    }
  }

  void _generateCode() {
    final code =
    ref.read(departmentNotifierProvider.notifier).generateNextCode();
    codeController.text = code;
  }

  /// Returns true if the code is already used by another department.
  bool _isCodeTaken(String code) {
    final list = ref.read(departmentListProvider).maybeWhen(
      data: (l) => l,
      orElse: () => const <Department>[],
    );

    final normalized = code.trim().toLowerCase();

    return list.any((d) {
      // When editing, allow keeping the same code for the current department
      if (isEditing && d.id == widget.department!.id) return false;
      return d.code.trim().toLowerCase() == normalized;
    });
  }

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    branchController.dispose();
    floorController.dispose();
    managerController.dispose();
    employeeCountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final code = codeController.text.trim();

    // Extra safety check for uniqueness
    if (_isCodeTaken(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department code already exists. Please use a unique code.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final employeeCount =
        int.tryParse(employeeCountController.text.trim()) ?? 0;

    final department = Department(
      id: widget.department?.id ?? '',
      code: code,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      type: selectedType,
      managerId: selectedManagerId,
      managerName: selectedManagerName,
      branch: branchController.text.trim(),
      floor: floorController.text.trim().isEmpty
          ? null
          : floorController.text.trim(),
      status: selectedStatus,
      employeeCount: employeeCount,
      createdAt: widget.department?.createdAt ?? DateTime.now(),
    );

    final notifier = ref.read(departmentNotifierProvider.notifier);
    bool success;

    // Both calls go through the API first (internet required)
    if (isEditing) {
      success =
      await notifier.updateDepartment(widget.department!.id, department);
    } else {
      success = await notifier.addDepartment(department);
    }

    if (!mounted) return;

    if (success) {
      final deptName = nameController.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? '$deptName updated successfully'
                : '$deptName added successfully',
          ),
          backgroundColor: isEditing ? Colors.blue : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }else {
      final err = ref.read(departmentNotifierProvider).error;
      final msg = err?.toString().replaceFirst('Exception: ', '') ??
          'Something went wrong';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(departmentNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
          isEditing ? 'Edit Department' : 'Add Department',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ===================== DEPARTMENT INFORMATION =====================
                _sectionCard(
                  title: 'Department Information',
                  icon: Icons.apartment_rounded,
                  children: [
                    // Department Code (editable + unique)
                    _buildTextField(
                      controller: codeController,
                      label: 'Department Code',
                      hint: 'e.g. DEP-001',
                      icon: Icons.tag,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter department code';
                        }
                        if (_isCodeTaken(v.trim())) {
                          return 'This code is already used. Enter a unique code.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),

                    // Department Name
                    _buildTextField(
                      controller: nameController,
                      label: 'Department Name',
                      hint: 'e.g. Human Resources',
                      icon: Icons.business_center_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter department name'
                          : null,
                    ),
                    SizedBox(height: 12.h),

                    // Description
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Description',
                      hint: 'What is this department responsible for?',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    SizedBox(height: 12.h),

                    // Department Type
                    _buildDropdown(
                      label: 'Department Type',
                      value: selectedType,
                      items: departmentTypes,
                      icon: Icons.category_outlined,
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // ===================== MANAGEMENT =====================
                _sectionCard(
                  title: 'Management',
                  icon: Icons.manage_accounts_rounded,
                  children: [
                    _buildTextField(
                      controller: managerController,
                      label: 'Department Head / Manager',
                      hint: 'Select or enter manager name',
                      icon: Icons.person_outline,
                      onChanged: (v) =>
                      selectedManagerName = v.trim().isEmpty ? null : v,
                    ),
                    SizedBox(height: 12.h),

                    // Total Employees field
                    _buildTextField(
                      controller: employeeCountController,
                      label: 'Total Employees',
                      hint: 'e.g. 25',
                      icon: Icons.people_outline,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter number of employees';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // ===================== LOCATION =====================
                _sectionCard(
                  title: 'Location',
                  icon: Icons.location_on_outlined,
                  children: [
                    _buildTextField(
                      controller: branchController,
                      label: 'Branch / Office',
                      hint: 'e.g. Head Office, Lahore Branch',
                      icon: Icons.storefront_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter branch/office'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: floorController,
                      label: 'Floor / Office Location (optional)',
                      hint: 'e.g. 2nd Floor, Room 204',
                      icon: Icons.layers_outlined,
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // ===================== STATUS =====================
                _sectionCard(
                  title: 'Status',
                  icon: Icons.toggle_on_outlined,
                  children: [
                    _buildDropdown(
                      label: 'Status',
                      value: selectedStatus,
                      items: statusList,
                      icon: Icons.check_circle_outline,
                      onChanged: (v) => setState(() => selectedStatus = v!),
                    ),
                  ],
                ),

                SizedBox(height: 28.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      gradient: AppColors.ctaGradient,
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),

                      child: isLoading
                          ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                          AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                          : Text(
                        isEditing
                            ? 'Update Department'
                            : 'Save Department',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E6EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0F4C81), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C2733),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20.sp, color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFFF4F6F9),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 14.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFE2E6EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: const Color(0xFF0F4C81), width: 1.6.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.2.w),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.6.w),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.grey.shade600,
        size: 24.sp,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.sp, color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFFF4F6F9),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 14.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFE2E6EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: const Color(0xFF0F4C81), width: 1.6.w),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              fontSize: 14.5.sp,
              color: const Color(0xFF1C2733),
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}

