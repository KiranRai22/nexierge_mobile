import 'package:flutter/material.dart';

/// Utility class for name validation and formatting
class NameValidator {
  /// Validates a name field according to the specified rules:
  /// - Only letters, hyphens, apostrophes, and single spaces allowed
  /// - Min 2 characters, max 50 characters (spaces not counted)
  /// - Max 1 space between letters
  /// - Cannot start or end with space
  static String? validateName(String value, String fieldName) {
    if (value.isEmpty) {
      return '$fieldName is required';
    }

    final trimmed = value.trim();
    
    // Count characters without spaces
    final characterCount = trimmed.replaceAll(' ', '').length;
    
    if (characterCount < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (characterCount > 50) {
      return '$fieldName must be at most 50 characters';
    }

    // Check if starts or ends with space
    if (value.startsWith(' ') || value.endsWith(' ')) {
      return '$fieldName cannot start or end with space';
    }

    // Check for multiple consecutive spaces
    if (value.contains('  ')) {
      return '$fieldName cannot have multiple consecutive spaces';
    }

    // Check for valid characters (letters, hyphens, apostrophes, and single spaces)
    final validCharsRegex = RegExp(r"^[a-zA-Z]+([ \-'][a-zA-Z]+)*$");
    if (!validCharsRegex.hasMatch(trimmed)) {
      return '$fieldName can only contain letters, hyphens, apostrophes, and single spaces';
    }

    return null;
  }

  /// Formats a name according to the rules:
  /// - Capitalizes first letter of each word
  /// - Removes extra spaces
  /// - Preserves hyphens and apostrophes
  static String formatName(String name) {
    if (name.isEmpty) return name;

    // Trim and normalize spaces
    String formatted = name.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Split by spaces and capitalize each word
    final words = formatted.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      
      // Handle words with hyphens or apostrophes
      if (word.contains('-') || word.contains("'")) {
        return _capitalizeComplexWord(word);
      }
      
      // Simple capitalization for regular words
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return capitalizedWords.join(' ');
  }

  /// Capitalizes a word that may contain hyphens or apostrophes
  /// Examples: "john-doe" -> "John-Doe", "o'connor" -> "O'Connor"
  static String _capitalizeComplexWord(String word) {
    // Split by hyphens and capitalize each part
    if (word.contains('-')) {
      final parts = word.split('-');
      final capitalizedParts = parts.map((part) {
        if (part.isEmpty) return part;
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      });
      return capitalizedParts.join('-');
    }
    
    // Handle apostrophes
    if (word.contains("'")) {
      final parts = word.split("'");
      if (parts.length >= 2) {
        // Capitalize first part
        final firstPart = parts[0].isNotEmpty 
            ? parts[0][0].toUpperCase() + parts[0].substring(1).toLowerCase()
            : "'";
        
        // Capitalize second part (after apostrophe)
        final secondPart = parts[1].isNotEmpty
            ? parts[1][0].toUpperCase() + parts[1].substring(1).toLowerCase()
            : '';
            
        return "$firstPart'$secondPart";
      }
    }
    
    // Fallback to simple capitalization
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  /// Validates a full name (first and last name combination)
  static String? validateFullName(String firstName, String lastName) {
    final firstError = validateName(firstName, 'First name');
    final lastError = validateName(lastName, 'Last name');
    
    return firstError ?? lastError;
  }

  /// Formats a full name (first and last name)
  static Map<String, String> formatFullName(String firstName, String lastName) {
    return {
      'firstName': formatName(firstName),
      'lastName': formatName(lastName),
    };
  }
}
