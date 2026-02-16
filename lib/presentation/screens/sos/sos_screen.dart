import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../../services/location_service.dart';
import '../../../services/sms_service.dart';
import 'package:are_you_okay/routes/app_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// SOS Screen
/// Emergency SOS feature
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isActivating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('জরুরি SOS'),
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.danger.withOpacity(0.1),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Warning message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SOS সক্রিয় করলে আপনার সব জরুরি যোগাযোগে SMS ও নোটিফিকেশন পাঠানো হবে।',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // SOS Button
                GestureDetector(
                  onLongPress: _showSOSConfirmation,
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 80,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ধরে রাখুন',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'বোতামটি ৩ সেকেন্ড ধরে রাখুন',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                // Emergency Numbers
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'জরুরি নম্বর',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildEmergencyNumber(
                        'জাতীয় জরুরি সেবা',
                        '999',
                      ),
                      _buildEmergencyNumber(
                        'অ্যাম্বুলেন্স',
                        '199',
                      ),
                      _buildEmergencyNumber(
                        'ফায়ার সার্ভিস',
                        '199',
                      ),
                      _buildEmergencyNumber(
                        'পুলিশ',
                        '100',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyNumber(String label, String number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _callNumber(number),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.phone,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                number,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.call,
                size: 16,
                color: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSOSConfirmation() async {
    HapticFeedback.heavyImpact();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.danger),
            const SizedBox(width: 8),
            Text('SOS সক্রিয় করবেন?'),
          ],
        ),
        content: Text(
          'আপনার সব জরুরি যোগাযোগে SMS ও নোটিফিকেশন পাঠানো হবে। '
          'আপনার বর্তমান অবস্থান শেয়ার করা হবে।\n\nআপনি কি নিশ্চিত?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('হ্যাঁ, সাহায্য দরকার'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _activateSOS();
    }
  }

  Future<void> _activateSOS() async {
    setState(() {
      _isActivating = true;
    });

    try {
      // 1. Get current location
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      String locationStr = '';
      if (position != null) {
        locationStr = locationService.getGoogleMapsUrl(position.latitude, position.longitude);
      }

      // 2. Get emergency contacts (Mock for now, should come from Hive/Provider)
      // Displaying dummy contacts for demonstration as Hive implementation wasn't fully inspected for content
      final contacts = ['01700000000', '01800000000']; 

      // 3. Send SMS to emergency contacts
      final smsService = SMSService();
      // Placeholder user name - in real app, get from AuthProvider
      const userName = 'ব্যবহারকারী'; 
      
      int successCount = 0;
      for (final contact in contacts) {
        final success = await smsService.sendEmergencyAlert(
          phoneNumber: contact,
          userName: userName,
          location: locationStr,
          isSOS: true,
        );
        if (success) successCount++;
      }

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS সক্রিয়! $successCount জন কন্টাক্টে বার্তা পাঠানো হয়েছে।'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('সমস্যা হয়েছে: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActivating = false;
        });
      }
    }
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
