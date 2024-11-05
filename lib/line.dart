import 'package:flutter/material.dart';

class TopLine extends StatelessWidget {
  final Widget child;


  const TopLine({super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 0.5,
          color: Colors.transparent,
        ),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
