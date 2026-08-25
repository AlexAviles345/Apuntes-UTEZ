# 📝 Formulario de Comandos (Data Science, Pandas y SQL)

*Basado en los archivos `.ipynb` y `.txt` del entorno de trabajo, estructurado como un formulario de referencia rápida.*

---

### 🌳 1. Gestión de Entornos (Conda)
* **Crear un entorno nuevo:** `conda create --name nombre_entorno`
* **Activar el entorno:** `conda activate nombre_entorno`
* **Ver todos los entornos existentes:** `conda env list`
* **Eliminar un entorno:** `conda remove --name nombre_entorno --all`

### 📚 2. Instalación de Librerías y Jupyter
* **Instalar paquetes desde PIP:** `pip install pandas openpyxl xlrd`
* **Instalar paquetes desde Conda:** `conda install jupyter matplotlib seaborn scikit-learn mysql-connector-python`
* **Lanzar Jupyter Notebook:** `jupyter notebook`

---

### 📂 3. Creación y Lectura de Archivos (Pandas)
> **Nota:** Primero se tiene que usar e importar la librería: `import pandas as pd`

**Crear un DataFrame desde cero:**
* **Con listas de registros (por filas):**
  ```python
  datos = [
      ['Alex', 23],
      ['Daniel', 45]
  ]
  df = pd.DataFrame(datos, columns=['nombre', 'edad'])
  ```
* **Con un diccionario (por columnas):**
  ```python
  datos = {
      'nombre': ['Alex', 'Daniel'],
      'edad': [23, 45]
  }
  df = pd.DataFrame(datos)
  ```

**Leer archivos existentes:**
* **Leer un archivo CSV:** 
  `df = pd.read_csv('archivo.csv')`
  * *Solucionar errores de codificación:* `encoding='ISO-8859-1'`
* **Leer un archivo Excel:** 
  `df = pd.read_excel('archivo.xlsx')`
  * *Extraer una hoja específica:* `sheet_name='NombreHoja'`
  * *Extraer todas las hojas (Devuelve un diccionario):* `sheet_name=None`
  * *Ignorar filas al inicio:* `skiprows=5`
  * *Especificar qué columnas leer:* `usecols='A:D, G'`
  * *Especificar motor y evitar NaN automáticos:* `engine='xlrd', keep_default_na=False`
  * *Solucionar errores de codificación:* `encoding='ISO-8859-1'`

* **Obtener los nombres de las hojas (si `sheet_name=None`):** `list(datos.keys())`

---

### 🔍 4. Exploración y Búsqueda en Documentos (DataFrames)
En esta sección especificamos los valores y campos a mostrar, filtrando la información.

* **Detalles generales del DataFrame:** `df.info()`
* **Estadísticas básicas y variables:** `df.describe()`
* **Obtener número de registros (filas) y columnas:** `df.shape`
* **Seleccionar campos/columnas específicas:** `df[['columna1', 'columna2']]`

#### 📍 Selección por Índice (`loc` e `iloc`)
* **`loc` (Por nombre/etiqueta):** Busca usando los nombres de filas y columnas.
  * *Celda exacta:* `df.loc['nombre_fila', 'nombre_columna']`
  * *Filtrar filas y mostrar columnas:* `df.loc[df['precio'] > 300, ['marca', 'precio']]`
* **`iloc` (Por posición numérica):** Busca usando el número de índice (0, 1, 2...).
  * *Celda exacta:* `df.iloc[0, 1]` (fila 0, columna 1)
  * *Seleccionar un rango:* `df.iloc[0:5, 0:3]` (primeras 5 filas, primeras 3 columnas)

#### 🎯 Filtrado y Uso de Operadores Lógicos
```python
# Recibe la condición para la columna
df[df['precio'] > 300]
```

