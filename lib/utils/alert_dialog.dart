import 'package:flutter/material.dart';

void alertMessage(context, title, {bool isCheckedIcon = false}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        scrollable: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        content: Text(title),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

BuildContext loadingDialog(context) {
  BuildContext dialogContext = context;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      dialogContext = context;
      return const AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: CircularProgressIndicator(),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text("Please wait..."),
              ),
            ),
          ],
        ),
      );
    },
  );

  return dialogContext;
}
