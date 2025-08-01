part of 'wheel.dart';

enum HapticImpact { none, light, medium, heavy }

Offset _calculateWheelOffset(
    BoxConstraints constraints, TextDirection textDirection) {
  final smallerSide = getSmallerSide(constraints);
  var offsetX = constraints.maxWidth / 2;
  if (textDirection == TextDirection.rtl) {
    offsetX = offsetX * -1 + smallerSide / 2;
  }
  return Offset(offsetX, constraints.maxHeight / 2);
}

double _calculateSliceAngle(int index, int itemCount) {
  final anglePerChild = 2 * _math.pi / itemCount;
  final childAngle = anglePerChild * index;
  // first slice starts at 90 degrees, if 0 degrees is at the top.
  // The angle offset puts the center of the first slice at the top.
  final angleOffset = -(_math.pi / 2 + anglePerChild / 2);
  return childAngle + angleOffset;
}

/// Calculates the start angle for a weighted slice at the given index.
///
/// Uses cumulative weight distribution to determine slice boundaries.
double _calculateWeightedSliceAngle(int index, List<FortuneItem> items) {
  if (items.isEmpty) return 0.0;

  // Calculate total weight
  final totalWeight = items.fold<double>(0.0, (sum, item) => sum + item.weight);

  if (totalWeight <= 0) return 0.0;

  // Calculate cumulative weight up to the current index
  double cumulativeWeight = 0.0;
  for (int i = 0; i < index; i++) {
    cumulativeWeight += items[i].weight;
  }

  // Calculate the start angle based on cumulative weight proportion
  final startAngle = 2 * _math.pi * (cumulativeWeight / totalWeight);

  // Apply the same offset as uniform slices
  final angleOffset = -(_math.pi / 2);
  return startAngle + angleOffset;
}

/// Calculates the angle span for a weighted slice at the given index.
///
/// Returns the angle in radians that this slice should occupy.
double _calculateWeightedSliceSpan(int index, List<FortuneItem> items) {
  if (items.isEmpty || index >= items.length) return 0.0;

  // Calculate total weight
  final totalWeight = items.fold<double>(0.0, (sum, item) => sum + item.weight);

  if (totalWeight <= 0) return 0.0;

  // Calculate this slice's weight proportion
  final sliceWeight = items[index].weight;
  return 2 * _math.pi * (sliceWeight / totalWeight);
}

/// Calculates the center angle for a weighted slice at the given index.
///
/// This is the angle where the slice's center should be positioned.
double _calculateWeightedSliceCenterAngle(int index, List<FortuneItem> items) {
  final startAngle = _calculateWeightedSliceAngle(index, items);
  final span = _calculateWeightedSliceSpan(index, items);
  return startAngle + span / 2;
}

double _calculateAlignmentOffset(Alignment alignment) {
  if (alignment == Alignment.topRight) {
    return _math.pi * 0.25;
  }

  if (alignment == Alignment.centerRight) {
    return _math.pi * 0.5;
  }

  if (alignment == Alignment.bottomRight) {
    return _math.pi * 0.75;
  }

  if (alignment == Alignment.bottomCenter) {
    return _math.pi;
  }

  if (alignment == Alignment.bottomLeft) {
    return _math.pi * 1.25;
  }

  if (alignment == Alignment.centerLeft) {
    return _math.pi * 1.5;
  }

  if (alignment == Alignment.topLeft) {
    return _math.pi * 1.75;
  }

  return 0;
}

class _WheelData {
  final BoxConstraints constraints;
  final int itemCount;
  final TextDirection textDirection;
  final List<FortuneItem> items;

  late final double smallerSide = getSmallerSide(constraints);
  late final double largerSide = getLargerSide(constraints);
  late final double sideDifference = largerSide - smallerSide;
  late final Offset offset = _calculateWheelOffset(constraints, textDirection);
  late final Offset dOffset = Offset(
    (constraints.maxHeight - smallerSide) / 2,
    (constraints.maxWidth - smallerSide) / 2,
  );
  late final double diameter = smallerSide;
  late final double radius = diameter / 2;
  late final double itemAngle = 2 * _math.pi / itemCount;

