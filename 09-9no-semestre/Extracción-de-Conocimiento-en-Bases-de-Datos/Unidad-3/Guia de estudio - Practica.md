# Práctica — Unidad 3: Métodos y Procedimientos

> Solo los métodos vistos en clase, paso a paso. Sin teoría adicional.

---

## Tabla de Contenidos

1. [Método 1 — Regresión Lineal Simple en Excel](#1-método-1--regresión-lineal-simple-en-excel)
2. [Método 2 — Regresión Lineal Múltiple en Excel](#2-método-2--regresión-lineal-múltiple-en-excel)
3. [Método 3 — Regresión Polinomial Grado 2 en Excel](#3-método-3--regresión-polinomial-grado-2-en-excel)
4. [Método 4 — Regresión Lineal Múltiple en Python](#4-método-4--regresión-lineal-múltiple-en-python)
5. [Método 5 — Regresión Polinomial en Python](#5-método-5--regresión-polinomial-en-python)
6. [Método 6 — División de Datos en R (Dataset Iris)](#6-método-6--división-de-datos-en-r-dataset-iris)
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
# y = b0 + b1*x1 + b2*x1² + b3*x2 + b4*x2² + b5*x1*x2
predicciones = modelo_poly.predict(x_test_poly)
print('Predicciones:', predicciones)
print('Originales:  ', y_test.values)

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

## 6. Método 6 — División de Datos en R (Dataset Iris)

**Ejercicio**: dataset `iris` en R. Separar en entrenamiento y prueba, con datos normalizados.

### Código visto en clase

```r
# Se asume que 'datos' ya contiene el iris normalizado (escala z-score)
# y que 'indices_train' ya fue generado con sample()

# Variables independientes (columnas 1 a 4: Sepal.Length, Sepal.Width,
#                                            Petal.Length, Petal.Width)
datos_train <- datos[indices_train, 1:4]    # Filas del entrenamiento
clase_train <- datos[indices_train, 5]      # Columna 5: Species (variable dependiente)

# El signo negativo excluye esas filas → lo que queda es el conjunto de prueba
datos_test  <- datos[-indices_train, 1:4]
clase_test  <- datos[-indices_train, 5]
```

### Lo que hace cada línea

| Línea | Resultado |
|---|---|
| `datos[indices_train, 1:4]` | Filas de entrenamiento, solo columnas de variables x |
| `datos[indices_train, 5]` | Filas de entrenamiento, solo la columna Species (y) |
| `datos[-indices_train, 1:4]` | Todo lo que **no** es entrenamiento → prueba, variables x |
| `datos[-indices_train, 5]` | Todo lo que **no** es entrenamiento → prueba, variable y |

---

## 7. Referencia Rápida de Fórmulas

### Regresión Lineal Simple

$$b_1 = \frac{n\sum xy - \sum x \sum y}{n\sum x^2 - (\sum x)^2} \qquad b_0 = \frac{\sum y \sum x^2 - \sum x \sum xy}{n\sum x^2 - (\sum x)^2}$$

Modelo: $\hat{y} = b_0 + b_1 x$

---

### Coeficientes S (para Múltiple)

$$Sx_i^2 = \sum x_i^2 - \frac{(\sum x_i)^2}{n}$$

$$Sx_iy = \sum x_iy - \frac{\sum x_i \cdot \sum y}{n}$$

$$Sx_1x_2 = \sum x_1x_2 - \frac{\sum x_1 \cdot \sum x_2}{n}$$

### Regresión Lineal Múltiple (2 variables)

$$b_1 = \frac{Sx_2^2 \cdot Sx_1y - Sx_1x_2 \cdot Sx_2y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1x_2)^2} \qquad b_2 = \frac{Sx_1^2 \cdot Sx_2y - Sx_1x_2 \cdot Sx_1y}{Sx_1^2 \cdot Sx_2^2 - (Sx_1x_2)^2}$$

$$b_0 = \bar{y} - b_1\bar{x}_1 - b_2\bar{x}_2$$

Modelo: $\hat{y} = b_0 + b_1 x_1 + b_2 x_2$

---

### Ecuaciones Normales Polinomial Grado 2

$$\begin{cases} nb_0 + \sum x \cdot b_1 + \sum x^2 \cdot b_2 = \sum y \\ \sum x \cdot b_0 + \sum x^2 \cdot b_1 + \sum x^3 \cdot b_2 = \sum xy \\ \sum x^2 \cdot b_0 + \sum x^3 \cdot b_1 + \sum x^4 \cdot b_2 = \sum x^2 y \end{cases}$$

Modelo: $\hat{y} = b_0 + b_1 x + b_2 x^2$

---

### Métricas

$$RMSE = \sqrt{\frac{\sum(y_i - \hat{y}_i)^2}{n}} \qquad R^2 = 1 - \frac{\sum(y_i - \hat{y}_i)^2}{\sum(y_i - \bar{y})^2}$$

- Elegir el modelo con **menor RMSE**.
- R² aceptable: **0.90 – 0.95**.
