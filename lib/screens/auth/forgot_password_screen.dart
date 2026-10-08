import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetRequest() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setState(() => _isSubmitting = true);

    // TODO: replace with real "send reset link" API call.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _emailSent = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
                child: _emailSent
                    ? _SuccessState(
                  email: _emailController.text.trim(),
                  onBackToLogin: () => _goToLogin(context),
                  onResendTap: () =>
                      setState(() => _emailSent = false),
                )
                    : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Address',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      _RoundedField(
                        controller: _emailController,
                        hint: 'you@example.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          final emailRegex = RegExp(
                              r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                          if (email.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!emailRegex.hasMatch(email)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 28.h),

                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.r),
                            gradient: AppColors.ctaGradient,
                          ),
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : _handleResetRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14.r),
                              ),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                              height: 22.h,
                              width: 22.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4.w,
                                valueColor:
                                const AlwaysStoppedAnimation(
                                    Colors.white),
                              ),
                            )
                                : Text(
                              'Send Reset Link',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                                letterSpacing: 0.3.w,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remembered your password?',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14.sp,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _goToLogin(context),
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

/// Shown after the reset email has been "sent".
class _SuccessState extends StatelessWidget {
  const _SuccessState({
    required this.email,
    required this.onBackToLogin,
    required this.onResendTap,
  });

  final String email;
  final VoidCallback onBackToLogin;
  final VoidCallback onResendTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 72.h,
          width: 72.w,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.success,
            size: 34.sp,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Check your inbox',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
            color: AppColors.navy,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          email.isEmpty
              ? "We've sent a password reset link to your email."
              : "We've sent a password reset link to $email.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14.sp,
            height: 1.4,
          ),
        ),
        SizedBox(height: 28.h),

        SizedBox(
          width: double.infinity,
          height: 54.h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              gradient: AppColors.ctaGradient,
            ),
            child: ElevatedButton(
              onPressed: onBackToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'Back to Log In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  letterSpacing: 0.3.w,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),

        TextButton(
          onPressed: onResendTap,
          child: Text(
            "Didn't get the email? Try again",
            style: TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    );
  }
}

/// Curved gradient header — matches Login / Sign Up screens.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 56.h),
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forgot password?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 24.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "No worries, we'll send you reset instructions",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 32.h);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 32.h,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Reusable rounded input field — matches Login / Sign Up screens.
class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.navy, fontSize: 15.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
        suffixIcon: suffixIcon,
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