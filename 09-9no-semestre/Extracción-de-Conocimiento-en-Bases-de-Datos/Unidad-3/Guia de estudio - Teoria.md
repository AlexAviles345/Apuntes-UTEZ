# Teoría — Unidad 3: Aprendizaje Supervisado y Regresión

---

## Tabla de Contenidos

1. [Aprendizaje Supervisado vs No Supervisado](#1-aprendizaje-supervisado-vs-no-supervisado)
2. [Algoritmos de Aprendizaje Supervisado](#2-algoritmos-de-aprendizaje-supervisado)
3. [Regresión — Definición y Tipos](#3-regresión--definición-y-tipos)
4. [Regresión Lineal Simple](#4-regresión-lineal-simple)
5. [Regresión Lineal Múltiple](#5-regresión-lineal-múltiple)
6. [Regresión Polinomial](#6-regresión-polinomial)
7. [Formas de Polinomios en Gráficas (Grados 1 al 5)](#7-formas-de-polinomios-en-gráficas-grados-1-al-5)
8. [Métricas de Evaluación: RMSE y R²](#8-métricas-de-evaluación-rmse-y-r)
9. [Transformación de Datos: Normalización vs Escalamiento](#9-transformación-de-datos-normalización-vs-escalamiento)
10. [División de Datos: Entrenamiento y Prueba](#10-división-de-datos-entrenamiento-y-prueba)

---

## 1. Aprendizaje Supervisado vs No Supervisado

### Aprendizaje Supervisado

Se encarga del **mapeo de entradas en salidas** con base en **datos de entrenamiento etiquetados** (pares entrada–salida ya conocidos).

- **Entrada**: variables independientes (x₁, x₂, ...).
- **Salida**: variable dependiente (y) ya conocida durante el entrenamiento.
- **Objetivo**: inferir una función que permita predecir o clasificar nuevos ejemplos nunca vistos.
- El algoritmo **produce una función inferida** (modelo). Con esa función se pueden hacer predicciones de manera razonable sobre datos nuevos.
- Siempre existe un **error de generalización**: la función nunca es perfecta para datos nuevos.

### Aprendizaje No Supervisado

Se usa cuando los datos **no tienen etiquetas**. No se predice ni clasifica; se **agrupa** para descubrir estructura oculta en los datos.

| | Supervisado | No Supervisado |
|---|---|---|
| Datos | Etiquetados (x → y conocida) | Sin etiquetas |
| Tarea | Predecir / clasificar | Agrupar / descubrir estructura |
| Algoritmos vistos | Regresión, K-NN | K-Means |
| Ejemplo | Predecir ventas, clasificar Aprobado/Reprobado | Segmentar clientes sin grupos predefinidos |

---

## 2. Algoritmos de Aprendizaje Supervisado

Los algoritmos supervisados se dividen en dos tareas según el tipo de variable objetivo:

| Tarea | Variable objetivo | Algoritmos |
|---|---|---|
| **Regresión** | Variable **continua** (números) | Regresión lineal, polinomial |
| **Clasificación** | Variable **discreta** (categorías) | K-NN, SVM, Árboles de decisión, Naive Bayes |

### Algoritmos vistos en el curso

**Regresión**
- Predice valores numéricos continuos.
- Se usa cuando la respuesta es un número (ventas, resistencia, temperatura).

**K-NN (K Nearest Neighbors)**
- Algoritmo de clasificación.
- Clasifica un dato nuevo según los **k vecinos más cercanos** en el espacio de características.
- Ejemplo: dos grupos (Aprobado / Reprobado); KNN asigna un nuevo punto al grupo más cercano.
- Requiere que los datos estén **normalizados** antes de usarlo (porque usa distancias).

**SVM, Árboles de decisión, Naive Bayes**
- Mencionados como parte del panorama de algoritmos supervisados de clasificación.

**K-Means (No supervisado)**
- Agrupa datos en K clusters según la distancia al centroide más cercano.
- No predice: descubre grupos.

---

## 3. Regresión — Definición y Tipos

La **regresión** es un método estadístico para estimar el nivel del **efecto de una variable independiente (x)** sobre una **variable dependiente (y)**, expresado como una función matemática.

### Clasificación de la regresión (según tus apuntes)

```
Regresión
 ├── Por cantidad de variables
 │     ├── Simple     → 1 variable independiente (x)
 │     └── Múltiple   → más de 1 variable independiente (x₁, x₂, ...)
 │
 └── Por grado del polinomio
       ├── Lineal     → grado 1
       └── Polinomial → grado > 1
```

Esto genera combinaciones: **Lineal Simple**, **Lineal Múltiple**, **Polinomial Simple**, **Polinomial Múltiple**.

### Tipos por forma de la curva

| Tipo | Cuándo usarla | Forma de la curva |
|---|---|---|
| **Lineal simple** | 1 variable x, relación recta | Línea recta |
| **Lineal múltiple** | Varias x, relación recta | Plano o hiperplano |
| **Polinomial** | Curva no recta | Parábola, cúbica, etc. |
| **Logística** | Variable y binaria (0 o 1) | Forma de "S" (sigmoide) |
| **Exponencial** | Crecimiento/decaimiento acelerado | Curva exponencial |
| **Logarítmica** | Crecimiento rápido que se estabiliza | Curva logarítmica |

---

## 4. Regresión Lineal Simple

### ¿Qué es?

Describe la relación entre **una variable independiente (x)** y **una variable dependiente (y)** cuando muestran una relación lineal.

Pregunta que responde: ¿cómo se incrementa o decrementa **y** cuando varía **x**?

### Fórmula del modelo

$$y = b_0 + b_1 x + E$$

| Símbolo | Nombre | Significado |
|---|---|---|
| $b_0$ | Intercepto | Valor de y cuando x = 0 |
| $b_1$ | Pendiente | Cuánto cambia y por cada unidad que aumenta x |
| $E$ | Error / residuo | Diferencia entre el valor real y el predicho |

### Fórmulas para calcular b₀ y b₁

$$b_1 = \frac{n \sum xy - \sum x \sum y}{n \sum x^2 - (\sum x)^2}$$

$$b_0 = \frac{\sum y \sum x^2 - \sum x \sum xy}{n \sum x^2 - (\sum x)^2}$$

Donde $n$ = número de observaciones.

### Datos requeridos para el cálculo manual

Se necesitan las siguientes sumatorias de la tabla de datos:

$$\sum x \quad \sum y \quad \sum x^2 \quad \sum xy \quad (\sum x)^2$$

### Ejemplo conceptual

Dados los puntos (0, −2), (1, 1), (2, 4):
- Se traza el scatter plot.
- Se calcula la pendiente a partir de los puntos.
- La función resultante es: $y = 3x - 2$

---

## 5. Regresión Lineal Múltiple

### ¿Qué es?

Extensión de la regresión lineal simple para cuando existen **más de una variable independiente**.

### Fórmula del modelo (2 variables)

$$y = b_0 + b_1 x_1 + b_2 x_2 + E$$

### ¿Qué son los coeficientes S?

Son valores intermedios que se calculan a partir de las sumatorias de los datos. Representan la **varianza y covarianza ajustadas** de cada variable.

$$Sx_1^2 = \sum x_1^2 - \frac{(\sum x_1)^2}{n}$$

$$Sx_2^2 = \sum x_2^2 - \frac{(\sum x_2)^2}{n}$$

$$Sx_1 y = \sum x_1 y - \frac{\sum x_1 \cdot \sum y}{n}$$

$$Sx_2 y = \sum x_2 y - \frac{\sum x_2 \cdot \sum y}{n}$$

$$Sx_1 x_2 = \sum x_1 x_2 - \frac{\sum x_1 \cdot \sum x_2}{n}$$

### Fórmulas para b₁, b₂ y b₀

$$b_1 = \frac{Sx_2^2 \cdot Sx_1 y - Sx_1 x_2 \cdot Sx_2 y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1 x_2)^2}$$

$$b_2 = \frac{Sx_1^2 \cdot Sx_2 y - Sx_1 x_2 \cdot Sx_1 y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1 x_2)^2}$$

$$b_0 = \bar{y} - b_1 \bar{x}_1 - b_2 \bar{x}_2$$

Donde $\bar{y}$, $\bar{x}_1$, $\bar{x}_2$ son las **medias** (promedios) de cada variable.

### Datos requeridos para el cálculo manual

$$\sum x_1 \quad \sum x_2 \quad \sum y \quad \sum x_1^2 \quad \sum x_2^2 \quad \sum x_1 y \quad \sum x_2 y \quad \sum x_1 x_2$$

---

## 6. Regresión Polinomial

### ¿Cuándo usarla?

Cuando la relación entre las variables **no es lineal** — la nube de puntos describe una curva, no una recta. Se necesita **elevar las variables a potencias** para capturar esa curvatura.

### Fórmula del modelo (grado 2, 1 variable)

$$y = b_0 + b_1 x + b_2 x^2$$

### Sistema de ecuaciones normales (grado 2)

Para obtener b₀, b₁ y b₂ se plantea y resuelve este sistema de 3 ecuaciones simultáneas:

$$\begin{cases} n b_0 + \sum x \cdot b_1 + \sum x^2 \cdot b_2 = \sum y \\ b_0 \sum x + \sum x^2 \cdot b_1 + \sum x^3 \cdot b_2 = \sum xy \\ b_0 \sum x^2 + \sum x^3 \cdot b_1 + \sum x^4 \cdot b_2 = \sum x^2 y \end{cases}$$

> Para grado 3 → 4 ecuaciones. Para grado $k$ → $k+1$ ecuaciones.

### Datos requeridos para el cálculo manual (grado 2)

$$\sum x \quad \sum x^2 \quad \sum x^3 \quad \sum x^4 \quad \sum y \quad \sum xy \quad \sum x^2 y$$

### Expansión polinomial con 2 variables (grado 2)

Cuando hay 2 variables independientes y se aplica grado 2, el modelo completo es:

$$y = b_0 + b_1 x_1 + b_2 x_1^2 + b_3 x_2 + b_4 x_2^2 + b_5 x_1 x_2$$

Python genera automáticamente todas esas columnas con `PolynomialFeatures`.

---

## 7. Formas de Polinomios en Gráficas (Grados 1 al 5)

| Grado | Nombre | Forma general | Forma de la curva |
|---|---|---|---|
| 1 | Lineal | $y = b_0 + b_1 x$ | Línea recta — siempre creciente o decreciente |
| 2 | Cuadrática | $y = b_0 + b_1 x + b_2 x^2$ | Parábola: U (b₂>0) o ∩ (b₂<0) — 1 extremo |
| 3 | Cúbica | $y = b_0 + b_1 x + b_2 x^2 + b_3 x^3$ | Curva en "S" suave — hasta 2 extremos |
| 4 | Cuártica | $y = b_0 + \ldots + b_4 x^4$ | Forma W o M — hasta 3 extremos |
| 5 | Quíntica | $y = b_0 + \ldots + b_5 x^5$ | Curva compleja — hasta 4 extremos |

### Reglas importantes

- El **grado** indica el número máximo de **raíces** (cruces con el eje x) y de **extremos locales** (máximos/mínimos).
- Grado **par** (2, 4): los dos extremos de la curva apuntan en la **misma dirección** (ambos hacia arriba o ambos hacia abajo).
- Grado **impar** (1, 3, 5): los dos extremos de la curva apuntan en **direcciones opuestas** (uno a +∞ y el otro a −∞).
- Grado 2 → máximo 1 extremo. Grado 3 → máximo 2 extremos. Grado $k$ → máximo $k-1$ extremos.

---

## 8. Métricas de Evaluación (Regresión y Clasificación)

Todas las tareas de aprendizaje supervisado requieren métricas para saber qué tan bien funciona el modelo.

### Métricas para Regresión

### R² — Coeficiente de Determinación

Mide **qué tan bien se ajustan los datos** a la función encontrada por el modelo.

$$R^2 = 1 - \frac{\sum(y_i - \hat{y}_i)^2}{\sum(y_i - \bar{y})^2}$$

$$R^2 \in [0, 1]$$

| Valor | Significado |
|---|---|
| R² = 1 | Ajuste perfecto — **no deseable** (el modelo estaría memorizando, no aprendiendo) |
| R² ∈ [0.90, 0.95] | **Rango aceptable** según la clase |
| R² < 0.80 | El modelo no explica bien la varianza |
| R² = 0 | El modelo no explica nada |

> R² no debería llegar a 1 porque eso significaría que el modelo es "perfecto", lo cual nunca ocurre en datos reales.

### RMSE — Root Squared Mean Error

Mide la diferencia promedio entre los valores **reales** y los **predichos** por el modelo.

$$RMSE = \sqrt{\frac{\sum(y_i - \hat{y}_i)^2}{n}}$$

$$RMSE \in [0, +\infty)$$

| Valor | Significado |
|---|---|
| RMSE = 0 | Perfecto — **imposible** en la práctica |
| RMSE pequeño | Menor error, mejor modelo |
| RMSE grande | Mayor error, peor modelo |

> RMSE **necesita comparación** — no tiene valor absoluto por sí solo. Se usa para comparar dos o más modelos y elegir el que tenga el **menor RMSE**.

### ¿Cómo elegir entre modelos?

1. Entrenar cada modelo (ej. grado 1, grado 2, grado 3).
2. Calcular R² y RMSE de cada uno.
3. Elegir el modelo con **menor RMSE** y **R² en rango 0.90–0.95**.

### Métricas para Clasificación

Al predecir clases (ej. K-NN), el error no se mide con distancias numéricas, sino contando aciertos y fallos.

- **Exactitud (Accuracy):** Porcentaje total de predicciones correctas sobre el total de datos.
- **Matriz de Confusión:** Tabla que muestra predicciones correctas y los errores de clasificación.
  - *Falsos Positivos:* Valores que en realidad eran negativos, pero el modelo clasificó como positivos.
  - *Falsos Negativos:* Valores que en realidad eran positivos, pero el modelo clasificó como negativos.
- **Reporte de Clasificación:** Proporciona métricas detalladas por clase (Precisión, Recall, F1-Score).

---

## 9. Transformación de Datos: Normalización vs Escalamiento

Antes de aplicar algoritmos basados en distancias (como K-NN) o cuando las variables tienen escalas muy diferentes, los datos deben **transformarse** para que todas las variables contribuyan por igual.

### Normalización (z-score / Desviación estándar)

$$z = \frac{x - \mu}{\sigma}$$

- Usa la **desviación estándar** de cada variable.
- Escala resultante: aproximadamente **−3 a +3**.
- Se usa en: K-NN, regresión cuando las escalas difieren mucho.
- **En Python**: Se implementa usando `StandardScaler` de `sklearn.preprocessing`.

### Escalamiento Min-Max

$$x_{norm} = \frac{x - x_{min}}{x_{max} - x_{min}}$$

- Usa el mínimo y máximo de cada variable.
- Escala resultante: **0 a 1**.
- Se usa en: redes neuronales, cuando se necesita un rango acotado entre 0 y 1.

### ¿Por qué es necesario transformar?

Si una variable tiene rango 0–100 000 y otra tiene rango 0–1, la primera dominará cualquier cálculo de distancia, haciendo que la segunda sea irrelevante para el modelo. La transformación elimina ese sesgo.

---

## 10. División de Datos: Entrenamiento y Prueba

Para evaluar qué tan bien **generaliza** el modelo (predice datos nuevos), los datos originales se dividen en dos conjuntos:

| Conjunto | Proporción | Uso |
|---|---|---|
| **Entrenamiento** | 70 % – 80 % | El algoritmo aprende la función con estos datos |
| **Prueba** | 20 % – 30 % | Se evalúa el modelo con datos que **nunca vio** |

### Conceptos clave de la división

- **Semilla aleatoria (random_state)**: parámetro que fija el resultado aleatorio para que la división sea reproducible. Con la misma semilla siempre se obtiene la misma división.
- **Estratificación (stratify)**: En clasificación, se usa el parámetro `stratify=y` al dividir los datos para asegurar que los conjuntos de entrenamiento y prueba mantengan la misma proporción de clases originales.
- Se usa **solo `fit` o `fit_transform`** con los datos de entrenamiento. Para los de prueba, solo `transform` — para no contaminar la evaluación con información del conjunto de prueba.
- El error medido sobre el conjunto de **prueba** es el que indica qué tan bien generalizará el modelo con datos reales futuros.
