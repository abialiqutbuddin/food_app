import 'package:flutter/material.dart';

class WebShell extends StatelessWidget {
  final Widget header;
  final Widget left;   // forms
  final Widget right;  // orders/preview
  const WebShell({super.key, required this.header, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isWide = c.maxWidth >= 1100;
      final body = isWide
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: left),
          const SizedBox(width: 24),
          Expanded(flex: 5, child: right),
        ],
      )
          : Column(
        children: [
          left,
          const SizedBox(height: 24),
          right,
        ],
      );

      return Scrollbar(
        thumbVisibility: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              titleSpacing: 0,
              title: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: header,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: body,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}