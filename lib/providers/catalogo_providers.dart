import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/barbero.dart';
import '../models/servicio.dart';
import '../services/barberos_service.dart';
import '../services/servicios_service.dart';

final serviciosProvider = FutureProvider<List<Servicio>>(
  (ref) => listarServicios(),
);

final barberosProvider = FutureProvider<List<Barbero>>(
  (ref) => listarBarberos(),
);
