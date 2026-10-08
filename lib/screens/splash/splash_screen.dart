
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../colors/colors.dart';

class SplashScreen extends StatefulWidget {
const SplashScreen({super.key});

@override
State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
with SingleTickerProviderStateMixin {
late final AnimationController _controller = AnimationController(
duration: const Duration(milliseconds: 1100),
vsync: this,
);

late final Animation<double> _logoScale = CurvedAnimation(
parent: _controller,
curve: const Interval(
0.0,
0.7,
curve: Curves.easeOutBack,
),
);

late final Animation<double> _logoFade = CurvedAnimation(
parent: _controller,
curve: const Interval(
0.0,
0.5,
curve: Curves.easeOut,
),
);

late final Animation<double> _textFade = CurvedAnimation(
parent: _controller,
curve: const Interval(
0.35,
0.85,
curve: Curves.easeOut,
),
);

late final Animation<Offset> _textSlide = Tween<Offset>(
begin: const Offset(0, 0.15),
end: Offset.zero,
).animate(
CurvedAnimation(
parent: _controller,
curve: const Interval(
0.35,
0.85,
curve: Curves.easeOut,
),
),
);

Timer? _navigationTimer;

@override
void initState() {
super.initState();

// Start splash animation
_controller.forward();

// Navigate after splash duration
_navigationTimer = Timer(
const Duration(milliseconds: 2400),
_goToSignUp,
);
}

void _goToSignUp() {
if (!mounted) return;

// Use GoRouter instead of Navigator.pushReplacement
context.go('/sign-up');
}

@override
void dispose() {
_navigationTimer?.cancel();
_controller.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: DecoratedBox(
decoration: const BoxDecoration(
gradient: AppColors.brandGradient,
),
child: SafeArea(
child: Column(
children: [
Expanded(
child: Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
// Logo
FadeTransition(
opacity: _logoFade,
child: ScaleTransition(
scale: _logoScale,
child: Container(
height: 140.r,
width: 140.r,
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(
color: Colors.white.withOpacity(0.35),
width: 2.w,
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.18),
blurRadius: 20.r,
offset: Offset(0, 10.h),
),
],
),
child: ClipOval(
child: Image(
image: const AssetImage(
'assets/images/images.jpg',
),
fit: BoxFit.cover,
width: 140.r,
height: 140.r,
),
),
),
),
),

SizedBox(height: 32.h),

// Wordmark + location
FadeTransition(
opacity: _textFade,
child: SlideTransition(
position: _textSlide,
child: Column(
children: [
Text(
'SECTION SOFT',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white,
fontWeight: FontWeight.w700,
fontSize: 26.sp,
letterSpacing: 3.w,
),
),
SizedBox(height: 8.h),
Text(
'PESHAWAR',
textAlign: TextAlign.center,
style: TextStyle(
color: AppColors.teal,
fontWeight: FontWeight.w600,
fontSize: 13.sp,
letterSpacing: 4.w,
),
),
],
),
),
),
],
),
),
),

// Loading indicator
FadeTransition(
opacity: _textFade,
child: SizedBox(
width: 28.r,
height: 28.r,
child: CircularProgressIndicator(
strokeWidth: 2.5.w,
valueColor: AlwaysStoppedAnimation<Color>(
AppColors.teal.withOpacity(0.9),
),
),
),
),

SizedBox(height: 40.h),
],
),
),
),
);
}
}

