// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';


// class ContactSection extends StatelessWidget {
//   const ContactSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             AppLocalizations.of(context).tr('more.contactUs'),
//             style: AppStyles.styleSemiBold20(
//               context,
//             ).copyWith(color: colorScheme.onSurface),
//           ),
//           const SizedBox(height: 16),

//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               color: colorScheme.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.email, color: colorScheme.primary, size: 20),
//                     const SizedBox(width: 8),
//                     Text(
//                       AppLocalizations.of(context).tr('contact.supportEmail'),
//                       style: AppStyles.styleSemiBold16(
//                         context,
//                       ).copyWith(color: colorScheme.primary),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'support@weeklyapp.com',
//                   style: AppStyles.styleRegular14(
//                     context,
//                   ).copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   AppLocalizations.of(context).tr('contact.responseTime'),
//                   style: AppStyles.styleRegular12(
//                     context,
//                   ).copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
//                 ),
//                 const SizedBox(height: 16),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () => _sendEmail(),
//                     icon: const Icon(Icons.email, size: 18),
//                     label: Text(
//                       AppLocalizations.of(context).tr('contact.sendEmail'),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: colorScheme.primary,
//                       foregroundColor: colorScheme.onPrimary,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 16),

//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               color: colorScheme.secondary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.share, color: colorScheme.secondary, size: 20),
//                     const SizedBox(width: 8),
//                     Text(
//                       AppLocalizations.of(context).tr('contact.followUs'),
//                       style: AppStyles.styleSemiBold16(
//                         context,
//                       ).copyWith(color: colorScheme.secondary),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildSocialButton(
//                       context,
//                       Icons.facebook,
//                       'Facebook',
//                       colorScheme.secondary,
//                       () => _openSocialMedia('facebook'),
//                     ),
//                     _buildSocialButton(
//                       context,
//                       Icons.flutter_dash,
//                       'Twitter',
//                       Colors.lightBlue[400]!,
//                       () => _openSocialMedia('twitter'),
//                     ),
//                     _buildSocialButton(
//                       context,
//                       Icons.camera_alt,
//                       'Instagram',
//                       colorScheme.tertiary,
//                       () => _openSocialMedia('instagram'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSocialButton(
//     BuildContext context,
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             width: 50,
//             height: 50,
//             decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//             child: Icon(icon, color: Colors.white, size: 24),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: AppStyles.styleRegular12(context).copyWith(color: color),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _sendEmail() async {
//     final Uri emailUri = Uri(
//       scheme: 'mailto',
//       path: 'ahmedelsersy101@gmail.com',
//       query:
//           'subject=Weekly App Support Request&body=Hello, I need help with the Weekly App.',
//     );

//     try {
//       if (await canLaunchUrl(emailUri)) {
//         await launchUrl(emailUri);
//       } else {
//         print('Could not launch email client');
//       }
//     } catch (e) {
//       print('Error launching email: $e');
//     }
//   }

//   Future<void> _openSocialMedia(String platform) async {
//     String url;
//     switch (platform) {
//       case 'facebook':
//         url = 'https://web.facebook.com/AhMedAlsErSy10';
//         break;
//       case 'whatsapp':
//         url = 'https://wa.me/qr/E7KX4XV5NJJAI1';
//         break;
//       case 'telegram':
//         url = 'https://t.me/ahmedelsersy10';
//         break;
//       default:
//         url = 'https://ahmedsersy10.github.io/weekly_app/';
//     }

//     try {
//       final Uri uri = Uri.parse(url);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       } else {
//         print('Could not launch $platform');
//       }
//     } catch (e) {
//       print('Error launching $platform: $e');
//     }
//   }
// }
