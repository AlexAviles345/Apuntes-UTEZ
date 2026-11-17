// Etapa 1 — reglas de la meta semanal. No conoce Flutter.

const metaInicial = 100.0;
const pasoMeta = 10.0;
const metaMinima = 10.0;

// Suma el cambio a la meta actual. Única dueña de la regla del mínimo.
double ajustarMeta(double actual, double cambio) =>
    (actual + cambio).clamp(metaMinima, double.infinity).toDouble();

// Fracción de la meta ya usada, entre 0 y 1. Si se rebasó, regresa 1.
double avanceDeMeta({required double total, required double meta}) {
  if (meta <= 0) return 0;
  return (total / meta).clamp(0, 1).toDouble();
}
