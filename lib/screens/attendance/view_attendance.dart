import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  String _selectedPeriod = 'Today';
  String _selectedDepartment = 'All Departments';
  String _selectedStatus = 'All Status';

  final TextEditingController _searchController = TextEditingController();

  final List<AttendanceRecord> _records = [
    AttendanceRecord(
      employeeId: 'A001',
      employeeName: 'Ali Khan',
      department: 'IT',
      date: '23 Sep 2026',
      checkIn: '09:05 AM',
      checkOut: '05:10 PM',
      workingHours: '8h 05m',
      status: 'Late',
      lateMinutes: 5,
      overtimeHours: '10m',
    ),
    AttendanceRecord(
      employeeId: 'A002',
      employeeName: 'Ahmed Khan',
      department: 'HR',
      date: '23 Sep 2026',
      checkIn: '08:55 AM',
      checkOut: '05:00 PM',
      workingHours: '8h 05m',
      status: 'Present',
      lateMinutes: 0,
      overtimeHours: '05m',
    ),
    AttendanceRecord(
      employeeId: 'A003',
      employeeName: 'Sara Ahmed',
      department: 'Finance',
      date: '23 Sep 2026',
      checkIn: '09:15 AM',
      checkOut: '05:20 PM',
      workingHours: '8h 05m',
      status: 'Late',
      lateMinutes: 15,
      overtimeHours: '20m',
    ),
    AttendanceRecord(
      employeeId: 'A004',
      employeeName: 'Usman Ali',
      department: 'Management',
      date: '23 Sep 2026',
      checkIn: '--',
      checkOut: '--',
      workingHours: '--',
      status: 'Absent',
      lateMinutes: 0,
      overtimeHours: '--',
    ),
    AttendanceRecord(
      employeeId: 'A005',
      employeeName: 'Ayesha Malik',
      department: 'Design',
      date: '23 Sep 2026',
      checkIn: '08:50 AM',
      checkOut: '05:05 PM',
      workingHours: '8h 15m',
      status: 'Present',
      lateMinutes: 0,
      overtimeHours: '15m',
    ),
    AttendanceRecord(
      employeeId: 'A006',
      employeeName: 'Hamza Shah',
      department: 'Finance',
      date: '23 Sep 2026',
      checkIn: '--',
      checkOut: '--',
      workingHours: '--',
      status: 'On Leave',
      lateMinutes: 0,
      overtimeHours: '--',
    ),
    AttendanceRecord(
      employeeId: 'A007',
      employeeName: 'Bilal Ahmad',
      department: 'IT',
      date: '23 Sep 2026',
      checkIn: '08:45 AM',
      checkOut: '05:30 PM',
      workingHours: '8h 45m',
      status: 'Present',
      lateMinutes: 0,
      overtimeHours: '30m',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AttendanceRecord> get _filteredRecords {
    final query = _searchController.text.toLowerCase().trim();

    return _records.where((record) {
      final matchesSearch =
          record.employeeName.toLowerCase().contains(query) ||
              record.employeeId.toLowerCase().contains(query) ||
              record.department.toLowerCase().contains(query);

      final matchesDepartment =
          _selectedDepartment == 'All Departments' ||
              record.department == _selectedDepartment;

      final matchesStatus =
          _selectedStatus == 'All Status' ||
              record.status == _selectedStatus;

      return matchesSearch && matchesDepartment && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.ctaGradient,
          ),
        ),
        title: Text(
          'Attendance Report',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 30.h),
                children: [
                  _buildSummarySection(),
                  SizedBox(height: 22.h),
                  _buildDateSelector(),
                  SizedBox(height: 18.h),
                  _buildSearchAndFilters(),
                  SizedBox(height: 22.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Attendance Records',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${records.length} records',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  if (records.isEmpty)
                    _buildEmptyState()
                  else
                    ...records.asMap().entries.map(
                          (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 14.h),
                        child: _SlideInAnimation(
                          key: ValueKey(entry.value.employeeId),
                          index: entry.key,
                          child: _AttendanceCard(
                            record: entry.value,
                            onTap: () =>
                                _showAttendanceDetails(entry.value),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.ctaGradient,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.18),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Attendance Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'Monitor employee attendance and working hours',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final summaryItems = [
      _SummaryCard(
        title: 'Total Employees',
        targetValue: 120,
        icon: Icons.people_alt_rounded,
        iconColor: AppColors.blue,
      ),
      _SummaryCard(
        title: 'Present',
        targetValue: 95,
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
      ),
      _SummaryCard(
        title: 'Absent',
        targetValue: 10,
        icon: Icons.cancel_rounded,
        iconColor: Colors.red,
      ),
      _SummaryCard(
        title: 'Late',
        targetValue: 5,
        icon: Icons.schedule_rounded,
        iconColor: Colors.orange,
      ),
      _SummaryCard(
        title: 'On Leave',
        targetValue: 10,
        icon: Icons.event_busy_rounded,
        iconColor: Colors.purple,
      ),
      _SummaryCard(
        title: 'Attendance',
        targetValue: 79.2,
        suffix: '%',
        decimalPlaces: 1,
        icon: Icons.analytics_rounded,
        iconColor: AppColors.teal,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.65,
      children: summaryItems
          .asMap()
          .entries
          .map(
            (entry) => _SlideInAnimation(
          key: ValueKey('summary_${entry.key}'),
          index: entry.key,
          child: entry.value,
        ),
      )
          .toList(),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 42.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _PeriodChip(
                title: 'Today',
                selected: _selectedPeriod == 'Today',
                onTap: () => setState(() => _selectedPeriod = 'Today'),
              ),
              _PeriodChip(
                title: 'Yesterday',
                selected: _selectedPeriod == 'Yesterday',
                onTap: () => setState(() => _selectedPeriod = 'Yesterday'),
              ),
              _PeriodChip(
                title: 'This Week',
                selected: _selectedPeriod == 'This Week',
                onTap: () => setState(() => _selectedPeriod = 'This Week'),
              ),
              _PeriodChip(
                title: 'This Month',
                selected: _selectedPeriod == 'This Month',
                onTap: () => setState(() => _selectedPeriod = 'This Month'),
              ),
              _PeriodChip(
                title: 'Custom',
                selected: _selectedPeriod == 'Custom',
                icon: Icons.date_range_rounded,
                onTap: _selectCustomDate,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search employee, ID or department...',
            hintStyle: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 22.sp,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              icon: Icon(Icons.close_rounded, size: 20.sp),
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                value: _selectedDepartment,
                items: const [
                  'All Departments',
                  'IT',
                  'HR',
                  'Finance',
                  'Management',
                  'Design',
                ],
                icon: Icons.business_rounded,
                onChanged: (value) {
                  setState(() => _selectedDepartment = value);
                },
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _FilterDropdown(
                value: _selectedStatus,
                items: const [
                  'All Status',
                  'Present',
                  'Absent',
                  'Late',
                  'On Leave',
                  'Half Day',
                  'Holiday',
                  'Weekend',
                ],
                icon: Icons.filter_alt_rounded,
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectCustomDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _selectedPeriod = 'Custom');
    }
  }

  void _showAttendanceDetails(AttendanceRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceDetailsScreen(record: record),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 55.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 50.sp,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12.h),
          Text(
            'No attendance records found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'Try changing your search or filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SLIDE-IN ANIMATION
// ============================================================

class _SlideInAnimation extends StatefulWidget {
  final Widget child;
  final int index;

  const _SlideInAnimation({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<_SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<_SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    Future.delayed(Duration(milliseconds: 150 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}

// ============================================================
// ATTENDANCE CARD
// ============================================================

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onTap;

  const _AttendanceCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: AppColors.blue.withOpacity(0.10),
                    child: Text(
                      record.employeeName
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join(),
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          record.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          '${record.employeeId} • ${record.department}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _StatusBadge(status: record.status),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TimeItem(
                        icon: Icons.login_rounded,
                        title: 'Check In',
                        value: record.checkIn,
                      ),
                    ),
                    Container(
                      width: 1.w,
                      height: 35.h,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _TimeItem(
                        icon: Icons.logout_rounded,
                        title: 'Check Out',
                        value: record.checkOut,
                      ),
                    ),
                    Container(
                      width: 1.w,
                      height: 35.h,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _TimeItem(
                        icon: Icons.timer_outlined,
                        title: 'Hours',
                        value: record.workingHours,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14.sp,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    record.date,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    record.lateMinutes > 0
                        ? '${record.lateMinutes} min late'
                        : 'On time',
                    style: TextStyle(
                      color: record.lateMinutes > 0
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12.sp,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatefulWidget {
  final String title;
  final double targetValue;
  final IconData icon;
  final Color iconColor;
  final String suffix;
  final int decimalPlaces;

  const _SummaryCard({
    required this.title,
    required this.targetValue,
    required this.icon,
    required this.iconColor,
    this.suffix = '',
    this.decimalPlaces = 0,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _countAnimation = Tween<double>(
      begin: 0,
      end: widget.targetValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: widget.iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              widget.icon,
              color: widget.iconColor,
              size: 21.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _countAnimation,
                  builder: (context, child) {
                    return Text(
                      '${_countAnimation.value.toStringAsFixed(widget.decimalPlaces)}${widget.suffix}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
                SizedBox(height: 2.h),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PERIOD CHIP
// ============================================================

class _PeriodChip extends StatelessWidget {
  final String title;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.title,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? AppColors.blue : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15.sp,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
                SizedBox(width: 6.w),
              ],
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textMuted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
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
// FILTER DROPDOWN
// ============================================================

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
            size: 22.sp,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 16.sp, color: AppColors.textMuted),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

// ============================================================
// TIME ITEM
// ============================================================

class _TimeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _TimeItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: AppColors.blue),
        SizedBox(height: 4.h),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STATUS BADGE
// ============================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status) {
      case 'Present':
        color = Colors.green;
        break;
      case 'Late':
        color = Colors.orange;
        break;
      case 'Absent':
        color = Colors.red;
        break;
      case 'On Leave':
        color = Colors.purple;
        break;
      case 'Half Day':
        color = Colors.blue;
        break;
      case 'Holiday':
        color = Colors.teal;
        break;
      case 'Weekend':
        color = Colors.grey;
        break;
      default:
        color = AppColors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// ATTENDANCE DETAILS SCREEN
// ============================================================

class AttendanceDetailsScreen extends StatelessWidget {
  final AttendanceRecord record;

  const AttendanceDetailsScreen({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.ctaGradient,
          ),
        ),
        title: Text(
          'Attendance Report',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEmployeeHeader(),
              SizedBox(height: 20.h),
              _buildAttendanceSummary(),
              SizedBox(height: 20.h),
              _buildAttendanceInformation(),
              SizedBox(height: 20.h),
              _buildReportStatistics(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.ctaGradient,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Text(
              record.employeeName
                  .split(' ')
                  .map((e) => e[0])
                  .take(2)
                  .join(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  record.employeeId,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  record.department,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return Row(
      children: [
        Expanded(
          child: _DetailSummary(
            title: 'Status',
            value: record.status,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _DetailSummary(
            title: 'Late',
            value: '${record.lateMinutes} min',
            icon: Icons.schedule_rounded,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _DetailSummary(
            title: 'Overtime',
            value: record.overtimeHours,
            icon: Icons.more_time_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceInformation() {
    return _WhiteSection(
      title: 'Attendance Information',
      icon: Icons.access_time_filled_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InfoRow(
            title: 'Date',
            value: record.date,
            icon: Icons.calendar_today_rounded,
          ),
          _InfoRow(
            title: 'Check In',
            value: record.checkIn,
            icon: Icons.login_rounded,
          ),
          _InfoRow(
            title: 'Check Out',
            value: record.checkOut,
            icon: Icons.logout_rounded,
          ),
          _InfoRow(
            title: 'Working Hours',
            value: record.workingHours,
            icon: Icons.timer_rounded,
          ),
          _InfoRow(
            title: 'Late Minutes',
            value: '${record.lateMinutes} minutes',
            icon: Icons.warning_amber_rounded,
          ),
          _InfoRow(
            title: 'Overtime',
            value: record.overtimeHours,
            icon: Icons.more_time_rounded,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildReportStatistics() {
    return _WhiteSection(
      title: 'Report Statistics',
      icon: Icons.analytics_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatisticRow(title: 'Attendance Percentage', value: '92%'),
          _StatisticRow(title: 'Present Days', value: '22'),
          _StatisticRow(title: 'Absent Days', value: '2'),
          _StatisticRow(title: 'Late Days', value: '3'),
          _StatisticRow(title: 'Leave Days', value: '1'),
          _StatisticRow(title: 'Total Working Hours', value: '176h 30m'),
          _StatisticRow(
            title: 'Total Overtime',
            value: '8h 20m',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DETAIL SUMMARY
// ============================================================

class _DetailSummary extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DetailSummary({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.blue, size: 21.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WHITE SECTION
// ============================================================

class _WhiteSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _WhiteSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool showDivider;

  const _InfoRow({
    required this.title,
    required this.value,
    required this.icon,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              Icon(icon, size: 18.sp, color: AppColors.textMuted),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1.h, color: Colors.grey.shade200),
      ],
    );
  }
}

// ============================================================
// STATISTIC ROW
// ============================================================

class _StatisticRow extends StatelessWidget {
  final String title;
  final String value;
  final bool showDivider;

  const _StatisticRow({
    required this.title,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1.h, color: Colors.grey.shade200),
      ],
    );
  }
}

// ============================================================
// MODEL
// ============================================================

class AttendanceRecord {
  final String employeeId;
  final String employeeName;
  final String department;
  final String date;
  final String checkIn;
  final String checkOut;
  final String workingHours;
  final String status;
  final int lateMinutes;
  final String overtimeHours;

  AttendanceRecord({
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.workingHours,
    required this.status,
    required this.lateMinutes,
    required this.overtimeHours,
  });
}