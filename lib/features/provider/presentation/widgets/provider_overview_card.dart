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
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFE8E8E8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
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
