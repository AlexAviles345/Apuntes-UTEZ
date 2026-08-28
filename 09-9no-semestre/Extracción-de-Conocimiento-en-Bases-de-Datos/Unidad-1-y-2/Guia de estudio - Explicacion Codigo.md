# 🔬 La Teoría detrás del Código (Pandas bajo la Lupa)

Al escribir código en Pandas, ocurren procesos lógicos y matemáticos muy específicos. Esta guía explica el "por qué" y el comportamiento interno de los comandos más usados en la guía práctica, acompañados de ejemplos.

---

### 1. ¿Series o DataFrames? (`df['Col']` vs `df[['Col']]`)
* **`df['precio']` (Un solo corchete):** Devuelve una **Serie**. En Pandas, una Serie es un vector unidimensional (una estructura simple equivalente a una columna suelta).
* **`df[['precio', 'edad']]` (Doble corchete):** Devuelve un **DataFrame**. Al usar dobles corchetes estás pasando una "lista de columnas". Esto obliga a Pandas a devolver una matriz bidimensional (tabla formal), incluso si solo pides una columna.

```python
# Devuelve una Serie (sin formato de tabla bonita)
serie_precios = df['precio']

# Devuelve un DataFrame (tabla formal con 1 sola columna)
df_precios = df[['precio']] 
```

### 2. ¿Qué es realmente una Condición? (`df['precio'] > 300`)
Cuando escribes `df['precio'] > 300`, **no** obtienes los datos filtrados de inmediato. La computadora devuelve una **Máscara Booleana**: una Serie temporal llena de `True` y `False`, evaluando la condición fila por fila.
Por eso, para ver los datos reales, la condición se envuelve nuevamente en el dataframe, para que Pandas solo te imprima las filas donde cayó un `True`.

```python
# 1. Esto solo escupe: [False, True, False, True...]
mascara = df['precio'] > 300 

# 2. Esto sí filtra la tabla usando los "Trues"
df_filtrado = df[mascara] 

# 3. Lo anterior es igual a la forma directa que siempre usamos:
df_filtrado = df[ df['precio'] > 300 ]
```

### 3. La diferencia entre `.count()` y `.sum()`
Estadísticamente hacen cosas completamente distintas:
* **`.count()` (Conteo):** Cuenta iterativamente cuántos registros **no están vacíos (no nulos)** en una columna. 
* **`.sum()` (Suma):** Realiza una suma aritmética de todos los números. 
  * **El truco en condicionales:** En Python, `True` equivale a `1` y `False` a `0`. Cuando haces `(condicion).sum()`, sumas puros *unos*, lo que astutamente te da la cantidad total de registros que cumplieron la regla.

```python
# ¿Cuántos clientes registraron su teléfono? (ignora vacíos)
total_telefonos = df['telefono'].count()

# ¿Cuánto suman todas las ventas del mes?
ingresos_totales = df['ventas'].sum()

# TRUCO: ¿Cuántos productos cuestan más de $300? 
# (Suma todos los "True" generados por la condición)
productos_caros = (df['precio'] > 300).sum()
```

### 4. ¿Por qué usamos `.iterrows()`?
Pandas es **vectorizado** (procesa columnas enteras de un solo golpe rapidísimo sin usar bucles). Sin embargo, cuando necesitamos hacer operaciones altamente personalizadas e independientes **fila por fila** (como inyectar registro por registro a una base de datos MySQL), la vectorización no nos sirve.
**`.iterrows()`** rompe temporalmente esa matriz masiva y extrae los datos renglón por renglón de manera iterativa en un bucle `for`.

```python
# Extraemos el 'indice' (numero de fila) y la 'fila' (datos de esa fila)
for indice, fila in df.iterrows():
    nombre = fila['nombre']
    
    # Podemos hacer operaciones individuales (ej. Insertar a SQL)
    cursor.execute('INSERT INTO Tabla(nom) VALUES(%s)', (nombre,))
```

### 5. El misterio de `inplace=True`
Por defecto, cuando Pandas modifica algo (como borrar duplicados), **no altera tu DataFrame original**, sino que crea una *copia* nueva en la memoria RAM con los cambios.
Escribir `inplace=True` le ordena a Pandas: *"No gastes memoria creando copias, haz la operación destructiva directamente en la estructura original que ya tengo abierta"*.

```python
# Forma 1 (Sin inplace): Tenemos que sobrescribir la variable original
df = df.drop_duplicates()

# Forma 2 (Con inplace): Modifica a 'df' silenciosamente de forma directa
df.drop_duplicates(inplace=True)
```

### 6. `.loc` vs `.iloc` (Las dos brújulas de Pandas)
Sirven para encontrar coordenadas exactas (fila y columna), pero "hablan idiomas" distintos:
* **`.loc` (Localización por Etiquetas):** Busca los **nombres exactos** (strings) de columnas e índices.
* **`.iloc` (Localización por Índices enteros):** Solo entiende de **posiciones numéricas** (0, 1, 2...), sin importar cómo se llamen.

```python
# "Dame la fila que se llama 'cliente_5' y la columna 'precio'"
dato_etiqueta = df.loc['cliente_5', 'precio']

# "Dame la fila 0 (la primera de todas) y la columna 1 (la segunda)"
dato_posicion = df.iloc[0, 1]
```

