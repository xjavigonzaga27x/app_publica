import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmButtonText;
  final String cancelButtonText;
  final Color? confirmButtonColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmButtonText = 'Eliminar',
    this.cancelButtonText = 'Cancelar',
    this.confirmButtonColor = Colors.red,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmButtonText = 'Eliminar',
    String cancelButtonText = 'Cancelar',
    Color? confirmButtonColor = Colors.red,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => ConfirmDialog(
            title: title,
            message: message,
            confirmButtonText: confirmButtonText,
            cancelButtonText: cancelButtonText,
            confirmButtonColor: confirmButtonColor,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelButtonText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: confirmButtonColor),
          child: Text(confirmButtonText),
        ),
      ],
    );
  }
}
