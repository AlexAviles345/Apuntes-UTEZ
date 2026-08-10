# Práctica — Unidad 3: Métodos y Procedimientos

> Solo los métodos vistos en clase, paso a paso. Sin teoría adicional.

---

## Tabla de Contenidos

1. [Método 1 — Regresión Lineal Simple en Excel](#1-método-1--regresión-lineal-simple-en-excel)
2. [Método 2 — Regresión Lineal Múltiple en Excel](#2-método-2--regresión-lineal-múltiple-en-excel)
3. [Método 3 — Regresión Polinomial Grado 2 en Excel](#3-método-3--regresión-polinomial-grado-2-en-excel)
4. [Método 4 — Regresión Lineal Múltiple en Python](#4-método-4--regresión-lineal-múltiple-en-python)
5. [Método 5 — Regresión Polinomial en Python](#5-método-5--regresión-polinomial-en-python)
6. [Método 6 — Clasificación K-NN en Python](#6-método-6--clasificación-k-nn-en-python)
7. [Referencia Rápida de Fórmulas](#7-referencia-rápida-de-fórmulas)

---

## 1. Método 1 — Regresión Lineal Simple en Excel

**Ejercicio**: dataset `marketing.xlsx`, hoja `LinealSimple`. Predecir `Sales` (y) a partir de `Spend` (x).

### Paso 1 — Construir la tabla

Agregar estas columnas junto a los datos originales:

| Columna | Fórmula (para fila 2) | ¿Qué hace? |
|---|---|---|
| `x²` | `=POWER(B2,2)` | Spend al cuadrado |
| `x·y` | `=B2*C2` | Spend × Sales |

La tabla queda: `x` | `y` | `x²` | `x·y`

### Paso 2 — Calcular las sumatorias

En celdas aparte calcular:

| Símbolo | Fórmula Excel |
|---|---|
| $\sum y$ | `=SUM(C2:C13)` |
| $\sum x^2$ | `=SUM(D2:D13)` |
| $\sum x$ | `=SUM(B2:B13)` |
| $\sum xy$ | `=SUM(E2:E13)` |
| $(\sum x)^2$ | `=POWER(SUMA_X, 2)` |

Donde `n = 12` (número de filas de datos).

### Paso 3 — Calcular b₁ y b₀

$$b_1 = \frac{n \cdot \sum xy - \sum x \cdot \sum y}{n \cdot \sum x^2 - (\sum x)^2}$$

$$b_0 = \frac{\sum y \cdot \sum x^2 - \sum x \cdot \sum xy}{n \cdot \sum x^2 - (\sum x)^2}$$

En Excel (referenciando las celdas con las sumatorias):

```
b1 = =((12*Sxy)-(Sx*Sy)) / ((12*Sx2)-(Sx)^2)
b0 = =(Sy*Sx2 - Sx*Sxy) / (12*Sx2 - (Sx)^2)
```

### Paso 4 — Escribir el modelo

$$y = b_0 + b_1 \cdot x$$

Para predecir un valor nuevo de `x`, sustituir en la fórmula:

```
=b0 + b1 * VALOR_X
```

---

## 2. Método 2 — Regresión Lineal Múltiple en Excel

**Ejercicio**: dataset `marketing.xlsx`, hoja `LinearMultiple`. Predecir `Sales` (y) a partir de `Month` (x₁) y `Spend` (x₂).

### Paso 1 — Construir la tabla

Agregar estas columnas:

| Columna | Fórmula (fila 2) |
|---|---|
| `x₁²` | `=POWER(A2,2)` |
| `x₁·y` | `=A2*C2` |
| `x₁·x₂` | `=A2*B2` |
| `x₂·y` | `=B2*C2` |
| `x₂²` | `=POWER(B2,2)` |

La tabla completa: `x₁` | `x₂` | `y` | `x₁²` | `x₁y` | `x₁x₂` | `x₂y` | `x₂²`

### Paso 2 — Calcular los coeficientes S

Con `n = 12`:

$$Sx_1^2 = \sum x_1^2 - \frac{(\sum x_1)^2}{n}$$

```excel
Sx1_2 = SUM(x1²_col) - POWER(SUM(x1_col),2)/12
```

$$Sx_2^2 = \sum x_2^2 - \frac{(\sum x_2)^2}{n}$$

```excel
Sx2_2 = SUM(x2²_col) - POWER(SUM(x2_col),2)/12
```

$$Sx_1 y = \sum x_1 y - \frac{\sum x_1 \cdot \sum y}{n}$$

```excel
Sx1y = SUM(x1y_col) - (SUM(x1_col)*SUM(y_col))/12
```

$$Sx_2 y = \sum x_2 y - \frac{\sum x_2 \cdot \sum y}{n}$$

```excel
Sx2y = SUM(x2y_col) - (SUM(x2_col)*SUM(y_col))/12
```

$$Sx_1 x_2 = \sum x_1 x_2 - \frac{\sum x_1 \cdot \sum x_2}{n}$$

```excel
Sx1x2 = SUM(x1x2_col) - (SUM(x1_col)*SUM(x2_col))/12
```

### Paso 3 — Calcular b₁ y b₂

$$b_1 = \frac{Sx_2^2 \cdot Sx_1 y - Sx_1 x_2 \cdot Sx_2 y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1 x_2)^2}$$

$$b_2 = \frac{Sx_1^2 \cdot Sx_2 y - Sx_1 x_2 \cdot Sx_1 y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1 x_2)^2}$$

### Paso 4 — Calcular b₀

$$b_0 = \bar{y} - b_1 \cdot \bar{x}_1 - b_2 \cdot \bar{x}_2$$

```excel
b0 = AVERAGE(y_col) - b1*AVERAGE(x1_col) - b2*AVERAGE(x2_col)
```

### Paso 5 — Escribir el modelo

$$y = b_0 + b_1 \cdot x_1 + b_2 \cdot x_2$$

---

## 3. Método 3 — Regresión Polinomial Grado 2 en Excel

**Ejercicio**: dataset `resistencia.xlsx`, hoja `resistencia`. Predecir `resistencia` (y) a partir de `concentración` (x).

### Paso 1 — Construir la tabla

Agregar estas columnas:

| Columna | Fórmula (fila 2) |
|---|---|
| `x²` | `=POWER(B2,2)` |
| `x³` | `=POWER(B2,3)` |
| `x⁴` | `=POWER(B2,4)` |
| `x·y` | `=B2*C2` |
| `x²·y` | `=D2*C2` *(D2 es la columna x²)* |

La tabla completa: `x` | `y` | `x²` | `x³` | `x⁴` | `xy` | `x²y`

### Paso 2 — Calcular las sumatorias

Con `n = 19`:

| Símbolo | Fórmula Excel |
|---|---|
| $\sum x$ | `=SUM(x_col)` |
| $\sum x^2$ | `=SUM(x²_col)` |
| $\sum x^3$ | `=SUM(x³_col)` |
| $\sum x^4$ | `=SUM(x⁴_col)` |
| $\sum y$ | `=SUM(y_col)` |
| $\sum xy$ | `=SUM(xy_col)` |
| $\sum x^2 y$ | `=SUM(x²y_col)` |

### Paso 3 — Plantear el sistema de 3 ecuaciones normales

Sustituir las sumatorias en el sistema:

$$\begin{cases} n \cdot b_0 + \sum x \cdot b_1 + \sum x^2 \cdot b_2 = \sum y \\ \sum x \cdot b_0 + \sum x^2 \cdot b_1 + \sum x^3 \cdot b_2 = \sum xy \\ \sum x^2 \cdot b_0 + \sum x^3 \cdot b_1 + \sum x^4 \cdot b_2 = \sum x^2 y \end{cases}$$

### Paso 4 — Resolver el sistema para obtener b₀, b₁, b₂

Usar eliminación gaussiana manualmente, o en Excel con matrices:

```excel
=MMULT(MINVERSE(matriz_coef), vector_terminos_independientes)
```

### Paso 5 — Escribir el modelo

$$y = b_0 + b_1 \cdot x + b_2 \cdot x^2$$

---

## 4. Método 4 — Regresión Lineal Múltiple en Python

**Ejercicio**: dataset `marketing.csv`. Predecir `Sales` a partir de `Month` y `Spend`.

### Código completo (del notebook `Unidad 3.ipynb`)

```python
# ── Importaciones ──────────────────────────────────────────────────────────────
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score
import pandas as pd
import numpy as np

# ── 1. Cargar datos ────────────────────────────────────────────────────────────
datos = pd.read_csv('marketing.csv')

# ── 2. Seleccionar filas y columnas ───────────────────────────────────────────
# .loc[filas, columnas] — selección por índice y nombre de columna
datos = datos.loc[0:11, ['Month', 'Spend', 'Sales']]

# ── 3. Separar variables ───────────────────────────────────────────────────────
datos_y = datos['Sales']             # Variable dependiente (lo que se quiere predecir)
datos_x = datos[['Month', 'Spend']]  # Variables independientes

# ── 4. Dividir en entrenamiento (80%) y prueba (20%) ──────────────────────────
x_train, x_test, y_train, y_test = train_test_split(
    datos_x, datos_y,
    test_size=0.20,
    random_state=42    # Semilla: garantiza que la división sea siempre igual
)

# ── 5. Crear y entrenar el modelo ─────────────────────────────────────────────
modelo_reg = LinearRegression()
modelo_reg.fit(x_train, y_train)   # El modelo aprende con los datos de entrenamiento

# ── 6. Hacer predicciones sobre datos de prueba ───────────────────────────────
predicciones = modelo_reg.predict(x_test)

# ── 7. Evaluar el modelo ──────────────────────────────────────────────────────
rmse = np.sqrt(mean_squared_error(y_test, predicciones))
r2   = r2_score(y_test, predicciones)
print('RMSE:', rmse)
print('R2:  ', r2)
```

### Qué devuelve cada línea clave

| Línea | Qué devuelve / hace |
|---|---|
| `datos.loc[0:11, [...]]` | DataFrame con 12 filas y las 3 columnas indicadas |
| `x_train` | 80% de datos_x (≈9-10 filas) para entrenar |
| `x_test` | 20% de datos_x (≈2-3 filas) para evaluar |
| `modelo_reg.fit(...)` | El modelo ajusta los coeficientes internamente |
| `modelo_reg.predict(x_test)` | Array con los valores de Sales predichos |
| `rmse` | Número — el error promedio del modelo |
| `r2` | Número entre 0 y 1 — qué tan bien explica el modelo |

---

## 5. Método 5 — Regresión Polinomial en Python

**Ejercicio**: mismo dataset `marketing.csv`, aplicando `PolynomialFeatures(degree=2)`.

### Código completo (del notebook `Unidad 3.ipynb`)

```python
# ── Importaciones adicionales ─────────────────────────────────────────────────
from sklearn.preprocessing import PolynomialFeatures

# (Los pasos 1–4 de carga y división son idénticos al Método 4)
# ...

# ── 5. Crear el transformador polinomial ──────────────────────────────────────
grado = 2
poly = PolynomialFeatures(degree=grado)

# ── 6. Transformar las variables ──────────────────────────────────────────────
# REGLA: fit_transform SOLO en entrenamiento
#        transform (sin fit) en prueba
x_train_poly = poly.fit_transform(x_train)  # Calcula estadísticas Y transforma
x_test_poly  = poly.transform(x_test)       # Solo transforma, NO recalcula

# ── 7. Crear y entrenar el modelo con datos transformados ──────────────────────
modelo_poly = LinearRegression()
modelo_poly.fit(x_train_poly, y_train)

# ── 8. Predicciones ───────────────────────────────────────────────────────────
# Predicción sobre los datos de prueba
predicciones = modelo_poly.predict(x_test_poly)

# Predicción de un dato nuevo multivariable (ej. Month=3, Spend=85)
# 1. Se crea un DataFrame con los nombres de columnas originales
nuevo_dato = pd.DataFrame([[3, 85]], columns=['Month', 'Spend'])
# 2. Se transforma el dato nuevo (usar SOLO transform, nunca fit_transform)
nuevo_dato_poly = poly.transform(nuevo_dato)
# 3. Se hace la predicción
pred_nuevo = modelo_poly.predict(nuevo_dato_poly)

# ── 9. Evaluar ────────────────────────────────────────────────────────────────
r2   = r2_score(y_test, predicciones)
rmse = np.sqrt(mean_squared_error(y_test, predicciones))
print('R2:', r2, '| RMSE:', rmse)

# ── 10. Ver los coeficientes del modelo ───────────────────────────────────────
print('Coeficientes:', modelo_poly.coef_)
print('Intercepto:  ', modelo_poly.intercept_)
```

### Diferencia entre `fit_transform` y `transform`

| Método | Qué hace | Dónde se usa |
|---|---|---|
| `poly.fit_transform(x_train)` | Calcula las estadísticas del polinomio **y** transforma los datos | **Solo en entrenamiento** |
| `poly.transform(x_test)` | Usa las estadísticas ya calculadas para transformar | **Solo en prueba** |

> Si se usa `fit_transform` en prueba, se calculan estadísticas distintas y las predicciones no son comparables con el entrenamiento.

### Qué contiene `modelo_poly.coef_` e `intercept_`

Después del entrenamiento, el modelo almacena los coeficientes de la función ajustada:

- `modelo_poly.intercept_` → $b_0$
- `modelo_poly.coef_` → $[b_1, b_2, b_3, b_4, b_5, ...]$ (todos los términos polinomiales)

---

## 6. Método 6 — Clasificación K-NN en Python

**Ejercicio**: dataset `iris.csv` en Python. Clasificar el tipo de flor (Species).

### Código completo

![Ejemplo de división Train/Test en R (similar conceptualmente al split en Python)](apuntes_images/image22.webp)

```python
# ── Importaciones ──────────────────────────────────────────────────────────────
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report

# ── 1. Cargar y preparar datos ────────────────────────────────────────────────
df = pd.read_csv('iris.csv')
# Convertir texto (Species) a números para el modelo (0, 1, 2)
df["target"] = df["Species"].astype("category").cat.codes

x = df[["SepalLengthCm", "SepalWidthCm", "PetalLengthCm", "PetalWidthCm"]]
y = df["target"]

# ── 2. División (con stratify) ────────────────────────────────────────────────
# stratify=y asegura que ambos conjuntos tengan la misma proporción de clases
x_train, x_test, y_train, y_test = train_test_split(
    x, y, test_size=0.2, random_state=42, stratify=y
)

# ── 3. Escalamiento de características ────────────────────────────────────────
scaler = StandardScaler()
# El modelo escala (entre aprox -3 y 3) para que ninguna variable domine
x_train_scaled = scaler.fit_transform(x_train)
x_test_scaled = scaler.transform(x_test)

# ── 4. Entrenar modelo K-NN ───────────────────────────────────────────────────
knn = KNeighborsClassifier(n_neighbors=5)
knn.fit(x_train_scaled, y_train)

# ── 5. Predicción y Evaluación ────────────────────────────────────────────────
y_pred = knn.predict(x_test_scaled)

precision = accuracy_score(y_test, y_pred)
matriz_confusion = confusion_matrix(y_test, y_pred)
reporte = classification_report(
    y_test, y_pred, target_names=df["Species"].astype("category").cat.categories
)

print(f"Precisión Global del Modelo: {precision * 100:.2f}%\\n")
print("Matriz de Confusión:\\n", matriz_confusion, "\\n")
print("Reporte de Clasificación:\\n", reporte)
```

---

## 7. Referencia Rápida de Fórmulas

### Regresión Lineal Simple

![Fórmulas b0, b1 regresión lineal simple](apuntes_images/image15.webp)

$$b_1 = \frac{n\sum xy - \sum x \sum y}{n\sum x^2 - (\sum x)^2} \qquad b_0 = \frac{\sum y \sum x^2 - \sum x \sum xy}{n\sum x^2 - (\sum x)^2}$$

Modelo: $\hat{y} = b_0 + b_1 x$

---

### Coeficientes S (para Múltiple)

![Fórmulas Coeficientes S](apuntes_images/image16.webp)

$$Sx_i^2 = \sum x_i^2 - \frac{(\sum x_i)^2}{n}$$

$$Sx_iy = \sum x_iy - \frac{\sum x_i \cdot \sum y}{n}$$

$$Sx_1x_2 = \sum x_1x_2 - \frac{\sum x_1 \cdot \sum x_2}{n}$$

### Regresión Lineal Múltiple (2 variables)

![Fórmulas regresión múltiple b0, b1, b2](apuntes_images/image17.webp)
> [!WARNING]
> **Error tipográfico en la diapositiva**: La imagen muestra el símbolo $\Sigma$ en lugar de $S$. Tal como indica la nota al pie de la imagen, se deben usar los coeficientes $S$ (calculados arriba). Las fórmulas matemáticas escritas a continuación son las correctas.

$$b_1 = \frac{Sx_2^2 \cdot Sx_1y - Sx_1x_2 \cdot Sx_2y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1x_2)^2} \qquad b_2 = \frac{Sx_1^2 \cdot Sx_2y - Sx_1x_2 \cdot Sx_1y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1x_2)^2}$$

$$b_0 = \bar{y} - b_1\bar{x}_1 - b_2\bar{x}_2$$

Modelo: $\hat{y} = b_0 + b_1 x_1 + b_2 x_2$

---

### Ecuaciones Normales Polinomial Grado 2

![Sistema de ecuaciones normales de regresión polinomial](apuntes_images/image19.webp)

$$\begin{cases} nb_0 + \sum x \cdot b_1 + \sum x^2 \cdot b_2 = \sum y \\ \sum x \cdot b_0 + \sum x^2 \cdot b_1 + \sum x^3 \cdot b_2 = \sum xy \\ \sum x^2 \cdot b_0 + \sum x^3 \cdot b_1 + \sum x^4 \cdot b_2 = \sum x^2 y \end{cases}$$

Modelo: $\hat{y} = b_0 + b_1 x + b_2 x^2$

---

### Métricas

$$RMSE = \sqrt{\frac{\sum(y_i - \hat{y}_i)^2}{n}} \qquad R^2 = 1 - \frac{\sum(y_i - \hat{y}_i)^2}{\sum(y_i - \bar{y})^2}$$

- Elegir el modelo con **menor RMSE**.
- R² aceptable: **0.90 – 0.95**.
