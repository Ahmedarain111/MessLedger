import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/status_style.dart';
import '../../models/meal_model.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/layout_widgets.dart';
import '../../widgets/common/shift_badge.dart';
import '../../widgets/common/skeleton.dart';

class DisputeScreen extends StatefulWidget {
  final String id;
  const DisputeScreen({super.key, required this.id});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final description = TextEditingController();
  String selectedReason = 'Wrong amount';
  late Future<Meal> _entryFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _entryFuture = context.read<MealProvider>().getEntry(widget.id);
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  Future<void> _submit(Meal entry) async {
    final reason = description.text.trim().isEmpty ? selectedReason : description.text.trim();
    if (reason.length < 5) {
      showError(context, 'Please enter at least 5 characters.');
      return;
    }
    final mealProvider = context.read<MealProvider>();
    setState(() => _submitting = true);
    try {
      await mealProvider.dispute(entry.id, reason: reason);
      if (!mounted) return;
      showSuccess(context, 'Dispute submitted.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: const Text('Raise Dispute'));
    return FutureBuilder<Meal>(
      future: _entryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: appBar, body: const ListSkeleton(itemCount: 2, itemHeight: 130));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: appBar,
            body: const EmptyState(title: 'Entry not found', message: 'This entry could not be loaded.', icon: Icons.search_off),
          );
        }
        final entry = snapshot.data!;
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: appBar,
          body: ContentList(
            maxWidth: 640,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    ShiftBadge(shift: entry.shift, size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(shiftLabel(entry.shift.name), style: text.titleMedium),
                        const SizedBox(height: 2),
                        Text(dateTimeText(entry.dateTime), style: text.bodySmall),
                        const SizedBox(height: 8),
                        Row(children: [
                          StatusChip.style(entryStatusStyle(context, entry.entryStatus)),
                          const Spacer(),
                          AmountText(entry.totalAmount, bold: true, size: 16),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SectionHeader('Reason for dispute'),
              Card(
                child: RadioGroup<String>(
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value!),
                  child: Column(
                    children: ['Wrong amount', 'Item missing', 'Didn\'t eat this', 'Other']
                        .map((reason) => RadioListTile<String>(value: reason, title: Text(reason)))
                        .toList(),
                  ),
                ),
              ),
              const SectionHeader('Details'),
              TextField(
                controller: description,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue in at least 5 characters.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: _submitting
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: scheme.onPrimary))
                    : const Icon(Icons.flag),
                label: Text(_submitting ? 'Submitting…' : 'Submit dispute'),
                onPressed: _submitting ? null : () => _submit(entry),
              ),
            ],
          ),
        );
      },
    );
  }
}
