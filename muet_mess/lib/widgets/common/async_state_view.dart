import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import 'skeleton.dart';

/// Standard wrapper handling loading / error / empty / data states.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.loading,
    this.error,
    required this.data,
    required this.builder,
    this.emptyMessage = 'Nothing to show',
    this.onRetry,
  });

  final bool loading;
  final String? error;
  final List<T> data;
  final Widget Function(BuildContext, List<T>) builder;
  final String emptyMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const ListSkeleton();
    if (error != null) {
      return ErrorState(title: 'Something went wrong', message: error!, onRetry: onRetry);
    }
    if (data.isEmpty) {
      return EmptyState(title: 'Nothing here yet', message: emptyMessage);
    }
    return builder(context, data);
  }
}
