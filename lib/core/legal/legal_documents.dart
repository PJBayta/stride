enum LegalDocument { privacyPolicy, termsOfService }

extension LegalDocumentContent on LegalDocument {
  String get title => switch (this) {
    LegalDocument.privacyPolicy => 'Privacy Policy',
    LegalDocument.termsOfService => 'Terms of Service',
  };

  List<String> get paragraphs => switch (this) {
    LegalDocument.privacyPolicy => const [
      'Stride values your privacy. All personal information, including your name, weight, height, activity history, and GPS route data, is stored locally on your device and is not shared with third parties or uploaded to external servers.',
      'Location permission is used only while tracking activities to calculate distance, pace, speed, and route information. You may revoke this permission at any time through your device settings, although some features may no longer function correctly.',
      'By using Stride, you acknowledge and agree to this privacy policy.',
    ],
    LegalDocument.termsOfService => const [
      'By using Stride, you agree to use the application responsibly and for its intended purpose as a fitness activity tracker.',
      'Stride provides estimated fitness metrics, including distance, pace, speed, steps, and calories burned. These values are approximations and should not be considered medical or professional health advice.',
      'The developers are not responsible for any loss of data, inaccurate measurements, injuries, or damages resulting from the use of the application. Users are responsible for ensuring their own safety while performing physical activities.',
      'Continued use of Stride constitutes acceptance of these terms.',
    ],
  };
}
