// shortcuts.dart - Professional Grade v3.0
// Complete widget library for Flutter apps with authentication support
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// ============================================================================
// GRADIENT COLOR SCHEMES ENUM
// ============================================================================

/// Enum for all available gradient color schemes
///
/// Available schemes: green, red, blue, purple, orange, pink, grey
///
/// Example:
/// ```dart
/// GradientColorScheme currentScheme = GradientColorScheme.purple;
/// ```
enum GradientColorScheme { green, red, blue, purple, orange, pink, grey }

// ============================================================================
// UNIFIED GRADIENT BACKGROUND
// ============================================================================

/// A unified gradient background widget with multiple color schemes
///
/// This widget provides 7 predefined color schemes and supports custom colors.
/// It creates smooth gradient transitions that can be rotated for different effects.
///
/// Features:
/// - 7 built-in color schemes (Green, Red, Blue, Purple, Orange, Pink, Grey)
/// - Customizable gradient direction
/// - Optional rotation effect
/// - Custom colors support
///
/// Parameters:
/// - [child]: Widget to display on top of the gradient
/// - [scheme]: Predefined color scheme (default: purple)
/// - [colors]: Custom color list (overrides scheme if provided)
/// - [begin]: Gradient start alignment (default: topLeft)
/// - [end]: Gradient end alignment (default: bottomRight)
/// - [rotation]: Rotation angle in degrees (optional)
///
/// Example:
/// ```dart
/// // Using predefined scheme
/// GradientBackground(
///   scheme: GradientColorScheme.purple,
///   child: YourWidget(),
/// )
///
/// // Using custom colors
/// GradientBackground(
///   colors: [Colors.black, Colors.deepPurple],
///   child: YourWidget(),
/// )
///
/// // With rotation
/// GradientBackground(
///   scheme: GradientColorScheme.blue,
///   rotation: 45,
///   child: YourWidget(),
/// )
/// ```
class GradientBackground extends StatelessWidget {
  final Widget child;
  final GradientColorScheme? scheme;
  final List<Color>? colors;
  final Alignment begin;
  final Alignment end;
  final double? rotation;

  const GradientBackground({
    super.key,
    required this.child,
    this.scheme = GradientColorScheme.purple,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.rotation,
  });

  /// Get color list based on the selected scheme
  List<Color> get _gradientColors {
    // If custom colors are provided, use them
    if (colors != null && colors!.isNotEmpty) {
      return colors!;
    }

    // Otherwise use predefined scheme
    switch (scheme!) {
      case GradientColorScheme.green:
        return const [
          Color(0xFF001F0E),
          Color(0xFF003300),
          Color(0xFF004D26),
          Color(0xFF006644),
          Color(0xFF00875A),
          Color(0xFF00A878),
          Color(0xFF00CC99),
          Color(0xFF33E6B0),
          Color(0xFF66FFCC),
          Color(0xFFB2FFE5),
        ];

      case GradientColorScheme.red:
        return const [
          Color(0xFF1A0000),
          Color(0xFF3C0000),
          Color(0xFF5C0000),
          Color(0xFF8E0E00),
          Color(0xFFB71C1C),
          Color(0xFFD32F2F),
          Color(0xFFEF5350),
        ];

      case GradientColorScheme.blue:
        return const [
          Color(0xFF000814),
          Color(0xFF001D3D),
          Color(0xFF003566),
          Color(0xFF004E92),
          Color(0xFF0077B6),
          Color(0xFF0096C7),
          Color(0xFF00B4D8),
          Color(0xFF48CAE4),
          Color(0xFF90E0EF),
          Color(0xFFCAF0F8),
        ];

      case GradientColorScheme.purple:
        return const [
          Color(0xFF0D0221),
          Color(0xFF10002B),
          Color(0xFF240046),
          Color(0xFF3C096C),
          Color(0xFF5A189A),
          Color(0xFF7B2CBF),
          Color(0xFF9D4EDD),
          Color(0xFFB185DB),
          Color(0xFFC77DFF),
          Color(0xFFE0AAFF),
        ];

      case GradientColorScheme.orange:
        return const [
          Color(0xFF2E1A0F),
          Color(0xFF4B2E0F),
          Color(0xFF6A3F10),
          Color(0xFF8C4E10),
          Color(0xFFB25C11),
          Color(0xFFD97714),
          Color(0xFFFFA726),
        ];

      case GradientColorScheme.pink:
        return const [
          Color(0xFF2E001A),
          Color(0xFF4B0033),
          Color(0xFF6A004D),
          Color(0xFF8C0066),
          Color(0xFFB20080),
          Color(0xFFD90099),
          Color(0xFFFF33AA),
        ];

      case GradientColorScheme.grey:
        return const [
          Color(0xFF1A1A1A),
          Color(0xFF333333),
          Color(0xFF4D4D4D),
          Color(0xFF666666),
          Color(0xFF808080),
          Color(0xFF999999),
          Color(0xFFB3B3B3),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: _gradientColors,
          transform: rotation != null
              ? GradientRotation(rotation! * math.pi / 180)
              : const GradientRotation(31 * math.pi / 180),
        ),
      ),
      child: child,
    );
  }
}