**Múltiples condiciones:**
* **Operador Y (AND):** `df[(df['descuento'] > 0.20) & (df['descuento'] < 0.40)]`
* **Operador O (OR):** `df[(df['marca'] == 'Xiaomi') | (df['marca'] == 'Dell')]`
* **Búsqueda en lista (IN):** `df[df['marca'].isin(['Xiaomi', 'Dell'])]`
* **Negación (NOT):** `df[~df['marca'].isin(['Xiaomi', 'Dell'])]`

#### Tabla de Operadores Pandas (Referencia)
| Significado | Operador Pandas | Símbolo Lógico |
| :---: | :---: | :---: |
| Greater than | `>` | Mayor que |
| Less than | `<` | Menor que |
| Equals | `==` | Igual a |
| No equals | `!=` | Diferente de |
| In (En lista)| `.isin([...])` | Pertenece a |
| And | `&` | Y lógico |
| Or | `\|` | O lógico |
| Not | `~` | Negación / NO lógico |

#### 🔡 Buscar un patrón en una cadena de texto (Strings)
Devuelve los registros que coincidan con el patrón en ese campo.
* **Empieza con (Like 'Patron%'):** `df[df['nombre'].str.startswith('Clean')]`
* **Contiene palabra (Like '%Patron%'):** `df[df['nombre'].str.contains('Home')]`
* **Coincide con Regex Expresión Regular:** `df[df['nombre'].str.match(r'^\d{1,2}[A-J]$')]`

> **Opciones adicionales al buscar texto:**
> * `case=False` → Hace que no importen las mayúsculas o minúsculas.
> * `na=False` → Solo analiza los registros llenos e ignora los vacíos.

---

### 🧹 5. Limpieza y Transformación de Datos (Data Cleaning)
* **Contar valores nulos (vacíos) por columna:** `df.isnull().sum()`
* **Filtrar registros que NO tienen vacíos en ninguna columna:** `df[df.notnull().all(axis=1)]`
* **Eliminar filas con todas sus celdas vacías:** `df.dropna(how='all')`
* **Contar registros duplicados:** `df.duplicated().sum()`
* **Eliminar registros duplicados directamente:** `df.drop_duplicates(inplace=True)`

**Transformación de Strings y Valores:**
* **Quitar espacios en blanco (Inicio/Fin):** `df['columna'] = df['columna'].str.strip()`
* **Reemplazar valores (Ej. por NaN):** `df['columna'].replace('', pd.NA)`

**Rellenar valores vacíos (Imputación):**
```python
# Usando el promedio
promedio = df['columna'].mean()
df['columna'] = df['columna'].fillna(promedio)

# Usando la mediana o moda
mediana = df['columna'].median()
moda = df['columna'].mode()[0]
```

---

### 📊 6. Agregación y Agrupación
* **Valor máximo de un campo:** `df['precio'].max()`
* **Promedio de un campo:** `df['precio'].mean()`
* **Contar registros en una columna:** `df['precio'].count()`
* **Contar registros aplicando una condición:** 
  `(df['precio'] > 600).sum()` o también `df[df['precio'] > 600].shape[0]`
* **Agrupar por campo y contar cantidad (Group By):** 
  `df.groupby('tipo').size().reset_index(name='cantidad')`

**Manejo de Estructuras e Iteraciones:**
* **Concatenar múltiples DataFrames (lista):** `df_consolidado = pd.concat(lista_dfs)`
* **Obtener columnas como lista (ej. de un rango):** `df.columns.tolist()[10:12]`

* **Iterar usando `enumerate` (Listas o Arrays):**
  Añade un contador automático al iterar (ej. empezando en 1).
  ```python
  for i, nombre in enumerate(hojas, 1):
      df = datos[nombre]
      df['Grupo'] = nombre
  ```

* **Iterar sobre filas de un DataFrame (`iterrows`):**
  Recorre cada registro devolviendo el índice y los datos de la fila. Muy útil para operaciones fila por fila (como inserts en bases de datos).
  ```python
  for indice, fila in df.iterrows():
      # Acceder al valor de la columna para la fila actual
      print(fila['NombreColumna'])
  ```

