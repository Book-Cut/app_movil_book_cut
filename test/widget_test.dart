// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:book_cut_app/main.dart';

void main() {
  testWidgets('starts on the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BookCutApp());

    expect(find.text('RESERVA TU CITA'), findsOneWidget);
    expect(find.text('Reservar ahora'), findsOneWidget);
    expect(find.text('Servicios'), findsNothing);
  });

  testWidgets('opens the login form from the welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BookCutApp());
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });

  testWidgets('opens registration from the login form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BookCutApp());
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(find.text('Confirmar contraseña'), findsOneWidget);
    expect(find.text('Acepto los términos y condiciones.'), findsOneWidget);
    expect(find.text('Registrarse con Google'), findsOneWidget);
    expect(find.text('Registrarse con Facebook'), findsOneWidget);
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(
      find.text('Debes aceptar los términos y condiciones.'),
      findsOneWidget,
    );
  });
}