// ============================================================================
// BACKWARD COMPATIBILITY ALIASES
// ============================================================================

class GradientBackgroundGreen extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final Alignment begin;
  final Alignment end;
  final double? rotation;

  const GradientBackgroundGreen({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      scheme: GradientColorScheme.green,
      colors: colors,
      begin: begin,
      end: end,
      rotation: rotation,
      child: child,
    );
  }
}

class GradientBackgroundRed extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final Alignment begin;
  final Alignment end;
  final double? rotation;

  const GradientBackgroundRed({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      scheme: GradientColorScheme.red,
      colors: colors,
      begin: begin,
      end: end,
      rotation: rotation,
      child: child,
    );
  }
}

class GradientBackgroundBlue extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final Alignment begin;
  final Alignment end;
  final double? rotation;

  const GradientBackgroundBlue({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      scheme: GradientColorScheme.blue,
      colors: colors,
      begin: begin,
      end: end,
      rotation: rotation,
      child: child,
    );
  }
}

class GradientBackgroundPurple extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final Alignment begin;
  final Alignment end;
  final double? rotation;

  const GradientBackgroundPurple({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      scheme: GradientColorScheme.purple,
      colors: colors,
      begin: begin,
      end: end,
      rotation: rotation,
      child: child,
    );
  }
}

class GradientBackgroundOrange extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final Alignment begin;
  final Alignment end;
  final double? rotation;

  const GradientBackgroundOrange({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      scheme: GradientColorScheme.orange,
      colors: colors,
      begin: begin,
      end: end,
      rotation: rotation,
      child: child,
    );
  }
}

class GradientBackgroundPink extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final Alignment begin;
  final Alignment end;
  final double? rotation;

  const GradientBackgroundPink({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      scheme: GradientColorScheme.pink,
      colors: colors,
      begin: begin,
      end: end,
      rotation: rotation,
      child: child,
    );
  }
}

class GradientBackgroundGrey extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final Alignment begin;
  final Alignment end;
  final double? rotation;

  const GradientBackgroundGrey({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      scheme: GradientColorScheme.grey,
      colors: colors,
      begin: begin,
      end: end,
      rotation: rotation,
      child: child,
    );
  }
}

// ============================================================================
// SPACING HELPERS
// ============================================================================

/// Creates a vertical gap with specified height
///
/// This is a convenience widget that returns a SizedBox with only height.
/// Useful for adding vertical spacing between widgets in Column.
///
/// Parameters:
/// - [h]: Height in logical pixels
///
/// Example:
/// ```dart
/// Column(
///   children: [
///     Text('First'),
///     gapH(20), // 20px vertical space
///     Text('Second'),
///   ],
/// )
/// ```
Widget gapH(double h) => SizedBox(height: h);

