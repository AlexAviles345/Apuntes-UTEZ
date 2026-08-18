# Teoría — Unidad 1: JavaScript de Básico a Intermedio

Esta guía presenta los conceptos de JavaScript estudiados en la Unidad 1, con ejemplos enfocados en comprender el funcionamiento de cada construcción. No incluye frameworks ni temas posteriores.

---

## Tabla de Contenidos

1. [Panorama de la Unidad](#1-panorama-de-la-unidad)
2. [JavaScript, Motores y Paradigmas](#2-javascript-motores-y-paradigmas)
3. [ECMAScript](#3-ecmascript)
4. [Variables, Declaraciones, Alcance y Tipado](#4-variables-declaraciones-alcance-y-tipado)
5. [Template Literals e Interpolación](#5-template-literals-e-interpolación)
6. [Truthy, Falsy y Coerción](#6-truthy-falsy-y-coerción)
7. [Funciones Tradicionales y Funciones Flecha](#7-funciones-tradicionales-y-funciones-flecha)
8. [El Contexto this](#8-el-contexto-this)
9. [arguments, Parámetros Rest y Valores por Defecto](#9-arguments-parámetros-rest-y-valores-por-defecto)
10. [Destructuración](#10-destructuración)
11. [Operador Spread](#11-operador-spread)
12. [Callbacks](#12-callbacks)
13. [Promesas y Handlers](#13-promesas-y-handlers)
14. [Ejecución Asíncrona, async y await](#14-ejecución-asíncrona-async-y-await)
15. [Tareas, Microtareas y Macrotareas](#15-tareas-microtareas-y-macrotareas)
16. [DOM y Eventos en el Panel de Lavadora](#16-dom-y-eventos-en-el-panel-de-lavadora)
17. [Diferencias que Debes Memorizar](#17-diferencias-que-debes-memorizar)
18. [Preguntas de Repaso](#18-preguntas-de-repaso)

---

## 1. Panorama de la Unidad

El objetivo de la unidad es reforzar conocimientos de JavaScript y preparar el camino para la programación y mantenimiento de *Voice Skills*.

Los temas desarrollados son:

```text
JavaScript y ECMAScript
│
├── Variables, alcance y tipado flexible
├── Template literals e interpolación
├── Truthy, falsy, coerción y operadores
├── Funciones tradicionales, flecha y contexto this
├── Destructuración, rest y spread
├── Callbacks
├── Promesas, handlers, async y await
├── Tareas, microtareas y macrotareas
└── DOM y eventos mediante el panel de lavadora
```

Clases, módulos, JSON y los métodos `map`, `filter` y `forEach` aparecen como elementos incorporados o estandarizados por ECMAScript. En esta unidad se utilizan directamente JSON mediante `JSON.stringify` y `map`; los demás se presentan como parte del contexto histórico.

---

## 2. JavaScript, Motores y Paradigmas

### ¿Qué es JavaScript?

JavaScript es un lenguaje de programación:

- **interpretado**;
- **multiparadigma**;
- orientado principalmente al desarrollo web;
- ejecutable en navegadores y también en servidores mediante entornos como Node.js.

JavaScript permite:

- manipular páginas web dinámicamente;
- responder a eventos del usuario;
- consumir APIs;
- crear aplicaciones frontend y backend.

### Lenguaje interpretado

El código es leído y ejecutado por un **motor de JavaScript**. En las notas se mencionan dos motores conocidos:

- **V8**;
- **JavaScriptCore**.

El motor entiende las reglas de ECMAScript y se encarga de ejecutar instrucciones como declaraciones, operaciones, funciones y promesas.

### Lenguaje multiparadigma

JavaScript permite organizar el código con distintos estilos:

- programación procedimental;
- programación orientada a objetos;
- programación funcional;
- programación basada en eventos.

Los ejercicios muestran esta combinación: funciones y arreglos representan el lado funcional/procedimental; objetos con métodos usan ideas orientadas a objetos; los botones con `onclick` emplean programación basada en eventos.

---

## 3. ECMAScript

### JavaScript frente a ECMAScript

**ECMAScript** es el estándar que define las reglas del lenguaje. Puede compararse con una receta:

- ECMAScript es la receta;
- JavaScript es el platillo construido siguiendo esa receta;
- los motores aplican esas reglas para que el código se comporte de forma consistente.

ECMAScript define, entre otras cosas mencionadas en las diapositivas:

- sintaxis;
- tipos de datos;
- declaración de funciones;
- manejo de clases;
- promesas;
- módulos.

### Versiones mencionadas

| Versión | Elementos principales estudiados |
|---|---|
| ES5 (2009) | JSON, *strict mode*, `map`, `filter` y `forEach` |
| ES6 / ECMAScript 2015 | `let`, `const`, funciones flecha, clases, módulos, promesas, template literals, destructuración y spread |
| ECMAScript 2020 / ES11 | Operador de coalescencia nula `??` |

### Strict mode

Es un modo que **define reglas más estrictas** para ejecutar JavaScript. Se estudia como parte de ES5, sin profundizar en una implementación específica de su directiva.

---

## 4. Variables, Declaraciones, Alcance y Tipado

### `var`

`var` era la forma principal de declarar variables antes de ES6.

```javascript
console.log(nombre); // undefined
var nombre = 'Fulano';
```

La declaración de `nombre` se procesa antes de ejecutar esa línea. Este comportamiento se estudia como **hoisting**. La asignación `'Fulano'` permanece en su lugar, por lo que antes de ella el valor es `undefined`.

`var` tiene alcance de función o global, no alcance de bloque. Esa menor precisión es la razón por la que se recomienda `let`.

### `let`

`let` declara una variable con alcance de bloque:

```javascript
let nombre = 'Sutano';
console.log(nombre);
```

Solo puede utilizarse dentro del bloque en el que se declaró. Aunque su declaración participa en el procesamiento previo del alcance, no puede accederse a ella antes de la línea de declaración.

### `const`

`const` se usa para valores y referencias que no serán reasignados:

```javascript
const numNivelLavado = 5;
const usuario = { name: 'Alexandro' };
```

`const` también tiene alcance de bloque. Impide asignar otra vez la variable completa, pero un objeto almacenado en ella puede conservar propiedades modificables.

### Cuándo se usa cada una en los ejercicios

| Declaración | Uso observado |
|---|---|
| `const` | Funciones, arreglos, objetos, configuraciones y referencias que no se sustituyen |
| `let` | Posiciones y estados que cambian, como `lavadoPosicion` |
| `var` | Ejemplo teórico para explicar hoisting |

### Alcance

El **alcance** determina desde qué parte del programa puede usarse una variable.

```javascript
if (true) {
    let mensaje = 'Solo existe dentro del bloque';
}
```

Los bloques se delimitan con llaves. Funciones, condicionales y ciclos generan distintos contextos de alcance.

### Tipado flexible

JavaScript permite almacenar tipos distintos en una misma variable en momentos diferentes:

```javascript
let valor = undefined;
valor = { username: 'Coker', active: true };
valor = 10;
valor = '¡Hola mundo!';
valor = '2026' === '2026';
```

La secuencia produce, respectivamente, un valor indefinido, un objeto, un número, una cadena y un booleano. Hacerlo es posible, aunque cambiar de tipo sin necesidad reduce la claridad.

---

## 5. Template Literals e Interpolación

Los **template literals** son cadenas delimitadas con acentos invertidos:

```javascript
const nombre = 'Coker';
const saludo = `Hola ${nombre}`;
```

### Interpolación

La sintaxis `${...}` evalúa lo que se encuentra dentro e inserta su resultado en la cadena.

Puede contener:

- variables;
- operaciones;
- comparaciones;
- expresiones ternarias;
- llamadas a funciones.

Ejemplo tomado del tema:

```javascript
const edad = 23;
const validacion = `Actualmente eres: ${edad >= 18 ? 'Mayor' : 'Menor'} de edad`;
```

La expresión `edad >= 18` es verdadera, por lo que el ternario elige `'Mayor'`.

### Concatenación frente a interpolación

```javascript
const texto1 = 'Nombre: ' + nombre + ' Edad: ' + edad;
const texto2 = `Nombre: ${nombre} Edad: ${edad}`;
```

Ambas construyen una cadena; la segunda resulta más directa. Las notas señalan que todo valor interpolado se representa como texto dentro del resultado final.

> [!NOTE]
> Interpolar un objeto directamente suele producir la cadena `[object Object]`. `JSON.stringify` permite mostrar sus propiedades como texto JSON.

---

## 6. Truthy, Falsy y Coerción

### Contexto booleano

En `if`, `while` y operadores lógicos, JavaScript puede evaluar valores que no son literalmente `true` o `false`.

- Un valor **truthy** se comporta como verdadero.
- Un valor **falsy** se comporta como falso.

### Valores falsy mostrados

```text
false
0
-0
0n
''  ""  ``
null
undefined
NaN
```

### Valores truthy mostrados

```text
true
1 y otros números distintos de cero
-1 y otros números negativos distintos de cero
[]
{}
'xd'
'false'
Infinity
funciones
```

> [!IMPORTANT]
> La cadena `'false'` es truthy porque contiene caracteres. Un arreglo vacío y un objeto vacío también son truthy. El número `0`, en cambio, es falsy; una nota de clase que dice que `0` se interpreta como truthy no coincide con el comportamiento de JavaScript.

### Coerción

La **coerción** es la conversión o interpretación automática de valores según el contexto.

### Operador AND `&&`

Evalúa de izquierda a derecha:

- devuelve el primer valor falsy;
- si ninguno es falsy, devuelve el último valor truthy.

```javascript
1 && 'Hola' && true; // true
0 && 'Hola';         // 0
```

### Operador OR `||`

Devuelve el primer valor truthy. Si ninguno lo es, devuelve el último valor.

```javascript
const valor = 0 || 100; // 100, porque 0 es falsy
```

### Coalescencia nula `??`

Usa el valor de la derecha solamente cuando el de la izquierda es `null` o `undefined`.

```javascript
const valor = 0 ?? 100; // 0
```

| Izquierda | `izquierda || 100` | `izquierda ?? 100` |
|---|---:|---:|
| `0` | `100` | `0` |
| `''` | `100` | `''` |
| `false` | `100` | `false` |
| `null` | `100` | `100` |
| `undefined` | `100` | `100` |

### Doble negación `!!`

Convierte cualquier valor a un booleano real:

```javascript
!!'Hola'; // true
!!0;      // false
```

El primer `!` niega el valor ya interpretado como booleano; el segundo vuelve a negarlo y conserva su significado original en forma de `true` o `false`.

### Comparación flexible y estricta

```javascript
100 == '100';  // true: permite coerción
100 === '100'; // false: compara valor y tipo
```

Se recomienda usar `===` y `!==` para evitar resultados inesperados por coerción.

---

## 7. Funciones Tradicionales y Funciones Flecha

### Función tradicional por declaración

```javascript
function sumarTodos() {
    // cuerpo
}
```

Se reconoce por la palabra `function` y un nombre. Las declaraciones tradicionales pueden llamarse incluso desde código colocado antes de su definición debido al hoisting de la declaración.

### Función tradicional como expresión

```javascript
const saludar = function () {
    console.log('Hola');
};
```

La función se crea como valor y se guarda en una variable. No debe usarse antes de que esa asignación haya sido ejecutada.

### Función flecha

```javascript
const saludar = () => {
    console.log('Hola');
};
```

Si solo devuelve una expresión, puede abreviarse:

```javascript
const formarId = (id, numero) => `${id}${numero}`;
```

### Diferencias vistas

| Característica | Tradicional | Flecha |
|---|---|---|
| Sintaxis | `function` | `=>` |
| Declaración con nombre | Sí | No; se guarda como expresión |
| Expresión en variable | Sí | Sí |
| `this` propio según llamada | Sí | No; usa el contexto exterior |
| Objeto `arguments` | Sí | No |
| Uso como constructor | Sí | No |
| `prototype` | Puede tenerlo | No se usa como función constructora |
| Uso destacado | Métodos de objetos y constructores | Callbacks y funciones sin contexto propio |
| Parámetros por defecto | Sí | Sí |

---

## 8. El Contexto this

`this` representa el contexto con el que se ejecuta una función tradicional. Puede comprenderse mediante la pregunta: **«¿quién me llama?»**

### Método tradicional de un objeto

```javascript
const usuario = {
    name: 'Alexandro',
    saludar: function () {
        console.log(`Hola ${this.name}`);
    }
};

usuario.saludar();
```

La llamada tiene la forma `usuario.saludar()`, por lo que `this` es `usuario` y `this.name` vale `'Alexandro'`.

### Función flecha como método

```javascript
const usuario = {
    name: 'Alexandro',
    saludar: () => console.log(`Hola ${this.name}`)
};
```

La flecha no crea su propio `this`; toma el del entorno exterior. No recibe automáticamente a `usuario` como contexto, por eso el ejercicio no obtiene `name`.

### Función tradicional interna

```javascript
const contador = {
    valor: 0,
    incrementar: function () {
        function segunda() {
            this.valor++;
        }
        segunda();
    }
};
```

Aunque `incrementar` fue llamado mediante `contador`, `segunda()` se invoca como función independiente. Su `this` no es automáticamente `contador`, de modo que no incrementa `contador.valor`.

### Flecha interna

Una flecha interna reutiliza el `this` de `incrementar`:

```javascript
const contador = {
    valor: 0,
    incrementar: function () {
        const segunda = () => {
            this.valor++;
        };
        segunda();
    }
};
```

### Guardar el contexto

Otra estrategia consiste en guardar el contexto:

```javascript
const contexto = this;
```

Una función interna puede usar `contexto` aunque su propio `this` sea diferente.

### `bind`

`bind` crea una función ligada permanentemente a un contexto:

```javascript
function incrementarInterno() {
    this.valor++;
}

const ligada = incrementarInterno.bind(this);
ligada();
```

También puede ligarse inmediatamente al crear la función:

```javascript
const incrementarInterno = function () {
    this.valor++;
}.bind(this);
```

---

## 9. arguments, Parámetros Rest y Valores por Defecto

### `arguments`

Las funciones tradicionales disponen de un objeto local llamado `arguments` con todos los argumentos recibidos:

```javascript
function sumarTodos() {
    let suma = 0;

    for (let i = 0; i < arguments.length; i++) {
        suma += arguments[i];
    }

    return suma;
}
```

- `arguments.length` indica cuántos argumentos llegaron.
- `arguments[i]` accede a uno por posición.
- No se declara como parámetro.
- No está disponible de forma propia en funciones flecha.

### Parámetro rest

Rest reúne una cantidad variable de argumentos en un arreglo:

```javascript
const sumarTodos = (...argumentos) => {
    let suma = 0;

    for (let i = 0; i < argumentos.length; i++) {
        suma += argumentos[i];
    }

    return suma;
};
```

Aunque rest y spread usan `...`, hacen operaciones opuestas:

- rest **reúne** valores recibidos;
- spread **expande** valores existentes.

### Valores por defecto

```javascript
function validarEdad(edad = 0) {
    // edad será 0 si el argumento no fue proporcionado
}
```

También aparecen en destructuración:

```javascript
const datos = ['Alexandro'];
const [nombre, edad = 23] = datos;
```

El valor por defecto se usa cuando el valor obtenido es `undefined`.

---

## 10. Destructuración

La destructuración extrae valores de arreglos u objetos y los guarda en variables.

### Arreglos por posición

```javascript
const arreglo = [10, 20, 30];
const [a, b, c] = arreglo;
```

El orden determina la asignación: `a=10`, `b=20`, `c=30`.

### Saltar elementos

```javascript
const colores = ['rojo', 'verde', 'azul', 'amarillo'];
const [rojo, , azul] = colores;
```

La coma vacía omite `'verde'`.

### Valor por defecto

```javascript
const datos = ['Alexandro'];
const [nombre, edad = 23] = datos;
```

### Intercambiar variables

```javascript
let x = 5;
let y = 10;
[x, y] = [y, x];
```

### Objetos por nombre de propiedad

```javascript
const usuario = { nombre: 'Alexandro', edad: 23, pais: 'Mexico' };
const { nombre, edad } = usuario;
```

En objetos no importa la posición, sino el nombre de la propiedad.

### Renombrar

```javascript
const { email: correo } = usuario;
```

La propiedad se llama `email`, pero la variable creada se llama `correo`.

### Destructuración anidada

```javascript
const usuario = {
    pais: 'México',
    direccion: { municipio: 'Xochitepec', cp: '62790' }
};

const {
    pais,
    direccion: { municipio, cp }
} = usuario;
```

### Arreglo dentro de un objeto

También se pueden extraer posiciones específicas:

```javascript
const { roles: [rol1, , rol2] } = usuario;
```

---

## 11. Operador Spread

Spread expande arreglos, objetos, cadenas u otros iterables mediante `...`.

### Copiar un arreglo

```javascript
const copia = [...arreglo];
```

Se crea otro arreglo; no es la misma referencia externa.

### Unir arreglos

```javascript
const unidos = [...a, ...b];
```

### Agregar al inicio o al final

```javascript
const final = [...frutas, 'mango'];
const inicio = ['kiwi', ...frutas];
```

### Expandir al llamar o imprimir

```javascript
console.log(...arreglo);
```

Cada elemento se entrega como un argumento separado.

### Copiar y combinar objetos

```javascript
const copia = { ...producto };
const venta = { ...producto, ...usuario };
```

Si dos objetos tienen la misma propiedad, gana el valor expandido al final:

```javascript
const producto = { nombre: 'Laptop', precio: 15000 };
const usuario = { nombre: 'Ana', edad: 20 };
const venta = { ...producto, ...usuario };

// venta.nombre es 'Ana'
```

Las copias con spread son superficiales: el operador copia el nivel visible de arreglos y objetos, no implementa una copia profunda.

---

## 12. Callbacks

Un **callback** es una función pasada como argumento a otra función para que esta la ejecute en algún momento.

```javascript
function resolverRespuesta(respuesta, callback) {
    callback(respuesta.message);
}
```

Usos mencionados:

- finalizar una petición a servidor;
- detectar un clic;
- terminar un temporizador;
- procesar una lista.

### Callback con una función flecha

```javascript
resolverRespuesta(respuesta, texto => {
    console.log(`El resultado fue ${texto}`);
});
```

### Métodos de arreglo mencionados

| Método | Papel del callback |
|---|---|
| `map` | Ejecuta el callback por cada elemento y construye un arreglo con los resultados |
| `filter` | Conserva los elementos para los que el callback produce un valor truthy |
| `forEach` | Ejecuta el callback por cada elemento sin construir un nuevo arreglo de resultados |

`map` puede convertir cada ID en una promesa de descarga.

---

## 13. Promesas y Handlers

Una **Promise** representa un resultado que puede estar disponible en el futuro.

### Estados

| Estado | Significado |
|---|---|
| `pending` | La operación sigue pendiente |
| `fulfilled` / `resolved` | Terminó correctamente |
| `rejected` | Terminó con rechazo o error |

### Estructura

```javascript
const promesa = new Promise((resolve, reject) => {
    const condicion = true;

    if (condicion) {
        resolve('Promesa resuelta');
    } else {
        reject('Promesa rechazada');
    }
});
```

La función entregada a `new Promise` se llama **executor**. Recibe:

- `resolve(valor)`: cumple la promesa con un valor;
- `reject(error)`: rechaza la promesa con una razón.

Una promesa solo queda resuelta o rechazada una vez. Los argumentos posteriores no cambian su estado.

### Handlers `.then` y `.catch`

Los handlers reaccionan al resultado:

```javascript
promesa
    .then(resultado => {
        console.log(resultado);
    })
    .catch(error => {
        console.log(error);
    });
```

- `.then` atiende un cumplimiento;
- `.catch` atiende un rechazo;
- cada handler devuelve otra promesa, por lo que pueden encadenarse.

### Encadenamiento

El ejemplo encadena tres transformaciones:

```text
número → multiplicar por 2 → sumar 10 → dividir entre 2 → resultado
```

El valor retornado por un `.then` llega al siguiente `.then`.

### `Promise.all`

`Promise.all` recibe un arreglo de promesas y devuelve una promesa:

- se cumple cuando todas se cumplen;
- entrega un arreglo de resultados en el mismo orden de entrada;
- normalmente se rechaza si cualquiera se rechaza.

En los ejercicios, cada promesa individual agrega:

```javascript
promesa.catch(error => error);
```

Ese handler convierte su rechazo en un valor cumplido. Así `Promise.all` puede recopilar tanto resultados exitosos como mensajes de error.

---

## 14. Ejecución Asíncrona, async y await

La ejecución asíncrona permite iniciar una operación que tardará y continuar el flujo mientras se completa.

### `async`

Marca una función como asíncrona:

```javascript
const iniciar = async () => {
    // instrucciones asíncronas
};
```

Una función `async` siempre produce una promesa como resultado.

### `await`

Espera el resultado de una promesa dentro del flujo de una función asíncrona:

```javascript
const resultado = await validarEdad(18);
```

La espera pausa esa función, no bloquea permanentemente todo el entorno de JavaScript.

### Manejar rechazo con `catch`

```javascript
const resultado = await validarEdad(12).catch(error => error);
```

El `catch` devuelve el error como un valor normal; por eso la asignación puede continuar.

### `setTimeout`

Programa un callback para ejecutarse después de un tiempo mínimo en milisegundos:

```javascript
setTimeout(() => {
    resolve('Promesa resuelta');
}, 3000);
```

No detiene el programa durante tres segundos. Registra el callback y permite que el flujo continúe.

### `fetch` y `response.json`

Las diapositivas muestran este patrón para una solicitud:

```javascript
fetch('url', config)
    .then(response => response.json())
    .then(result => {
        // usar resultado
    })
    .catch(error => {
        // manejar error
    });
```

- `fetch` inicia la petición y devuelve una promesa;
- `response.json()` obtiene el cuerpo interpretado como JSON y también devuelve una promesa;
- los handlers procesan cada resultado en orden.

---

## 15. Tareas, Microtareas y Macrotareas

El tema aparece en el temario y se observa mediante promesas, handlers, temporizadores y eventos.

### Flujo esencial

1. JavaScript ejecuta primero el código síncrono actual.
2. Los handlers de promesas pendientes se programan como **microtareas** cuando la promesa se resuelve.
3. Los callbacks de temporizadores y eventos se atienden como tareas o **macrotareas**.
4. Al terminar la tarea actual, se vacían las microtareas disponibles antes de tomar la siguiente macrotarea.

```text
Código síncrono actual
        ↓
Microtareas listas (promesas: then/catch/continuación de await)
        ↓
Siguiente macrotarea (setTimeout, evento de botón, etc.)
```

Esto explica por qué `setTimeout` no congela la aplicación y por qué una promesa puede entregar su resultado después.

---

## 16. DOM y Eventos en el Panel de Lavadora

El ejemplo del panel de lavadora conecta HTML y JavaScript.

### Elementos HTML usados

- `<input type="checkbox">`: representa una opción seleccionable;
- `<label for="...">`: describe un control mediante su ID;
- `<button onclick="...">`: ejecuta una función al hacer clic;
- `<div id="estado-texto">`: contiene el estado visible;
- `<script src="codigo.js">`: carga código JavaScript externo.

### `document.getElementById`

Busca el elemento cuyo atributo `id` coincide exactamente:

```javascript
const estado = document.getElementById('estado-texto');
```

Devuelve el elemento o `null` si no existe.

### Propiedad `checked`

Controla si un checkbox está seleccionado:

```javascript
elemento.checked = true;
elemento.checked = false;
```

### Propiedad `textContent`

Lee o reemplaza el contenido textual:

```javascript
estado.textContent = 'Lavando';
```

### Eventos `onclick`

```html
<button onclick="iniciarLavado();">Lavar</button>
```

Cuando el usuario hace clic, el navegador invoca `iniciarLavado`.

### Función autoejecutable

El script termina con:

```javascript
(() => {
    // configuración inicial
})();
```

La primera pareja de paréntesis crea una función flecha; la segunda `()` la ejecuta inmediatamente. Inicializa los primeros checkboxes y coloca el estado en «Pausada».

---

## 17. Diferencias que Debes Memorizar

### `var`, `let` y `const`

| | `var` | `let` | `const` |
|---|---|---|---|
| Alcance principal | Función/global | Bloque | Bloque |
| Reasignación | Sí | Sí | No para la referencia |
| Uso estudiado | Ejemplo de hoisting | Estado cambiante | Valores, funciones y objetos |

### `||` frente a `??`

- `||` usa la derecha ante cualquier falsy.
- `??` usa la derecha solo ante `null` o `undefined`.

### Tradicional frente a flecha

- Tradicional: su `this` depende de cómo se llama y tiene `arguments`.
- Flecha: hereda `this` y usa rest si necesita argumentos variables.

### Rest frente a spread

- `(...argumentos)` reúne.
- `[...arreglo]` o `{...objeto}` expande.

### Callback frente a promesa

- Callback: función entregada para ejecutarse posteriormente.
- Promesa: objeto que representa un resultado futuro y se atiende con handlers o `await`.

### `.then` frente a `await`

Ambos consumen promesas. `.then` registra un callback; `await` permite escribir la espera dentro de una función `async` con un flujo más lineal.

---

## 18. Preguntas de Repaso

1. ¿Qué significa que JavaScript sea interpretado y multiparadigma?
2. ¿Qué relación existe entre ECMAScript, JavaScript y un motor?
3. ¿Qué elementos se atribuyen a ES5, ES6 y ES11?
4. ¿Qué diferencia de alcance existe entre `var` y `let`?
5. ¿Por qué acceder a una variable `var` antes de su asignación puede producir `undefined`?
6. ¿Qué delimitador usa un template literal?
7. ¿Qué evalúa `${...}`?
8. Menciona todos los valores falsy estudiados.
9. ¿Por qué `'false'`, `[]` y `{}` son truthy?
10. ¿Qué devuelve `&&` y qué devuelve `||`?
11. ¿Cuándo difieren `0 || 100` y `0 ?? 100`?
12. ¿Qué hace `!!valor`?
13. ¿Qué diferencia existe entre `==` y `===`?
14. ¿Por qué una flecha usada directamente como método no obtiene el objeto como `this`?
15. ¿Por qué una función tradicional interna pierde el contexto del método exterior?
16. ¿Qué hacen guardar `this` y utilizar `bind(this)`?
17. ¿Qué diferencia existe entre `arguments` y un parámetro rest?
18. ¿Cómo se omite una posición al destructurar un arreglo?
19. ¿Qué objeto gana si dos spreads contienen la misma propiedad?
20. ¿Qué es un callback?
21. ¿Cuáles son los tres estados de una promesa?
22. ¿Qué hacen `resolve`, `reject`, `.then` y `.catch`?
23. ¿Cuándo se resuelve y cuándo se rechaza `Promise.all`?
24. ¿Qué diferencia existe entre `async` y `await`?
25. ¿Por qué `setTimeout` no detiene todo el programa?
26. ¿Qué busca `document.getElementById`?
27. ¿Qué controlan `checked` y `textContent`?
28. ¿Qué inicializa la función autoejecutable del panel?
