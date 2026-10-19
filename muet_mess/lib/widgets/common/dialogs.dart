import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for a short free-text reason. Returns the trimmed text (possibly
/// empty) on confirm, or null if the dialog was cancelled.
Future<String?> reasonDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Submit',
  String hint = 'Reason',
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      hint: hint,
      destructive: destructive,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.hint,
    required this.destructive,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String hint;
  final bool destructive;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: widget.hint),
          ),
        ]),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError)
              : null,
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

enum _ToastKind { success, error, info }

void _toast(BuildContext context, String message, _ToastKind kind) {
  final tokens = context.tokens;
  final scheme = Theme.of(context).colorScheme;
  final (IconData icon, Color color) = switch (kind) {
    _ToastKind.success => (Icons.check_circle, tokens.success),
    _ToastKind.error => (Icons.error, tokens.danger),
    _ToastKind.info => (Icons.info, scheme.inversePrimary),
  };
  final wide = MediaQuery.sizeOf(context).width > 640;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      width: wide ? 460 : null,
      duration: Duration(seconds: kind == _ToastKind.error ? 5 : 3),
      content: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ]),
    ));
}

void showError(BuildContext context, String message) => _toast(context, message, _ToastKind.error);

void showInfo(BuildContext context, String message) => _toast(context, message, _ToastKind.info);

void showSuccess(BuildContext context, String message) => _toast(context, message, _ToastKind.success);
