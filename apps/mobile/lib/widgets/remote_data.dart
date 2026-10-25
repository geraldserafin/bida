import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import 'error_view.dart';

/// Shows data fetched from the server: a spinner while it loads, an
/// [ErrorView] with a retry button when it fails, [builder] once it is there.
///
/// The data is fetched again whenever the parent rebuilds, so screens stay
/// current after the state they watch changes, and the last data stays on
/// screen until the new data arrives.
class RemoteData<T> extends StatefulWidget {
  const RemoteData({
    super.key,
    required this.load,
    required this.builder,
    this.version,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  /// When given, the data is only fetched again once this value changes
  /// (compared with `==`), e.g. for a screen that rebuilds on every filter tap.
  final Object? version;

  @override
  State<RemoteData<T>> createState() => _RemoteDataState<T>();
}

class _RemoteDataState<T> extends State<RemoteData<T>> {
  late Future<T> _future = widget.load();

  @override
  void didUpdateWidget(RemoteData<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.version == null || widget.version != oldWidget.version) {
      _future = widget.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return widget.builder(context, snapshot.data as T);
        }
        final error = snapshot.error;
        if (error is ApiException) {
          return ErrorView(
            error: error,
            onRetry: () => setState(() => _future = widget.load()),
          );
        }
        if (error != null) {
          throw error; // a bug, not a failed request
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
