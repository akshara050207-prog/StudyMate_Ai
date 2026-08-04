import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../main_navigation_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final PreAuthData preAuthData;
  final String password;
  final bool isPhoneAuth;

  const OtpVerificationScreen({
    super.key,
    required this.preAuthData,
    required this.password,
    this.isPhoneAuth = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    if (widget.isPhoneAuth && widget.preAuthData.generatedOtpCode != null) {
      _otpController.text = widget.preAuthData.generatedOtpCode!;
    }
  }

  void _resendAction() async {
    setState(() => _isResending = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    if (widget.isPhoneAuth) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          widget.preAuthData.generatedOtpCode = "654321";
          _otpController.text = "654321";
          _isResending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("A new 6-digit OTP code has been sent to your mobile number: 654321"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else {
      await auth.sendFirebaseEmailVerification(widget.preAuthData.email, widget.password);
      if (mounted) {
        setState(() => _isResending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("A fresh verification link has been sent to your Gmail: ${widget.preAuthData.email}"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _verifyAndProceed() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    bool success = false;

    if (widget.isPhoneAuth) {
      final code = _otpController.text.trim();
      if (code.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter the complete 6-digit OTP code.")),
        );
        return;
      }
      success = await auth.loginWithPhone(widget.preAuthData.phoneNumber ?? "phone_user", code);
    } else {
      success = await auth.verifyAndCompleteFirebaseLogin(
        widget.preAuthData.email,
        widget.password,
      );
    }

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification unsuccessful. Please try again or check your Gmail inbox link."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);
    final displayContact = widget.isPhoneAuth
        ? (widget.preAuthData.phoneNumber ?? 'your Mobile Number')
        : widget.preAuthData.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPhoneAuth ? "Phone OTP Verification" : "Gmail Verification",
          style: AppTypography.headingMedium(isDark: isDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.isPhoneAuth ? LucideIcons.phoneCall : LucideIcons.mailCheck,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isPhoneAuth ? "OTP Code Sent" : "Verification Link Sent",
                            style: AppTypography.headingSmall(isDark: isDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayContact,
                            style: AppTypography.caption(isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (widget.isPhoneAuth) ...[
                Text("Enter 6-Digit Phone OTP", style: AppTypography.headingSmall(isDark: isDark)),
                const SizedBox(height: 6),
                Text(
                  "Enter the 6-digit security code sent to $displayContact.",
                  style: AppTypography.bodyMedium(isDark: isDark),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: "000000",
                    hintStyle: const TextStyle(letterSpacing: 4, fontSize: 20, color: Colors.grey),
                    counterText: "",
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text("Verify Your Gmail Account", style: AppTypography.headingSmall(isDark: isDark)),
                const SizedBox(height: 8),
                Text(
                  "We have sent an official verification link to $displayContact.",
                  style: AppTypography.bodyMedium(isDark: isDark),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Steps to complete:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("1. Open your Gmail inbox.", style: AppTypography.caption(isDark: isDark)),
                      Text("2. Click on the verification link sent by StudyMate AI.", style: AppTypography.caption(isDark: isDark)),
                      Text("3. Return here and tap 'I've Verified My Gmail'.", style: AppTypography.caption(isDark: isDark)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              CustomButton(
                text: widget.isPhoneAuth ? "Verify & Enter StudyMate" : "I've Verified My Gmail",
                icon: LucideIcons.checkCircle2,
                isLoading: auth.isLoading,
                onPressed: _verifyAndProceed,
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton.icon(
                  onPressed: _isResending ? null : _resendAction,
                  icon: const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.primary),
                  label: Text(
                    _isResending
                        ? "Resending..."
                        : (widget.isPhoneAuth ? "Resend OTP Code" : "Resend Link to Gmail"),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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
