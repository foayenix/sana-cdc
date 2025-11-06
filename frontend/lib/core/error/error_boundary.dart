import 'package:flutter/material.dart';

/// Error Boundary Widget
///
/// Catches and displays errors gracefully in the UI.
/// Prevents app crashes and provides user-friendly error messages.
///
/// Usage:
/// ErrorBoundary(
///   child: YourWidget(),
///   onError: (error, stackTrace) {
///     // Optional: Send to error tracking service
///     print('Error caught: $error');
///   },
/// )
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });

        widget.onError?.call(details.exception, details.stack ?? StackTrace.empty);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!);
      }

      return ErrorView(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return widget.child;
  }
}

/// Default Error View
///
/// Displays a user-friendly error message with retry button.
class ErrorView extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _getUserFriendlyMessage(error),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // In development, show error details
              if (_isDevelopment()) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Error Details (Development Only)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      '$error\n\n${stackTrace ?? "No stack trace"}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getUserFriendlyMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Unable to connect to the server.\nPlease check your internet connection.';
    }

    if (errorString.contains('timeout')) {
      return 'The request took too long.\nPlease try again.';
    }

    if (errorString.contains('permission')) {
      return 'Permission denied.\nPlease check your app permissions.';
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'The requested resource was not found.';
    }

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Authentication failed.\nPlease log in again.';
    }

    if (errorString.contains('500') || errorString.contains('server error')) {
      return 'Server error occurred.\nPlease try again later.';
    }

    return 'An unexpected error occurred.\nWe\'re working to fix it.';
  }

  bool _isDevelopment() {
    bool isDev = false;
    assert(() {
      isDev = true;
      return true;
    }());
    return isDev;
  }
}

/// Global Error Handler
///
/// Set up global error handling for the entire app.
/// Call this in main() before runApp().
///
/// Usage:
/// void main() {
///   GlobalErrorHandler.init(
///     onError: (error, stackTrace) {
///       // Send to error tracking service (Sentry, etc.)
///       print('Global error: $error');
///     },
///   );
///   runApp(MyApp());
/// }
class GlobalErrorHandler {
  static void init({
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      onError?.call(details.exception, details.stack ?? StackTrace.empty);
    };

    // Catch errors outside Flutter framework (async errors)
    // This requires importing dart:isolate
    // Isolate.current.addErrorListener(
    //   RawReceivePort((pair) {
    //     final List<dynamic> errorAndStacktrace = pair;
    //     onError?.call(errorAndStacktrace.first, errorAndStacktrace.last);
    //   }).sendPort,
    // );
  }
}
