import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled Nunito so widget and golden tests render real glyphs.
Future<void> loadNunito() async {
  final bytes = File('assets/fonts/Nunito-Variable.ttf').readAsBytesSync();
  final loader = FontLoader('Nunito')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}
