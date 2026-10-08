import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../active_tab_provider/active_tab_provider.dart';
import '../../colors/colors.dart';
import '../../providers/profile_provider.dart';
import '../../route_observer.dart'; // adjust path if needed

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.showBackButton = true,
    this.isActive = false,
  });

  final bool showBackButton;
  final bool isActive;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with RouteAware {
  int _animationKey = 0;

  // This tab's index in the bottom nav (Profile = 3)
  static const int _tabIndex = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  // Fires when a screen pushed on top of this one (e.g. a future
  // "Change Password" or "Documents" screen) is popped and this
  // screen becomes visible again.
  @override
  void didPopNext() {
    _replayAnimation();
  }

  void _replayAnimation() {
    setState(() => _animationKey++);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fires every time the bottom nav sets this tab as active — even if
    // this widget instance was already alive inside the IndexedStack.
    ref.listen<int>(activeTabIndexProvider, (previous, next) {
      if (next == _tabIndex) {
        _replayAnimation();
      }
    });

    final state = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

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
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          if (!state.isEditing)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.white, size: 24.sp),
              onPressed: notifier.startEditing,
            )
          else
            TextButton(
              onPressed: notifier.cancelEditing,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        key: ValueKey(_animationKey), // forces rebuild → animation restarts
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
        children: [
          // ========== Avatar ==========
          _SlideInAnimation(
            key: ValueKey('avatar_$_animationKey'),
            index: 0,
            child: Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48.r,
                        backgroundColor: AppColors.navy.withOpacity(0.12),
                        child: Text(
                          state.fullName.isNotEmpty
                              ? state.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      if (state.isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            height: 32.h,
                            width: 32.w,
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
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    state.fullName,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    state.role,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    state.email,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 22.h),

          // ========== Personal ==========
          _SlideInAnimation(
            key: ValueKey('personal_$_animationKey'),
            index: 1,
            child: _SectionCard(
              title: 'Personal Information',
              icon: Icons.person_outline_rounded,
              children: [
                _InfoRow(
                  label: 'Employee ID',
                  value: state.employeeId,
                  readOnly: true,
                ),
                _EditableRow(
                  label: 'Full Name',
                  value: state.fullName,
                  editing: state.isEditing,
                  onChanged: notifier.setFullName,
                ),
                _EditableRow(
                  label: 'Email',
                  value: state.email,
                  editing: state.isEditing,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: notifier.setEmail,
                ),
                _EditableRow(
                  label: 'Phone',
                  value: state.phone,
                  editing: state.isEditing,
                  keyboardType: TextInputType.phone,
                  onChanged: notifier.setPhone,
                ),
                _EditableRow(
                  label: 'Address',
                  value: state.address,
                  editing: state.isEditing,
                  onChanged: notifier.setAddress,
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // ========== Job ==========
          _SlideInAnimation(
            key: ValueKey('job_$_animationKey'),
            index: 2,
            child: _SectionCard(
              title: 'Job Information',
              icon: Icons.work_outline_rounded,
              children: [
                _InfoRow(label: 'Role', value: state.role, readOnly: true),
                _EditableRow(
                  label: 'Department',
                  value: state.department,
                  editing: state.isEditing,
                  onChanged: notifier.setDepartment,
                ),
                _EditableRow(
                  label: 'Designation',
                  value: state.designation,
                  editing: state.isEditing,
                  onChanged: notifier.setDesignation,
                ),
                _InfoRow(
                  label: 'Joining Date',
                  value: state.joiningDate,
                  readOnly: true,
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // ========== Company ==========
          _SlideInAnimation(
            key: ValueKey('company_$_animationKey'),
            index: 3,
            child: _SectionCard(
              title: 'Company',
              icon: Icons.apartment_rounded,
              children: [
                _InfoRow(
                  label: 'Company',
                  value: state.companyName,
                  readOnly: true,
                ),
                _EditableRow(
                  label: 'Branch',
                  value: state.branch,
                  editing: state.isEditing,
                  onChanged: notifier.setBranch,
                ),
              ],
            ),
          ),

          // ========== Save Button ==========
          if (state.isEditing) ...[
            SizedBox(height: 24.h),
            _SlideInAnimation(
              key: ValueKey('save_$_animationKey'),
              index: 4,
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    gradient: AppColors.ctaGradient,
                  ),
                  child: ElevatedButton(
                    onPressed: state.isSaving
                        ? null
                        : () async {
                      final ok = await notifier.save();
                      if (!context.mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (ref
                          .read(profileProvider)
                          .errorMessage !=
                          null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ref.read(profileProvider).errorMessage!,
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: state.isSaving
                        ? SizedBox(
                      height: 22.h,
                      width: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                        AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
// UI HELPERS
// ============================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
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
              Icon(icon, color: AppColors.navy, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.readOnly = false,
  });

  final String label;
  final String value;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (readOnly)
            Icon(Icons.lock_outline, size: 14.sp, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.value,
    required this.editing,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String value;
  final bool editing;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return _InfoRow(label: label, value: value);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          TextFormField(
            initialValue: value,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: TextStyle(color: AppColors.navy, fontSize: 14.sp),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide:
                BorderSide(color: AppColors.blue, width: 1.4.w),
              ),
            ),
          ),
        ],
      ),
    );
  }
}