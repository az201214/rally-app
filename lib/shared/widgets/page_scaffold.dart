import 'package:flutter/material.dart';

/// Shared page layout for Rally's application-shell screens.
class PageScaffold extends StatelessWidget {
  const PageScaffold({this.title, this.child, super.key})
    : assert(
        (title == null) != (child == null),
        'Provide either a title or a child.',
      );

  final String? title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            child ??
            Text(title!, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
