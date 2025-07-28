import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

int roll(int itemCount) {
  return Random().nextInt(itemCount);
}

/// Rolls a weighted selection from a list of FortuneItems.
///
/// Uses the weight property of each FortuneItem to determine selection probability.
/// Items with higher weights have a greater chance of being selected.
int rollWeighted(List<FortuneItem> items) {
  return Fortune.randomWeightedIndex(items);
}

typedef IntCallback = void Function(int);

class RollButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const RollButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text('Roll'),
      onPressed: onPressed,
    );
  }
}

class RollButtonWithPreview extends StatelessWidget {
  final int selected;
  final List<String> items;
  final VoidCallback? onPressed;

  const RollButtonWithPreview({
    Key? key,
    required this.selected,
    required this.items,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.vertical,
      children: [
        RollButton(onPressed: onPressed),
        Text('Rolled Value: ${items[selected]}'),
      ],
    );
  }
}

class WeightedRollButtonWithPreview extends StatelessWidget {
  final int selected;
  final List<FortuneItem> items;
  final VoidCallback? onPressed;

  const WeightedRollButtonWithPreview({
    Key? key,
    required this.selected,
    required this.items,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.vertical,
      children: [
        ElevatedButton(
          child: Text('Roll Weighted'),
          onPressed: onPressed,
        ),
        Text('Rolled Value: ${(items[selected].child as Text).data}'),
        Text('Weight: ${items[selected].weight}'),
      ],
    );
  }
}
