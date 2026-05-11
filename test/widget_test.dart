import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amena_vallee_ops/app_data.dart';
import 'package:amena_vallee_ops/main.dart';

void main() {
  testWidgets('navigates through the local operations workspace', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AmenaOpsApp(initialStore: OpsStore.seeded(screenshotMode: true)),
    );

    expect(find.text('Operations desk'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Staff training'), findsOneWidget);
    expect(find.text('Patient record handling'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Workspace settings'), findsOneWidget);
    expect(find.textContaining('local app storage'), findsOneWidget);
  });

  testWidgets('creates a local patient record', (WidgetTester tester) async {
    await tester.pumpWidget(
      AmenaOpsApp(initialStore: OpsStore.seeded(screenshotMode: true)),
    );

    await tester.tap(find.byIcon(Icons.folder_shared_outlined));
    await tester.pump(const Duration(milliseconds: 400));
    final newPatientButton = tester.widget<FloatingActionButton>(
      find.byKey(const Key('newPatientButton')),
    );
    newPatientButton.onPressed?.call();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('patientNameField')),
      'Nadia Roux',
    );
    await tester.enterText(
      find.byKey(const Key('patientCarePlanField')),
      'Intake paperwork and appointment follow up',
    );
    await tester.tap(find.byKey(const Key('savePatientButton')));
    await tester.pumpAndSettle();

    expect(find.text('Nadia Roux'), findsOneWidget);
  });
}
