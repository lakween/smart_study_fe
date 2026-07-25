import '../constants/app_strings.dart';
import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.emailRequired;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) return AppStrings.emailInvalid;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.passwordRequired;
    if (value.length < AppConstants.minPasswordLength) return AppStrings.passwordTooShort;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    if (!hasLetter || !hasNumber) return AppStrings.passwordWeak;
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return AppStrings.passwordRequired;
    if (value != password) return AppStrings.passwordsDoNotMatch;
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.nameRequired;
    if (value.trim().length < AppConstants.minNameLength) return AppStrings.nameTooShort;
    return null;
  }

  static String? subjectName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.subjectNameRequired;
    if (value.trim().length < AppConstants.minNameLength) return AppStrings.subjectNameTooShort;
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? quizTitle(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.quizTitleRequired;
    if (value.trim().length < AppConstants.minQuizTitleLength) {
      return 'Quiz title must be at least ${AppConstants.minQuizTitleLength} characters';
    }
    return null;
  }

  static String? questionText(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.questionRequired;
    if (value.trim().length < AppConstants.minQuestionLength) {
      return 'Question must be at least ${AppConstants.minQuestionLength} characters';
    }
    return null;
  }

  static String? option(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.optionRequired;
    return null;
  }
}
