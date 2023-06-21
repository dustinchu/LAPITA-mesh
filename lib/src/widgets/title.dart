import 'package:flutter/material.dart';

class TitleWidget extends StatelessWidget {
  TitleWidget({Key? key, required this.titleText});
  String titleText;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        titleText,
        style: theme.useMaterial3
            ? theme.textTheme.titleMedium!
            : theme.textTheme.titleMedium!,
      ),
    );
  }
}

class TitleWidget2 extends StatelessWidget {
  TitleWidget2(
      {Key? key,
      required this.titleText,
      required this.isScanning,
      required this.onTap});
  String titleText;
  bool isScanning;
  VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titleText,
            style: theme.useMaterial3
                ? theme.textTheme.titleMedium!
                : theme.textTheme.titleMedium!,
          ),
          isScanning
              ? Container(
                  margin: EdgeInsets.only(right: 10),
                  width: 20,
                  height: 20,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : IconButton(onPressed: onTap, icon: const Icon(Icons.refresh))
        ],
      ),
    );
  }
}
