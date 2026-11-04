import 'package:flutter/material.dart';

import '../dominio/publicacion.dart';

class TarjetaPublicacion extends StatelessWidget {
  const TarjetaPublicacion({super.key, required this.publicacion});

  final Publicacion publicacion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, child: Text('${publicacion.id}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    publicacion.titulo,
                    style: tema.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(publicacion.cuerpo, style: tema.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Autor #${publicacion.autorId}',
              style: tema.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
