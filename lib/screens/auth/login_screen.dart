import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_button.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  void _showGmailModal(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.mail, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Enter Your Gmail",
                        style: AppTypography.headingMedium(isDark: isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We will dispatch an official verification link to your Gmail inbox.",
                    style: AppTypography.bodySmall(isDark: isDark),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: "Gmail Address",
                      labelStyle: TextStyle(color: isDark ? AppColors.primaryLight : AppColors.primary, fontWeight: FontWeight.w600),
                      hintText: "your.email@gmail.com",
                      hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                      prefixIcon: const Icon(LucideIcons.mail, color: AppColors.primary),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primarySubtle,
                          width: 2.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: isDark ? AppColors.primaryLight : AppColors.primary, fontWeight: FontWeight.w600),
                      prefixIcon: const Icon(LucideIcons.lock, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: Colors.grey,
                        ),
                        onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primarySubtle,
                          width: 2.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: "Send Verification Link",
                    icon: LucideIcons.send,
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (!email.contains("@")) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter a valid Gmail address."),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (password.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Password must be at least 6 characters."),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      _processGmailLogin(email, password);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPhoneModal(BuildContext context) {
    final phoneController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.phone, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Enter Mobile Number",
                    style: AppTypography.headingMedium(isDark: isDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "We will send a 6-digit OTP code to your phone number.",
                style: AppTypography.bodySmall(isDark: isDark),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: TextStyle(color: isDark ? AppColors.primaryLight : AppColors.primary, fontWeight: FontWeight.w600),
                  hintText: "+91 9876543210",
                  hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  prefixIcon: const Icon(LucideIcons.phone, color: AppColors.primary),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primarySubtle,
                      width: 2.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: "Send OTP Code",
                icon: LucideIcons.messageSquareCode,
                onPressed: () {
                  final phone = phoneController.text.trim();
                  if (phone.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a valid phone number."),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  _processPhoneLogin(phone);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _processGmailLogin(String email, String password) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final preAuthData = await auth.sendFirebaseEmailVerification(email, password);

    if (mounted && preAuthData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            preAuthData: preAuthData,
            password: password,
            isPhoneAuth: false,
          ),
        ),
      );
    }
  }

  void _processPhoneLogin(String phone) async {
    final preAuthData = PreAuthData(
      tempAuthToken: "phone_${DateTime.now().millisecondsSinceEpoch}",
      email: "$phone@phone.user",
      emailVerificationSent: false,
      phoneNumber: phone,
      generatedOtpCode: "123456",
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            preAuthData: preAuthData,
            password: "",
            isPhoneAuth: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.primary,
                      child: const Icon(LucideIcons.sparkles, size: 48, color: Colors.white),
                    ),
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 28),

              // App Title (3 words subtitle removed completely!)
              Text(
                "StudyMate AI",
                textAlign: TextAlign.center,
                style: AppTypography.headingLarge(isDark: isDark).copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),

              // Primary Action 1: Continue with Gmail
              CustomButton(
                text: "Continue with Gmail",
                icon: LucideIcons.mail,
                isLoading: auth.isLoading,
                onPressed: () => _showGmailModal(context),
              ),
              const SizedBox(height: 16),

              // Primary Action 2: Continue with Phone Number
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1.5),
                ),
                icon: const Icon(LucideIcons.phone, color: AppColors.primary, size: 20),
                label: Text(
                  "Continue with Phone Number",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onPressed: () => _showPhoneModal(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
