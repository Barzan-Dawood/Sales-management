import 'package:flutter/material.dart';
import 'dark_mode_utils.dart';

class ScreenUpdater {
  // Update common hardcoded colors to be theme-aware
  static void updateCommonColors() {
    // This method can be used to update common color patterns across screens
  }

  // Create a theme-aware container with consistent styling
  static Widget createThemedContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? DarkModeUtils.getCardColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border:
            border ?? Border.all(color: DarkModeUtils.getBorderColor(context)),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: DarkModeUtils.getShadowColor(context),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: child,
    );
  }

  // Create a theme-aware list tile with consistent styling
  static Widget createThemedListTile({
    required BuildContext context,
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return DarkModeUtils.createListTile(
      context: context,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: contentPadding,
    );
  }

  // Create a theme-aware card with consistent styling
  static Widget createThemedCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: DarkModeUtils.createCardDecoration(context),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  // Create a theme-aware floating action button
  static Widget createThemedFAB({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      child: Icon(icon),
    );
  }

  // Create a theme-aware chip
  static Widget createThemedChip({
    required BuildContext context,
    required String label,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onDeleted,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: DarkModeUtils.createChip(
        context: context,
        label: label,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onDeleted: onDeleted,
      ),
    );
  }

  // Create a theme-aware divider
  static Widget createThemedDivider(BuildContext context) {
    return Divider(
      color: DarkModeUtils.getDividerColor(context),
      thickness: 1,
    );
  }

  // Create a theme-aware loading indicator
  static Widget createThemedLoadingIndicator(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // Create a theme-aware error widget
  static Widget createThemedErrorWidget({
    required BuildContext context,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: DarkModeUtils.getErrorColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: DarkModeUtils.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }

  // Create a theme-aware empty state widget
  static Widget createThemedEmptyState({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 64,
            color: DarkModeUtils.getSecondaryTextColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DarkModeUtils.getTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: DarkModeUtils.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }

  // Create a theme-aware search bar
  static Widget createThemedSearchBar({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: DarkModeUtils.createInputDecoration(
        context,
        hintText: hintText,
        prefixIcon: Icons.search,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              )
            : null,
      ),
    );
  }

  // Create a theme-aware status indicator
  static Widget createThemedStatusIndicator({
    required BuildContext context,
    required String status,
    Color? color,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
        statusColor = DarkModeUtils.getSuccessColor(context);
        break;
      case 'warning':
      case 'pending':
        statusColor = DarkModeUtils.getWarningColor(context);
        break;
      case 'error':
      case 'failed':
      case 'inactive':
        statusColor = DarkModeUtils.getErrorColor(context);
        break;
      default:
        statusColor = color ?? DarkModeUtils.getInfoColor(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