/// Creates a horizontal gap with specified width
///
/// This is a convenience widget that returns a SizedBox with only width.
/// Useful for adding horizontal spacing between widgets in Row.
///
/// Parameters:
/// - [w]: Width in logical pixels
///
/// Example:
/// ```dart
/// Row(
///   children: [
///     Icon(Icons.star),
///     gapW(10), // 10px horizontal space
///     Text('Rating'),
///   ],
/// )
/// ```
Widget gapW(double w) => SizedBox(width: w);

// ============================================================================
// TEXT STYLES
// ============================================================================

/// Predefined text styles using Google Fonts
///
/// This class provides ready-to-use TextStyle objects for both English and Arabic.
/// All styles default to white color and 16px font size, but can be customized
/// using .copyWith().
///
/// English Fonts:
/// - orbitron: Modern, tech-inspired font
/// - lobster: Casual, script-like font
/// - cagliostro: Elegant, readable font (recommended for body text)
/// - poppins: Clean, professional font
///
/// Arabic Fonts:
/// - cairo: Modern Arabic font (recommended for general use)
/// - reemKufi: Geometric Arabic font
/// - tajawal: Clean, readable Arabic font
/// - amiri: Traditional Arabic font
///
/// Example:
/// ```dart
/// Text(
///   "Hello World",
///   style: SCText.orbitron.copyWith(
///     fontSize: 24,
///     fontWeight: FontWeight.bold,
///     color: Colors.blue,
///   ),
/// )
/// ```
class SCText {
  // English fonts
  static const TextStyle orbitron = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle lobster = TextStyle(
    fontFamily: 'Lobster',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle cagliostro = TextStyle(
    fontFamily: 'Cagliostro',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle poppins = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  // Arabic fonts
  static const TextStyle cairo = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle reemKufi = TextStyle(
    fontFamily: 'ReemKufi',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle tajawal = TextStyle(
    fontFamily: 'Tajawal',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle amiri = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );
}

class SCButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const SCButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.black.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor ?? Colors.white, size: 20),
                    gapW(8),
                  ],
                  Text(
                    text,
                    style: SCText.orbitron.copyWith(
                      color: textColor ?? Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// NOTIFICATIONS
// ============================================================================

/// Shows a styled snackbar notification
///
/// This class provides static methods to show different types of snackbars
/// with appropriate colors and icons. All snackbars are floating, have
/// rounded corners, and include an "OK" action button.
///
/// Available methods:
/// - show(): Generic snackbar with custom styling
/// - success(): Green snackbar with checkmark icon
/// - error(): Red snackbar with error icon
/// - info(): Blue snackbar with info icon
/// - warning(): Orange snackbar with warning icon
///
/// Parameters for show():
/// - [context]: BuildContext (required)
/// - [message]: Message to display (required)
/// - [duration]: How long to show (default: 3 seconds)
/// - [backgroundColor]: Background color (default: black87)
/// - [icon]: Optional icon to display
///
/// Example:
/// ```dart
/// SCSnackBar.success(context, "Login successful!");
/// SCSnackBar.error(context, "Invalid credentials");
/// SCSnackBar.info(context, "Please wait...");
/// SCSnackBar.warning(context, "Low battery");
///
/// // Custom snackbar
/// SCSnackBar.show(
///   context,
///   "Custom message",
///   backgroundColor: Colors.purple,
///   icon: Icons.favorite,
///   duration: Duration(seconds: 5),
/// )
/// ```
class SCSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    IconData? icon,
  }) {
    final snackBar = SnackBar(
      elevation: 10,
      margin: const EdgeInsets.all(12),
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            gapW(12),
          ],
          Expanded(
            child: Text(message, style: SCText.poppins.copyWith(fontSize: 14)),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: duration,
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.green.shade700,
      icon: Icons.check_circle,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.blue.shade700,
      icon: Icons.info,
    );
  }

