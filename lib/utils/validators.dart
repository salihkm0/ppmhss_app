class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Enter a valid phone number';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? validateNumber(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }
    if (min != null && number < min) {
      return 'Value must be at least $min';
    }
    if (max != null && number > max) {
      return 'Value must be at most $max';
    }
    return null;
  }
  
  static String? validateMarks(String? value, int maxMarks) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final marks = int.tryParse(value);
    if (marks == null) {
      return 'Enter a valid number';
    }
    if (marks < 0) {
      return 'Marks cannot be negative';
    }
    if (marks > maxMarks) {
      return 'Marks cannot exceed $maxMarks';
    }
    return null;
  }
}