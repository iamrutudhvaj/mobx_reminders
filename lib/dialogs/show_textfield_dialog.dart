import 'package:flutter/material.dart';

enum TextfieldDialogButtonType { confirm, cancel }

typedef DialogOptionsBuilder = Map<TextfieldDialogButtonType, String>
    Function();

final controller = TextEditingController();

Future<String?> showTextFieldDialog({
  required BuildContext context,
  required String title,
  required String? hintText,
  required DialogOptionsBuilder optionsBuilder,
}) async {
  controller.clear();
  final options = optionsBuilder();

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          autofocus: true,
          controller: controller,
          onSubmitted: (value) {
            Navigator.of(context).pop(controller.text);
          },
          decoration: InputDecoration(
            hintText: hintText,
          ),
        ),
        actions: options.entries.map(
          (option) {
            return TextButton(
              onPressed: () {
                switch (option.key) {
                  case TextfieldDialogButtonType.confirm:
                    if (controller.text.isNotEmpty) {
                      Navigator.of(context).pop(controller.text);
                    } else {
                      Navigator.of(context).pop();
                    }
                    break;
                  case TextfieldDialogButtonType.cancel:
                    Navigator.of(context).pop();
                }
              },
              child: Text(option.value),
            );
          },
        ).toList(),
      );
    },
  );
}
