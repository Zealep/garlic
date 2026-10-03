import 'dart:typed_data';

import 'sync.dart';

/// Foto guardada en el equipo (evidencia de evaluación o comprobante de compra) para la galería.
abstract interface class FotoLocal {
  String get id;
  Uint8List get bytes;
  SyncState get syncState;
}