  _WheelData({
    required this.constraints,
    required this.itemCount,
    required this.textDirection,
    required this.items,
  });
}

/// A fortune wheel visualizes a (random) selection process as a spinning wheel
/// divided into uniformly sized slices, which correspond to the number of
/// [items].
///
/// ![](https://raw.githubusercontent.com/kevlatus/flutter_fortune_wheel/main/images/img-wheel-256.png?sanitize=true)
///
/// See also:
///  * [FortuneBar], which provides an alternative visualization
///  * [FortuneWidget()], which automatically chooses a fitting widget
///  * [Fortune.randomItem], which helps selecting random items from a list
///  * [Fortune.randomDuration], which helps choosing a random duration
class FortuneWheel extends HookWidget implements FortuneWidget {
  /// The default value for [indicators] on a [FortuneWheel].
  /// Currently uses a single [TriangleIndicator] on [Alignment.topCenter].
  static const List<FortuneIndicator> kDefaultIndicators = <FortuneIndicator>[
    FortuneIndicator(
      alignment: Alignment.topCenter,
      child: TriangleIndicator(),
    ),
  ];

  static const StyleStrategy kDefaultStyleStrategy = AlternatingStyleStrategy();

  /// {@macro flutter_fortune_wheel.FortuneWidget.items}
  final List<FortuneItem> items;

  /// {@macro flutter_fortune_wheel.FortuneWidget.selected}
  final Stream<int> selected;

  /// {@macro flutter_fortune_wheel.FortuneWidget.rotationCount}
  final int rotationCount;

  /// {@macro flutter_fortune_wheel.FortuneWidget.duration}
  final Duration duration;

  /// {@macro flutter_fortune_wheel.FortuneWidget.indicators}
  final List<FortuneIndicator> indicators;

  /// {@macro flutter_fortune_wheel.FortuneWidget.animationType}
  final Curve curve;

  /// {@macro flutter_fortune_wheel.FortuneWidget.onAnimationStart}
  final VoidCallback? onAnimationStart;

  /// {@macro flutter_fortune_wheel.FortuneWidget.onAnimationEnd}
  final VoidCallback? onAnimationEnd;

  /// {@macro flutter_fortune_wheel.FortuneWidget.styleStrategy}
  final StyleStrategy styleStrategy;

  /// {@macro flutter_fortune_wheel.FortuneWidget.animateFirst}
  final bool animateFirst;

  /// {@macro flutter_fortune_wheel.FortuneWidget.physics}
  final PanPhysics physics;

  /// {@macro flutter_fortune_wheel.FortuneWidget.onFling}
  final VoidCallback? onFling;

  /// The position to which the wheel aligns the selected value.
  ///
  /// Defaults to [Alignment.topCenter]
  final Alignment alignment;

  /// HapticFeedback strength on each section border crossing.
  ///
  /// Defaults to [HapticImpact.none]
  final HapticImpact hapticImpact;

  /// Called with the index of the item at the focused [alignment] whenever
  /// a section border is crossed.
  final ValueChanged<int>? onFocusItemChanged;

  double _getAngle(double progress) {
    return 2 * _math.pi * rotationCount * progress;
  }

  /// {@template flutter_fortune_wheel.FortuneWheel}
  /// Creates a new [FortuneWheel] with the given [items], which is centered
  /// on the [selected] value.
  ///
  /// {@macro flutter_fortune_wheel.FortuneWidget.ctorArgs}.
  ///
  /// See also:
  ///  * [FortuneBar], which provides an alternative visualization.
  /// {@endtemplate}
  FortuneWheel({
    Key? key,
    required this.items,
    this.rotationCount = FortuneWidget.kDefaultRotationCount,
    this.selected = const Stream<int>.empty(),
    this.duration = FortuneWidget.kDefaultDuration,
    this.curve = FortuneCurve.spin,
    this.indicators = kDefaultIndicators,
    this.styleStrategy = kDefaultStyleStrategy,
    this.animateFirst = true,
    this.onAnimationStart,
    this.onAnimationEnd,
    this.alignment = Alignment.topCenter,
    this.hapticImpact = HapticImpact.none,
    PanPhysics? physics,
    this.onFling,
    this.onFocusItemChanged,
  })  : physics = physics ?? CircularPanPhysics(),
        assert(items.length > 1),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // Arrow animation: Setting up the AnimationController and Animation
    final arrowController =
        useAnimationController(duration: const Duration(milliseconds: 300));
// Initializes an AnimationController with a duration of 300 milliseconds.
// This controller manages the timing of the animation.

