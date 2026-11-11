import 'package:book_cut_app/components/selector_hora_sheet.dart';
import 'package:book_cut_app/core/sesion.dart';
import 'package:book_cut_app/main.dart';
import 'package:book_cut_app/models/barbero.dart';
import 'package:book_cut_app/models/servicio.dart';
import 'package:book_cut_app/providers/catalogo_providers.dart';
import 'package:book_cut_app/views/navegacion_rol.dart';
import 'package:book_cut_app/views/pantalla_admin_pendiente.dart';
import 'package:book_cut_app/views/pantalla_barbero.dart';
import 'package:book_cut_app/views/pantalla_bienvenida.dart';
import 'package:book_cut_app/views/pantalla_principal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    Sesion.token = null;
    Sesion.rolId = null;
    Sesion.nombre = null;
  });

  testWidgets('starts on the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BookCutApp());

    expect(find.text('RESERVA TU CITA'), findsOneWidget);
    expect(find.text('Reservar ahora'), findsOneWidget);
    expect(find.text('¿No tienes cuenta? Regístrate aquí'), findsOneWidget);
    expect(
      find.text(
        'Explora el catálogo e inicia sesión o regístrate para confirmar tu reserva.',
      ),
      findsNothing,
    );
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
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });

  testWidgets('opens registration from the login form and validates domains', (
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
    expect(find.text('Gmail, Hotmail, Outlook o sena.edu.co'), findsNothing);

    await tester.ensureVisible(find.text('Ver'));
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(find.text('Términos y condiciones'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(TextFormField, 'Teléfono'),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Teléfono'),
      '300abc1234567',
    );
    final telefonoField = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Teléfono'),
        matching: find.byType(TextField),
      ),
    );
    expect(telefonoField.controller?.text, '3001234567');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Teléfono'),
      '300123',
    );

    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(
      find.text('Debes aceptar los términos y condiciones.'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'prueba@yahoo.com',
    );
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('El teléfono debe tener 10 dígitos.'), findsOneWidget);
    expect(
      find.text(
        'Usa correo @gmail.com, @hotmail.com, @outlook.com o @sena.edu.co.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('PantallaAdminPendiente muestra mensaje conciso y sus dos botones', (
    WidgetTester tester,
  ) async {
    Sesion.nombre = 'Juan Admin';
    await tester.pumpWidget(
      const MaterialApp(home: PantallaAdminPendiente()),
    );

    expect(
      find.text('El panel de administrador aún está pendiente.'),
      findsOneWidget,
    );
    expect(find.text('Ir a mi perfil'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.text('Panel de administrador próximamente'), findsNothing);
  });

  test('pantallaInicioPorRol separa cliente, barbero, admin e invitado', () {
    Sesion.token = null;
    Sesion.rolId = null;
    expect(pantallaInicioPorRol(), isA<PantallaBienvenida>());

    Sesion.token = 'tok';
    Sesion.rolId = 3;
    expect(pantallaInicioPorRol(), isA<PantallaPrincipal>());

    Sesion.rolId = 2;
    expect(pantallaInicioPorRol(), isA<PantallaBarbero>());

    Sesion.rolId = 1;
    expect(pantallaInicioPorRol(), isA<PantallaAdminPendiente>());
  });

  testWidgets(
    'invitado en PantallaPrincipal ve aviso de inicio de sesion y al reservar pide crear cuenta o iniciar sesion',
    (WidgetTester tester) async {
      final serviciosMock = [
        Servicio(
          id: 3,
          nombre: 'Corte y Barba Premium',
          duracion: 60,
          precio: 35000,
        ),
      ];
      final barberosMock = [
        const Barbero(
          id: 2,
          nombre: 'Carlos Gomez',
          especialidad: 'Corte y Barba Premium',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            serviciosProvider.overrideWith((ref) async => serviciosMock),
            barberosProvider.overrideWith((ref) async => barberosMock),
          ],
          child: const MaterialApp(home: PantallaPrincipal()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inicia sesión para reservar'), findsOneWidget);

      await tester.tap(find.text('Corte y Barba Premium').first);
      await tester.pump();
      await tester.ensureVisible(find.text('Carlos Gomez'));
      await tester.tap(find.text('Carlos Gomez'));
      await tester.pumpAndSettle();

      expect(find.text('Crear cuenta para reservar'), findsOneWidget);
      expect(find.text('Ya tengo cuenta · Iniciar sesión'), findsOneWidget);
    },
  );

  testWidgets('SelectorHoraSheet limita horas al rango de la barberia', (
    WidgetTester tester,
  ) async {
    String? elegida;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                elegida = await mostrarSelectorHora(
                  context: context,
                  titulo: 'Lunes · Hora de fin',
                  horaActual: '19:00',
                  horaApertura: '09:00',
                  horaCierre: '19:00',
                  horaMinimaExclusiva: '13:00',
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Lunes · Hora de fin'), findsOneWidget);
    expect(
      find.text('Barbería: 9:00 AM – 7:00 PM · Posterior a 1:00 PM'),
      findsOneWidget,
    );
    expect(find.text('7:00 PM'), findsOneWidget);
    expect(find.text('7:30 PM'), findsNothing);
    expect(find.text('11:30 PM'), findsNothing);

    await tester.tap(find.text('Mañana'));
    await tester.pumpAndSettle();
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('8:30 AM'), findsNothing);

    await tester.tap(find.text('Tarde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1:00 PM'));
    await tester.pumpAndSettle();
    expect(elegida, isNull);

    await tester.tap(find.text('2:30 PM'));
    await tester.pumpAndSettle();
    expect(elegida, '14:30');
  });

  testWidgets('SelectorHoraSheet oculta franjas vacias segun horario del dia', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                mostrarSelectorHora(
                  context: context,
                  titulo: 'Domingo · Hora de inicio',
                  horaActual: '10:00',
                  horaApertura: '10:00',
                  horaCierre: '15:00',
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Mañana'), findsOneWidget);
    expect(find.text('Tarde'), findsOneWidget);
    expect(find.text('Noche'), findsNothing);
  });

  test('generarHorasFranja y ajustarHoraFinTrasInicio respetan apertura/cierre', () {
    final lunes = generarHorasFranja('09:00', '19:00');
    expect(lunes.first, '09:00');
    expect(lunes.last, '19:00');
    expect(lunes.length, 21);

    final sabado = generarHorasFranja('10:00', '20:00');
    expect(sabado.first, '10:00');
    expect(sabado.last, '20:00');

    expect(
      ajustarHoraFinTrasInicio('09:00', '19:00', horaCierre: '19:00'),
      '19:00',
    );
    expect(
      ajustarHoraFinTrasInicio('18:30', '18:30', horaCierre: '19:00'),
      '19:00',
    );
    expect(
      ajustarHoraFinTrasInicio('10:00', '21:00', horaCierre: '20:00'),
      '20:00',
    );
  });
}
