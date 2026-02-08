import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_bar_impl.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';

void main() {
  group('Bar - build actions', () {
    test('Bar - build default collapsible actions', () {
      //--- given
      FormatusControllerImpl ctrl = FormatusControllerImpl();

      //--- when
      FormatusBarImpl bar = FormatusBarImpl(
        controller: ctrl,
        actions: FormatusBar.collapsedActions,
      );

      //--- then
      expect(bar.actionGroups.length, 4);
      expect(bar.actionGroups[Formatus.collapseSections]?.length, 4);
      expect(bar.actions.length, 4);
    });
    test('Bar - build sections with end plus successor', () {
      //--- given
      FormatusControllerImpl ctrl = FormatusControllerImpl();

      //--- when
      FormatusBarImpl bar = FormatusBarImpl(
        controller: ctrl,
        actions: [
          Formatus.collapseSections,
          Formatus.header1,
          Formatus.header2,
          Formatus.collapseEnd,
          Formatus.header3,
        ],
      );

      //--- then
      expect(bar.actionGroups.length, 1);
      expect(bar.actionGroups[Formatus.collapseSections]?.length, 2);
      expect(bar.actions.length, 2);
      expect(bar.actions[0], Formatus.collapseSections);
      expect(bar.actions[1], Formatus.header3);
    });
    test('Bar - build sections ending with some inline', () {
      //--- given
      FormatusControllerImpl ctrl = FormatusControllerImpl();

      //--- when
      FormatusBarImpl bar = FormatusBarImpl(
        controller: ctrl,
        actions: [
          Formatus.collapseSections,
          Formatus.header1,
          Formatus.header2,
          Formatus.bold,
        ],
      );

      //--- then
      expect(bar.actionGroups.length, 1);
      expect(bar.actionGroups[Formatus.collapseSections]?.length, 2);
      expect(bar.actions.length, 2);
      expect(bar.actions[0], Formatus.collapseSections);
      expect(bar.actions[1], Formatus.bold);
    });
  });
}