### 7. ¿Por qué encadenamos `.isnull().sum()`?
* `df.isnull()` devuelve una tabla del mismo tamaño llena de `True` (si el campo está vacío) y `False`.
* Como es imposible leer una tabla gigante de puros booleanos, le encadenamos `.sum()`. Este comando aplasta la tabla y suma los `True` (unos), diciéndote cuántos nulos hay agrupados por columna.

```python
# Nos devuelve una lista de columnas y cuántos vacíos tiene cada una
# Ejemplo: 
# nombre      0
# telefono   15
vacios_por_columna = df.isnull().sum()
```

### 8. ¿Para qué sirve el `.reset_index()` después de un Group By?
Cuando agrupas con `groupby()`, Pandas toma la columna que usaste para agrupar y la convierte en el **"Índice principal"** (la llave maestra), rompiendo la estructura de tabla normal.
El `.reset_index()` le quita esos privilegios a la columna y le pone números estándar (0, 1, 2...) al índice para que todo vuelva a ser un DataFrame regular.

```python
# Sin reset_index (El 'tipo' se queda atorado como índice)
agrupado_feo = df.groupby('tipo').size()

# Con reset_index (El 'tipo' vuelve a ser columna normal y se crea un df bonito)
agrupado_bonito = df.groupby('tipo').size().reset_index(name='cantidad')
```

### 9. El Accesor de Texto (`.str.`)
En Python normal, si tienes una palabra usas `palabra.startswith('A')`. Pero en Pandas no puedes aplicarle comandos de texto directamente a toda una columna a la vez.
El accesor `.str.` funciona como un "puente". Le dice a Pandas: *"Trata toda esta columna temporalmente como si fueran strings de Python, para que yo pueda usar funciones de texto iterativamente en todos los registros de golpe"*.

```python
# Filtrar todos los clientes cuyo nombre empiece con "Alex"
df_alex = df[ df['nombre'].str.startswith('Alex') ]

# Convertir toda la columna a mayúsculas de un solo golpe
df['nombre_mayusculas'] = df['nombre'].str.upper()
```

### 10. La función `enumerate()`
Esta no es una función de Pandas, sino de Python nativo. Sirve para recorrer una lista y generar un **contador automático** al mismo tiempo. Es ideal para no tener que crear variables manuales como `contador = 0` antes de un ciclo.

```python
hojas = ['Enero', 'Febrero', 'Marzo']

# enumerate(lista, 1) significa: recorre la lista pero empieza a contar desde el 1
for numero, hoja in enumerate(hojas, 1):
    print(f"La hoja número {numero} se llama {hoja}")
    
# Salida:
# La hoja número 1 se llama Enero
# La hoja número 2 se llama Febrero
# La hoja número 3 se llama Marzo
```

### 11. ¿Qué hace `df.columns.tolist()[10:12]`?
Esta línea es una técnica muy útil que combina Pandas con los "recortes" (Slicing) de listas nativas de Python. Se divide en tres pasos lógicos:
1. **`df.columns`**: Extrae el objeto interno de Pandas que guarda los nombres de todas las columnas (este objeto es un "Índice", es rígido y difícil de manipular directamente).
2. **`.tolist()`**: Convierte ese objeto rígido en una simple lista de texto tradicional de Python (ej. `['id', 'nombre', 'edad', ...]`).
3. **`[10:12]` (Slicing / Rebanado)**: Esto es puro Python. Le indica a la computadora: *"Rebana esta lista y quédate únicamente con los elementos desde la posición 10 hasta la 12 (sin incluir la 12)"*. 
En programación el conteo empieza en 0, por lo que te estás robando exclusivamente los nombres de la **11ª y 12ª columna**.

```python
# Digamos que tienes un DataFrame inmenso con 15 columnas.
# En este caso, solo te interesa saber cómo se llaman las columnas 11 y 12.

tipocalificacion = df_consolidado.columns.tolist()[10:12]

# Resultado imaginario: 
# tipocalificacion = ['Calificacion_Matematicas', 'Calificacion_Historia']
```

### 12. La memoria del Cursor (`.fetchone()` vs `.fetchall()`)
Cuando ejecutas una consulta `SELECT` en MySQL usando Python (`cursor.execute(...)`), los resultados de la base de datos no se guardan automáticamente en tu variable. Se quedan "atorados" flotando en la memoria del cursor. Tienes que "pescarlos" (fetch):
* **`.fetchone()`**: Pesca **únicamente el primer registro** que encontró la base de datos y suelta el resto. Es súper rápido y eficiente cuando solo necesitas saber una cosa muy puntual (Ej. *"¿Ya existe este cliente sí o no?"* o *"Dame el ID que se acaba de crear"*).
* **`.fetchall()`**: Pesca **todos los registros de golpe** y los descarga a tu RAM como una enorme lista de Python para que puedas hacer un bucle `for` sobre ellos. 
  * **Dato vital:** Extraer los datos "limpia" la memoria del cursor. Si alguna vez ejecutas un `SELECT` pero se te olvida poner el `fetchone/fetchall`, MySQL te bloqueará el programa lanzando un error de *Unread results* (Resultados sin leer) cuando intentes hacer tu siguiente consulta.

```python
cursor.execute('SELECT nombre FROM Alumnos WHERE calificacion = 10')

# Si usamos fetchone() solo obtenemos al primer alumno que la base de datos escupa
primer_alumno = cursor.fetchone() 

# Si usamos fetchall() nos descarga la lista completa de todos los aplicados
todos_los_alumnos = cursor.fetchall()
```
