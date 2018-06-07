import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/Components/InputFields.dart';
import '../lib/Screens/SignUp/index.dart';


void main() {
  testWidgets('Sign up Page widgets', (WidgetTester tester) async {
    Key inputKey = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(        
        home: new Material(
          child: new SignUpScreen(key: inputKey),
        ),
      )
    );    
    expect(find.widgetWithText(MaterialButton , 'SIGN UP'), findsOneWidget);
    expect(find.byIcon(Icons.email), findsOneWidget); 
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
    expect(find.byType(InputFieldArea), findsNWidgets(3));   
    expect(find.byType(Logo), findsOneWidget);            
  });
}