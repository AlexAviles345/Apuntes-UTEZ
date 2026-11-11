# Recetario_utez — Práctica Evaluada: Consumir una API desde Cero (Unidad II)

Aplicación Flutter para consultar recetas de la cafetería UTEZ consumiendo el servicio real **DummyJSON Recipes** por HTTPS con **Dio**. Implementa separación estricta en tres capas (`dominio`, `datos`, `presentacion`), conversión manual y segura de JSON a objetos tipados, cliente HTTP con timeouts e interceptor de bitácora segura (`BitacoraInterceptor`), traducción de errores HTTP y de red a una jerarquía sellada (`FallaRed`), máquina de estados excluyentes (`EstadoRecetas`) en el ViewModel (`ChangeNotifier` + `ListenableBuilder`), 55 pruebas automatizadas en 5 etapas y evidencias de escenarios reales.

## Orden de Lectura

1. [Práctica evaluada — Recetario UTEZ: consumir una API desde cero](01%20-%20Recetario_utez%20-%20Pr%C3%A1ctica%20evaluada%20consumo%20de%20API.md): documento íntegro de la práctica con la actividad, reglas, entregables, cronograma, contratos de las Etapas 0 a 6 y tabla de calificación.
2. [Explicación de componentes, arquitectura y flujos](02%20-%20Recetario_utez%20-%20Explicaci%C3%B3n%20de%20componentes%2C%20arquitectura%20y%20flujos.md): análisis detallado de cada capa y archivo, diagramas de arquitectura, flujo de petición/respuesta/error y máquina de estados, desglose de las 55 pruebas por etapa y evidencias.

## Proyecto

| Carpeta | Uso |
|---|---|
| [`recetario_utez/`](recetario_utez/) | Aplicación Flutter completa con `lib/`, `test/` (55 pruebas de `kit_alumno`), `verificar_recetario.sh` y `docs/` (evidencias y capturas) |

## Ejecutar la Solución y las Verificaciones

Desde esta carpeta (`Recetario UTEZ`):

```bash
cd recetario_utez
flutter pub get
flutter run -d chrome
```

Para comprobar el verificador de arquitectura, el analizador estático y las 55 pruebas desde `recetario_utez/`:

```bash
bash verificar_recetario.sh
flutter analyze
flutter test -r expanded
```

[Volver al índice de Trabajos](../README.md).

