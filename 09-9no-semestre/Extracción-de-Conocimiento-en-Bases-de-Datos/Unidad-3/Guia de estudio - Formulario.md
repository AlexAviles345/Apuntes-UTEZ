# 📝 Formulario de Funciones Python (Unidad 3: Aprendizaje Supervisado)

*Formulario de referencia rápida enfocado estrictamente en las funciones y métodos de Python utilizados en la Unidad 3.*

---

### 📦 Instalación y Configuración

**Comandos de Instalación:**
* **Usando PIP:** `pip install pandas numpy scikit-learn`
* **Usando Conda:** `conda install pandas numpy scikit-learn`

**Importaciones Requeridas:**
```python
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import PolynomialFeatures, StandardScaler
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import mean_squared_error, r2_score, accuracy_score, confusion_matrix, classification_report
```

---

### 🐼 1. Pandas
> **Nota:** Primero se tiene que importar la librería: `import pandas as pd`

* **Leer un archivo CSV:** 
  `df = pd.read_csv(filepath)`
  * *Ruta del archivo (cadena de texto):* `filepath`
* **Acceder a un grupo de filas y columnas:** 
  `df.loc[filas, columnas]`
  * *Rango de filas a extraer:* `filas`
  * *Lista de columnas a extraer:* `columnas`
* **Convertir el tipo de dato de una columna:** 
  `df['col'].astype(dtype)`
  * *Tipo de dato deseado (ej. 'category' para texto):* `dtype`
* **Obtener códigos numéricos de categorías:** 
  `df['col'].cat.codes`
* **Obtener nombres originales de categorías:** 
  `df['col'].cat.categories`

---

### 🧮 2. Numpy
> **Nota:** Primero se tiene que importar la librería: `import numpy as np`

* **Calcular la raíz cuadrada (usado para RMSE):** 
  `np.sqrt(array)`
  * *Arreglo o número a calcular:* `array`

---

### 🧪 3. Scikit-Learn: Selección de Modelos (`sklearn.model_selection`)

* **Dividir datos en entrenamiento y prueba:** 
  `x_train, x_test, y_train, y_test = train_test_split(*arrays, test_size, random_state, stratify)`
  * *Datos a dividir (normalmente x e y):* `*arrays`
  * *Proporción reservada para pruebas (ej. 0.2):* `test_size`
  * *Semilla aleatoria para reproducibilidad:* `random_state`
  * *Mantiene proporción original de clases:* `stratify=y`

---

### 📈 4. Scikit-Learn: Modelos Lineales (`sklearn.linear_model`)

* **Inicializar el modelo de regresión lineal:** 
  `modelo = LinearRegression()`
* **Entrenar el modelo (Aprender):** 
  `modelo.fit(X, y)`
  * *Características (datos independientes de entrenamiento):* `X`
  * *Etiquetas (datos objetivo/reales):* `y`
* **Realizar predicciones:** 
  `predicciones = modelo.predict(X)`
  * *Datos a evaluar/predecir:* `X`
* **Obtener los coeficientes (pendientes):** 
  `modelo.coef_`
* **Obtener el intercepto con el eje Y:** 
  `modelo.intercept_`

---

### 🛠️ 5. Scikit-Learn: Preprocesamiento (`sklearn.preprocessing`)

**Polinomios:**
* **Crear transformador de características polinomiales:** 
  `poly = PolynomialFeatures(degree)`
  * *Grado del polinomio (ej. 2):* `degree`
* **Calcular estadísticas y transformar (Solo Entrenamiento):** 
  `poly.fit_transform(X)`
* **Transformar sin recalcular estadísticas (Solo Prueba):** 
  `poly.transform(X)`

**Estandarización (Normalización Z-score):**
* **Inicializar escalador para estandarizar variables:** 
  `scaler = StandardScaler()`
* **Calcular la media/varianza y escalar (Solo Entrenamiento):** 
  `scaler.fit_transform(X)`
* **Escalar utilizando la media/varianza calculada (Solo Prueba):** 
  `scaler.transform(X)`

---

### 🏷️ 6. Scikit-Learn: Clasificadores (`sklearn.neighbors`)

* **Inicializar clasificador K-NN:** 
  `knn = KNeighborsClassifier(n_neighbors)`
  * *Número de vecinos (k) a consultar:* `n_neighbors`
* **Entrenar el clasificador:** 
  `knn.fit(X, y)`
* **Predecir clases:** 
  `knn.predict(X)`

---

### 📏 7. Scikit-Learn: Métricas de Evaluación (`sklearn.metrics`)

* **Calcular Error Cuadrático Medio (MSE):** 
  `mean_squared_error(y_true, y_pred)`
  * *Valores reales de prueba:* `y_true`
  * *Valores predichos por el modelo:* `y_pred`
* **Calcular Coeficiente de Determinación (R²):** 
  `r2_score(y_true, y_pred)`
* **Calcular precisión de la clasificación (Accuracy):** 
  `accuracy_score(y_true, y_pred)`
* **Obtener Matriz de Confusión (Errores y aciertos por clase):** 
  `confusion_matrix(y_true, y_pred)`
* **Generar reporte completo de clasificación:** 
  `classification_report(y_true, y_pred, target_names)`
  * *Nombres legibles de las clases (opcional):* `target_names`
