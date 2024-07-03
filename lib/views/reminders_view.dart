import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../dialogs/delete_reminder_dialog.dart';
import '../dialogs/show_textfield_dialog.dart';
import '../state/app_state.dart';
import 'main_popup_menu_button.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            onPressed: () async {
              final reminderText = await showTextFieldDialog(
                context: context,
                title: 'What do you want me to remind about?',
                hintText: 'Enter your reminder text here...',
                optionsBuilder: () => {
                  TextfieldDialogButtonType.cancel: 'Cancel',
                  TextfieldDialogButtonType.confirm: 'Save',
                },
              );
              if (reminderText == null || !context.mounted) {
                return;
              }
              context.read<AppState>().createReminder(reminderText);
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add Reminder',
          ),
          const MainPopupMenuButton(),
        ],
      ),
      body: const ReminderListView(),
    );
  }
}

class ReminderListView extends StatelessWidget {
  const ReminderListView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Observer(
      builder: (context) {
        return ListView.builder(
          itemCount: appState.sortedReminders.length,
          itemBuilder: (context, index) {
            final reminder = appState.sortedReminders[index];
            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: reminder.isDone,
              onChanged: (isDone) {
                appState.modifyReminder(
                  reminderId: reminder.id,
                  isDone: isDone ?? false,
                );
                reminder.isDone = isDone ?? false;
              },
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      reminder.text,
                      style: TextStyle(
                        decoration:
                            reminder.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final shouldDeleteReminder =
                          await showDeleteReminderDialog(context);
                      if (shouldDeleteReminder) {
                        if (!context.mounted) return;
                        context.read<AppState>().delete(reminder);
                      }
                    },
                    icon: const Icon(
                      Icons.delete,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
