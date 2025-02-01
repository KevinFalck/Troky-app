import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.bottom,
  }) : super(key: key);

  @override
  Size get preferredSize {
    return Size.fromHeight(bottom?.preferredSize.height ?? kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      automaticallyImplyLeading: false, // Retire la flèche de retour
      actions: actions,
      bottom: bottom,
    );
  }
}
