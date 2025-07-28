// ignore_for_file: avoid_classes_with_only_static_members

part of 'core.dart';

/// Static methods for common tasks when working with [FortuneWidget]s.
abstract class Fortune {
  /// Generates a random integer uniformly distributed in the range
  /// from [min], inclusive, to [max], exclusive.
  ///
  /// The value of [max] must be larger than or equal to [min]. If it is equal
  /// to [min], this function always returns [min].
  ///
  /// An instance of [_math.Random] can optionally be passed to customize the
  /// random sample distribution.
  static int randomInt(int min, int max, [_math.Random? random]) {
    random = random ?? _math.Random();
    if (min == max) {
      return min;
    }
    final _rng = _math.Random();
    return min + _rng.nextInt(max - min);
  }

  /// Generates a random [Duration] uniformly distributed in the range
  /// from [min], inclusive, to [max], exclusive.
  ///
  /// The value of [max] must be larger than or equal to [min]. If it is equal
  /// to [min], this function always returns [min].
  ///
  /// An instance of [_math.Random] can optionally be passed to customize the
  /// random sample distribution.
  static Duration randomDuration(
    Duration min,
    Duration max, [
    _math.Random? random,
  ]) {
    random = random ?? _math.Random();
    return Duration(
      milliseconds: randomInt(min.inMilliseconds, max.inMilliseconds, random),
    );
  }

  /// Picks a random item from [iterable] and returns it.
  ///
  /// Uses [randomInt] internally to select an item index.
  ///
  /// An instance of [_math.Random] can optionally be passed to customize the
  /// random sample distribution.
  static T randomItem<T>(Iterable<T> iterable, [_math.Random? random]) {
    random = random ?? _math.Random();
    return iterable.elementAt(
      randomInt(0, iterable.length, random),
    );
  }

  /// Picks a random item from a list of [FortuneItem]s using their weights.
  ///
  /// Items with higher weights have a greater probability of being selected.
  /// Uses cumulative distribution function (CDF) for efficient weighted selection.
  ///
  /// An instance of [_math.Random] can optionally be passed to customize the
  /// random sample distribution.
  ///
  /// Example:
  /// ```dart
  /// final items = [
  ///   FortuneItem(child: Text('Common'), weight: 1.0),
  ///   FortuneItem(child: Text('Rare'), weight: 0.5),
  ///   FortuneItem(child: Text('Legendary'), weight: 0.1),
  /// ];
  /// final selected = Fortune.randomWeightedItem(items);
  /// ```
  static FortuneItem randomWeightedItem(
    List<FortuneItem> items, [
    _math.Random? random,
  ]) {
    random = random ?? _math.Random();

    if (items.isEmpty) {
      throw ArgumentError('Items list cannot be empty');
    }

    if (items.length == 1) {
      return items.first;
    }

    // Calculate total weight
    final totalWeight =
        items.fold<double>(0.0, (sum, item) => sum + item.weight);

    if (totalWeight <= 0) {
      throw ArgumentError('Total weight must be greater than 0');
    }

    // Generate random value between 0 and total weight
    final randomValue = random.nextDouble() * totalWeight;

    // Find the item using cumulative distribution
    double cumulativeWeight = 0.0;
    for (final item in items) {
      cumulativeWeight += item.weight;
      if (randomValue <= cumulativeWeight) {
        return item;
      }
    }

    // Fallback to last item (shouldn't happen with proper implementation)
    return items.last;
  }

  /// Picks a random index from a list of [FortuneItem]s using their weights.
  ///
  /// Items with higher weights have a greater probability of being selected.
  /// Returns the index of the selected item.
  ///
  /// An instance of [_math.Random] can optionally be passed to customize the
  /// random sample distribution.
  ///
  /// Example:
  /// ```dart
  /// final items = [
  ///   FortuneItem(child: Text('Common'), weight: 1.0),
  ///   FortuneItem(child: Text('Rare'), weight: 0.5),
  ///   FortuneItem(child: Text('Legendary'), weight: 0.1),
  /// ];
  /// final selectedIndex = Fortune.randomWeightedIndex(items);
  /// ```
  static int randomWeightedIndex(
    List<FortuneItem> items, [
    _math.Random? random,
  ]) {
    random = random ?? _math.Random();

    if (items.isEmpty) {
      throw ArgumentError('Items list cannot be empty');
    }

    if (items.length == 1) {
      return 0;
    }

    // Calculate total weight
    final totalWeight =
        items.fold<double>(0.0, (sum, item) => sum + item.weight);

    if (totalWeight <= 0) {
      throw ArgumentError('Total weight must be greater than 0');
    }

    // Generate random value between 0 and total weight
    final randomValue = random.nextDouble() * totalWeight;

    // Find the item index using cumulative distribution
    double cumulativeWeight = 0.0;
    for (int i = 0; i < items.length; i++) {
      cumulativeWeight += items[i].weight;
      if (randomValue <= cumulativeWeight) {
        return i;
      }
    }

    // Fallback to last item (shouldn't happen with proper implementation)
    return items.length - 1;
  }
}
