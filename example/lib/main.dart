// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    EdgeInsets insets1 = EdgeInsets.only(left: 1.0, right: 2.0);
    EdgeInsets insets2 = const EdgeInsets.all(14.0);
    Alignment alignment1 = Alignment.bottomLeft;
    Alignment alignment2 = Alignment(1, 2);

    return Stack(
      children: <Widget>[
        Positioned(
          left: 1.0,
          top: 2.0,
          child: ColoredBox(color: Theme.of(context).primaryColor),
        ),
        Positioned.fill(right: 4.0, child: const Placeholder()),
        Padding(
          padding: EdgeInsets.only(top: 18.0, left: 10.0, right: 11.0),
          child: Padding(
            padding: .only(left: 8.0),
            child: Align(
              alignment: Alignment.center,
              child: Align(
                alignment: .topLeft,
                child: Align(
                  alignment: Alignment(0, 0),
                  child: Text(
                    'Hello',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MyTest extends StatefulWidget {
  const MyTest({int? a, required int b, super.key});

  @override
  State<MyTest> createState() => _MyTestState();
}

class _MyTestState extends State<MyTest> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class SuperKeyFirst extends StatelessWidget {
  const SuperKeyFirst({super.key, this.title = 'Title'});

  final String title;

  @override
  Widget build(BuildContext context) => Text(title);
}

class Counter {
  Counter(this.start);

  final int start;
  static const int max = 10;
}

class HardcodedStrings extends StatelessWidget {
  const HardcodedStrings({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text('Hello'),
        Text('Hello $name'),
        const Tooltip(message: 'Save', child: Icon(Icons.save)),
        const TextField(decoration: InputDecoration(hintText: 'Email')),
        const Text.rich(TextSpan(text: 'Terms')),
        // Not reported: no letter, an asset path, an `Object` parameter.
        const Text('42'),
        Image.asset('assets/logo.png'),
        const Hero(tag: 'avatar', child: Placeholder()),
      ],
    );
  }
}