  static void warning(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning,
    );
  }
}

/// Legacy snackbar function (kept for backward compatibility)
///
/// Shows a basic snackbar with default styling.
/// Prefer using SCSnackBar class methods for more options.
///
/// Example:
/// ```dart
/// SCsnackBar(context, "Something happened");
/// ```
void SCsnackBar(BuildContext context, String message) {
  SCSnackBar.show(context, message);
}

// ============================================================================
// DIALOGS
// ============================================================================

/// A custom styled alert dialog
///
/// This widget creates a professional-looking alert dialog with optional
/// icon, customizable colors, and cancel button. Perfect for confirmations,
/// warnings, and important messages.
///
/// Features:
/// - Customizable title and content
/// - Optional icon in header
/// - Optional cancel button
/// - Confirmation callback
/// - Rounded corners
/// - Color-coded for different purposes
///
/// Parameters:
/// - [title]: Dialog title (required)
/// - [content]: Dialog message (required)
/// - [onConfirmed]: Callback when confirmed (required)
/// - [buttonText]: Confirm button text (default: "Confirm")
/// - [cancelText]: Cancel button text (optional, default: "Cancel")
/// - [isCancel]: Show cancel button (default: false)
/// - [titleColor]: Title and icon color (default: red)
/// - [icon]: Optional icon for header
///
/// Example:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => SCAlertDialog(
///     title: "Delete Item",
///     content: "Are you sure you want to delete this item?",
///     icon: Icons.delete,
///     titleColor: Colors.red,
///     buttonText: "Delete",
///     isCancel: true,
///     onConfirmed: () {
///       // Delete logic here
///     },
///   ),
/// )
/// ```
class SCAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final String? cancelText;
  final bool isCancel;
  final VoidCallback onConfirmed;
  final Color? titleColor;
  final IconData? icon;

  const SCAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirmed,
    this.buttonText = "Confirm",
    this.cancelText,
    this.isCancel = false,
    this.titleColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: titleColor ?? Colors.red, size: 28),
            gapW(12),
          ],
          Expanded(
            child: Text(
              title,
              style: SCText.cagliostro.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: titleColor ?? Colors.red,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: SCText.cagliostro.copyWith(fontSize: 17, color: Colors.black87),
      ),
      actions: [
        if (isCancel)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              cancelText ?? "Cancel",
              style: SCText.cagliostro.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirmed();
          },
          child: Text(
            buttonText,
            style: SCText.cagliostro.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: titleColor ?? Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// NAVIGATION HELPERS
// ============================================================================

/// Navigate to a new page
///
/// Pushes a new page onto the navigation stack. The current page
/// remains in the stack and can be returned to.
///
/// Parameters:
/// - [context]: BuildContext (required)
/// - [page]: Widget to navigate to (required)
///
/// Example:
/// ```dart
/// navigateTo(context, ProfilePage());
/// ```
void navigateTo(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}

/// Navigate to a new page and remove current from stack
///
/// Replaces the current page with a new one. The current page is
/// removed from the stack and cannot be returned to.
///
/// Parameters:
/// - [context]: BuildContext (required)
/// - [page]: Widget to navigate to (required)
///
/// Example:
/// ```dart
/// navigateToReplacement(context, HomePage());
/// ```
void navigateToReplacement(BuildContext context, Widget page) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

/// Navigate to a new page and clear all previous routes
///
/// Removes all pages from the navigation stack and pushes the new page.
/// Useful for logout scenarios or completing onboarding.
///
/// Parameters:
/// - [context]: BuildContext (required)
/// - [page]: Widget to navigate to (required)
///
/// Example:
/// ```dart
/// navigateToAndRemoveAll(context, LoginPage());
/// ```
void navigateToAndRemoveAll(BuildContext context, Widget page) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => page),
    (route) => false,
  );
}

