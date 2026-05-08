import 'dart:core';

/// Comprehensive string manipulation utilities for consistent formatting
/// throughout the application. Provides methods for names, roles, text
/// normalization, and various formatting needs.
abstract class StringUtils {
  // ---------------------------------------------------------------------------
  // Basic Text Manipulation
  // ---------------------------------------------------------------------------

  /// Converts string to uppercase
  static String toUpperCase(String input) {
    if (input.isEmpty) return input;
    return input.toUpperCase();
  }

  /// Converts string to lowercase
  static String toLowerCase(String input) {
    if (input.isEmpty) return input;
    return input.toLowerCase();
  }

  /// Capitalizes the first letter and makes the rest lowercase
  static String capitalizeFirst(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  /// Capitalizes the first letter of each word (Title Case)
  static String capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .map((word) => word.isNotEmpty ? capitalizeFirst(word) : '')
        .join(' ');
  }

  /// Removes extra spaces and keeps only single spaces between words
  static String normalizeSpaces(String input) {
    if (input.isEmpty) return input;
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Removes all spaces from the string
  static String removeSpaces(String input) {
    if (input.isEmpty) return input;
    return input.replaceAll(' ', '');
  }

  /// Converts snake_case to camelCase
  static String snakeToCamel(String input) {
    if (input.isEmpty) return input;
    final parts = input.split('_');
    if (parts.length == 1) return parts.first;
    return parts.first.toLowerCase() +
        parts
            .skip(1)
            .map((part) => capitalizeFirst(part.toLowerCase()))
            .join('');
  }

  /// Converts snake_case to Title Case (Space-separated words)
  static String snakeToTitleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split('_')
        .map((word) => capitalizeFirst(word.toLowerCase()))
        .join(' ');
  }

  /// Converts camelCase to snake_case
  static String camelToSnake(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .toLowerCase();
  }

  // ---------------------------------------------------------------------------
  // Name Formatting
  // ---------------------------------------------------------------------------

  /// Formats a name with proper capitalization
  /// Handles various input formats and ensures consistent output
  static String formatName(String name) {
    if (name.isEmpty) return name;

    // Normalize spaces first
    String formatted = normalizeSpaces(name);

    // Capitalize each word
    formatted = capitalizeWords(formatted);

    return formatted;
  }

  /// Formats first name specifically
  static String formatFirstName(String firstName) {
    return formatName(firstName);
  }

  /// Formats last name specifically
  static String formatLastName(String lastName) {
    return formatName(lastName);
  }

  /// Gets initials from a full name (max 2 characters)
  static String getInitials(String fullName) {
    if (fullName.isEmpty) return '';

    final words = normalizeSpaces(fullName).split(' ');
    if (words.isEmpty) return '';

    if (words.length == 1) {
      return words.first.isNotEmpty ? words.first[0].toUpperCase() : '';
    }

    final first = words.first.isNotEmpty ? words.first[0].toUpperCase() : '';
    final second = words.last.isNotEmpty ? words.last[0].toUpperCase() : '';

    return '$first$second';
  }

  // ---------------------------------------------------------------------------
  // Role Formatting
  // ---------------------------------------------------------------------------

  /// Formats role string from various formats to consistent Title Case
  /// Handles: lowercase, UPPERCASE, snake_case, camelCase, mixed formats
  static String formatRole(String role) {
    if (role.isEmpty) return role;

    // First convert to snake_case for normalization
    String normalized = role;

    // Handle camelCase to snake_case
    if (normalized.contains(RegExp(r'[a-z][A-Z]'))) {
      normalized = camelToSnake(normalized);
    }

    // Handle spaces to snake_case
    normalized = normalized.replaceAll(' ', '_');

    // Handle multiple underscores
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');

    // Remove leading/trailing underscores
    normalized = normalized.replaceAll(RegExp(r'^_|_$'), '');

    // Convert to Title Case
    return snakeToTitleCase(normalized);
  }

  /// Common role mappings for consistency
  static Map<String, String> get roleMappings => {
    'admin': 'Administrator',
    'staff': 'Staff',
    'manager': 'Manager',
    'supervisor': 'Supervisor',
    'receptionist': 'Receptionist',
    'housekeeping': 'Housekeeping',
    'maintenance': 'Maintenance',
    'security': 'Security',
    'system_engineer': 'System Engineer',
    'software_engineer': 'Software Engineer',
    'dev_ops': 'Dev Ops',
    'devops': 'Dev Ops',
    'hr': 'Human Resources',
    'human_resources': 'Human Resources',
    'ceo': 'Chief Executive Officer',
    'cto': 'Chief Technology Officer',
    'cfo': 'Chief Financial Officer',
    'system_controller': 'System Controller',
    'systemcontroller': 'System Controller',
  };

  /// Formats role with common mappings
  static String formatRoleWithMapping(String role) {
    final formatted = formatRole(role);
    return roleMappings[formatted.toLowerCase()] ?? formatted;
  }

  // ---------------------------------------------------------------------------
  // Text Validation and Cleaning
  // ---------------------------------------------------------------------------

  /// Removes special characters, keeping only letters, numbers, and basic punctuation
  static String removeSpecialCharacters(
    String input, {
    bool keepSpaces = true,
  }) {
    if (input.isEmpty) return input;

    String pattern = keepSpaces
        ? r'[^a-zA-Z0-9\s.,!?@#\$%\^&\*\(\)\-\+]'
        : r'[^a-zA-Z0-9.,!?@#\$%\^&\*\(\)\-\+]';

    return input.replaceAll(RegExp(pattern), '');
  }

  /// Validates if string contains only alphanumeric characters
  static bool isAlphanumeric(String input) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(input);
  }

  /// Validates if string contains only numbers
  static bool isNumeric(String input) {
    return RegExp(r'^[0-9]+$').hasMatch(input);
  }

  /// Validates if string contains only letters
  static bool isAlpha(String input) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(input);
  }

  /// Truncates string to specified length with ellipsis
  static String truncate(String input, int maxLength, {String suffix = '...'}) {
    if (input.length <= maxLength) return input;
    return input.substring(0, maxLength - suffix.length) + suffix;
  }

  /// Masks sensitive information (like phone numbers, emails)
  static String maskSensitive(
    String input, {
    int visibleChars = 4,
    String maskChar = '*',
  }) {
    if (input.isEmpty) return input;
    if (input.length <= visibleChars) return input;

    final visible = input.substring(0, visibleChars);
    final masked = maskChar * (input.length - visibleChars);

    return visible + masked;
  }

  // ---------------------------------------------------------------------------
  // Input Field Helpers
  // ---------------------------------------------------------------------------

  /// Formats text for input fields based on specified format type
  static String formatForInput(String input, InputFormat format) {
    switch (format) {
      case InputFormat.uppercase:
        return toUpperCase(input);
      case InputFormat.lowercase:
        return toLowerCase(input);
      case InputFormat.capitalize:
        return capitalizeFirst(input);
      case InputFormat.titleCase:
        return capitalizeWords(input);
      case InputFormat.noSpaces:
        return removeSpaces(input);
      case InputFormat.normalizeSpaces:
        return normalizeSpaces(input);
      case InputFormat.name:
        return formatName(input);
      case InputFormat.role:
        return formatRole(input);
    }
  }
}

/// Supported input formatting types
enum InputFormat {
  uppercase,
  lowercase,
  capitalize,
  titleCase,
  noSpaces,
  normalizeSpaces,
  name,
  role,
}