    final arrowAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(
        parent: arrowController,
        curve: Curves.easeOut, // Curve for the forward animation (ease out)
        reverseCurve:
            Curves.easeIn, // Curve for the reverse animation (ease in)
      ),
    );
// Creates an Animation that interpolates from 0 to -20 using a Tween.
// The animation uses a CurvedAnimation to apply easing curves for smoother motion.

    useEffect(() {
      // Add a listener to the arrowController to monitor animation status changes
      arrowController.addStatusListener((status) {
        // If the animation has completed (reached the end)
        if (status == AnimationStatus.completed) {
          // Reverse the animation back to the starting point
          arrowController.reverse();
        }
      });
      // No cleanup necessary, so return null
      return null;
    }, [arrowController]); // The effect depends on arrowController

    void _animateArrow() {
      // Check if the animation has completed (reached the end)
      if (arrowController.isCompleted) {
        // Reset the animation controller to the beginning
        arrowController.reset();
      }
      // Start the animation moving forward from the current position
      arrowController.forward();
    }

    final rotateAnimCtrl = useAnimationController(duration: duration);
    final rotateAnim = CurvedAnimation(parent: rotateAnimCtrl, curve: curve);
    Future<void> animate() async {
      if (rotateAnimCtrl.isAnimating) {
        return;
      }

      await Future.microtask(() => onAnimationStart?.call());
      await rotateAnimCtrl.forward(from: 0);
      await Future.microtask(() => onAnimationEnd?.call());
    }

    useEffect(() {
      if (animateFirst) animate();
      return null;
    }, []);

    final selectedIndex = useState<int>(0);

    useEffect(() {
      final subscription = selected.listen((event) {
        selectedIndex.value = event;
        animate();
      });
      return subscription.cancel;
    }, []);

    final lastVibratedAngle = useRef<double>(0);

    return PanAwareBuilder(
      behavior: HitTestBehavior.translucent,
      physics: physics,
      onFling: onFling,
      builder: (context, panState) {
        return Stack(
          children: [
            AnimatedBuilder(
              animation: rotateAnim,
              builder: (context, _) {
                final size = MediaQuery.of(context).size;
                final meanSize = (size.width + size.height) / 2;
                final panFactor = 6 / meanSize;

                return LayoutBuilder(builder: (context, constraints) {
                  final wheelData = _WheelData(
                    constraints: constraints,
                    itemCount: items.length,
                    textDirection: Directionality.of(context),
                    items: items,
                  );

                  final isAnimatingPanFactor =
                      rotateAnimCtrl.isAnimating ? 0 : 1;

                  // Calculate selected angle based on weighted slice position
                  final selectedAngle = _calculateWeightedSliceCenterAngle(
                        selectedIndex.value,
                        items,
                      ) *
                      -1; // Negative to rotate in correct direction

                  final panAngle =
                      panState.distance * panFactor * isAnimatingPanFactor;
                  final rotationAngle = _getAngle(rotateAnim.value);
                  final alignmentOffset = _calculateAlignmentOffset(alignment);
                  final totalAngle = selectedAngle + panAngle + rotationAngle;

                  final focusedIndex = _borderCrossWeighted(
                    totalAngle,
                    lastVibratedAngle,
                    items,
                    hapticImpact,
                    _animateArrow,
                  );
                  if (focusedIndex != null) {
                    onFocusItemChanged?.call(focusedIndex % items.length);
                  }

                  final transformedItems = [
                    for (var i = 0; i < items.length; i++)
                      TransformedFortuneItem(
                        item: items[i],
                        angle: totalAngle +
                            alignmentOffset +
                            _calculateWeightedSliceAngle(i, items),
                        offset: wheelData.offset,
                      ),
                  ];

                  return SizedBox.expand(
                    child: _CircleSlices(
                      items: transformedItems,
                      wheelData: wheelData,
                      styleStrategy: styleStrategy,
                    ),
                  );
                });
              },
            ),
            for (var it in indicators)
              IgnorePointer(
                child: Container(
                  alignment: it.alignment,
                  child: AnimatedBuilder(
                    animation: arrowAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, arrowAnimation.value),
                        child: child,
                      );
                    },
                    child: it.child,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// * vibrate and animate arrow when cross border
  int? _borderCross(
    double angle,
    ObjectRef<double> lastVibratedAngle,
    int itemsNumber,
    HapticImpact hapticImpact,
    VoidCallback animateArrow,
  ) {
    final step = 360 / itemsNumber;
    final angleDegrees = (angle * 180 / _math.pi).abs() + step / 2;
    if (step.isNaN ||
        angleDegrees.isNaN ||
        lastVibratedAngle.value.isNaN ||
        lastVibratedAngle.value.isInfinite ||
        angleDegrees.isInfinite ||
        step == 0) {
      return null;
    }
    if (lastVibratedAngle.value ~/ step == angleDegrees ~/ step) {
      return null;
    }
    final index = angleDegrees ~/ step * angle.sign.toInt() * -1;
    final hapticFeedbackFunction;
    switch (hapticImpact) {
      case HapticImpact.none:
        return index;
      case HapticImpact.heavy:
        hapticFeedbackFunction = HapticFeedback.heavyImpact;
        break;
      case HapticImpact.medium:
        hapticFeedbackFunction = HapticFeedback.mediumImpact;
        break;
      case HapticImpact.light:
        hapticFeedbackFunction = HapticFeedback.lightImpact;
        break;
    }
    hapticFeedbackFunction();
    animateArrow();
    lastVibratedAngle.value = (angleDegrees ~/ step) * step;
    return index;
  }

  /// * vibrate and animate arrow when cross border for weighted items
  int? _borderCrossWeighted(
    double angle,
    ObjectRef<double> lastVibratedAngle,
    List<FortuneItem> items,
    HapticImpact hapticImpact,
    VoidCallback animateArrow,
  ) {
    if (items.isEmpty) return null;

    // Convert angle to degrees and normalize to positive
    final angleDegrees = (angle * 180 / _math.pi).abs();

    // Calculate total weight
    final totalWeight =
        items.fold<double>(0.0, (sum, item) => sum + item.weight);
    if (totalWeight <= 0) return null;

    // Find which slice the angle falls into
    double cumulativeWeight = 0.0;
    for (int i = 0; i < items.length; i++) {
      final sliceWeight = items[i].weight;
      final sliceAngle = 360 * (sliceWeight / totalWeight);
      final sliceStart = 360 * (cumulativeWeight / totalWeight);
      final sliceEnd = sliceStart + sliceAngle;

      if (angleDegrees >= sliceStart && angleDegrees < sliceEnd) {
        // Check if we've crossed a border since last time
        final currentSlice = i;
        final lastSlice = lastVibratedAngle.value ~/ 360 * items.length;

        if (currentSlice != lastSlice) {
          final hapticFeedbackFunction;
          switch (hapticImpact) {
            case HapticImpact.none:
              return currentSlice;
            case HapticImpact.heavy:
              hapticFeedbackFunction = HapticFeedback.heavyImpact;
              break;
            case HapticImpact.medium:
              hapticFeedbackFunction = HapticFeedback.mediumImpact;
              break;
            case HapticImpact.light:
              hapticFeedbackFunction = HapticFeedback.lightImpact;
              break;
          }
          hapticFeedbackFunction();
          animateArrow();
          lastVibratedAngle.value = angleDegrees;
          return currentSlice;
        }
        return null;
      }

      cumulativeWeight += sliceWeight;
    }

    return null;
  }
}
