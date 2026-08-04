# 📚 Guía de Estudio Teórico: Procesamiento y Análisis de Datos (Unidad 1 y 2)

Esta guía recopila y explica los conceptos teóricos fundamentales presentes en los archivos de tus libretas de Jupyter, estructurados de manera clara para tu examen.

---

## 1. ETL (Extract, Transform, Load)
Es el proceso central en la integración de datos, utilizado para mover datos desde múltiples fuentes hacia un sistema centralizado (como una base de datos o un data warehouse) preparándolos para su análisis.

* **Extract (Extraer):** Consiste en leer y extraer la información de diversas fuentes de origen. En tu caso, involucra la lectura de archivos CSV (`pd.read_csv`) o Excel (`pd.read_excel`), especificando motores correctos (como `xlrd` para archivos `.xls` antiguos) y gestionando la lectura de múltiples hojas de cálculo simultáneamente.
* **Transform (Transformar):** Es la fase más crítica. Aquí los datos "crudos" se limpian, filtran, validan y formatean para que sean consistentes. Incluye la limpieza de nulos, eliminación de duplicados, corrección de errores y escalamiento numérico.
* **Load (Cargar):** Es la inserción de los datos ya transformados y limpios en la base de datos de destino (ej. MySQL). Implica respetar el modelo relacional (obtener y relacionar las llaves foráneas o IDs) mediante consultas y sentencias `INSERT`.

---

## 2. Data Cleaning (Limpieza de Datos)
Es el proceso de detectar, corregir o eliminar registros inexactos o corruptos de un conjunto de datos. En las libretas se dividen en 4 problemas principales:

### A. Valores Vacíos (Nulos / NaN)
Son los datos faltantes en el sistema. ¿Qué hacer con ellos?
* **Eliminación:** Borrar los registros que tengan datos faltantes (ej. si toda la fila está vacía).
* **Imputación (Relleno):** En lugar de borrar, se sustituyen los valores nulos por un valor estimado para no perder la fila entera. Los métodos estadísticos más comunes son:
  * **Media (Promedio) / Mediana / Moda:** Rellenar con los valores centrales de esa columna.
  * **KNN (K-Nearest Neighbors):** Un algoritmo más avanzado que busca los registros ("vecinos") más similares y usa sus datos para estimar el valor faltante.

### B. Valores Duplicados
Registros que se repiten idénticamente. Se identifican analizando fila por fila o por un subconjunto de columnas y, por lo general, se eliminan directamente del conjunto de datos original (`drop_duplicates`).

### C. Valores Atípicos (Outliers)
Son números que se escapan drásticamente de la normalidad (ej. una casa que cuesta 100 veces más que el resto). Para identificarlos estadísticamente se usan los **Cuartiles (Q1 y Q3)** y el rango intercuartílico, con los que se calculan un **Límite Inferior (low_limit)** y un **Límite Superior (high_limit)**. Cualquier valor fuera de esa caja se considera atípico y suele ser filtrado para no sesgar el análisis.

### D. Datos Erróneos o Conflictivos
Errores de dedo, espacios en blanco al inicio o al final de las palabras, o tipos de datos incorrectos. Se solucionan aplicando reemplazos, expresiones regulares o transformaciones de strings (como quitar espacios o cambiar formatos).

---

## 3. Preparación y Transformación de Datos

Antes de aplicar modelos de inteligencia artificial o gráficas complejas, los datos numéricos a veces necesitan cambiar de "forma" o escala:

* **Generalización (Discretización):** Convertir números continuos en categorías. Por ejemplo, tomar un rango continuo de precios numéricos y convertirlos en etiquetas discretas ("barato", "moderado", "caro") estableciendo límites o contenedores (bins).
* **Escalamiento y Normalización:** Sirve para nivelar columnas numéricas que tienen magnitudes muy distintas, para que ninguna opaque a otra.
  * **MinMaxScaler (Reescalamiento):** Cambia la escala de los valores considerando el máximo y el mínimo absolutos, de forma que el valor más pequeño siempre será `0` y el más grande será `1`.
  * **StandardScaler (Normalización):** Cambia la escala basándose en el promedio y la **desviación estándar**. Convierte el promedio a `0` y mide los demás valores como distancias positivas o negativas desde ese centro.
* **Smoothing (Suavizado):** Se usa para quitar el "ruido" en series de tiempo, aplicando promedios móviles (ej. sacar el promedio de los últimos 10 días constantemente) para ver tendencias más claras.

---

## 4. Conceptos Base de Análisis (Pandas)

* **Dataframe:** Estructura de datos bidimensional (como una hoja de cálculo con filas y columnas) que es el pilar para analizar datos en Python.
* **Filtros y Condicionales:** Capacidad de extraer un subconjunto de datos cumpliendo reglas lógicas (`AND`, `OR`, `NOT`) o buscando pertenencia en listas (`IN`).
* **Búsqueda de Patrones (Strings/Regex):** Uso de métodos textuales para encontrar registros que empiecen, terminen o contengan ciertas palabras, a veces ignorando mayúsculas/minúsculas.
* **Funciones de Agregación:** Funciones matemáticas que resumen muchos datos en uno solo. Ejemplos: `MAX`, `MIN`, `AVG` (Promedio/Media), `SUM` (Suma total) y `COUNT` (Conteo de registros).
* **Agrupamiento (Group By):** Técnica analítica que consiste en dividir los datos en categorías (ej. agrupar por 'Tipo de habitación') y luego aplicarle una función de agregación a cada grupo por separado (ej. contar cuántos hay de cada tipo).
