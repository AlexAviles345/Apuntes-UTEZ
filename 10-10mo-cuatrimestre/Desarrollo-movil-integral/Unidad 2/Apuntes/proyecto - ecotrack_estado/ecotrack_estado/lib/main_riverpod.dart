//   flutter run -t lib/main_riverpod.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecotrack_estado/variantes/b_riverpod.dart';
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const ProviderScope(child: AppRiverpod()));
}