import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/Screens/ForgotPassword/index.dart';

void main() {
  testWidgets('Reset Password Page widgets', (WidgetTester tester) async {
    Key inputKey = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(        
        home: new Material(
          child: new ForgotPasswordScreen(key: inputKey),
        ),
      )
    );    
    expect(find.widgetWithText(MaterialButton , 'RESET PASSWORD'), findsOneWidget);
    expect(find.byIcon(Icons.email), findsOneWidget);    
    expect(find.byType(Logo), findsOneWidget);   
    await tester.tap(find.byType(MaterialButton));
    await tester.pumpAndSettle(
      new Duration(
        milliseconds: 100
      )
    );
    expect(find.widgetWithText(ListBody , 'Account does not exist'), findsOneWidget);    
  });
}