import '../../../../shared/theme/app_theme.dart' show kSoftCardDecoration;

import 'package:flutter/material.dart';

/// A light, single surface for provider overview content.
class ProviderOverviewCard extends StatelessWidget {
  const ProviderOverviewCard({
    super.key,
    this.heading,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget? heading;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: kSoftCardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (heading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: heading,
          ),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}
