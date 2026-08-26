# Práctica — Unidad 4: K-Means y PCA Paso a Paso

> Procedimientos basados en los dos notebooks de `Apuntes`, explicados y corregidos para poder repetirlos desde cero. Primero se reproduce K-Means y después se agrega la práctica de PCA correspondiente a las notas de la unidad.

---

## Tabla de Contenidos

1. [Preparación del Entorno](#1-preparación-del-entorno)
2. [Método 1 — K-Means con Clientes](#2-método-1--k-means-con-clientes)
3. [Método 2 — Elegir K con Codo y Silueta](#3-método-2--elegir-k-con-codo-y-silueta)
4. [Método 3 — Interpretar Clústeres y Datos Nuevos](#4-método-3--interpretar-clústeres-y-datos-nuevos)
5. [Método 4 — K-Means con Iris](#5-método-4--k-means-con-iris)
6. [Método 5 — Comparar Clústeres con Species](#6-método-5--comparar-clústeres-con-species)
7. [Método 6 — PCA con Iris](#7-método-6--pca-con-iris)
8. [Método 7 — Visualizar K-Means mediante PCA](#8-método-7--visualizar-k-means-mediante-pca)
9. [Método 8 — Elegir el Número de Componentes](#9-método-8--elegir-el-número-de-componentes)
10. [Procedimiento Completo para Examen](#10-procedimiento-completo-para-examen)
11. [Errores Frecuentes y Soluciones](#11-errores-frecuentes-y-soluciones)
12. [Ejercicios de Práctica](#12-ejercicios-de-práctica)
13. [Referencia Rápida de Código](#13-referencia-rápida-de-código)

---

## 1. Preparación del Entorno

### Archivos utilizados

```text
Unidad-4/
├── Guia de estudio - Teoria.md
├── Guia de estudio - Practica.md
└── Apuntes/
    ├── Kmeans/
    │   ├── Ejercicio-1/
    │   │   ├── Kmeans.ipynb
    │   │   └── puntuacion.csv
    │   └── Ejercicio-2/
    │       ├── Kmeans-iris ejercicio.ipynb
    │       └── iris.csv
```

Los notebooks originales leen el CSV por su nombre, por lo que cada notebook debe ejecutarse desde la carpeta donde se encuentra su archivo CSV.

### Instalar las librerías

```bash
pip install pandas numpy scikit-learn matplotlib
```

Si se utiliza Conda:

```bash
conda install pandas numpy scikit-learn matplotlib jupyter
```

### Importaciones necesarias

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import silhouette_score
from sklearn.decomposition import PCA
```

| Importación | Uso |
|---|---|
| `pandas` | Leer CSV y manipular DataFrames |
| `numpy` | Operaciones numéricas y acumulados |
| `matplotlib.pyplot` | Crear gráficas |
| `KMeans` | Formar clústeres |
| `StandardScaler` | Estandarizar características |
| `silhouette_score` | Medir separación y cohesión de los clústeres |
| `PCA` | Reducir dimensiones |

### Flujo que se repetirá

```text
Cargar → explorar → seleccionar características → limpiar
       → estandarizar → ajustar → evaluar → interpretar
```

> [!IMPORTANT]
> K-Means y PCA requieren variables numéricas. Un identificador no es una característica y una etiqueta conocida no debe utilizarse para formar un agrupamiento no supervisado.

---

## 2. Método 1 — K-Means con Clientes

**Notebook:** `Apuntes/Kmeans/Ejercicio-1/Kmeans.ipynb`  
**Dataset:** `Apuntes/Kmeans/Ejercicio-1/puntuacion.csv`  
**Objetivo:** agrupar 150 clientes usando ingreso anual y puntuación de gasto.

### Paso 1 — Importar librerías

```python
import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
```

### Paso 2 — Cargar el dataset

Desde el notebook ubicado en `Kmeans/Ejercicio-1`:

```python
df = pd.read_csv('puntuacion.csv')
```

Explorar antes de modelar:

```python
print(df.head())
print(df.shape)
print(df.info())
print(df.describe())
print(df.isnull().sum())
print('Duplicados:', df.duplicated().sum())
```

La estructura esperada es:

| Elemento | Valor |
|---|---|
| Filas | 150 |
| Columnas | 2 |
| Característica 1 | `Ingreso_Anual_kUSD` |
| Característica 2 | `Puntuacion_Gasto` |

### Paso 3 — Seleccionar solamente las características

```python
caracteristicas = ['Ingreso_Anual_kUSD', 'Puntuacion_Gasto']
X = df[caracteristicas]
```

Usar una lista explícita ofrece dos ventajas:

1. deja claro qué información recibe el algoritmo;
2. evita que una columna agregada después, como `Cluster`, se utilice accidentalmente.

### Paso 4 — Estandarizar

```python
escalador = StandardScaler()
datos_escalados = escalador.fit_transform(X)
```

Comprobar la transformación:

```python
print('Medias:', datos_escalados.mean(axis=0))
print('Desviaciones:', datos_escalados.std(axis=0))
```

Se esperan medias muy cercanas a `0` y desviaciones cercanas a `1`.

| Expresión | Acción |
|---|---|
| `fit(X)` | Aprende la media y desviación de cada columna |
| `transform(X)` | Aplica la estandarización aprendida |
| `fit_transform(X)` | Realiza ambas operaciones consecutivamente |
| `inverse_transform(Xz)` | Regresa de z-score a unidades originales |

### Paso 5 — Crear y ajustar K-Means

```python
modelo_kmeans = KMeans(
    n_clusters=3,
    random_state=42,
    n_init=10
)

etiquetas = modelo_kmeans.fit_predict(datos_escalados)
df['Cluster'] = etiquetas
```

El resultado de `fit_predict` es un arreglo de 150 etiquetas. Cada posición corresponde a la fila con el mismo índice.

```python
print(etiquetas[:10])
print(df.head())
print(df['Cluster'].value_counts().sort_index())
```

Con los parámetros del notebook, los grupos tienen 50 clientes cada uno:

```text
Cluster 0: 50
Cluster 1: 50
Cluster 2: 50
```

### Paso 6 — Recuperar centroides en unidades originales

`cluster_centers_` está expresado en la escala estandarizada porque ese fue el espacio utilizado durante el ajuste.

```python
centroides_originales = escalador.inverse_transform(
    modelo_kmeans.cluster_centers_
)

tabla_centroides = pd.DataFrame(
    centroides_originales,
    columns=caracteristicas
)

tabla_centroides.index.name = 'Cluster'
print(tabla_centroides.round(2))
```

Resultado aproximado:

| Cluster | Ingreso anual (kUSD) | Puntuación de gasto |
|---:|---:|---:|
| 0 | 28.87 | 20.09 |
| 1 | 79.69 | 80.67 |
| 2 | 30.76 | 74.89 |

> [!NOTE]
> Los identificadores podrían intercambiarse con otra configuración. Se deben reconocer los grupos por sus centroides, no memorizar el número de clúster.

### Paso 7 — Graficar puntos y centroides

```python
plt.figure(figsize=(8, 6))

plt.scatter(
    df['Ingreso_Anual_kUSD'],
    df['Puntuacion_Gasto'],
    c=df['Cluster'],
    cmap='viridis',
    s=60,
    alpha=0.8
)

plt.scatter(
    centroides_originales[:, 0],
    centroides_originales[:, 1],
    c='red',
    marker='X',
    s=200,
    edgecolor='black',
    label='Centroides'
)

plt.title('Agrupamiento de clientes con K-Means')
plt.xlabel('Ingreso anual (kUSD)')
plt.ylabel('Puntuación de gasto (1-100)')
plt.legend()
plt.grid(True, alpha=0.3)
plt.show()
```

### Lectura de la gráfica

- Cada punto representa un cliente.
- El color indica el clúster asignado.
- Las `X` rojas son los promedios de los clústeres.
- Los grupos aparecen compactos y claramente separados.
- Los centroides deben dibujarse en unidades originales porque los ejes también muestran unidades originales.

### Código completo del método

```python
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

# 1. Cargar
df = pd.read_csv('puntuacion.csv')

# 2. Seleccionar
caracteristicas = ['Ingreso_Anual_kUSD', 'Puntuacion_Gasto']
X = df[caracteristicas]

# 3. Estandarizar
escalador = StandardScaler()
datos_escalados = escalador.fit_transform(X)

# 4. Agrupar
modelo_kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
df['Cluster'] = modelo_kmeans.fit_predict(datos_escalados)

# 5. Recuperar centroides originales
centroides_originales = escalador.inverse_transform(
    modelo_kmeans.cluster_centers_
)

# 6. Visualizar
plt.figure(figsize=(8, 6))
plt.scatter(
    df['Ingreso_Anual_kUSD'], df['Puntuacion_Gasto'],
    c=df['Cluster'], cmap='viridis', s=60
)
plt.scatter(
    centroides_originales[:, 0], centroides_originales[:, 1],
    c='red', marker='X', s=200, label='Centroides'
)
plt.title('Agrupamiento de clientes con K-Means')
plt.xlabel('Ingreso anual (kUSD)')
plt.ylabel('Puntuación de gasto (1-100)')
plt.legend()
plt.grid(True)
plt.show()
```

---

## 3. Método 2 — Elegir K con Codo y Silueta

El notebook prueba valores desde 2 hasta 8. Se comienza en 2 porque el coeficiente de silueta necesita comparar cada clúster con al menos otro clúster.

### Paso 1 — Importar la métrica

```python
from sklearn.metrics import silhouette_score
```

### Paso 2 — Preparar listas y rango

```python
inercias = []
puntajes_silueta = []
rango_k = range(2, 9)
```

`range(2, 9)` genera `2, 3, 4, 5, 6, 7, 8`; el límite superior no se incluye.

### Paso 3 — Entrenar un modelo para cada K

```python
for k in rango_k:
    kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
    etiquetas_k = kmeans.fit_predict(datos_escalados)

    inercias.append(kmeans.inertia_)
    puntajes_silueta.append(
        silhouette_score(datos_escalados, etiquetas_k)
    )
```

> [!IMPORTANT]
> Dentro del ciclo se usa `etiquetas_k`, no la columna final `df['Cluster']`. Cada valor de $K$ produce una asignación diferente y debe evaluarse con sus propias etiquetas.

### Paso 4 — Construir una tabla comparativa

```python
resultados_k = pd.DataFrame({
    'K': list(rango_k),
    'Inercia': inercias,
    'Silueta': puntajes_silueta
})

print(resultados_k.round(4))
```

Valores aproximados para `puntuacion.csv`:

| K | Inercia | Silueta |
|---:|---:|---:|
| 2 | 112.3156 | 0.6044 |
| 3 | 16.0019 | **0.7926** |
| 4 | 12.4126 | 0.6600 |
| 5 | 10.6031 | 0.5235 |
| 6 | 9.2363 | 0.5193 |
| 7 | 7.9300 | 0.3634 |
| 8 | 6.7014 | 0.3759 |

### Paso 5 — Gráfica del codo

```python
plt.figure(figsize=(8, 4))
plt.plot(
    list(rango_k),
    inercias,
    marker='o',
    linestyle='--',
    color='blue'
)
plt.title('Método del codo (Elbow Method)')
plt.xlabel('Número de clústeres (K)')
plt.ylabel('Inercia (WCSS)')
plt.xticks(list(rango_k))
plt.grid(True, alpha=0.3)
plt.show()
```

La caída de $K=2$ a $K=3$ es muy grande. A partir de 3 la mejora es mucho menor; por ello el codo está en 3.

### Paso 6 — Gráfica de silueta

```python
plt.figure(figsize=(8, 4))
plt.plot(
    list(rango_k),
    puntajes_silueta,
    marker='s',
    linestyle='-',
    color='green'
)
plt.title('Puntuación de silueta')
plt.xlabel('Número de clústeres (K)')
plt.ylabel('Puntuación de silueta')
plt.xticks(list(rango_k))
plt.grid(True, alpha=0.3)
plt.show()
```

El valor más alto se encuentra en $K=3$.

### Paso 7 — Obtener programáticamente el mejor K por silueta

```python
indice_mejor = int(np.argmax(puntajes_silueta))
mejor_k = list(rango_k)[indice_mejor]
mejor_silueta = puntajes_silueta[indice_mejor]

print('Mejor K por silueta:', mejor_k)
print('Silueta:', round(mejor_silueta, 4))
```

Salida esperada:

```text
Mejor K por silueta: 3
Silueta: 0.7926
```

### Conclusión del ejercicio

$K=3$ es una selección sólida porque:

- coincide con el codo;
- tiene la silueta más alta;
- produce tres perfiles claros;
- cada grupo contiene suficientes observaciones.

---

## 4. Método 3 — Interpretar Clústeres y Datos Nuevos

### Paso 1 — Crear perfiles

```python
perfil_clusters = (
    df.groupby('Cluster')[caracteristicas]
      .agg(['count', 'mean', 'median', 'min', 'max'])
      .round(2)
)

print(perfil_clusters)
```

Para una tabla compacta:

```python
resumen = (
    df.groupby('Cluster')[caracteristicas]
      .mean()
      .round(2)
)

resumen['Cantidad'] = df.groupby('Cluster').size()
print(resumen)
```

### Paso 2 — Asignar nombres interpretables

Según los centroides del resultado actual:

```python
nombres_cluster = {
    0: 'Ingreso bajo / gasto bajo',
    1: 'Ingreso alto / gasto alto',
    2: 'Ingreso bajo / gasto alto'
}

df['Perfil'] = df['Cluster'].map(nombres_cluster)
print(df.head())
```

> [!WARNING]
> Este diccionario solo es correcto para las etiquetas obtenidas con la configuración actual. Si los números cambian, primero hay que volver a revisar los centroides.

### Paso 3 — Asignar un cliente nuevo

Supóngase un cliente con ingreso anual de 32 kUSD y puntuación de gasto de 78.

```python
nuevo_cliente = pd.DataFrame(
    [[32, 78]],
    columns=caracteristicas
)

nuevo_escalado = escalador.transform(nuevo_cliente)
cluster_nuevo = modelo_kmeans.predict(nuevo_escalado)[0]

print('Clúster:', cluster_nuevo)
print('Perfil:', nombres_cluster[cluster_nuevo])
```

El orden correcto es:

```text
Dato nuevo en unidades originales
        ↓ escalador.transform
Dato nuevo en la misma escala de entrenamiento
        ↓ modelo_kmeans.predict
Clúster más cercano
```

### Error que debe evitarse

```python
# INCORRECTO: aprende otra media y desviación con el dato nuevo
nuevo_escalado = escalador.fit_transform(nuevo_cliente)
```

Con una sola fila, esa operación la convertiría en ceros y destruiría la relación con el espacio usado para entrenar.

### Paso 4 — Guardar el resultado

```python
df.to_csv('puntuacion_con_clusters.csv', index=False)
```

Esto crea un archivo nuevo y conserva el CSV original.

---

## 5. Método 4 — K-Means con Iris

**Notebook:** `Apuntes/Kmeans/Ejercicio-2/Kmeans-iris ejercicio.ipynb`  
**Dataset:** `Apuntes/Kmeans/Ejercicio-2/iris.csv`  
**Objetivo:** buscar agrupaciones a partir de las cuatro mediciones de cada flor.

### Paso 1 — Cargar y revisar

```python
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

df = pd.read_csv('iris.csv')

print(df.head())
print(df.shape)
print(df.dtypes)
print(df.isnull().sum())
```

Columnas del dataset:

| Columna | Uso en K-Means | Motivo |
|---|---|---|
| `Id` | No | Solo identifica la fila |
| `SepalLengthCm` | Sí | Medición numérica |
| `SepalWidthCm` | Sí | Medición numérica |
| `PetalLengthCm` | Sí | Medición numérica |
| `PetalWidthCm` | Sí | Medición numérica |
| `Species` | No | Etiqueta conocida; no debe verla el agrupamiento |

### Paso 2 — Seleccionar las cuatro características

```python
caracteristicas = [
    'SepalLengthCm',
    'SepalWidthCm',
    'PetalLengthCm',
    'PetalWidthCm'
]

X = df[caracteristicas]
```

### Paso 3 — Estandarizar

```python
escalador = StandardScaler()
datos_escalados = escalador.fit_transform(X)
```

### Paso 4 — Formar tres clústeres

```python
modelo_kmeans = KMeans(
    n_clusters=3,
    random_state=42,
    n_init=10
)

df['Cluster'] = modelo_kmeans.fit_predict(datos_escalados)

print(df.head())
print(df['Cluster'].value_counts().sort_index())
```

Tamaños aproximados:

| Cluster | Cantidad |
|---:|---:|
| 0 | 53 |
| 1 | 50 |
| 2 | 47 |

### Paso 5 — Obtener centroides originales

```python
centroides_originales = escalador.inverse_transform(
    modelo_kmeans.cluster_centers_
)

tabla_centroides = pd.DataFrame(
    centroides_originales,
    columns=caracteristicas
)

tabla_centroides.index.name = 'Cluster'
print(tabla_centroides.round(3))
```

Resultado aproximado:

| Cluster | SepalLength | SepalWidth | PetalLength | PetalWidth |
|---:|---:|---:|---:|---:|
| 0 | 5.802 | 2.674 | 4.370 | 1.413 |
| 1 | 5.006 | 3.418 | 1.464 | 0.244 |
| 2 | 6.781 | 3.096 | 5.511 | 1.972 |

### Paso 6 — Graficar largo y ancho del pétalo

El notebook original selecciona correctamente las variables del pétalo para los puntos, pero conserva por error el título y los nombres de ejes del ejercicio de clientes. Además, el código de centroides aparece comentado.

Versión corregida:

```python
plt.figure(figsize=(8, 6))

plt.scatter(
    df['PetalLengthCm'],
    df['PetalWidthCm'],
    c=df['Cluster'],
    cmap='viridis',
    s=60,
    alpha=0.8
)

# En caracteristicas, PetalLengthCm ocupa la posición 2
# y PetalWidthCm ocupa la posición 3.
plt.scatter(
    centroides_originales[:, 2],
    centroides_originales[:, 3],
    c='red',
    marker='X',
    s=200,
    edgecolor='black',
    label='Centroides'
)

plt.title('Agrupamiento de flores Iris con K-Means')
plt.xlabel('Longitud del pétalo (cm)')
plt.ylabel('Ancho del pétalo (cm)')
plt.legend()
plt.grid(True, alpha=0.3)
plt.show()
```

### Por qué se usan `[:, 2]` y `[:, 3]`

Las columnas de los centroides mantienen el mismo orden de `caracteristicas`:

| Posición | Característica |
|---:|---|
| 0 | `SepalLengthCm` |
| 1 | `SepalWidthCm` |
| 2 | `PetalLengthCm` |
| 3 | `PetalWidthCm` |

Usar `[:, 0]` y `[:, 1]` dibujaría coordenadas del sépalo sobre ejes que representan pétalo, por lo que los centroides quedarían mal ubicados.

### Paso 7 — Evaluar posibles valores de K

```python
from sklearn.metrics import silhouette_score

inercias = []
siluetas = []
rango_k = range(2, 9)

for k in rango_k:
    modelo = KMeans(n_clusters=k, random_state=42, n_init=10)
    etiquetas_k = modelo.fit_predict(datos_escalados)
    inercias.append(modelo.inertia_)
    siluetas.append(silhouette_score(datos_escalados, etiquetas_k))

resultados = pd.DataFrame({
    'K': list(rango_k),
    'Inercia': inercias,
    'Silueta': siluetas
})

print(resultados.round(4))
```

Resultados aproximados:

| K | Inercia | Silueta |
|---:|---:|---:|
| 2 | 223.7320 | **0.5802** |
| 3 | 140.9658 | 0.4590 |
| 4 | 114.6179 | 0.3853 |
| 5 | 91.2954 | 0.3473 |
| 6 | 81.7566 | 0.3407 |
| 7 | 71.3198 | 0.3288 |
| 8 | 62.6518 | 0.3404 |

### Interpretación correcta

- La silueta indica que la separación geométrica más fuerte es de dos grupos.
- El ejercicio usa tres clústeres para buscar una estructura comparable con las tres especies conocidas.
- No es una contradicción: `Iris-setosa` se separa con claridad, mientras que `Iris-versicolor` e `Iris-virginica` se solapan.
- La decisión final depende tanto de las métricas como del propósito del análisis.

---

## 6. Método 5 — Comparar Clústeres con Species

Iris sí contiene una etiqueta real, pero K-Means no la utiliza durante el ajuste. Después del agrupamiento se puede comparar para comprender el resultado.

### Paso 1 — Crear una tabla cruzada

```python
comparacion = pd.crosstab(
    df['Species'],
    df['Cluster'],
    rownames=['Especie real'],
    colnames=['Clúster encontrado']
)

print(comparacion)
```

Resultado aproximado con la configuración usada:

| Especie real | Cluster 0 | Cluster 1 | Cluster 2 |
|---|---:|---:|---:|
| Iris-setosa | 0 | 50 | 0 |
| Iris-versicolor | 39 | 0 | 11 |
| Iris-virginica | 14 | 0 | 36 |

### Interpretación

- El clúster 1 contiene las 50 flores `Iris-setosa`.
- Los clústeres 0 y 2 mezclan parte de `Iris-versicolor` y `Iris-virginica`.
- Los números de clúster no equivalen a los códigos de las especies.
- Esta comparación es una evaluación posterior, no parte del entrenamiento.

### Paso 2 — Graficar clúster y especie lado a lado

```python
especies_codigo = df['Species'].astype('category').cat.codes

fig, ejes = plt.subplots(1, 2, figsize=(14, 5))

ejes[0].scatter(
    df['PetalLengthCm'], df['PetalWidthCm'],
    c=df['Cluster'], cmap='viridis', s=45
)
ejes[0].set_title('Clústeres encontrados por K-Means')
ejes[0].set_xlabel('Longitud del pétalo (cm)')
ejes[0].set_ylabel('Ancho del pétalo (cm)')

ejes[1].scatter(
    df['PetalLengthCm'], df['PetalWidthCm'],
    c=especies_codigo, cmap='viridis', s=45
)
ejes[1].set_title('Especies reales (solo comparación)')
ejes[1].set_xlabel('Longitud del pétalo (cm)')
ejes[1].set_ylabel('Ancho del pétalo (cm)')

plt.tight_layout()
plt.show()
```

> [!IMPORTANT]
> No debe evaluarse K-Means con `accuracy_score` comparando directamente `Species` con `Cluster`, porque los identificadores de clúster son arbitrarios. Para una evaluación formal con etiquetas conocidas se utilizan métricas invariantes a la permutación, como el índice de Rand ajustado.

### Comparación opcional mediante ARI

```python
from sklearn.metrics import adjusted_rand_score

ari = adjusted_rand_score(df['Species'], df['Cluster'])
print('Adjusted Rand Index:', round(ari, 4))
```

Con esta configuración, el valor aproximado es `0.6201`.

---

## 7. Método 6 — PCA con Iris

**Objetivo:** proyectar las cuatro mediciones sobre dos componentes principales y conservar la mayor varianza posible.

Este método utiliza el mismo `X`, `escalador` y `datos_escalados` del ejercicio de Iris.

### Paso 1 — Importar y crear PCA

```python
from sklearn.decomposition import PCA

pca = PCA(n_components=2)
```

`n_components=2` solicita dos nuevas dimensiones: CP1 y CP2.

### Paso 2 — Ajustar y proyectar

```python
datos_pca = pca.fit_transform(datos_escalados)
```

La forma cambia de 150 filas por 4 columnas a 150 filas por 2 componentes:

```python
print('Antes:', datos_escalados.shape)
print('Después:', datos_pca.shape)
```

Salida:

```text
Antes: (150, 4)
Después: (150, 2)
```

### Paso 3 — Crear un DataFrame de componentes

```python
df_pca = pd.DataFrame(
    datos_pca,
    columns=['CP1', 'CP2']
)

df_pca['Cluster'] = df['Cluster'].to_numpy()
df_pca['Species'] = df['Species'].to_numpy()

print(df_pca.head())
```

Primeras coordenadas aproximadas:

| CP1 | CP2 |
|---:|---:|
| -2.2645 | 0.5057 |
| -2.0864 | -0.6554 |
| -2.3680 | -0.3185 |
| -2.3042 | -0.5754 |
| -2.3888 | 0.6748 |

### Paso 4 — Consultar la varianza explicada

```python
varianza = pca.explained_variance_ratio_
varianza_acumulada = np.cumsum(varianza)

print('Varianza por componente:', varianza)
print('Varianza acumulada:', varianza_acumulada)
print('Total conservado:', varianza.sum())
```

Resultado aproximado:

```text
CP1: 0.7277 = 72.77 %
CP2: 0.2303 = 23.03 %
Total:       = 95.80 %
```

Se reducen cuatro columnas a dos y se conserva aproximadamente el 95.8 % de la varianza.

### Paso 5 — Graficar la proyección

```python
plt.figure(figsize=(8, 6))

plt.scatter(
    df_pca['CP1'],
    df_pca['CP2'],
    c=df_pca['Cluster'],
    cmap='viridis',
    s=60,
    alpha=0.8
)

plt.title('Iris proyectado sobre dos componentes principales')
plt.xlabel(f'CP1 ({varianza[0] * 100:.2f}% de varianza)')
plt.ylabel(f'CP2 ({varianza[1] * 100:.2f}% de varianza)')
plt.grid(True, alpha=0.3)
plt.show()
```

Esta gráfica muestra las cuatro características originales resumidas sobre los nuevos ejes calculados por PCA.

### Paso 6 — Examinar las cargas

```python
cargas = pd.DataFrame(
    pca.components_,
    columns=caracteristicas,
    index=['CP1', 'CP2']
)

print(cargas.round(4))
```

Resultado aproximado:

| Componente | SepalLength | SepalWidth | PetalLength | PetalWidth |
|---|---:|---:|---:|---:|
| CP1 | 0.5224 | -0.2634 | 0.5813 | 0.5656 |
| CP2 | 0.3723 | 0.9256 | 0.0211 | 0.0654 |

Lectura práctica:

- CP1 recibe contribuciones positivas fuertes del largo del sépalo, largo del pétalo y ancho del pétalo.
- CP2 está dominado principalmente por el ancho del sépalo.
- El signo indica dirección; la magnitud absoluta indica qué tan fuerte participa la variable.

> [!NOTE]
> Todo el vector de cargas puede aparecer con signos opuestos en otra ejecución o implementación y seguir representando el mismo eje geométrico.

### Código completo de PCA

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

# 1. Cargar y seleccionar
df = pd.read_csv('iris.csv')
caracteristicas = [
    'SepalLengthCm', 'SepalWidthCm',
    'PetalLengthCm', 'PetalWidthCm'
]
X = df[caracteristicas]

# 2. Estandarizar
escalador = StandardScaler()
X_escalado = escalador.fit_transform(X)

# 3. Reducir de cuatro dimensiones a dos
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X_escalado)

# 4. Organizar resultados
df_pca = pd.DataFrame(X_pca, columns=['CP1', 'CP2'])
df_pca['Species'] = df['Species']

# 5. Mostrar varianza
print('Varianza individual:', pca.explained_variance_ratio_)
print('Varianza total:', pca.explained_variance_ratio_.sum())

# 6. Visualizar usando Species solo para interpretar
codigos = df_pca['Species'].astype('category').cat.codes
plt.figure(figsize=(8, 6))
plt.scatter(df_pca['CP1'], df_pca['CP2'], c=codigos, cmap='viridis')
plt.xlabel('CP1')
plt.ylabel('CP2')
plt.title('PCA de Iris: cuatro variables proyectadas en dos')
plt.grid(True, alpha=0.3)
plt.show()
```

---

## 8. Método 7 — Visualizar K-Means mediante PCA

Hay dos procedimientos válidos, pero responden a preguntas ligeramente diferentes.

### Opción A — K-Means usa cuatro variables; PCA solo dibuja

Este es el procedimiento recomendado cuando se desea que el agrupamiento aproveche las cuatro mediciones.

```python
# X_escalado contiene las cuatro características estandarizadas

# 1. Agrupar en cuatro dimensiones
kmeans_4d = KMeans(n_clusters=3, random_state=42, n_init=10)
clusters_4d = kmeans_4d.fit_predict(X_escalado)

# 2. Proyectar las mismas observaciones a dos dimensiones
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X_escalado)

# 3. Dibujar la proyección y colorear con el resultado 4D
plt.figure(figsize=(8, 6))
plt.scatter(
    X_pca[:, 0], X_pca[:, 1],
    c=clusters_4d, cmap='viridis', s=60
)
plt.xlabel('CP1')
plt.ylabel('CP2')
plt.title('Clústeres calculados en 4D y visualizados con PCA')
plt.grid(True, alpha=0.3)
plt.show()
```

PCA cambia la vista, pero las etiquetas provienen del K-Means entrenado con cuatro variables.

### Opción B — PCA reduce primero; K-Means usa dos componentes

```python
# 1. Reducir
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X_escalado)

# 2. Agrupar en el espacio reducido
kmeans_pca = KMeans(n_clusters=3, random_state=42, n_init=10)
clusters_pca = kmeans_pca.fit_predict(X_pca)

# 3. Dibujar puntos y centroides, ambos en coordenadas PCA
plt.figure(figsize=(8, 6))
plt.scatter(
    X_pca[:, 0], X_pca[:, 1],
    c=clusters_pca, cmap='viridis', s=60
)
plt.scatter(
    kmeans_pca.cluster_centers_[:, 0],
    kmeans_pca.cluster_centers_[:, 1],
    c='red', marker='X', s=200, label='Centroides'
)
plt.xlabel('CP1')
plt.ylabel('CP2')
plt.title('K-Means aplicado después de PCA')
plt.legend()
plt.grid(True, alpha=0.3)
plt.show()
```

En este caso los centroides ya están en coordenadas CP1–CP2 y pueden dibujarse directamente.

### Comparación

| Aspecto | Opción A | Opción B |
|---|---|---|
| Datos usados por K-Means | Cuatro variables | Dos componentes |
| PCA se usa para | Visualizar | Reducir y luego modelar |
| Pérdida antes de agrupar | Ninguna por PCA | Aproximadamente 4.2 % de varianza en Iris |
| Centroides | Están en 4D | Están en 2D PCA |

> [!WARNING]
> En la opción A no deben dibujarse directamente `kmeans_4d.cluster_centers_` sobre CP1 y CP2. Primero habría que transformar esos centroides con `pca.transform`.

Versión correcta para agregar centroides a la opción A:

```python
centroides_pca = pca.transform(kmeans_4d.cluster_centers_)

plt.scatter(
    centroides_pca[:, 0],
    centroides_pca[:, 1],
    c='red', marker='X', s=200, label='Centroides proyectados'
)
```

---

## 9. Método 8 — Elegir el Número de Componentes

### Paso 1 — Ajustar PCA con todos los componentes

```python
pca_completo = PCA()
pca_completo.fit(X_escalado)
```

### Paso 2 — Crear tabla de varianza

```python
varianza_individual = pca_completo.explained_variance_ratio_
varianza_acumulada = np.cumsum(varianza_individual)

tabla_varianza = pd.DataFrame({
    'Componente': np.arange(1, len(varianza_individual) + 1),
    'Varianza_individual': varianza_individual,
    'Varianza_acumulada': varianza_acumulada
})

print(tabla_varianza.round(4))
```

Para Iris:

| Componente | Varianza individual | Acumulada |
|---:|---:|---:|
| 1 | 0.7277 | 0.7277 |
| 2 | 0.2303 | 0.9580 |
| 3 | 0.0368 | 0.9948 |
| 4 | 0.0052 | 1.0000 |

### Paso 3 — Graficar varianza acumulada

```python
componentes = np.arange(1, len(varianza_acumulada) + 1)

plt.figure(figsize=(8, 4))
plt.plot(componentes, varianza_acumulada, marker='o')
plt.axhline(
    y=0.95,
    color='red',
    linestyle='--',
    label='Umbral de 95%'
)
plt.xticks(componentes)
plt.ylim(0, 1.05)
plt.xlabel('Número de componentes')
plt.ylabel('Varianza explicada acumulada')
plt.title('Selección de componentes principales')
plt.legend()
plt.grid(True, alpha=0.3)
plt.show()
```

### Paso 4 — Calcular el mínimo de componentes para 95 %

```python
umbral = 0.95
n_componentes = np.argmax(varianza_acumulada >= umbral) + 1

print('Componentes necesarios:', n_componentes)
```

Salida para Iris:

```text
Componentes necesarios: 2
```

### Alternativa directa de scikit-learn

```python
pca_95 = PCA(n_components=0.95)
X_pca_95 = pca_95.fit_transform(X_escalado)

print('Componentes elegidos:', pca_95.n_components_)
print('Forma final:', X_pca_95.shape)
```

Cuando `n_components` es un decimal entre 0 y 1, PCA conserva automáticamente el número mínimo de componentes necesario para alcanzar esa proporción de varianza.

### Transformar una flor nueva con PCA

```python
nueva_flor = pd.DataFrame(
    [[6.0, 3.0, 4.8, 1.8]],
    columns=caracteristicas
)

nueva_escalada = escalador.transform(nueva_flor)
nueva_pca = pca.transform(nueva_escalada)

print('Coordenadas CP1 y CP2:', nueva_pca)
```

El mismo principio se mantiene:

- `escalador.transform`, no `fit_transform`;
- `pca.transform`, no `fit_transform`;
- las transformaciones deben ser las que se ajustaron con los datos de referencia.

---

## 10. Procedimiento Completo para Examen

### Si el problema pide agrupamiento con K-Means

1. **Identificar las características numéricas.** Excluir IDs, etiquetas y columnas irrelevantes.
2. **Revisar calidad.** Buscar nulos, duplicados, errores y valores atípicos.
3. **Estandarizar.** Aplicar `StandardScaler().fit_transform(X)`.
4. **Probar varios K.** Entrenar modelos dentro de un ciclo.
5. **Calcular inercia y silueta.** Guardar `inertia_` y `silhouette_score`.
6. **Elegir K.** Combinar codo, silueta e interpretación.
7. **Ajustar el modelo final.** Usar `fit_predict`.
8. **Agregar etiquetas.** Guardarlas en una columna `Cluster`.
9. **Interpretar centroides.** Aplicar `inverse_transform` si hubo escalamiento.
10. **Perfilar grupos.** Usar `groupby` y estadísticas.
11. **Visualizar.** Usar dos variables o PCA.
12. **Explicar la conclusión.** Describir grupos, no solo mostrar números.

### Si el problema pide reducción con PCA

1. **Seleccionar variables numéricas.** Excluir IDs y etiquetas.
2. **Estandarizar.** Aplicar `StandardScaler`.
3. **Ajustar PCA completo.** Examinar la varianza explicada.
4. **Elegir componentes.** Usar un umbral o el número necesario para visualizar.
5. **Transformar.** Obtener las nuevas coordenadas.
6. **Revisar varianza acumulada.** Cuantificar cuánta información se conserva.
7. **Examinar cargas.** Interpretar la contribución de las variables.
8. **Graficar.** Usar CP1 y CP2 cuando se conserven dos componentes.
9. **Aplicar a datos nuevos.** Usar solamente `transform`.

### Plantilla combinada

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
from sklearn.decomposition import PCA

# 1. Cargar
df = pd.read_csv('archivo.csv')

# 2. Seleccionar
caracteristicas = ['columna_1', 'columna_2', 'columna_3']
X = df[caracteristicas]

# 3. Revisar
print(X.info())
print(X.isnull().sum())

# 4. Estandarizar
escalador = StandardScaler()
X_escalado = escalador.fit_transform(X)

# 5. Elegir K
for k in range(2, 9):
    modelo_prueba = KMeans(n_clusters=k, random_state=42, n_init=10)
    etiquetas_prueba = modelo_prueba.fit_predict(X_escalado)
    print(
        k,
        modelo_prueba.inertia_,
        silhouette_score(X_escalado, etiquetas_prueba)
    )

# 6. Ajustar K-Means final
kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
df['Cluster'] = kmeans.fit_predict(X_escalado)

# 7. Reducir para visualizar
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X_escalado)

print('Varianza conservada:', pca.explained_variance_ratio_.sum())

# 8. Graficar
plt.scatter(X_pca[:, 0], X_pca[:, 1], c=df['Cluster'], cmap='viridis')
plt.xlabel('CP1')
plt.ylabel('CP2')
plt.title('Clústeres visualizados mediante PCA')
plt.show()
```

---

## 11. Errores Frecuentes y Soluciones

### `ValueError: could not convert string to float`

**Causa:** se incluyó una columna de texto como `Species`.

**Solución:** seleccionar solamente las columnas numéricas relevantes.

```python
X = df[['SepalLengthCm', 'SepalWidthCm',
        'PetalLengthCm', 'PetalWidthCm']]
```

### `ValueError: Input X contains NaN`

**Causa:** existen valores faltantes.

**Diagnóstico:**

```python
print(X.isnull().sum())
```

**Solución:** limpiar o imputar antes de escalar y agrupar.

### La gráfica no muestra la leyenda

**Causa:** se llamó `plt.legend()` sin haber asignado `label` a ningún elemento.

**Solución:** agregar, por ejemplo, `label='Centroides'` al segundo `scatter`, o quitar `plt.legend()` si no se necesita.

### Los centroides aparecen en un lugar incorrecto

Posibles causas:

- los puntos están en unidades originales y los centroides siguen estandarizados;
- se eligieron columnas de centroide distintas a las mostradas en los ejes;
- se mezclaron coordenadas originales con componentes PCA.

Verificación:

```python
print(caracteristicas)
print(modelo_kmeans.cluster_centers_.shape)
```

### El resultado cambia al volver a ejecutar

**Causa:** inicialización aleatoria no fijada.

**Solución:**

```python
KMeans(n_clusters=3, random_state=42, n_init=10)
```

### Todos los datos nuevos se transforman en cero

**Causa:** se aplicó `fit_transform` por separado a una sola fila.

**Solución:** reutilizar el escalador entrenado:

```python
nuevo_escalado = escalador.transform(nuevo_dato)
```

### `silhouette_score` falla con un solo clúster

La silueta compara el clúster propio con otro clúster. Use un rango que comience en 2.

### PCA parece devolver resultados diferentes

Primero compruebe:

- que las mismas columnas estén en el mismo orden;
- que se haya aplicado el mismo escalador;
- que se compare la magnitud y no solo el signo de las cargas;
- que `n_components` sea el mismo.

### Advertencia de memoria de K-Means en Windows

El notebook muestra una advertencia relacionada con MKL y el número de hilos. No cambia la lógica del ejercicio. Si aparece en ese entorno, se puede establecer `OMP_NUM_THREADS=1` **antes de iniciar Python o Jupyter** desde PowerShell:

```powershell
$env:OMP_NUM_THREADS = '1'
jupyter notebook
```

### Título incorrecto en la gráfica de Iris

El notebook conserva el texto «Agrupamiento de Clientes» y ejes de ingreso/gasto. Deben sustituirse por:

```python
plt.title('Agrupamiento de flores Iris con K-Means')
plt.xlabel('Longitud del pétalo (cm)')
plt.ylabel('Ancho del pétalo (cm)')
```

---

## 12. Ejercicios de Práctica

### Ejercicio 1 — Reproducir clientes

1. Cargue `puntuacion.csv`.
2. Estandarice ambas columnas.
3. Entrene K-Means con $K=3$.
4. Muestre la cantidad de clientes por clúster.
5. Recupere los centroides originales.
6. Explique cada grupo con una frase.

**Comprobación:** deben aparecer tres grupos de 50 observaciones y una silueta cercana a `0.7926`.

### Ejercicio 2 — Comparar K

Pruebe $K=2,3,4,5,6,7,8$ con clientes y responda:

1. ¿Dónde está el codo?
2. ¿Qué K maximiza la silueta?
3. ¿Coinciden ambos criterios?
4. ¿Por qué no se elige $K=8$ aunque tenga menor inercia?

**Respuesta esperada:** ambos criterios favorecen $K=3$; $K=8$ fragmenta los grupos y la menor inercia ocurre naturalmente al agregar centroides.

### Ejercicio 3 — Predecir clúster de clientes nuevos

Asigne los siguientes clientes mediante el escalador y modelo ya ajustados:

| Ingreso | Gasto |
|---:|---:|
| 30 | 20 |
| 82 | 85 |
| 28 | 75 |

Explique por qué no debe usar `fit_transform` con estas tres filas.

### Ejercicio 4 — K-Means con Iris

1. Excluya `Id` y `Species`.
2. Forme tres clústeres.
3. Dibuje largo contra ancho del pétalo.
4. Agregue centroides con las posiciones correctas.
5. Cree una tabla cruzada con `Species`.

**Comprobación:** `Iris-setosa` debe quedar completamente dentro de un solo clúster con esta configuración.

### Ejercicio 5 — Decisión de K en Iris

Calcule inercia y silueta entre 2 y 8. Explique por qué:

- la mejor silueta puede corresponder a $K=2$;
- el ejercicio puede continuar usando $K=3$;
- una especie real y un clúster no son conceptos idénticos.

### Ejercicio 6 — Proyección PCA

1. Reduzca Iris de cuatro variables a dos componentes.
2. Muestre `explained_variance_ratio_`.
3. Calcule la suma de las dos proporciones.
4. Grafique CP1 contra CP2.
5. Explique con sus propias palabras qué «diagonal» eligió PCA.

**Comprobación:** los dos componentes conservan aproximadamente 95.8 % de la varianza.

### Ejercicio 7 — Interpretar cargas

Muestre `pca.components_` como un DataFrame y responda:

1. ¿Qué variables tienen mayor peso absoluto en CP1?
2. ¿Qué variable domina CP2?
3. ¿Qué significa un peso negativo?
4. ¿Por qué CP1 no puede llamarse simplemente «longitud del pétalo»?

### Ejercicio 8 — Comparar dos flujos

Implemente:

- K-Means con cuatro variables y PCA solo para visualizar;
- PCA a dos componentes seguido de K-Means.

Compare inercia, silueta y asignaciones. Explique por qué las inercias de espacios diferentes no deben compararse directamente como si tuvieran la misma dimensionalidad.

---

## 13. Referencia Rápida de Código

### Seleccionar características

```python
caracteristicas = ['columna_1', 'columna_2']
X = df[caracteristicas]
```

### Estandarizar

```python
escalador = StandardScaler()
X_escalado = escalador.fit_transform(X)
```

### Entrenar K-Means

```python
kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
etiquetas = kmeans.fit_predict(X_escalado)
```

### Consultar resultados de K-Means

```python
kmeans.labels_
kmeans.cluster_centers_
kmeans.inertia_
```

### Recuperar centroides originales

```python
centroides_originales = escalador.inverse_transform(
    kmeans.cluster_centers_
)
```

### Calcular silueta

```python
silueta = silhouette_score(X_escalado, etiquetas)
```

### Perfilar clústeres

```python
df['Cluster'] = etiquetas
perfil = df.groupby('Cluster')[caracteristicas].mean()
```

### Asignar un dato nuevo

```python
nuevo_escalado = escalador.transform(nuevo_dato)
cluster_nuevo = kmeans.predict(nuevo_escalado)
```

### Reducir con PCA

```python
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X_escalado)
```

### Consultar resultados de PCA

```python
pca.explained_variance_ratio_  # proporción por componente
pca.components_                # cargas o direcciones
pca.n_components_              # cantidad final de componentes
```

### Varianza acumulada

```python
varianza_acumulada = np.cumsum(
    pca.explained_variance_ratio_
)
```

### Transformar datos nuevos con PCA

```python
nuevo_escalado = escalador.transform(nuevo_dato)
nuevo_pca = pca.transform(nuevo_escalado)
```

### Regla de memoria

```text
DATOS DE REFERENCIA: fit_transform
DATOS NUEVOS:         transform

K-MEANS: grupos y centroides
PCA:     componentes y varianza explicada
```

> **Orden recomendado:** limpiar → seleccionar → estandarizar → aplicar K-Means o PCA → evaluar → interpretar.
