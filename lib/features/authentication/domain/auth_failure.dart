enum AuthFailureCode {
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  invalidCredentials,
  network,
  sessionExpired,
  unavailable,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;

  String get message => switch (code) {
    AuthFailureCode.emailAlreadyInUse =>
      'An account already exists for that email.',
    AuthFailureCode.weakPassword => 'Choose a stronger password.',
    AuthFailureCode.invalidEmail => 'Enter a valid email address.',
    AuthFailureCode.invalidCredentials => 'Email or password is incorrect.',
    AuthFailureCode.network =>
      'You appear to be offline. Check your connection and try again.',
    AuthFailureCode.sessionExpired =>
      'Your session expired. Please log in again.',
    AuthFailureCode.unavailable =>
      'Authentication is temporarily unavailable. Try again shortly.',
    AuthFailureCode.unknown => 'Something went wrong. Please try again.',
  };
}
