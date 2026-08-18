# Teoría — Unidad 4: Aprendizaje No Supervisado, K-Means y PCA

Esta guía continúa el orden de la Unidad 3. En la unidad anterior se estudió el **aprendizaje supervisado**, donde existe una respuesta conocida; ahora se estudia el **aprendizaje no supervisado**, donde el algoritmo debe encontrar estructura en datos que no tienen una etiqueta objetivo.

---

## Tabla de Contenidos

1. [Aprendizaje No Supervisado](#1-aprendizaje-no-supervisado)
2. [Las Dos Tareas de la Unidad](#2-las-dos-tareas-de-la-unidad)
3. [Agrupamiento y K-Means](#3-agrupamiento-y-k-means)
4. [Elementos Fundamentales de K-Means](#4-elementos-fundamentales-de-k-means)
5. [Funcionamiento Paso a Paso de K-Means](#5-funcionamiento-paso-a-paso-de-k-means)
6. [Distancia Euclidiana e Inercia](#6-distancia-euclidiana-e-inercia)
7. [Estandarización de las Características](#7-estandarización-de-las-características)
8. [Cómo Elegir el Número de Clústeres](#8-cómo-elegir-el-número-de-clústeres)
9. [Parámetros Importantes de K-Means](#9-parámetros-importantes-de-k-means)
10. [Interpretación de Clústeres y Centroides](#10-interpretación-de-clústeres-y-centroides)
11. [Ventajas, Limitaciones y Supuestos de K-Means](#11-ventajas-limitaciones-y-supuestos-de-k-means)
12. [Reducción de Dimensionalidad y PCA](#12-reducción-de-dimensionalidad-y-pca)
13. [La Proyección sobre una Nueva Diagonal](#13-la-proyección-sobre-una-nueva-diagonal)
14. [Funcionamiento Paso a Paso de PCA](#14-funcionamiento-paso-a-paso-de-pca)
15. [Varianza Explicada y Elección de Componentes](#15-varianza-explicada-y-elección-de-componentes)
16. [Relación entre K-Means y PCA](#16-relación-entre-k-means-y-pca)
17. [Casos Estudiados en los Apuntes](#17-casos-estudiados-en-los-apuntes)
18. [Errores Comunes](#18-errores-comunes)
19. [Preguntas de Repaso](#19-preguntas-de-repaso)
20. [Resumen y Fórmulas de Referencia](#20-resumen-y-fórmulas-de-referencia)

---

## 1. Aprendizaje No Supervisado

El **aprendizaje no supervisado** es una rama del aprendizaje automático que trabaja con datos **sin una respuesta o etiqueta objetivo conocida**.

En un problema supervisado se dispone de pares como:

$$X \rightarrow y$$

donde $X$ contiene las características y $y$ es la respuesta que el modelo debe aprender a predecir. En un problema no supervisado solo se dispone de:

$$X$$

El algoritmo analiza semejanzas, diferencias, relaciones y variaciones dentro de $X$ para descubrir una estructura que no fue indicada previamente.

### Comparación con la Unidad 3

| Aspecto | Aprendizaje supervisado | Aprendizaje no supervisado |
|---|---|---|
| Datos | Tienen una etiqueta o respuesta $y$ | No tienen una respuesta $y$ |
| Pregunta principal | «¿Qué valor o clase debo predecir?» | «¿Qué estructura existe en los datos?» |
| Resultado | Una predicción o clasificación | Grupos, representaciones o patrones |
| Tareas vistas | Regresión y clasificación | Agrupamiento y reducción de dimensionalidad |
| Algoritmos vistos | Regresión, K-NN | K-Means, PCA |
| Ejemplo | Predecir ventas o clasificar una especie | Segmentar clientes o representar cuatro variables en dos ejes |

> [!IMPORTANT]
> En aprendizaje no supervisado, la ausencia de una etiqueta no significa que los datos no tengan columnas descriptivas. Significa que **ninguna columna se entrega como la respuesta correcta que el modelo debe aprender**.

### ¿Descubrir significa que el resultado siempre es correcto?

No. El algoritmo encuentra una organización matemática de los datos, pero una persona debe decidir si esa organización tiene sentido en el problema real.

Por ejemplo, K-Means puede separar clientes por ingreso y gasto, pero los números `0`, `1` y `2` de los clústeres no explican por sí solos qué representa cada grupo. Es necesario observar sus centroides y describirlos como, por ejemplo, «ingreso bajo y gasto bajo».

---

## 2. Las Dos Tareas de la Unidad

De acuerdo con los apuntes, las dos tareas principales del aprendizaje no supervisado estudiadas en esta unidad son:

```text
Aprendizaje no supervisado
├── Agrupamiento
│     └── Algoritmo estudiado: K-Means
│
└── Reducción de dimensionalidad
      └── Algoritmo estudiado: PCA
```

### Tarea 1 — Agrupamiento

El **agrupamiento** o *clustering* busca dividir las observaciones en grupos de forma que:

- los elementos del mismo grupo sean lo más parecidos posible;
- los elementos de grupos diferentes sean lo más distintos posible;
- los grupos no hayan sido definidos previamente mediante una etiqueta.

Ejemplo: formar segmentos de clientes usando su ingreso anual y su puntuación de gasto.

### Tarea 2 — Reducción de dimensionalidad

La **reducción de dimensionalidad** transforma un conjunto con muchas variables en otro con menos variables, intentando conservar la mayor cantidad posible de información.

Ejemplo: transformar las cuatro mediciones de Iris en dos componentes principales para poder dibujar cada flor en una gráfica bidimensional.

| Tarea | Entrada | Salida | Pregunta que responde |
|---|---|---|---|
| Agrupamiento | $n$ observaciones y $p$ características | Una etiqueta de clúster para cada observación | «¿Qué observaciones se parecen?» |
| Reducción | $n$ observaciones y $p$ características | Las mismas observaciones en $q$ componentes, con $q < p$ | «¿Cómo represento la información con menos ejes?» |

> [!NOTE]
> Agrupar y reducir no son lo mismo. K-Means asigna un grupo; PCA crea nuevas coordenadas. Pueden utilizarse por separado o combinarse.

---

## 3. Agrupamiento y K-Means

**K-Means** es un algoritmo de agrupamiento que divide los datos en exactamente $K$ clústeres. Cada clúster está representado por su **centroide**, es decir, el promedio de las observaciones que pertenecen al grupo.

El nombre se interpreta de esta forma:

- **K**: cantidad de grupos que se desea formar.
- **Means**: medias o promedios usados como centros de los grupos.

### Idea intuitiva

Supóngase que cada cliente es un punto en un plano:

- eje horizontal: ingreso anual;
- eje vertical: puntuación de gasto.

K-Means coloca $K$ centros, mide qué centro queda más cerca de cada cliente, forma los grupos y mueve cada centro al promedio de su grupo. Este proceso se repite hasta que las asignaciones dejan de cambiar o los centroides casi no se mueven.

### Qué recibe y qué produce

**Recibe:**

- una matriz numérica $X$;
- el número de clústeres $K$;
- opciones para controlar la inicialización y reproducibilidad.

**Produce:**

- una etiqueta de clúster para cada fila;
- las coordenadas de los $K$ centroides;
- la inercia total del agrupamiento.

K-Means no produce nombres semánticos. Los valores `Cluster = 0`, `1` o `2` son identificadores arbitrarios, no categorías ordenadas.

---

## 4. Elementos Fundamentales de K-Means

### Observación

Es una fila del conjunto de datos. En el ejercicio de clientes, una observación representa a un cliente.

### Característica

Es una variable utilizada para comparar las observaciones. En el primer ejercicio:

- `Ingreso_Anual_kUSD`;
- `Puntuacion_Gasto`.

### Clúster

Es un conjunto de observaciones consideradas similares por el algoritmo.

### Centroide

Es el vector promedio de todas las observaciones de un clúster. Para un clúster $C_j$ con $|C_j|$ elementos:

$$\mu_j = \frac{1}{|C_j|}\sum_{x_i \in C_j}x_i$$

Si un clúster contiene puntos bidimensionales, su centroide también tiene dos coordenadas:

$$\mu_j = (\overline{x}_1, \overline{x}_2)$$

### Etiqueta de clúster

Es el identificador entero asignado por el modelo. No debe interpretarse como una calificación:

- `Cluster 0` no es necesariamente el peor;
- `Cluster 2` no es necesariamente mejor que `Cluster 1`;
- otra ejecución podría intercambiar los números sin cambiar el agrupamiento real.

### K

Es el número de clústeres. Se especifica antes de entrenar K-Means. Elegir un $K$ razonable es parte del análisis, no una respuesta que K-Means determine automáticamente.

---

## 5. Funcionamiento Paso a Paso de K-Means

K-Means utiliza un proceso iterativo:

1. **Elegir $K$:** decidir cuántos grupos se intentarán formar.
2. **Inicializar centroides:** colocar $K$ centros iniciales, normalmente mediante `k-means++`.
3. **Asignar observaciones:** calcular la distancia de cada punto a cada centroide y asignarlo al más cercano.
4. **Actualizar centroides:** calcular la media de los puntos de cada clúster.
5. **Repetir:** volver a asignar puntos y recalcular centroides.
6. **Converger:** detenerse cuando los centroides dejan de cambiar de forma significativa o se alcanza el máximo de iteraciones.

```text
Centroides iniciales
        ↓
Medir distancias
        ↓
Asignar cada punto al centro más cercano
        ↓
Recalcular la media de cada grupo
        ↓
¿Los centroides cambiaron?
   ├── Sí → repetir
   └── No → agrupamiento final
```

### Ejemplo conceptual de actualización

Si un clúster contiene los puntos:

$$A=(2,4), \quad B=(4,6), \quad C=(6,8)$$

su nuevo centroide es:

$$\mu=\left(\frac{2+4+6}{3},\frac{4+6+8}{3}\right)=(4,6)$$

### ¿Qué significa converger?

Significa que el proceso llegó a una configuración estable. Sin embargo, estable no siempre significa globalmente óptima: diferentes centroides iniciales pueden llevar a soluciones distintas. Por eso se realizan varias inicializaciones mediante `n_init`.

---

## 6. Distancia Euclidiana e Inercia

### Distancia euclidiana

K-Means utiliza normalmente la **distancia euclidiana**. Para dos puntos $x=(x_1,x_2,\ldots,x_p)$ y $\mu=(\mu_1,\mu_2,\ldots,\mu_p)$:

$$d(x,\mu)=\sqrt{\sum_{r=1}^{p}(x_r-\mu_r)^2}$$

En dos dimensiones:

$$d(x,\mu)=\sqrt{(x_1-\mu_1)^2+(x_2-\mu_2)^2}$$

Cada observación se asigna al centroide cuya distancia sea menor.

### Inercia o WCSS

La **inercia** mide la suma de las distancias cuadradas entre cada observación y el centroide de su clúster:

$$\text{WCSS}=\sum_{j=1}^{K}\sum_{x_i\in C_j}\lVert x_i-\mu_j\rVert^2$$

WCSS significa *Within-Cluster Sum of Squares* o suma de cuadrados dentro de los clústeres.

- inercia pequeña: los puntos están cerca de su centroide;
- inercia grande: los grupos son internamente más dispersos;
- en scikit-learn se consulta con `modelo_kmeans.inertia_`.

> [!WARNING]
> La inercia siempre disminuye o se mantiene al aumentar $K$. Si se crea un clúster para cada punto, la inercia llega a cero, pero el resultado no es útil. Por eso no se elige $K$ buscando solamente la menor inercia.

---

## 7. Estandarización de las Características

K-Means depende de distancias. Si una variable tiene valores mucho mayores que otra, dominará el cálculo aunque no sea más importante.

Ejemplo:

- ingreso anual: valores aproximados de 20 a 100;
- una variable adicional hipotética: valores de 0 a 1.

Una diferencia de 20 unidades en ingreso afectaría mucho más la distancia que cualquier diferencia posible en la segunda variable.

### Estandarización z-score

`StandardScaler` transforma cada valor mediante:

$$z=\frac{x-\mu}{\sigma}$$

donde:

- $x$: valor original;
- $\mu$: media de la característica;
- $\sigma$: desviación estándar;
- $z$: valor estandarizado.

Después de la transformación, cada característica queda con media cercana a 0 y desviación estándar cercana a 1.

> [!NOTE]
> En algunos apuntes se usa la palabra **normalización** para esta operación. El nombre técnico más preciso de `StandardScaler` es **estandarización**. `MinMaxScaler`, en cambio, reescala normalmente al intervalo de 0 a 1.

### Por qué también es importante para PCA

PCA busca direcciones de máxima varianza. Una variable medida con números muy grandes puede aparentar tener más varianza solamente por su unidad de medida. Estandarizar evita que una característica domine artificialmente tanto las distancias de K-Means como los componentes de PCA.

### Regla de transformación

- Para un análisis exploratorio como los notebooks de esta unidad, el escalador se ajusta al conjunto analizado.
- Si después llegan datos nuevos, se usa `escalador.transform(nuevos_datos)`, no otro `fit_transform`.
- En un proyecto con separación de entrenamiento y prueba, el escalador se ajusta solo con entrenamiento para evitar fuga de información.

---

## 8. Cómo Elegir el Número de Clústeres

Los apuntes emplean dos herramientas complementarias: el **método del codo** y el **coeficiente de silueta**.

### Método del codo

El procedimiento es:

1. entrenar K-Means con varios valores de $K$;
2. guardar la inercia de cada modelo;
3. graficar $K$ contra la inercia;
4. buscar el punto donde la reducción deja de ser tan pronunciada.

Ese cambio de pendiente se asemeja al codo de un brazo.

```text
Inercia
  alta | *
       |   *
       |     *  ← posible codo
       |        *  *  *
  baja +-----------------
          2  3  4  5  6     K
```

**Interpretación:** antes del codo, agregar clústeres mejora mucho la compactación; después del codo, la mejora adicional es pequeña.

El método puede ser ambiguo cuando la curva no presenta un cambio claro. Por eso debe complementarse con silueta y conocimiento del problema.

### Coeficiente de silueta

Para cada observación $i$ se consideran:

- $a(i)$: distancia media a los demás puntos de su propio clúster;
- $b(i)$: menor distancia media a los puntos de otro clúster.

La silueta individual es:

$$s(i)=\frac{b(i)-a(i)}{\max(a(i),b(i))}$$

Su rango es:

$$-1\le s(i)\le 1$$

| Valor aproximado | Interpretación |
|---|---|
| Cercano a 1 | El punto está bien integrado a su clúster y separado de otros |
| Cercano a 0 | El punto está cerca de una frontera |
| Menor que 0 | El punto podría estar asignado al clúster incorrecto |

`silhouette_score` devuelve el promedio de las siluetas de todas las observaciones. Entre opciones comparables, un valor mayor indica normalmente grupos más compactos y separados.

### Decisión conjunta

No existe una sola regla mecánica. Conviene elegir un $K$ que:

1. se encuentre cerca del codo;
2. tenga una silueta alta;
3. produzca grupos suficientemente grandes y estables;
4. pueda interpretarse en el contexto real.

En el dataset `puntuacion.csv`, $K=3$ es una elección muy clara: el codo aparece en 3 y la silueta aproximada es `0.793`, mayor que las demás opciones de 2 a 8.

En Iris aparece una diferencia importante:

- la silueta favorece $K=2$ con aproximadamente `0.580`;
- se puede elegir $K=3$ si el objetivo didáctico es buscar tres grupos y compararlos después con las tres especies;
- esto demuestra que el número de categorías conocidas no siempre coincide con la estructura geométrica más marcada.

---

## 9. Parámetros Importantes de K-Means

El modelo utilizado en los notebooks es:

```python
KMeans(n_clusters=3, random_state=42, n_init=10)
```

### `n_clusters`

Cantidad $K$ de grupos que formará el algoritmo.

### `random_state`

Fija la semilla aleatoria para obtener resultados reproducibles. Con el mismo conjunto, versión y configuración, permite repetir la misma inicialización.

### `n_init`

Indica cuántas veces se ejecutará K-Means con centroides iniciales diferentes. El algoritmo conserva la ejecución con menor inercia.

Usar `n_init=10` reduce el riesgo de conservar una mala solución causada por una inicialización poco favorable.

### `init`

Su valor habitual es `k-means++`. Esta estrategia distribuye de manera inteligente los centroides iniciales para mejorar la convergencia.

### `max_iter`

Número máximo de iteraciones permitidas en cada ejecución.

### Atributos y métodos principales

| Elemento | Resultado |
|---|---|
| `fit(X)` | Ajusta el modelo, pero no devuelve directamente las etiquetas |
| `fit_predict(X)` | Ajusta el modelo y devuelve las etiquetas |
| `predict(X_nuevo)` | Asigna datos nuevos al centroide aprendido más cercano |
| `labels_` | Etiquetas del conjunto usado en `fit` |
| `cluster_centers_` | Coordenadas de los centroides |
| `inertia_` | WCSS de la solución final |

---

## 10. Interpretación de Clústeres y Centroides

Una columna `Cluster` solo indica pertenencia. Para convertir el resultado en conocimiento se necesita **perfilar** cada grupo.

### Perfilado

Consiste en calcular para cada clúster:

- cantidad de observaciones;
- media o mediana de cada característica;
- valores mínimos y máximos;
- distribución de otras variables descriptivas.

Ejemplo conceptual:

| Clúster | Ingreso promedio | Gasto promedio | Interpretación posible |
|---|---:|---:|---|
| 0 | Bajo | Bajo | Clientes de consumo limitado |
| 1 | Alto | Alto | Clientes de alto valor |
| 2 | Bajo | Alto | Clientes muy activos pese a menor ingreso |

Los nombres deben asignarse **después** de observar los valores. No se deducen del identificador numérico.

### Centroides estandarizados y originales

Si K-Means se entrenó con datos estandarizados, `cluster_centers_` se encuentra en unidades z-score. Para interpretarlo en las unidades originales se aplica:

```python
centroides_originales = escalador.inverse_transform(
    modelo_kmeans.cluster_centers_
)
```

En el ejercicio de clientes, esto permite volver a leer los centroides en `kUSD` y puntos de gasto.

### Visualización

Con dos características se puede dibujar directamente:

- cada observación como un punto;
- el color como etiqueta de clúster;
- cada centroide como una `X`.

Con más de dos características no es posible mostrar toda la estructura en una sola gráfica 2D. Se puede:

- seleccionar dos variables concretas;
- crear varias gráficas;
- reducir a dos componentes con PCA.

---

## 11. Ventajas, Limitaciones y Supuestos de K-Means

### Ventajas

- Es fácil de comprender e implementar.
- Suele ser rápido en conjuntos medianos y grandes.
- Sus centroides ayudan a resumir y describir los grupos.
- Permite asignar nuevas observaciones a clústeres ya aprendidos.

### Limitaciones

- Es necesario indicar $K$ antes de entrenar.
- Es sensible a la escala de las variables.
- Es sensible a valores atípicos, porque los centroides son medias.
- Puede converger a una solución local diferente según la inicialización.
- Funciona mejor con grupos compactos, aproximadamente esféricos y de densidad semejante.
- Puede fallar con grupos alargados, anillos, formas irregulares o densidades muy distintas.
- Solo trabaja directamente con características numéricas.

### Supuesto geométrico

K-Means crea regiones alrededor de centroides según distancia euclidiana. Por ello tiende a dividir el espacio mediante fronteras rectas y a encontrar agrupaciones semejantes a «nubes» alrededor de un centro.

### Efecto de valores atípicos

Un punto muy lejano puede arrastrar el promedio de su clúster. Antes de aplicar K-Means conviene revisar:

- valores nulos;
- duplicados;
- errores de captura;
- valores atípicos;
- escalas incompatibles.

Esto conecta directamente con la limpieza de datos estudiada en las Unidades 1 y 2.

---

## 12. Reducción de Dimensionalidad y PCA

Una **dimensión** corresponde a una característica utilizada para representar una observación.

- dos características → puntos en un plano;
- tres características → puntos en un espacio tridimensional;
- cuatro o más características → espacio de alta dimensionalidad que ya no puede visualizarse directamente.

**PCA** significa *Principal Component Analysis* o **Análisis de Componentes Principales**. Es un algoritmo no supervisado de reducción de dimensionalidad.

PCA construye nuevas variables llamadas **componentes principales**:

- son combinaciones lineales de las variables originales;
- son perpendiculares entre sí;
- se ordenan de mayor a menor varianza explicada;
- permiten conservar la mayor información posible con menos dimensiones.

### Qué cambia y qué se conserva

PCA no elimina filas ni crea grupos. Conserva las mismas observaciones, pero cambia el sistema de coordenadas.

```text
Antes:  X1, X2, X3, X4
             ↓ PCA
Después: CP1, CP2
```

Las nuevas columnas `CP1` y `CP2` no son variables originales. Cada una mezcla información de varias características.

### Usos principales

- visualizar datos de muchas dimensiones en 2D o 3D;
- comprimir información;
- eliminar redundancia entre variables correlacionadas;
- reducir ruido;
- acelerar otros algoritmos;
- facilitar la exploración antes o después de un agrupamiento.

---

## 13. La Proyección sobre una Nueva Diagonal

La idea anotada en clase puede expresarse así:

> PCA proyecta los puntos sobre nuevos ejes; en un plano $X$-$Y$, uno de esos ejes puede verse como una diagonal. Se debe analizar cuál diagonal conviene.

### ¿Por qué una diagonal?

Imagine una nube de puntos alargada desde la esquina inferior izquierda hasta la esquina superior derecha. Los ejes originales $X$ y $Y$ no siguen la dirección principal de la nube. Una diagonal sí puede recorrerla longitudinalmente.

```text
Y
↑                 •
|             •  •
|         •  •
|     •  •          /  ← nueva dirección CP1
|  •              /
+------------------------→ X
```

Proyectar un punto significa trazarlo sobre el nuevo eje y guardar su posición a lo largo de ese eje.

### ¿Qué diagonal conviene?

PCA elige como primer componente la dirección que:

1. captura la **mayor varianza** de los datos proyectados;
2. mantiene los puntos lo más separados posible sobre el nuevo eje;
3. equivale a minimizar el error cuadrático de reconstrucción al representar los datos con una sola dimensión.

Una diagonal con poca varianza amontonaría las proyecciones y perdería más información. Por eso no se elige visualmente al azar: PCA la calcula.

### Primer y segundo componente

- **CP1:** dirección con la mayor varianza posible.
- **CP2:** dirección perpendicular a CP1 con la mayor varianza restante.
- **CP3:** dirección perpendicular a las anteriores con la siguiente mayor varianza.

Cada componente captura información que no fue capturada por los componentes anteriores.

> [!IMPORTANT]
> El signo de un componente puede invertirse sin cambiar su significado matemático. Una implementación puede mostrar una diagonal apuntando en un sentido y otra en el contrario; ambas describen el mismo eje.

---

## 14. Funcionamiento Paso a Paso de PCA

### Paso 1 — Seleccionar características numéricas

Se forma una matriz $X$ de $n$ observaciones por $p$ variables. No deben incluirse identificadores como `Id` ni etiquetas como `Species`.

### Paso 2 — Centrar o estandarizar

PCA requiere centrar las variables. Cuando sus escalas son diferentes, normalmente se estandarizan:

$$z=\frac{x-\mu}{\sigma}$$

### Paso 3 — Calcular relaciones entre variables

Se construye una matriz de covarianza sobre los datos centrados. Esta matriz expresa cuánto varían conjuntamente las características.

### Paso 4 — Obtener direcciones y magnitudes

Se calculan:

- **eigenvectores o vectores propios:** direcciones de los componentes;
- **eigenvalores o valores propios:** cantidad de varianza capturada por esas direcciones.

### Paso 5 — Ordenar los componentes

Los componentes se ordenan del eigenvalor mayor al menor. El primero explica más varianza que el segundo, y así sucesivamente.

### Paso 6 — Proyectar los datos

Si $W_q$ contiene las direcciones de los primeros $q$ componentes, la nueva representación es:

$$Z=X_{centrado}W_q$$

donde:

- $X_{centrado}$: datos centrados o estandarizados;
- $W_q$: matriz con los componentes elegidos;
- $Z$: coordenadas de cada observación en el nuevo espacio.

### Combinación lineal

Para cuatro variables estandarizadas, CP1 tiene una forma como:

$$CP1=w_1z_1+w_2z_2+w_3z_3+w_4z_4$$

Los pesos $w$ se llaman **cargas** o *loadings*. Un peso de gran magnitud indica que esa característica participa fuertemente en el componente.

---

## 15. Varianza Explicada y Elección de Componentes

### Varianza explicada

La proporción explicada por el componente $j$ es:

$$\text{Proporción}_j=\frac{\lambda_j}{\sum_{r=1}^{p}\lambda_r}$$

donde $\lambda_j$ es el eigenvalor del componente.

En scikit-learn se consulta con:

```python
pca.explained_variance_ratio_
```

### Varianza acumulada

La varianza acumulada de los primeros $q$ componentes es:

$$\text{Varianza acumulada}_q=\sum_{j=1}^{q}\text{Proporción}_j$$

Ejemplo:

| Componente | Varianza individual | Varianza acumulada |
|---|---:|---:|
| CP1 | 72.77 % | 72.77 % |
| CP2 | 23.03 % | 95.80 % |
| CP3 | 3.68 % | 99.48 % |
| CP4 | 0.52 % | 100.00 % |

Estos son los valores aproximados obtenidos al estandarizar las cuatro mediciones de `iris.csv`.

### ¿Cuántos componentes conservar?

Se puede elegir:

- el mínimo número que alcance un umbral, como 90 % o 95 %;
- dos componentes cuando la prioridad es una visualización 2D;
- tres componentes para una visualización 3D;
- una cantidad validada según el rendimiento del proceso posterior.

En Iris, dos componentes conservan aproximadamente **95.80 %** de la varianza total. Por ello, pasar de cuatro variables a dos mantiene gran parte de la información y permite visualizar los datos.

> [!WARNING]
> Conservar mucha varianza no garantiza conservar toda la información relevante para cualquier tarea. PCA prioriza variación, no necesariamente separación de clases ni significado de negocio.

### Reconstrucción y pérdida

Si se conservan todos los componentes, el cambio es esencialmente una rotación de coordenadas y no se pierde información. La reducción ocurre cuando se descartan componentes de baja varianza. A cambio de una representación más simple, se acepta una pérdida controlada.

---

## 16. Relación entre K-Means y PCA

K-Means y PCA resuelven problemas diferentes:

| Característica | K-Means | PCA |
|---|---|---|
| Tarea | Agrupamiento | Reducción de dimensionalidad |
| Resultado | Etiquetas de clúster | Nuevas coordenadas o componentes |
| Elemento central | Distancia a centroides | Direcciones de máxima varianza |
| Hiperparámetro principal | Número de clústeres $K$ | Número de componentes $q$ |
| Evaluación vista | Inercia y silueta | Varianza explicada |
| Requiere escala comparable | Sí, normalmente | Sí, normalmente |

### Formas de combinarlos

**Opción A — Agrupar con todas las variables y usar PCA para visualizar**

1. estandarizar las características;
2. ajustar K-Means con todas las variables;
3. transformar esas mismas variables a dos componentes;
4. dibujar los componentes usando el clúster como color.

Esta opción conserva toda la información para el agrupamiento y usa PCA solamente como vista 2D.

**Opción B — Reducir primero y agrupar después**

1. estandarizar;
2. ajustar PCA y conservar varios componentes;
3. aplicar K-Means a esos componentes.

Puede reducir ruido y costo computacional, pero el resultado depende de cuánta información se haya conservado.

> [!NOTE]
> Si PCA se usa solo para dibujar, K-Means puede seguir entrenándose con todas las variables. No es obligatorio entrenarlo solamente con dos componentes.

---

## 17. Casos Estudiados en los Apuntes

### Ejercicio 1 — Segmentación de clientes

Archivo: `Apuntes/Ejercicio-1/puntuacion.csv`.

Características:

- `Ingreso_Anual_kUSD`;
- `Puntuacion_Gasto`.

El notebook estandariza las dos columnas y entrena K-Means con $K=3$. Con `random_state=42` y `n_init=10` se obtienen tres grupos de 50 clientes cada uno.

Centroides aproximados en unidades originales:

| Clúster | Ingreso anual (kUSD) | Puntuación de gasto | Interpretación |
|---:|---:|---:|---|
| 0 | 28.87 | 20.09 | Ingreso bajo, gasto bajo |
| 1 | 79.69 | 80.67 | Ingreso alto, gasto alto |
| 2 | 30.76 | 74.89 | Ingreso bajo, gasto alto |

Los números de clúster pueden cambiar entre configuraciones; lo importante son sus perfiles.

Resultados aproximados para elegir $K$:

| K | Inercia | Silueta |
|---:|---:|---:|
| 2 | 112.316 | 0.604 |
| 3 | 16.002 | **0.793** |
| 4 | 12.413 | 0.660 |
| 5 | 10.603 | 0.524 |
| 6 | 9.236 | 0.519 |
| 7 | 7.930 | 0.363 |
| 8 | 6.701 | 0.376 |

### Ejercicio 2 — Agrupamiento de Iris

Archivo: `Apuntes/Ejercicio-2/iris.csv`.

Características utilizadas:

- `SepalLengthCm`;
- `SepalWidthCm`;
- `PetalLengthCm`;
- `PetalWidthCm`.

No se usan como características:

- `Id`, porque solo identifica la fila;
- `Species`, porque es una etiqueta conocida y K-Means debe agrupar sin verla.

Con $K=3$, los tamaños obtenidos son aproximadamente 53, 50 y 47 observaciones. La especie `Iris-setosa` se separa con claridad, mientras que `Iris-versicolor` e `Iris-virginica` presentan solapamiento.

Esto no convierte K-Means en un clasificador. `Species` puede utilizarse **después** para comparar e interpretar el resultado, pero no se proporciona durante el agrupamiento.

### PCA aplicado a Iris

Al estandarizar las cuatro mediciones:

- CP1 explica aproximadamente 72.77 %;
- CP2 explica aproximadamente 23.03 %;
- juntas explican aproximadamente 95.80 %.

Esto convierte cuatro dimensiones en dos con una pérdida de varianza aproximada de solo 4.20 %.

---

## 18. Errores Comunes

### Confundir K-Means con K-NN

| K-Means | K-NN |
|---|---|
| No supervisado | Supervisado |
| Agrupa datos sin etiqueta | Clasifica usando etiquetas conocidas |
| `K` = número de clústeres | `k` = número de vecinos |
| Aprende centroides | Conserva ejemplos de entrenamiento |

### Incluir `Id` en el modelo

Un identificador no describe la flor. Si se incluye, las filas cercanas por número podrían parecer artificialmente similares.

### Incluir `Species` durante el agrupamiento

K-Means requiere datos numéricos y, además, usar la especie rompería el objetivo no supervisado. La etiqueta solo debe utilizarse después para comprobar o interpretar.

### No estandarizar

Las variables de mayor escala dominan la distancia y la varianza.

### Interpretar los números de clúster como orden

Las etiquetas son arbitrarias. Siempre deben interpretarse mediante centroides o estadísticas agrupadas.

### Elegir $K$ solo porque coincide con categorías conocidas

En un análisis genuinamente no supervisado, esas categorías pueden no existir o no coincidir con la geometría de los datos.

### Elegir $K$ por la menor inercia

La inercia disminuye al aumentar $K$. Deben observarse el codo, la silueta y el sentido práctico.

### Ajustar otra vez el escalador para datos nuevos

Los nuevos datos deben transformarse con el escalador ya ajustado. De lo contrario, quedarían en otro sistema de coordenadas.

### Graficar centroides con columnas incorrectas

Si K-Means se ajustó con cuatro variables y la gráfica usa `PetalLengthCm` y `PetalWidthCm`, los centroides deben tomar las posiciones 2 y 3:

```python
centroides_originales[:, 2]  # PetalLengthCm
centroides_originales[:, 3]  # PetalWidthCm
```

### Pensar que CP1 es una variable original

CP1 es una combinación lineal. No representa exclusivamente largo de pétalo, ancho de sépalo ni otra columna individual.

### Pensar que PCA selecciona columnas

PCA normalmente **construye** nuevas variables. No se limita a escoger dos columnas originales.

### Aplicar `fit_transform` por separado a cada conjunto

Esto crea sistemas de coordenadas diferentes. Se ajustan el escalador y PCA una sola vez sobre los datos de referencia; después se aplica `transform`.

---

## 19. Preguntas de Repaso

### Conceptuales

1. ¿Qué diferencia existe entre aprendizaje supervisado y no supervisado?
2. ¿Cuáles son las dos tareas no supervisadas vistas en la unidad?
3. ¿Qué problema resuelve K-Means?
4. ¿Qué problema resuelve PCA?
5. ¿Qué representa un centroide?
6. ¿Por qué `Cluster 2` no significa que sea mejor que `Cluster 1`?
7. ¿Por qué K-Means necesita que se indique $K$?
8. ¿Por qué se estandarizan los datos?
9. ¿Qué mide la inercia?
10. ¿Qué significa una silueta cercana a 1, 0 o -1?
11. ¿Por qué la inercia no basta para elegir $K$?
12. ¿Qué significa proyectar datos sobre una nueva diagonal?
13. ¿Qué criterio usa PCA para elegir CP1?
14. ¿Qué significa que dos componentes expliquen 95.8 % de la varianza?
15. ¿Cuál es la diferencia entre cargas y coordenadas transformadas?

### Aplicadas a los notebooks

1. ¿Por qué `puntuacion.csv` utiliza solamente dos características?
2. ¿Por qué no se usa `Species` para entrenar K-Means con Iris?
3. ¿Por qué tampoco debe utilizarse `Id`?
4. ¿Qué hace `fit_predict`?
5. ¿Qué almacena `cluster_centers_`?
6. ¿Por qué se aplica `inverse_transform` a los centroides?
7. ¿Qué hacen `random_state=42` y `n_init=10`?
8. ¿Por qué el rango de silueta comienza en $K=2$?
9. ¿Qué columnas de un centroide de Iris corresponden al largo y ancho del pétalo?
10. ¿Cómo se usaría PCA para visualizar los clústeres de Iris?

### Respuestas breves de comprobación

1. No supervisado no dispone de una respuesta $y$ durante el ajuste.
2. Las tareas son agrupamiento y reducción de dimensionalidad.
3. K-Means asigna cada punto al centroide más cercano y actualiza los centroides mediante medias.
4. PCA elige CP1 por máxima varianza y los siguientes componentes por máxima varianza restante, manteniendo perpendicularidad.
5. En Iris, `Id` no describe la flor y `Species` es la etiqueta que no debe ver el algoritmo.
6. La silueta necesita al menos dos clústeres para comparar el grupo propio con otro grupo.
7. Para pétalo se usan las columnas 2 y 3 de `centroides_originales`.

---

## 20. Resumen y Fórmulas de Referencia

### Mapa mental

```text
APRENDIZAJE NO SUPERVISADO
│
├── AGRUPAMIENTO
│   └── K-Means
│       ├── elegir K
│       ├── estandarizar
│       ├── asignar al centroide más cercano
│       ├── actualizar centroides
│       └── evaluar con codo y silueta
│
└── REDUCCIÓN DE DIMENSIONALIDAD
    └── PCA
        ├── estandarizar
        ├── encontrar nuevas direcciones
        ├── ordenar por varianza explicada
        └── proyectar sobre los componentes elegidos
```

### Distancia euclidiana

$$d(x,\mu)=\sqrt{\sum_{r=1}^{p}(x_r-\mu_r)^2}$$

### Centroide

$$\mu_j=\frac{1}{|C_j|}\sum_{x_i\in C_j}x_i$$

### Inercia

$$\text{WCSS}=\sum_{j=1}^{K}\sum_{x_i\in C_j}\lVert x_i-\mu_j\rVert^2$$

### Silueta

$$s(i)=\frac{b(i)-a(i)}{\max(a(i),b(i))}$$

### Estandarización

$$z=\frac{x-\mu}{\sigma}$$

### Proyección PCA

$$Z=X_{centrado}W_q$$

### Varianza explicada

$$\text{Proporción}_j=\frac{\lambda_j}{\sum_{r=1}^{p}\lambda_r}$$

### Regla final para recordar

> **K-Means responde «¿qué puntos pertenecen juntos?»; PCA responde «¿sobre qué nuevos ejes puedo representar la mayor información con menos dimensiones?».**