---

### 🤖 7. Machine Learning, Preprocesamiento y Generalización
**Identificar Valores Atípicos (Cuartiles):**
```python
Q1 = df['precio'].quantile(0.25)
Q3 = df['precio'].quantile(0.75)
limite_inferior = Q1 - 1.5 * (Q3 - Q1)
limite_superior = Q3 + 1.5 * (Q3 - Q1)
```

**Generalización (Crear nuevas columnas por condiciones):**
* **Condicional Simple (np.where):**
  `df['costo'] = np.where(df['precio'] >= 600, 'caro', 'barato')`
* **Por Rangos Definidos (pd.cut):**
  ```python
  limites = [0, 200, 600, float('inf')]
  etiquetas = ['barato', 'moderado', 'caro']
  df['costo'] = pd.cut(df['precio'], bins=limites, labels=etiquetas)
  ```

* **Suavizado de series temporales (Smoothing):**
  `df['suavizado'] = df['disponibilidad'].rolling(window=10).mean()`

**Imputación y Escalamiento:**
* **Imputar vacíos usando KNN:** 
  ```python
  from sklearn.impute import KNNImputer
  imputer = KNNImputer(n_neighbors=4)
  df[['columna']] = imputer.fit_transform(df[['columna']])
  ```
* **Normalización (StandardScaler):** Considera la desviación estándar.
  ```python
  from sklearn.preprocessing import StandardScaler
  scaler_std = StandardScaler()
  df['col_std'] = scaler_std.fit_transform(df[['columna']])
  ```
* **Reescalamiento (MinMaxScaler):** Cambia la escala donde 1 es el máximo y 0 el mínimo.
  ```python
  from sklearn.preprocessing import MinMaxScaler
  scaler_minmax = MinMaxScaler()
  df['col_minmax'] = scaler_minmax.fit_transform(df[['columna']])
  ```

---

### 📈 8. Gráficas y Visualización
* **Crear Histograma básico con Pandas:** `df['col'].plot(kind='hist', bins=20, color='skyblue', edgecolor='black')`
* **Gráfica de Líneas con Matplotlib:**
  ```python
  import matplotlib.pyplot as plt
  plt.plot(df.index, df['columna'], color='black', marker='o', linestyle='--')
  plt.show()
  ```
* **Crear Diagrama de Caja (Boxplot) con Seaborn:**
  ```python
  import seaborn as sns
  import matplotlib.pyplot as plt
  
  plt.figure(figsize=(5, 2)) # Tamaño de gráfica
  sns.boxplot(x=df['col'])   # Crea el gráfico de caja
  plt.title('Título del Gráfico')
  plt.show()                 # Muestra el gráfico
  ```

---

### 🗄️ 9. Conexión a Base de Datos MySQL (Proceso ETL)
* **Crear y verificar conexión a la Base de Datos:**
  ```python
  import mysql.connector
  from mysql.connector import Error
  
  config_db = {'host': 'localhost', 'user':'root', 'password':'...', 'database':'db'}
  try:
      connection = mysql.connector.connect(**config_db)
      if connection.is_connected():
          print('Conexión exitosa')
  except Error as e:
      print(f"Error al conectar: {e}")
  ```
* **Insertar un documento/registro (Insert):**
  ```python
  cursor = connection.cursor()
  cursor.execute('INSERT IGNORE INTO Tabla(campo) VALUES(%s)', ('valor',))
  connection.commit()
  ```
* **Buscar / Seleccionar registros (Select):**
  ```python
  cursor.execute('SELECT idCampo FROM Tabla WHERE nombre = %s', ('valor',))
  resultado = cursor.fetchone()  # Trae un solo registro
  # cursor.fetchall() Traería todos los registros (limpia el cursor)
  ```
* **Obtener el ID del último registro insertado:** `cursor.lastrowid`
