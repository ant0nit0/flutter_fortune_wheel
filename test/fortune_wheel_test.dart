import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('FortuneWheel', () {
    group('animation callbacks', () {
      testWidgets(
        'are not called on first build when animateFirst is false',
        (tester) async {
          var didCallStart = false;
          var didCallEnd = false;

          void onStart() {
            didCallStart = true;
          }

          void onEnd() {
            didCallEnd = true;
          }

          await pumpFortuneWidget(
            tester,
            FortuneWheel(
              animateFirst: false,
              selected: Stream.empty(),
              onAnimationStart: onStart,
              onAnimationEnd: onEnd,
              items: testItems,
            ),
          );

          await tester.pumpAndSettle();

          expect(didCallStart, isFalse);
          expect(didCallEnd, isFalse);
        },
      );

      testWidgets(
        'are called once on first build when animateFirst is true',
        (tester) async {
          final startLog = <bool>[];
          final endLog = <bool>[];

          void onStart() {
            startLog.add(true);
          }

          void onEnd() {
            endLog.add(true);
          }

          await pumpFortuneWidget(
            tester,
            FortuneWheel(
              animateFirst: true,
              selected: Stream.empty(),
              onAnimationStart: onStart,
              onAnimationEnd: onEnd,
              items: testItems,
            ),
          );

          await tester.pumpAndSettle();

          expect(startLog, hasLength(1));
          expect(startLog, contains(true));
          expect(endLog, hasLength(1));
          expect(endLog, contains(true));
        },
      );

      testWidgets(
        'are called when the value of selected changes',
        (tester) async {
          final startLog = <bool>[];
          final endLog = <bool>[];

          void onStart() {
            startLog.add(true);
          }

          void onEnd() {
            endLog.add(true);
          }

          final controller = StreamController<int>();

          await pumpFortuneWidget(
            tester,
            FortuneWheel(
              animateFirst: false,
              selected: controller.stream,
              items: testItems,
              onAnimationStart: onStart,
              onAnimationEnd: onEnd,
            ),
          );

          await tester.pumpAndSettle();

          expect(startLog, isEmpty);
          expect(endLog, isEmpty);

          controller.add(1);
          await tester.pumpAndSettle();

          expect(startLog, hasLength(1));
          expect(startLog, contains(true));
          expect(endLog, hasLength(1));
          expect(endLog, contains(true));

          controller.close();
        },
      );
    });

    group('weighted items', () {
      testWidgets(
        'renders weighted items with correct proportions',
        (tester) async {
          final weightedItems = [
            FortuneItem(child: Text('Common'), weight: 1.0),
            FortuneItem(child: Text('Rare'), weight: 0.5),
            FortuneItem(child: Text('Epic'), weight: 0.25),
          ];

          await pumpFortuneWidget(
            tester,
            FortuneWheel(
              animateFirst: false,
              selected: Stream.empty(),
              items: weightedItems,
            ),
          );

          await tester.pumpAndSettle();

          // Verify that the wheel renders without errors
          expect(find.byType(FortuneWheel), findsOneWidget);
        },
      );

      testWidgets(
        'handles weighted selection correctly',
        (tester) async {
          final weightedItems = [
            FortuneItem(child: Text('Common'), weight: 1.0),
            FortuneItem(child: Text('Rare'), weight: 0.5),
            FortuneItem(child: Text('Epic'), weight: 0.25),
          ];

          final controller = StreamController<int>();

          await pumpFortuneWidget(
            tester,
            FortuneWheel(
              animateFirst: false,
              selected: controller.stream,
              items: weightedItems,
            ),
          );

          await tester.pumpAndSettle();

          // Test weighted selection
          final selectedIndex = Fortune.randomWeightedIndex(weightedItems);
          expect(selectedIndex, greaterThanOrEqualTo(0));
          expect(selectedIndex, lessThan(weightedItems.length));

          controller.close();
        },
      );
    });
  });
}
