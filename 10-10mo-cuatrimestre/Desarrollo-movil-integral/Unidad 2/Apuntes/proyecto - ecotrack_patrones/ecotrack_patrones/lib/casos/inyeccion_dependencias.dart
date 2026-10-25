import 'package:flutter/material.dart';

abstract class FuenteLab {
  Future<void> guardar(String laboratorio, double litros);
}

class LabEnMemoria implements FuenteLab {
  @override
  Future<void> guardar(String laboratorio, double litros) async {}
}

class LabQueFalla implements FuenteLab {
  @override
  Future<void> guardar(String laboratorio, double litros) async {
    throw Exception('Fallo simulado al guardar $laboratorio');
  }
}

/// Esta clase NO cambia entre los dos modos.
class PantallaRegistro extends StatelessWidget {
  const PantallaRegistro({super.key, required this.fuente});

  final FuenteLab fuente;

  Future<void> _alPulsarGuardar(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await fuente.guardar('Lab Química', 12.5);
      mensajero.showSnackBar(const SnackBar(content: Text('Guardado')));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => _alPulsarGuardar(context),
      child: const Text('Guardar Lab Química · 12.5 L'),
    );
  }
}

class PantallaLab extends StatefulWidget {
  const PantallaLab({super.key});

  @override
  State<PantallaLab> createState() => _PantallaLabState();
}

class _PantallaLabState extends State<PantallaLab> {
  bool _ensayarFallo = false;

  @override
  Widget build(BuildContext context) {
    final FuenteLab fuente = _ensayarFallo ? LabQueFalla() : LabEnMemoria();

    return Scaffold(
      appBar: AppBar(title: const Text('Laboratorio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Entregar LabQueFalla'),
            subtitle: Text('Se entrega: ${fuente.runtimeType}'),
            value: _ensayarFallo,
            onChanged: (v) => setState(() => _ensayarFallo = v),
          ),
          const SizedBox(height: 16),
          PantallaRegistro(fuente: fuente),
        ],
      ),
    );
  }
}

