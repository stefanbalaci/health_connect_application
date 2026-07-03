import 'package:flutter/material.dart';

/// The Health Connect brand lockup: the app-icon logo above the wordmark.
class HCLogo extends StatelessWidget {
  const HCLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'HEALTH ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Color(0xFF1A3A5C),
                ),
              ),
              TextSpan(
                text: 'CONNECT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Color(0xFF2ABFBF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
