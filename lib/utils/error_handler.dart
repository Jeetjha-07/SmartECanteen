/// Error Handler Utility
/// Converts technical error messages into user-friendly error messages
class ErrorHandler {
  /// Format error message to be user-friendly
  static String formatError(String errorMessage) {
    // Handle null or empty errors
    if (errorMessage.isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Check for specific error patterns and convert to user-friendly messages
    final lowerError = errorMessage.toLowerCase();

    // Authentication Errors
    if (lowerError.contains('unauthorized') || lowerError.contains('401')) {
      return 'Invalid email or password. Please check and try again.';
    }

    if (lowerError.contains('user not found')) {
      return 'No account found with this email. Please sign up first.';
    }

    if (lowerError.contains('incorrect password') ||
        lowerError.contains('wrong password')) {
      return 'Incorrect password. Please try again.';
    }

    if (lowerError.contains('email already exists') ||
        lowerError.contains('already registered')) {
      return 'This email is already registered. Please log in instead.';
    }

    if (lowerError.contains('weak password')) {
      return 'Password must be at least 6 characters long.';
    }

    if (lowerError.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    // Network Errors
    if (lowerError.contains('connection error') ||
        lowerError.contains('cannot connect')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    if (lowerError.contains('timeout')) {
      return 'Request timed out. Please check your internet connection and try again.';
    }

    if (lowerError.contains('socket exception') ||
        lowerError.contains('network error')) {
      return 'Network error. Please check your internet connection.';
    }

    // Server Errors
    if (lowerError.contains('500') ||
        lowerError.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }

    if (lowerError.contains('400') || lowerError.contains('bad request')) {
      return 'Invalid request. Please check your input and try again.';
    }

    if (lowerError.contains('403') || lowerError.contains('forbidden')) {
      return 'You do not have permission to perform this action.';
    }

    if (lowerError.contains('404') || lowerError.contains('not found')) {
      return 'The requested item was not found.';
    }

    // Payment Errors
    if (lowerError.contains('payment failed')) {
      return 'Payment could not be processed. Please try again or use a different payment method.';
    }

    if (lowerError.contains('payment signature verification failed') ||
        lowerError.contains('signature verification')) {
      return 'Payment verification failed. Please try the payment again.';
    }

    if (lowerError.contains('invalid card')) {
      return 'Invalid card details. Please check and try again.';
    }

    if (lowerError.contains('insufficient funds')) {
      return 'Insufficient funds. Please use another payment method.';
    }

    // Coupon/Discount Errors
    if (lowerError.contains('invalid coupon') ||
        lowerError.contains('coupon not found')) {
      return 'Invalid or expired coupon code.';
    }

    if (lowerError.contains('coupon already used')) {
      return 'This coupon has already been used.';
    }

    // Order Errors
    if (lowerError.contains('order not found')) {
      return 'Order not found. Please check the order ID.';
    }

    if (lowerError.contains('invalid order')) {
      return 'Invalid order. Please try another order.';
    }

    // Menu/Restaurant Errors
    if (lowerError.contains('restaurant not found')) {
      return 'Restaurant not found. Please try another restaurant.';
    }

    if (lowerError.contains('menu item not found')) {
      return 'Menu item is no longer available.';
    }

    if (lowerError.contains('out of stock')) {
      return 'This item is currently out of stock.';
    }

    // Time Slot Errors
    if (lowerError.contains('slot unavailable') ||
        lowerError.contains('slot not available')) {
      return 'This time slot is not available. Please select another.';
    }

    if (lowerError.contains('time slot')) {
      return 'Please select a valid time slot.';
    }

    // Database Errors
    if (lowerError.contains('database error') ||
        lowerError.contains('mongodb')) {
      return 'Database error occurred. Please try again later.';
    }

    // If the error message is very long (likely a technical stack trace), truncate it
    if (errorMessage.length > 100) {
      // Extract key info if possible
      if (errorMessage.contains('Error:')) {
        final parts = errorMessage.split('Error:');
        if (parts.length > 1) {
          return 'Something went wrong. Please try again.';
        }
      }
      return 'An error occurred. Please try again.';
    }

    // If error contains only codes/URLs, return generic message
    if (errorMessage.startsWith('API Error:') ||
        errorMessage.contains('localhost') ||
        errorMessage.contains('HTTP')) {
      return 'An error occurred while processing your request. Please try again.';
    }

    // Return original message if it's already friendly
    return errorMessage;
  }

  /// Get error icon based on error type
  static String getErrorType(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('payment')) {
      return 'payment';
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'network';
    }
    if (lowerError.contains('auth') || lowerError.contains('password')) {
      return 'auth';
    }
    if (lowerError.contains('server') || lowerError.contains('500')) {
      return 'server';
    }

    return 'general';
  }

  /// Check if error is critical (requires action)
  static bool isCriticalError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();
    return lowerError.contains('500') ||
        lowerError.contains('database') ||
        lowerError.contains('internal server');
  }

  /// Get suggestion for user action
  static String getSuggestion(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('connection') || lowerError.contains('network')) {
      return 'Check your internet connection and try again.';
    }

    if (lowerError.contains('password')) {
      return 'Check that your password is correct. Use "Forgot Password" if needed.';
    }

    if (lowerError.contains('payment')) {
      return 'Try again with a different payment method or contact support.';
    }

    if (lowerError.contains('server') || lowerError.contains('500')) {
      return 'Please try again in a few moments.';
    }

    if (lowerError.contains('time slot')) {
      return 'Select a different time slot.';
    }

    return 'Please try again or contact support if the problem persists.';
  }
}
