import 'package:flutter/material.dart' show BuildContext;

import 'generic_dialog.dart';

Future<bool> showDeleteReminderDialog(BuildContext context) async {
  return showGenericDialog<bool>(
    context: context,
    title: 'Delete Reminder',
    content:
        'Are you sure you want to delete this reminder? You cannot undo this action!',
    optionsBuilder: () => {
      'Cancel': false,
      'Delete Reminder': true,
    },
  ).then(
    (value) => value ?? false,
  );
}
