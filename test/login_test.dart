import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/Components/InputFields.dart';
import '../lib/Screens/Login/index.dart';

void main() {
  testWidgets('Login Page widgets', (WidgetTester tester) async {
    Key inputKey = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(        
        home: new Material(
          child: new LoginScreen(key: inputKey),
        ),
      )
    );    
    expect(find.widgetWithText(MaterialButton , 'SIGN IN'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byType(InputFieldArea), findsNWidgets(2));
    expect(find.widgetWithText(FlatButton , "Don't have an account? Sign Up"), findsOneWidget);
    expect(find.byType(Tick), findsOneWidget);      
  });
}