# La "depuración con patito de goma"

## Guía de la fuente

> El método de depuración con patito de goma es una técnica de ingeniería de software que consiste en explicar la lógica de un programa en voz alta frente a un objeto inanimado para identificar fallos. Este proceso psicológico obliga al desarrollador a abandonar las suposiciones mentales y a procesar la información de una manera mucho más lenta y analítica. Al tener que verbalizar cada instrucción paso a paso, el programador suele experimentar un hallazgo espontáneo del error antes incluso de terminar su relato. En definitiva, el texto ilustra cómo el simple acto de traducir el pensamiento al lenguaje puede revelar inconsistencias que pasan desapercibidas durante una lectura silenciosa.

---

La "depuración con patito de goma" (Rubber Duck Debugging) es una técnica clásica en ingeniería de software que consiste en explicarle tu código línea por línea a un patito de goma de juguete para encontrar un error.

**El principio psicológico detrás de esta técnica es simple:**

- **Obliga a verbalizar la lógica:** Cuando lees código en silencio, tu mente tiende a dar por sentadas muchas cosas y asume que "todo está bien".
- **Fuerza a bajar la velocidad:** Al intentar explicarle a un objeto que no sabe programar qué debe hacer cada instrucción (ejemplo: "Primero selecciono el botón, luego escucho el clic, luego convierto la respuesta a JSON y... ¡espera, no puse el await!"), tu cerebro procesa el flujo de forma analítica.
- **El hallazgo espontáneo:** En la mayoría de los casos, el programador descubre la falla por sí mismo en medio de la explicación, antes de terminar de hablar.
