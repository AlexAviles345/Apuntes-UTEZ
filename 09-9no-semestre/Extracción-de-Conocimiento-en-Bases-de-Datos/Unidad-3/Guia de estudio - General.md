# Guía de Estudio — Unidad 3: Aprendizaje Supervisado y Regresión

> Esta guía cubre la teoría y práctica de los temas de la Unidad 3. Los valores numéricos concretos de los ejercicios (ventas, resistencias, etc.) son solo ejemplos; lo importante es entender **el procedimiento y los conceptos**.

---

## Tabla de Contenidos

1. [Aprendizaje Supervisado](#1-aprendizaje-supervisado)
2. [Análisis Supervisado vs No Supervisado](#2-análisis-supervisado-vs-no-supervisado)
3. [Regresión — Conceptos Generales](#3-regresión--conceptos-generales)
4. [Regresión Lineal Simple](#4-regresión-lineal-simple)
5. [Regresión Lineal Múltiple](#5-regresión-lineal-múltiple)
6. [Regresión Polinomial](#6-regresión-polinomial)
7. [Formas de Polinomios en Gráficas (Grados 1 al 5)](#7-formas-de-polinomios-en-gráficas-grados-1-al-5)
8. [Métricas de Evaluación: RMSE y R²](#8-métricas-de-evaluación-rmse-y-r)
9. [Implementación en Python con scikit-learn](#9-implementación-en-python-con-scikit-learn)
10. [Transformación de Datos: Normalización vs Escalamiento](#10-transformación-de-datos-normalización-vs-escalamiento)
11. [Clasificación con K-NN en R (Dataset Iris)](#11-clasificación-con-k-nn-en-r-dataset-iris)
12. [Flujo Completo de un Proyecto de Regresión](#12-flujo-completo-de-un-proyecto-de-regresión)
13. [Ejercicios Prácticos con Excel](#13-ejercicios-prácticos-con-excel)
14. [Preguntas de Repaso](#14-preguntas-de-repaso)

---

## 1. Aprendizaje Supervisado

### ¿Qué es?

El **análisis supervisado** se encarga del **mapeo de entradas en salidas** con base en **datos de entrenamiento etiquetados** (pares entrada-salida).

- **Entrada**: variables independientes (x₁, x₂, ...).
- **Salida**: variable dependiente (y) ya conocida durante el entrenamiento.
- **Objetivo**: inferir una función que permita **mapear nuevos ejemplos** (datos que no se han visto antes).

### ¿Cómo funciona el algoritmo?

1. Se le da al algoritmo un conjunto de datos con pares (x → y) conocidos.
2. El algoritmo analiza esos datos y **produce una función inferida** (el modelo).
3. Con esa función se pueden hacer predicciones sobre datos nuevos **de manera razonable**.
4. Siempre existe un **error de generalización**: la función no es perfecta para datos nunca vistos.

### División: Entrenamiento y Prueba

Para saber qué tan bien generaliza el modelo, los datos se dividen:

| Conjunto | Proporción típica | Uso |
|---|---|---|
| Entrenamiento | 70 % – 80 % | El algoritmo "aprende" con estos datos |
| Prueba | 20 % – 30 % | Se evalúa qué tan bien predice el modelo |

> En Python: `train_test_split(X, y, test_size=0.20, random_state=42, stratify=y)`  
> `random_state` es la **semilla aleatoria** — garantiza que la división sea reproducible.  
> `stratify=y` — garantiza que se mantenga la proporción original de las clases.

---

## 2. Análisis Supervisado vs No Supervisado

| | Análisis **Supervisado** | Análisis **No Supervisado** |
|---|---|---|
| Datos de entrenamiento | Etiquetados (x → y conocida) | Sin etiquetas |
| Tarea principal | Predecir / clasificar | Agrupar / descubrir estructura |
| Algoritmos | Regresión, K-NN, SVM, etc. | K-Means, DBSCAN, etc. |
| Ejemplo | Predecir ventas, clasificar aprobado/reprobado | Segmentar clientes sin saber los grupos |

### Análisis Supervisado — Algoritmos

Los algoritmos supervisados se dividen en dos grandes tareas:

| Tarea | Variable objetivo | Algoritmos |
|---|---|---|
| **Regresión** | Variable **continua** (números) | Regresión lineal, polinomial |
| **Clasificación** | Variable **discreta** (categorías) | K-NN, SVM, Árboles de decisión, Naive Bayes |

- **Regresión** — predice valores numéricos continuos.
- **K-NN (K Nearest Neighbors)** — clasifica un dato nuevo según sus k vecinos más cercanos. Ejemplo visual: dos grupos (Aprobado / Reprobado) como círculos; KNN decide a cuál pertenece un punto nuevo según quiénes tiene más cerca.
- **Support Vector Machines (SVM)** — encuentra el hiperplano que mejor separa clases.
- **Árboles de decisión** — divide los datos mediante reglas if/else en forma de árbol.
- **Naive Bayes** — clasificador probabilístico basado en el teorema de Bayes.

### Análisis No Supervisado — K-Means

Cuando los datos **no tienen etiquetas**, se usa agrupamiento (clustering):

- **K-Means** — agrupa los datos en K grupos (clusters) según la distancia al centroide más cercano.
- No necesita datos etiquetados.
- El resultado son grupos, NO predicciones de valores o clases.

> Ejemplo: agrupar clientes en segmentos sin saber de antemano cuántos tipos de cliente existen.

---

## 3. Regresión — Conceptos Generales

La **regresión** es un método estadístico para estimar el nivel del efecto de una **variable independiente (x)** sobre una **variable dependiente (y)**.

Se usa para comprender o describir la **relación entre un conjunto de variables independientes y dependientes** expresada como una función matemática.

### Organización según tus apuntes

La regresión se clasifica en **dos dimensiones**:

```
Regresión
 ├── Cantidad de variables
 │     ├── Simple        → 1 variable independiente (x)
 │     └── Múltiple      → más de 1 variable independiente (x₁, x₂, ...)
 │
 └── Grado del polinomio
       ├── Lineal         → grado 1
       └── Polinomial     → grado > 1
```

Por eso existen combinaciones como: **Lineal Simple**, **Lineal Múltiple**, **Polinomial Simple**, **Polinomial Múltiple**.

### Tipos de regresión (por forma de la curva)

| Tipo | Cuándo usarla |
|---|---|
| **Lineal simple** | Una variable x, relación lineal |
| **Lineal múltiple** | Varias variables x, relación lineal |
| **Polinomial** | Una o varias x, pero la curva no es recta |
| **Logística** | Variable y binaria (0 o 1), probabilidad |
| **Exponencial** | Crecimiento/decaimiento exponencial |
| **Logarítmica** | Crecimiento rápido inicial que se estabiliza |

---

## 4. Regresión Lineal Simple

### ¿Qué es?

Técnica de análisis supervisado que describe la relación entre una variable independiente (x) y una variable dependiente (y) cuando muestran una **relación lineal**.

Pregunta clave: **¿cómo se incrementa/decrementa y cuando varía x?**

### Fórmula del modelo

$$y = b_0 + b_1 x + E$$

- $b_0$ = intercepto (valor de y cuando x = 0)
- $b_1$ = pendiente (cuánto cambia y por cada unidad de x)
- $E$ = error (residuo)

### Cálculo manual de b₀ y b₁

$$b_0 = \frac{\sum y \sum x^2 - \sum x \sum xy}{n \sum x^2 - (\sum x)^2}$$

$$b_1 = \frac{n \sum xy - \sum x \sum y}{n \sum x^2 - (\sum x)^2}$$

### Procedimiento en Excel (hoja `LinealSimple`)

Se construye una tabla con las columnas:

| x | y | x² | x·y |
|---|---|---|---|
| (variable independiente) | (variable dependiente) | `=POWER(x,2)` | `=x*y` |

Luego se calculan las sumatorias: `Σy`, `Σx²`, `Σx`, `Σxy`, `(Σx)²` y se aplican las fórmulas de b₀ y b₁.

**Ejemplo del ejercicio marketing (lineal simple):**
- Variables: `Spend` (x), `Sales` (y)
- 12 observaciones (meses)
- Se obtiene la función: `y = b₀ + b₁ · Spend`

### Ejemplo visual

Dados los puntos (0, −2), (1, 1), (2, 4):

1. Trazar el scatter plot.
2. Calcular la pendiente: $m = \frac{x_1 - x_2}{y_1 - y_2}$ *(nota: cuidado con el orden de las diferencias en la fórmula real)*.
3. La función resultante es: $y = 3x - 2$

---

## 5. Regresión Lineal Múltiple

### ¿Qué es?

Cuando hay **más de una variable independiente** (x₁, x₂, ...) el modelo es:

$$y = b_0 + b_1 x_1 + b_2 x_2 + E$$

### Procedimiento (2 variables independientes)

#### Paso 1 — Calcular los coeficientes de regresión S

$$Sx_1^2 = \sum x_1^2 - \frac{(\sum x_1)^2}{n}$$

$$Sx_2^2 = \sum x_2^2 - \frac{(\sum x_2)^2}{n}$$

$$Sx_1 y = \sum x_1 y - \frac{\sum x_1 \cdot \sum y}{n}$$

$$Sx_2 y = \sum x_2 y - \frac{\sum x_2 \cdot \sum y}{n}$$

$$Sx_1 x_2 = \sum x_1 x_2 - \frac{\sum x_1 \cdot \sum x_2}{n}$$

#### Paso 2 — Calcular b₁ y b₂

$$b_1 = \frac{Sx_2^2 \cdot Sx_1 y - Sx_1 x_2 \cdot Sx_2 y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1 x_2)^2}$$

$$b_2 = \frac{Sx_1^2 \cdot Sx_2 y - Sx_1 x_2 \cdot Sx_1 y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1 x_2)^2}$$

#### Paso 3 — Calcular b₀

$$b_0 = \bar{y} - b_1 \bar{x}_1 - b_2 \bar{x}_2$$

Donde $\bar{y}$, $\bar{x}_1$, $\bar{x}_2$ son las **medias** de cada variable.

### Procedimiento en Excel (hoja `LinearMultiple`)

Columnas necesarias en la tabla:

| x₁ | x₂ | y | x₁² | x₁·y | x₁·x₂ | x₂·y | x₂² |
|---|---|---|---|---|---|---|---|

Luego se calculan los coeficientes S con las fórmulas de SUMATORIAS y se obtienen b₀, b₁, b₂.

**Ejemplo del ejercicio marketing (múltiple):**
- Variables: `Month` (x₁), `Spend` (x₂), `Sales` (y)
- 12 observaciones
- Se obtiene: `Sales = b₀ + b₁·Month + b₂·Spend`

---

## 6. Regresión Polinomial

### ¿Cuándo usarla?

Cuando la relación entre variables **no es lineal** y la nube de puntos describe una curva. Incluir solo variables lineales no es suficiente; es necesario **elevar las variables a potencias** (grados).

### Fórmula general (grado 2)

$$y = b_0 + b_1 x + b_2 x^2$$

### Sistema de ecuaciones normales (grado 2)

Se resuelven simultáneamente estas 3 ecuaciones:

$$n b_0 + \sum x \cdot b_1 + \sum x^2 \cdot b_2 = \sum y$$

$$b_0 \sum x + \sum x^2 \cdot b_1 + \sum x^3 \cdot b_2 = \sum xy$$

$$b_0 \sum x^2 + \sum x^3 \cdot b_1 + \sum x^4 \cdot b_2 = \sum x^2 y$$

> Para grado mayor (3, 4, 5) el sistema crece: grado 3 tiene 4 ecuaciones, etc.

### Procedimiento en Excel (hoja `resistencia`)

Columnas necesarias:

| x | y | x² | x³ | x⁴ | x·y | x²·y |
|---|---|---|---|---|---|---|

Luego se calculan: `Σx`, `Σx²`, `Σx³`, `Σx⁴`, `Σy`, `Σxy`, `Σx²y`  
y se resuelve el sistema de 3 ecuaciones para obtener b₀, b₁, b₂.

**Ejemplo del ejercicio resistencia:**
- Variables: `concentración` (x), `resistencia` (y)
- 19 observaciones
- La curva no es lineal → se usa regresión polinomial grado 2
- Se obtiene: `resistencia = b₀ + b₁·concentración + b₂·concentración²`

### En Python (múltiples variables con grado 2)

Con 2 variables independientes (x₁, x₂) y grado 2, el modelo expandido es:

$$y = b_0 + b_1 x_1 + b_2 x_1^2 + b_3 x_2 + b_4 x_2^2 + b_5 x_1 x_2$$

`PolynomialFeatures` se encarga de crear automáticamente todas esas columnas.

---

## 7. Formas de Polinomios en Gráficas (Grados 1 al 5)

*(Esta sección se complementará con las imágenes del documento docx)*

Conceptos clave a conocer para cada grado:

| Grado | Nombre | Forma general | Forma de la curva |
|---|---|---|---|
| 1 | Lineal | $y = b_0 + b_1 x$ | Línea recta |
| 2 | Cuadrática | $y = b_0 + b_1 x + b_2 x^2$ | Parábola (U o ∩) |
| 3 | Cúbica | $y = b_0 + b_1 x + b_2 x^2 + b_3 x^3$ | Curva con 1 punto de inflexión |
| 4 | Cuártica | $y = b_0 + \ldots + b_4 x^4$ | Curva con 2 puntos de inflexión (forma W o M) |
| 5 | Quíntica | $y = b_0 + \ldots + b_5 x^5$ | Curva con 3 puntos de inflexión |

### Lo que debes saber de cada forma:

- **Grado 1 (lineal)**: siempre creciente o decreciente, sin curvas.
- **Grado 2 (parabólica)**: tiene 1 máximo o 1 mínimo. Si b₂ > 0 → abre hacia arriba (U); si b₂ < 0 → abre hacia abajo (∩).
- **Grado 3 (cúbica)**: puede tener 1 máximo local Y 1 mínimo local. Extremos van a +∞ y −∞ (o al revés).
- **Grado 4 (cuártica)**: simétrica si todos los coeficientes de grado impar son 0. Puede tener hasta 3 extremos.
- **Grado 5 (quíntica)**: similar a la cúbica pero más compleja; siempre tiene extremos que van en direcciones opuestas.

> **Truco para el examen**: el grado del polinomio indica el número máximo de raíces (cruces con eje x) y de extremos locales (máximos/mínimos).

---

## 8. Métricas de Evaluación: RMSE y R²

> Todas las tareas de aprendizaje supervisado (regresión y clasificación) usan métricas para evaluar qué tan bien funciona el modelo.

### R² — Coeficiente de Determinación

Mide qué tan bien se ajustan los datos a la función encontrada.

$$R^2 \in [0, 1]$$

| Valor | Interpretación |
|---|---|
| R² = 1 | Perfecto — **NO es deseable**, significaría que el modelo memoriza los datos |
| R² ∈ [0.90, 0.95] | **Rango aceptable** (buen modelo sin ser perfecto) |
| R² < 0.80 | El modelo explica poco la varianza de los datos |
| R² = 0 | El modelo no explica nada |

> **Regla de tus apuntes**: R² no debería llegar a 1 porque sería "perfecto" y eso nunca va a pasar en la realidad.

- En Python: `r2_score(y_test, predicciones)`

---

### RMSE — Root Squared Mean Error (Error Cuadrático Medio Raíz)

Mide la diferencia entre los valores **reales** vs los **predichos**.

$$RMSE = \sqrt{\frac{1}{n} \sum_{i=1}^{n} (y_i - \hat{y}_i)^2}$$

$$RMSE \in [0, +\infty)$$

| Valor | Interpretación |
|---|---|
| RMSE = 0 | Perfecto — **NO es deseable** (nunca va a pasar) |
| RMSE pequeño | Mejor ajuste |
| RMSE grande | Error elevado, peor ajuste |

> **Regla clave**: RMSE **necesita comparación** — no tiene interpretación absoluta por sí solo. Se comparan varios modelos (o varios grados de polinomio) y se **elige el modelo con el menor RMSE**.

- En Python: `np.sqrt(mean_squared_error(y_test, predicciones))`

---

### ¿Cómo elegir entre modelos?

Cuando pruebas varios modelos (ej. grado 1 vs grado 2 vs grado 3):

1. Entrena cada modelo.
2. Calcula R² y RMSE para cada uno.
3. **Elige el que tenga el menor RMSE** (y R² dentro del rango 0.90–0.95).

### Resumen de métricas

| Métrica | Rango | Valor ideal | Lo que NO quieres |
|---|---|---|---|
| R² | [0, 1] | 0.90 – 0.95 | R² = 1 (sobreajuste) |
| RMSE | [0, +∞) | Lo más pequeño posible | RMSE = 0 (imposible) |

### Métricas para Clasificación

- **Exactitud (Accuracy):** Porcentaje de aciertos globales.
- **Matriz de Confusión:** Tabla de predicciones correctas e incorrectas (falsos positivos/negativos).
  - *Falsos Positivos:* Valores negativos reales clasificados como positivos.
  - *Falsos Negativos:* Valores positivos reales clasificados como negativos.
- **Reporte de Clasificación:** Muestra precision, recall y f1-score por clase.

---

## 9. Implementación en Python con scikit-learn

### Librerías necesarias

```python
from sklearn.model_selection import train_test_split   # División entrenamiento/prueba
from sklearn.linear_model import LinearRegression       # Regresión lineal y polinomial
from sklearn.preprocessing import PolynomialFeatures, StandardScaler    # Transformaciones
from sklearn.metrics import mean_squared_error, r2_score  # Métricas regresión
from sklearn.neighbors import KNeighborsClassifier      # Clasificador K-NN
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix # Métricas clasificación
import pandas as pd
import numpy as np
```

---

### Flujo: Regresión Lineal Múltiple

```python
# 1. Cargar datos
datos = pd.read_csv('marketing.csv')

# 2. Seleccionar columnas y filas
datos = datos.loc[0:11, ['Month', 'Spend', 'Sales']]

# 3. Definir variables
datos_y = datos['Sales']               # Variable dependiente
datos_x = datos[['Month', 'Spend']]    # Variables independientes

# 4. Dividir en entrenamiento y prueba (80/20)
x_train, x_test, y_train, y_test = train_test_split(
    datos_x, datos_y,
    test_size=0.20,
    random_state=42   # Semilla para reproducibilidad
)

# 5. Crear y entrenar el modelo
modelo_reg = LinearRegression()
modelo_reg.fit(x_train, y_train)  # El algoritmo aprende con los datos de entrenamiento

# 6. Hacer predicciones
predicciones = modelo_reg.predict(x_test)

# 7. Evaluar
rmse = np.sqrt(mean_squared_error(y_test, predicciones))
r2   = r2_score(y_test, predicciones)
print(f'RMSE: {rmse}  |  R²: {r2}')
```

---

### Flujo: Regresión Polinomial

```python
# 1–4. Mismos pasos de carga y división que arriba

# 5. Definir el grado del polinomio
grado = 2
poly = PolynomialFeatures(degree=grado)

# 6. Transformar las variables
# IMPORTANTE: fit_transform SOLO en entrenamiento
# transform (sin fit) en prueba — para no calcular una desviación estándar diferente
x_train_poly = poly.fit_transform(x_train)
x_test_poly  = poly.transform(x_test)      # ← NO fit_transform aquí

# 7. Entrenar con los datos transformados
modelo_poly = LinearRegression()
modelo_poly.fit(x_train_poly, y_train)

# 8. Predicciones y evaluación
predicciones = modelo_poly.predict(x_test_poly)
r2   = r2_score(y_test, predicciones)
rmse = np.sqrt(mean_squared_error(y_test, predicciones))
print(f'R²: {r2}  |  RMSE: {rmse}')

# 9. Ver los coeficientes obtenidos
print('Coeficientes:', modelo_poly.coef_)
print('Intercepto:', modelo_poly.intercept_)
```

---

### Conceptos clave del código

| Concepto | Descripción |
|---|---|
| `datos.loc[0:11, ['Month','Spend','Sales']]` | Selección de filas y columnas por índice y nombre |
| `test_size=0.20` | 20 % de los datos para prueba, 80 % para entrenamiento |
| `random_state=42` | Semilla aleatoria — hace que la división sea siempre igual |
| `modelo.fit(x_train, y_train)` | El modelo "aprende" con los datos de entrenamiento |
| `modelo.predict(x_test)` | El modelo "predice" sobre los datos de prueba |
| `poly.fit_transform(x_train)` | Calcula estadísticas de escala Y transforma los datos de entrenamiento |
| `poly.transform(x_test)` | Usa estadísticas del entrenamiento para transformar los de prueba |
| `modelo.coef_` | Coeficientes b₁, b₂, ... del modelo entrenado |
| `modelo.intercept_` | Intercepto b₀ del modelo entrenado |

> **Regla crítica**: NUNCA usar `fit_transform` en los datos de prueba. Solo `transform`. Si se hace `fit_transform` en prueba, el modelo calcula una normalización diferente y los resultados no serían comparables.

---

## 10. Clasificación con K-NN (Dataset Iris)

### Dataset Iris

Dataset clásico de clasificación supervisada. Contiene 150 flores con 4 características:

| Variable | Tipo |
|---|---|
| `Sepal.Length` | Variable independiente (x) |
| `Sepal.Width` | Variable independiente (x) |
| `Petal.Length` | Variable independiente (x) |
| `Petal.Width` | Variable independiente (x) |
| `Species` | Variable dependiente (y) — 3 clases: setosa, versicolor, virginica |

### Normalización / Estandarización

Antes de aplicar K-NN (y otros algoritmos basados en distancias), los datos se **normalizan** para que todas las variables estén en la misma escala.

La estandarización (z-score) transforma los valores así:

$$z = \frac{x - \mu}{\sigma}$$

- Los valores estandarizados quedan aproximadamente entre **−3 y +3**.
- Si no se normalizan los datos, variables con valores grandes dominarán la distancia.



### Flujo Completo: K-NN en Python

```python
# 1. Cargar y convertir variables categóricas (texto a números)
df = pd.read_csv('iris.csv')
df["target"] = df["Species"].astype("category").cat.codes

# 2. Definir variables
x = df[["SepalLengthCm", "SepalWidthCm", "PetalLengthCm", "PetalWidthCm"]]
y = df["target"]

# 3. Dividir datos (usando stratify para preservar proporción de clases)
x_train, x_test, y_train, y_test = train_test_split(
    x, y, test_size=0.2, random_state=42, stratify=y
)

# 4. Escalar los datos (-3 a +3) para evitar dominio de variables
scaler = StandardScaler()
x_train_scaled = scaler.fit_transform(x_train)
x_test_scaled = scaler.transform(x_test)

# 5. Entrenar modelo
knn = KNeighborsClassifier(n_neighbors=5)
knn.fit(x_train_scaled, y_train)

# 6. Predecir y Evaluar
y_pred = knn.predict(x_test_scaled)
print(f"Accuracy: {accuracy_score(y_test, y_pred)}")
print("Matriz de Confusión:\\n", confusion_matrix(y_test, y_pred))
print("Reporte:\\n", classification_report(y_test, y_pred))
```

---

## 12. Flujo Completo de un Proyecto de Regresión

```
Datos crudos
    │
    ▼
Exploración y limpieza (pd.read_csv, .loc, etc.)
    │
    ▼
Definir X (variables independientes) e y (variable dependiente)
    │
    ▼
División Entrenamiento / Prueba (train_test_split)
    │
    ├─ ¿Relación lineal?  ──────────────► LinearRegression()
    │                                         .fit(x_train, y_train)
    │                                         .predict(x_test)
    │
    └─ ¿Relación no lineal? ────────────► PolynomialFeatures(degree=n)
                                              .fit_transform(x_train)
                                              .transform(x_test)
                                          LinearRegression()
                                              .fit(x_train_poly, y_train)
                                              .predict(x_test_poly)
    │
    ▼
Evaluación del modelo
    ├── RMSE → ¿El error es aceptable?
    └── R²   → ¿El modelo explica los datos?
```

---

## 13. Ejercicios Prácticos con Excel

### Ejercicio 1 — Marketing (Regresión Lineal Simple y Múltiple)

**Dataset**: 12 meses con columnas `Month`, `Spend`, `Sales`

#### Hoja `LinealSimple`

Objetivo: predecir `Sales` en función de `Spend`.

| Columna | Fórmula Excel |
|---|---|
| Spend² | `=POWER(B2,2)` |
| Spend·Sales | `=B2*C2` |
| Σy | `=SUM(C2:C13)` |
| Σx² | `=SUM(D2:D13)` |
| Σx | `=SUM(B2:B13)` |
| Σxy | `=SUM(E2:E13)` |
| (Σx)² | `=POWER(Σx, 2)` |
| b₀ | `=(Σy·Σx² - Σx·Σxy) / (n·Σx² - (Σx)²)` |
| b₁ | `=(n·Σxy - Σx·Σy) / (n·Σx² - (Σx)²)` |

#### Hoja `LinearMultiple`

Objetivo: predecir `Sales` en función de `Month` y `Spend`.

Columnas adicionales necesarias: `Month²`, `Month·Sales`, `Month·Spend`, `Spend·Sales`, `Spend²`

Luego calcular los coeficientes S y los valores b₀, b₁, b₂.

---

### Ejercicio 2 — Resistencia (Regresión Polinomial Grado 2)

**Dataset**: 19 muestras con columnas `concentración` (x), `resistencia` (y)

| Columna | Fórmula Excel |
|---|---|
| x² | `=POWER(B2,2)` |
| x³ | `=POWER(B2,3)` |
| x⁴ | `=POWER(B2,4)` |
| x·y | `=B2*C2` |
| x²·y | `=D2*C2` |

Con las sumatorias `Σx`, `Σx²`, `Σx³`, `Σx⁴`, `Σy`, `Σxy`, `Σx²y`, se plantea y resuelve el sistema de 3 ecuaciones normales para obtener b₀, b₁, b₂.

> **Nota**: Para resolver el sistema de 3 ecuaciones se puede usar eliminación gaussiana o la función de matrices en Excel (`MINVERSE`, `MMULT`).

---

## 14. Preguntas de Repaso

### Conceptuales

1. ¿Qué diferencia hay entre aprendizaje supervisado y no supervisado?
2. ¿Por qué se necesitan datos etiquetados en el aprendizaje supervisado?
3. ¿Cuál es la diferencia entre regresión y clasificación? Da un ejemplo de cada uno.
4. ¿Qué es el error de generalización y por qué siempre existe?
5. ¿Por qué se divide el dataset en entrenamiento y prueba?
6. ¿Qué significa `random_state=42` en `train_test_split`?
7. ¿Cuándo es preferible usar regresión polinomial sobre lineal?

### Sobre las fórmulas

8. ¿Cuál es la diferencia entre b₀ y b₁ en la regresión lineal simple?
9. En la regresión lineal múltiple con 2 variables, ¿cuántos coeficientes S se calculan?
10. ¿Cuántas ecuaciones normales se tienen para un polinomio de grado 2? ¿Y de grado 3?
11. Escribe la fórmula completa de la regresión polinomial grado 2 con 2 variables independientes (expansión completa).

### Sobre Python

12. ¿Cuál es la diferencia entre `fit_transform` y `transform` en `PolynomialFeatures`?
13. ¿Por qué NO se debe usar `fit_transform` en los datos de prueba?
14. ¿Qué devuelve `modelo.coef_` y `modelo.intercept_` después de entrenar?
15. ¿Qué indica un R² = 0.95?
16. ¿Qué indica un RMSE muy alto? ¿Cómo se interpreta relativo al rango de los datos?

### Sobre los tipos de regresión

17. Observas una gráfica de datos en forma de "S" (sigmoide). ¿Qué tipo de regresión usarías?
18. Observas crecimiento que se estabiliza rápidamente. ¿Regresión exponencial o logarítmica?
19. ¿Qué forma tiene la gráfica de un polinomio de grado 4?

---

## Apéndice — Fórmulas Rápidas de Referencia

### Regresión Lineal Simple

$$b_1 = \frac{n\sum xy - \sum x \sum y}{n\sum x^2 - (\sum x)^2} \qquad b_0 = \frac{\sum y \sum x^2 - \sum x \sum xy}{n\sum x^2 - (\sum x)^2}$$

### Regresión Lineal Múltiple (2 variables)

$$b_1 = \frac{Sx_2^2 \cdot Sx_1y - Sx_1x_2 \cdot Sx_2y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1x_2)^2}$$

$$b_2 = \frac{Sx_1^2 \cdot Sx_2y - Sx_1x_2 \cdot Sx_1y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1x_2)^2}$$

$$b_0 = \bar{y} - b_1\bar{x}_1 - b_2\bar{x}_2$$

### Coeficientes S

$$Sx_i^2 = \sum x_i^2 - \frac{(\sum x_i)^2}{n} \qquad Sx_iy = \sum x_iy - \frac{\sum x_i \sum y}{n} \qquad Sx_1x_2 = \sum x_1x_2 - \frac{\sum x_1 \sum x_2}{n}$$

### Ecuaciones Normales Polinomial Grado 2

$$\begin{cases} nb_0 + \sum x\,b_1 + \sum x^2\,b_2 = \sum y \\ b_0\sum x + \sum x^2\,b_1 + \sum x^3\,b_2 = \sum xy \\ b_0\sum x^2 + \sum x^3\,b_1 + \sum x^4\,b_2 = \sum x^2y \end{cases}$$

### Métricas

$$RMSE = \sqrt{\frac{\sum(y_i - \hat{y}_i)^2}{n}} \qquad R^2 = 1 - \frac{\sum(y_i - \hat{y}_i)^2}{\sum(y_i - \bar{y})^2}$$

---

*Guía generada con base en: `Unidad 3.ipynb`, `Aprenderse formas de polinomios en graficas hasta la 5ta potencia.docx`, `marketing.xlsx`, `resistencia.xlsx` y los archivos de imágenes complementarios.*

*Guía completa — todos los documentos e imágenes analizados: 22 slides del docx, notebook Python, Excel de marketing y resistencia, y 2 fotos de apuntes de clase.*
