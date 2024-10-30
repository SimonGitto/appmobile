import 'package:flutter/material.dart';

class TopLine extends StatelessWidget {
  final Widget child;


  TopLine({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 1.5,
          color: Colors.black12,
        ),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
