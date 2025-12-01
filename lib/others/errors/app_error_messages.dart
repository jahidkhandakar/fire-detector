class AppErrorMessages {
  // Generic / default messages
  static const network =
      'Network error. Please check your internet connection.';
  static const timeout =
      'Request timed out. Please try again.';
  static const server =
      'Server error. Please try again later.';
  static const notFound =
      'No data found.';
  static const empty =
      'No data found.';
  static const parsing =
      'Something went wrong while reading the data.';
  static const unauthorized =
      'You are not authorized. Please login again.';
  static const unknown =
      'Something went wrong. Please try again.';

  // Module-specific Messages
  static const faqNotFound = 'FAQ not found.';
  static const faqEmpty = 'No FAQ available right now.';
  static const profileNotFound = 'Profile not found.';

  // 🔐 Auth-specific
  static const authRegistrationFailed =
      'Could not create your account. Please try again.';
  static const authVerificationFailed =
      'Verification failed. Please check the code and try again.';
  static const authLoginFailed =
      'Login failed. Please check your credentials.';
  static const authRefreshFailed =
      'Could not refresh your session. Please login again.';
  static const authOtpSessionExpired =
      'OTP session expired. Please start again.';
  static const authResendFailed =
      'Could not resend the OTP. Please try again.';

  static const authForgotInitFailed =
      'Could not start password reset. Please try again.';
  static const authForgotCompleteFailed =
      'Could not reset your password. Please check the code and try again.';
  static const authChangePasswordFailed =
      'Could not change your password. Please try again.';
}
