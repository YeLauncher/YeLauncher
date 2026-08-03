import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yelauncher/ui/core/tooltip.dart';

void main() {
  testWidgets('Tooltip stays within screen bounds', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) {
                return Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Tooltip(
                        message: 'This is a very long tooltip message that might go off screen if not properly bounded.',
                        child: const SizedBox(width: 50, height: 50),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );

    // Hover over the tooltip
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    // Move to the target (top right corner, so around x: 775, y: 25)
    await gesture.moveTo(const Offset(775, 25));
    await tester.pumpAndSettle();

    // Verify the tooltip is rendered
    expect(find.text('This is a very long tooltip message that might go off screen if not properly bounded.'), findsOneWidget);

    // Get the RenderBox of the tooltip text
    final RenderBox textRenderer = tester.renderObject(find.text('This is a very long tooltip message that might go off screen if not properly bounded.'));
    final offset = textRenderer.localToGlobal(Offset.zero);
    final size = textRenderer.size;

    // The screen size in tests is normally 800x600.
    // The right edge of the tooltip should not exceed 800.
    final rightEdge = offset.dx + size.width;
    // The screen size in tests is normally 800x600.
    expect(rightEdge <= 800.0, isTrue, reason: 'Tooltip right edge \$rightEdge exceeds screen width 800');
    expect(offset.dx >= 0.0, isTrue, reason: 'Tooltip left edge \${offset.dx} is less than 0');
  });
}