// ============================================================================
// CARDS
// ============================================================================

/// A simple card with icon and title
///
/// Creates a tappable card with an icon and title, styled with semi-transparent
/// background and rounded corners. Perfect for dashboard-style grids.
///
/// Parameters:
/// - [icon]: IconData to display (required)
/// - [title]: Text to display below icon (required)
/// - [onTap]: Callback when card is tapped (required)
/// - [color]: Card background color (default: white with 10% opacity)
/// - [iconSize]: Size of the icon (default: 38px)
/// - [fontSize]: Size of the title text (default: 18px)
///
/// Example:
/// ```dart
/// SCSimpleCard(
///   icon: Icons.home,
///   title: "Home",
///   onTap: () => navigateTo(context, HomePage()),
///   color: Colors.blue,
///   iconSize: 48,
/// )
/// ```
class SCSimpleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;
  final double? iconSize;
  final double? fontSize;

  const SCSimpleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.iconSize,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: iconSize ?? 38),
            gapH(12),
            Text(
              title,
              style: SCText.cagliostro.copyWith(
                fontSize: fontSize ?? 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A masonry grid card for displaying items with images
///
/// Creates a Pinterest-style masonry grid layout where items can have different
/// heights. Each item shows an image with a title overlay at the bottom.
///
/// Parameters:
/// - [items]: List of maps containing 'image' and 'title' keys (required)
/// - [count]: Number of columns in the grid (required)
/// - [onItemTap]: Optional callback when an item is tapped (receives index)
///
/// Example:
/// ```dart
/// SCProCard(
///   items: [
///     {'image': 'assets/img1.jpg', 'title': 'Item 1'},
///     {'image': 'assets/img2.jpg', 'title': 'Item 2'},
///   ],
///   count: 2,
///   onItemTap: (index) => print('Tapped item $index'),
/// )
/// ```
class SCProCard extends StatelessWidget {
  final List<Map<String, String>> items;
  final int count;
  final Function(int)? onItemTap;

  const SCProCard({
    super.key,
    required this.items,
    required this.count,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: count,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final imageUrl = item['image'];
        final title = item['title'] ?? 'No Title';

        return InkWell(
          onTap: () => onItemTap?.call(index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey[850],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                imageUrl != null && imageUrl.isNotEmpty
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueGrey.shade700,
                              Colors.grey.shade900,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'No Photo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    title,
                    style: SCText.cagliostro.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// TEXT FIELDS
// ============================================================================

/// Enhanced text field with validation and obscure text toggle
///
/// A sophisticated text field that includes real-time validation for email
/// and password fields. Automatically shows/hides password visibility toggle
/// and displays validation errors.
///
/// Features:
/// - Real-time validation
/// - Email format validation
/// - Password strength validation
/// - Show/hide password toggle
/// - Error indicators with icons
/// - Rounded corners with custom styling
///
/// Parameters:
/// - [hint]: Placeholder text (required)
/// - [label]: Field label (optional)
/// - [obscureText]: Hide text input (default: false)
/// - [controller]: TextEditingController (optional)
/// - [suffixIcon]: Icon at end of field (optional)
/// - [prefixIcon]: Icon at start of field (optional)
/// - [isEmail]: Enable email validation (default: false)
/// - [isPassword]: Enable password validation (default: false)
/// - [onChanged]: Callback with error text (optional)
///
/// Example:
/// ```dart
/// final emailController = TextEditingController();
///
/// SCtextField(
///   hint: "Enter email",
///   label: "Email",
///   controller: emailController,
///   prefixIcon: Icons.email,
///   isEmail: true,
/// )
///
/// SCtextField(
///   hint: "Enter password",
///   label: "Password",
///   controller: passwordController,
///   prefixIcon: Icons.lock,
///   obscureText: true,
///   isPassword: true,
/// )
/// ```
class SCtextField extends StatefulWidget {
  final String? label;
  final String hint;
  final bool obscureText;
  final TextEditingController? controller;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final bool isEmail;
  final bool isPassword;
  final Function(String?)? onChanged;

  const SCtextField({
    super.key,
    this.label,
    required this.hint,
    this.obscureText = false,
    this.controller,
    this.suffixIcon,
    this.prefixIcon,
    this.isEmail = false,
    this.isPassword = false,
    this.onChanged,
  });

  @override
  State<SCtextField> createState() => _SCtextFieldState();
}

class _SCtextFieldState extends State<SCtextField> {
  bool _obscureText = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    widget.controller?.addListener(_validateInput);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_validateInput);
    super.dispose();
  }

  void _validateInput() {
    final text = widget.controller?.text ?? '';

    if (widget.isEmail) {
      setState(() {
        _errorText = _validateEmail(text);
      });
    } else if (widget.isPassword) {
      setState(() {
        _errorText = _validatePassword(text);
      });
    }

    if (widget.onChanged != null) {
      widget.onChanged!(_errorText);
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }

    if (!email.contains('@')) {
      return 'Email must contain @';
    }

    if (!email.contains('.')) {
      return 'Email must contain a domain (.com, .net, etc.)';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }

    if (email.contains(' ')) {
      return 'Email cannot contain spaces';
    }

    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (password.contains(' ')) {
      return 'Password cannot contain spaces';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: widget.obscureText && _obscureText,
          style: SCText.cagliostro,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(
                color: _errorText != null ? Colors.red : Colors.black,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(
                color: _errorText != null ? Colors.red : Colors.black,
                width: 3.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            labelText: widget.label,
            labelStyle: SCText.cagliostro.copyWith(
              color: Colors.grey.shade300,
              fontWeight: FontWeight.w400,
              letterSpacing: 2.0,
            ),
            hintText: widget.hint,
            hintStyle: SCText.cagliostro.copyWith(
              color: Colors.grey.shade600,
              fontSize: 14.0,
            ),
            prefixIcon: Icon(
              widget.prefixIcon,
              color: Colors.white.withOpacity(0.7),
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : Icon(widget.suffixIcon, color: Colors.white.withOpacity(0.7)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 22.0,
              horizontal: 18.0,
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.4),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _errorText!,
                    style: SCText.poppins.copyWith(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}



// ============================================================================
// THEMED CONTENT WRAPPER
// ============================================================================

/// Wrapper widget that applies the selected theme gradient to content
///
/// This widget automatically applies the current theme's gradient background
/// to any content. It listens to theme changes and updates the background
/// accordingly.
///
/// How it works:
/// 1. Gets the theme controller
/// 2. Observes the current theme selection
/// 3. Applies the corresponding gradient background
/// 4. Updates automatically when theme changes
///
/// Parameters:
/// - [child]: Widget to wrap with themed background (required)
///
/// Example:
/// ```dart
/// Scaffold(
///   body: ThemedContent(
///     child: YourPageContent(),
///   ),
/// )
// /// ```
// class ThemedContent extends StatelessWidget {
//   final Widget child;

//   const ThemedContent({super.key, required this.child});

//   ThemeController _getThemeController() {
//     if (Get.isRegistered<ThemeController>()) {
//       return Get.find<ThemeController>();
//     } else {
//       return Get.put(ThemeController(), permanent: true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeController = _getThemeController();

//     return Obx(() {
//       switch (themeController.currentTheme.value) {
//         case 'green':
//           return GradientBackgroundGreen(child: child);
//         case 'blue':
//           return GradientBackgroundBlue(child: child);
//         case 'purple':
//           return GradientBackgroundPurple(child: child);
//         case 'red':
//           return GradientBackgroundRed(child: child);
//         case 'pink':
//           return GradientBackgroundPink(child: child);
//         case 'grey':
//           return GradientBackgroundGrey(child: child);
//         case 'orange':
//         default:
//           return GradientBackgroundOrange(child: child);
//       }
//     });
//   }
// }

// ============================================================================
// UTILITY CONTAINERS
// ============================================================================

/// A styled container with consistent design
///
/// This container provides a semi-transparent background with rounded corners
/// and a border. It's perfect for grouping content on gradient backgrounds.
///
/// Parameters:
/// - [child]: Content to display inside (required)
/// - [color]: Background color (default: black with 30% opacity)
/// - [padding]: Internal spacing (default: 10px all sides)
/// - [margin]: External spacing (default: 10px all sides)
/// - [alignment]: Content alignment (default: center)
/// - [borderRadius]: Corner radius (default: 16px)
/// - [border]: Custom border (default: white with 30% opacity)
/// - [boxShadow]: Optional shadow effects
///
/// Example:
/// ```dart
/// SCContainer(
///   padding: EdgeInsets.all(20),
///   child: Column(
///     children: [
///       Text('Title'),
///       Text('Content'),
///     ],
///   ),
/// )
/// ```
class SCContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final double? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const SCContainer({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.margin,
    this.alignment,
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(10),
      margin: margin ?? const EdgeInsets.all(10),
      alignment: alignment ?? Alignment.center,
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: border ?? Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

/// A styled icon button with consistent design
///
/// Creates a tappable icon inside a rounded container with semi-transparent
/// background. Perfect for toolbar actions and controls.
///
/// Parameters:
/// - [icon]: IconData to display (required)
/// - [onTap]: Callback when tapped (required)
/// - [color]: Background color (default: black with 30% opacity)
/// - [size]: Icon size (default: 20px)
///
/// Example:
/// ```dart
/// SCiconbutton(
///   icon: Icons.edit,
///   onTap: () => editItem(),
///   color: Colors.blue.withOpacity(0.3),
///   size: 24,
/// )
/// ```
class SCiconbutton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double? size;

  const SCiconbutton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color ?? Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: size ?? 20),
      ),
    );
  }
}

final List<IconData> commonIcons = [
  Icons.task,
  Icons.work,
  Icons.home,
  Icons.emoji_events,
  Icons.school,
  Icons.fitness_center,
  Icons.shopping_cart,
  Icons.lightbulb,
  Icons.palette,
  Icons.games,
  Icons.music_note,
  Icons.flight,
  Icons.computer,
  Icons.phone_android,
  Icons.movie,
  Icons.restaurant,
  Icons.sports_soccer,
  Icons.star,
  Icons.favorite,
  Icons.celebration,
  Icons.beach_access,
  Icons.camera,
  Icons.book,
  Icons.code,
  Icons.build,
  Icons.attach_money,
  Icons.health_and_safety,
  Icons.pets,
  Icons.directions_car,
  Icons.train,
];

/// Icon names for display (matches commonIcons order)
///
/// Use these to show text labels alongside icons in a picker.
///
/// Example:
/// ```dart
/// ListView.builder(
///   itemCount: commonIcons.length,
///   itemBuilder: (context, index) {
///     return ListTile(
///       leading: Icon(commonIcons[index]),
///       title: Text(commonIconNames[index]),
///     );
///   },
/// )
/// ```
final List<String> commonIconNames = [
  'Task',
  'Work',
  'Home',
  'Goals',
  'Education',
  'Fitness',
  'Shopping',
  'Ideas',
  'Art',
  'Games',
  'Music',
  'Travel',
  'Tech',
  'Mobile',
  'Movies',
  'Food',
  'Sports',
  'Favorites',
  'Love',
  'Party',
  'Vacation',
  'Photography',
  'Reading',
  'Programming',
  'Projects',
  'Finance',
  'Health',
  'Pets',
  'Car',
  'Transport',
];
