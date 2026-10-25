// Pantalla que prueban las pruebas de INTERFAZ:
// "con litros vacíos se lee el mensaje y la pantalla de resumen no aparece".

import 'package:flutter/material.dart';
import '../datos/consumo_repositorio.dart';
import '../dominio/consumo.dart';
import 'historial_page.dart';
import 'resumen_page.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key, required this.repositorio});

  final ConsumoRepository repositorio;

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _litros = TextEditingController();
  final _kwh = TextEditingController();
  String _laboratorio = laboratrio.first;

  @override
  void dispose() {
    _litros.dispose();
    _kwh.dispose();
    super.dispose();
  }

  double? _numero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResumenPage(
          repositorio: widget.repositorio,
          consumo: Consumo(
            laboratorio: _laboratorio,
            litros: _numero(_litros.text)!,
            kwh: _numero(_kwh.text)!,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar consumo'),
        actions: [
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistorialPage(repositorio: widget.repositorio),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _laboratorio,
              decoration: const InputDecoration(labelText: 'Laboratorio'),
              items: [
                for (final lab in laboratrio)
                  DropdownMenuItem(value: lab, child: Text(lab)),
              ],
              onChanged: (lab) => setState(() => _laboratorio = lab!),
            ),
            TextFormField(
              key: const Key('campoLitros'),
              controller: _litros,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Litros'),
              validator: (v) => ReglaConsumo.validarLitros(_numero(v ?? '')),
            ),
            TextFormField(
              key: const Key('campoKwh'),
              controller: _kwh,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'kWh'),
              validator: (v) => ReglaConsumo.validarKwh(_numero(v ?? '')),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _continuar, child: const Text('Continuar')),
          ],
        ),
      ),
    );
  }
}
