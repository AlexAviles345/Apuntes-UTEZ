import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'datos/bitacora_interceptor.dart';
import 'datos/cliente_http.dart';
import 'datos/falla_simulada_interceptor.dart';
import 'datos/publicaciones_api.dart';
import 'presentacion/publicaciones_pagina.dart';
import 'presentacion/publicaciones_view_model.dart';

/// Raíz de composición: el único lugar que arma Dio, la API y el ViewModel.
class AppHttp extends StatefulWidget {
  const AppHttp({super.key});

  @override
  State<AppHttp> createState() => _AppHttpState();
}

class _AppHttpState extends State<AppHttp> {
  final _falla = FallaSimuladaInterceptor();
  late final Dio _dio = crearDio(
    interceptores: [BitacoraInterceptor(), _falla],
  );
  late final _vm = PublicacionesViewModel(PublicacionesApi(_dio));

  @override
  void dispose() {
    _vm.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoTrack HTTP',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: PublicacionesPagina(
        vm: _vm,
        acciones: [
          PopupMenuButton<ModoFalla>(
            tooltip: 'Simular falla',
            icon: Icon(
              _falla.modo == ModoFalla.ninguna ? Icons.wifi : Icons.bug_report,
            ),
            initialValue: _falla.modo,
            onSelected: (modo) => setState(() => _falla.modo = modo),
            itemBuilder: (_) => [
              for (final modo in ModoFalla.values)
                PopupMenuItem(value: modo, child: Text(modo.etiqueta)),
            ],
          ),
        ],
      ),
    );
  }
}
