# Práctica — Unidad 1: Funciones, Destructuración, Promesas y DOM

Esta guía aplica paso a paso los conceptos de la Unidad 1. Los ejemplos están diseñados como bloques independientes, por lo que deben ejecutarse por separado cuando reutilicen nombres declarados con `const` o `let`.

---

## Tabla de Contenidos

1. [Cómo Practicar los Ejemplos](#1-cómo-practicar-los-ejemplos)
2. [Práctica 1 — Funciones y Contexto this](#2-práctica-1--funciones-y-contexto-this)
3. [Práctica 2 — Destructuración y Spread](#3-práctica-2--destructuración-y-spread)
4. [Práctica 3 — Promesas, async-await y Handlers](#4-práctica-3--promesas-async-await-y-handlers)
5. [Práctica 4 — Panel de Lavadora y DOM](#5-práctica-4--panel-de-lavadora-y-dom)
6. [Referencia de Todas las Funciones y Métodos Vistos](#6-referencia-de-todas-las-funciones-y-métodos-vistos)
7. [Aclaraciones Importantes](#7-aclaraciones-importantes)
8. [Ejercicios de Repaso](#8-ejercicios-de-repaso)

---

## 1. Cómo Practicar los Ejemplos

### JavaScript asociado con HTML

Los dos HTML cargan JavaScript al final del `body`:

```html
<script src="./codigo.js"></script>
```

o:

```html
<script src="codigo.js"></script>
```

Al estar al final, los elementos HTML ya fueron interpretados cuando comienza el script. Esto permite que el panel busque sus checkboxes y el texto de estado.

### Ejemplos que deben probarse por separado

Varios ejemplos reutilizan identificadores como `usuario` y `sumarTodos`. JavaScript no permite declarar dos veces un mismo `const` o `let` dentro del mismo alcance.

Por eso, para practicarlos:

1. copie un solo ejercicio a la consola del navegador;
2. ejecútelo y revise su salida;
3. limpie o recargue la consola antes del siguiente;
4. no mezcle bloques que declaren los mismos identificadores.

---

## 2. Práctica 1 — Funciones y Contexto this

### Ejercicio 1 — Método tradicional

```javascript
const usuario = {
    name: 'Alexandro',
    saludar: function () {
        console.log(`Hola ${this.name}!!!`);
    }
};

usuario.saludar();
```

#### Funcionamiento

1. `usuario` almacena un objeto.
2. `name` es una propiedad de datos.
3. `saludar` es una propiedad cuyo valor es una función tradicional; por eso se considera un método.
4. La llamada se realiza como `usuario.saludar()`.
5. El objeto colocado antes del punto es el contexto de la llamada.
6. `this` apunta a `usuario` y `this.name` obtiene `'Alexandro'`.

Salida:

```text
Hola Alexandro!!!
```

### Ejercicio 2 — Flecha como propiedad

```javascript
const usuario = {
    name: 'Alexandro',
    saludar: () => {
        console.log(`Hola ${this.name}!!!`);
    }
};

usuario.saludar();
```

#### Funcionamiento

La flecha no recibe un `this` propio al invocarse. Busca `this` en el contexto donde fue creada, no en el objeto situado antes del punto. Por eso no recupera `usuario.name`.

La nota muestra:

```text
Hola !!!
```

El detalle exacto puede variar según el entorno: `this.name` puede ser `undefined` o incluso provocar un error si `this` también lo es. La conclusión que debe estudiarse es que **la flecha no toma a `usuario` como contexto**.

### Ejercicio 3 — Función tradicional interna

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

contador.incrementar();
console.log(contador.valor);
```

#### Funcionamiento

- En `contador.incrementar()`, `this` dentro de `incrementar` sí es `contador`.
- `segunda()` es una nueva función tradicional.
- Se llama sin objeto antes del punto.
- Por ello, su `this` no se hereda de `incrementar`.
- `contador.valor` permanece en `0`.

#### Formas de conservar el contexto

Flecha interna que hereda el contexto exterior:

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

Guardar el contexto:

```javascript
const contador = {
    valor: 0,
    incrementar: function () {
        const contexto = this;

        function segunda() {
            contexto.valor++;
        }

        segunda();
    }
};
```

Ligar la función con `bind`:

```javascript
const contador = {
    valor: 0,
    incrementar: function () {
        const segunda = function () {
            this.valor++;
        }.bind(this);

        segunda();
    }
};
```

### Ejercicio 4 — Sumar con `arguments`

```javascript
function sumarTodos() {
    let suma = 0;

    for (let i = 0; i < arguments.length; i++) {
        suma += arguments[i];
    }

    return suma;
}

sumarTodos(2, 4, 1, 6, 3); // 16
```

#### Funcionamiento

- No hay parámetros declarados, pero la función tradicional recibe cinco argumentos.
- `arguments.length` vale `5`.
- El ciclo recorre las posiciones de `0` a `4`.
- `arguments[i]` obtiene cada número.
- `return suma` entrega `16` al lugar de la llamada.

`suma` e `i` se declaran con `let` para que pertenezcan al alcance de la función y del ciclo.

### Ejercicio 5 — Sumar con rest

```javascript
const sumarTodos = (...argumentos) => {
    let suma = 0;

    for (let i = 0; i < argumentos.length; i++) {
        suma += argumentos[i];
    }

    return suma;
};

sumarTodos(2, 4, 1, 6, 3); // 16
```

`...argumentos` reúne todos los valores en un arreglo real. Esto sustituye a `arguments` porque las flechas no tienen un objeto `arguments` propio.

---

## 3. Práctica 2 — Destructuración y Spread

### Ejercicio 1 — Destructurar todas las posiciones

```javascript
const arreglo = [10, 20, 30];
const [a, b, c] = arreglo;
```

| Variable | Posición | Valor |
|---|---:|---:|
| `a` | 0 | 10 |
| `b` | 1 | 20 |
| `c` | 2 | 30 |

### Ejercicio 2 — Saltar una posición

```javascript
const colores = ['rojo', 'verde', 'azul', 'amarillo'];
const [rojo, , azul] = colores;
```

La coma sin variable avanza una posición. Se obtienen `'rojo'` y `'azul'`.

### Ejercicio 3 — Valor por defecto

```javascript
const datos = ['Alexandro'];
const [nombre, edad = 23] = datos;
```

La posición 1 no existe, por lo que su valor es `undefined`. Entonces se utiliza el valor por defecto `23`.

### Ejercicio 4 — Intercambio

```javascript
let x = 5;
let y = 10;
[x, y] = [y, x];
```

La derecha se evalúa primero como `[10, 5]`; después se asigna `10` a `x` y `5` a `y`.

### Ejercicio 5 — Propiedades de un objeto

```javascript
const usuario = {
    nombre: 'Alexandro',
    edad: 23,
    pais: 'Mexico'
};

const { nombre, edad } = usuario;
```

Los nombres dentro de las llaves buscan propiedades con esos mismos nombres.

### Ejercicio 6 — Propiedades anidadas

Para representar correctamente una dirección anidada se utiliza esta estructura:

```javascript
const usuario = {
    nombre: 'Alexandro',
    edad: 23,
    pais: 'Mexico',
    direccion: {
        municipio: 'Xochitepec',
        cp: '62790'
    }
};

const {
    pais,
    direccion: { municipio, cp }
} = usuario;
```

Si `municipio` y `cp` estuvieran directamente en `usuario`, se usaría `const { pais, municipio, cp }`. Esa forma no debe confundirse con la destructuración anidada de `direccion`.

### Ejercicio 7 — Copia de arreglo

```javascript
const arreglo2 = [...arreglo];
```

Spread toma cada elemento de `arreglo` y lo coloca en un arreglo nuevo.

### Ejercicio 8 — Unir y ordenar

```javascript
const grupoA = [-11, 20, 3, 45, 5, 6];
const grupoB = [10, 8, 9];
const arregloNuevo = [...grupoA, ...grupoB];
const resultado = arregloNuevo.sort((a, b) => a - b);
```

#### `sort` y su callback

`sort` modifica el arreglo y usa el resultado del callback para comparar pares:

- `a - b < 0`: `a` va antes;
- `a - b > 0`: `b` va antes;
- `a - b === 0`: se consideran equivalentes para el orden.

Resultado real:

```javascript
[-11, 3, 5, 6, 8, 9, 10, 20, 45]
```

El resultado correcto es el arreglo ordenado mostrado arriba.

### Ejercicio 9 — Combinar objetos

```javascript
const producto = {
    nombre: 'Laptop',
    precio: 15000
};

const comprador = {
    nombre: 'Ana',
    edad: 20
};

const venta = {
    ...producto,
    ...comprador
};
```

Resultado conceptual:

```javascript
const venta = {
    nombre: 'Ana',
    precio: 15000,
    edad: 20
};
```

Ambos objetos tienen `nombre`. Como `comprador` se expande al final, `'Ana'` sobrescribe `'Laptop'`.

Para ver el objeto se usa:

```javascript
console.log(venta);
```

Interpolarlo como `${venta}` no muestra sus propiedades; normalmente genera `[object Object]`.

### Ejercicio 10 — Agregar sin modificar el original

```javascript
const frutas = ['manzana', 'pera', 'uva'];
const copiaFinal = [...frutas, 'mango'];
const copiaInicio = ['kiwi', ...frutas];
```

| Arreglo | Contenido |
|---|---|
| `frutas` | manzana, pera, uva |
| `copiaFinal` | manzana, pera, uva, mango |
| `copiaInicio` | kiwi, manzana, pera, uva |

---

## 4. Práctica 3 — Promesas, async-await y Handlers

### Ejercicio 1 — Validar edad

```javascript
const validarEdad = edad => new Promise((resolve, reject) => {
    if (edad >= 18) {
        resolve({ resuelta: true, message: 'Eres mayor de edad' });
    } else {
        reject({ resuelta: true, message: 'Eres menor de edad' });
    }
});

const resultadoEdad = await validarEdad(18);
```

#### Flujo

1. Se llama `validarEdad(18)`.
2. Se construye una promesa.
3. El executor recibe `resolve` y `reject`.
4. `18 >= 18` es verdadero.
5. `resolve` cumple la promesa con un objeto.
6. `await` obtiene ese objeto.
7. `resultadoEdad.message` vale `'Eres mayor de edad'`.

En la rama de rechazo conviene que una propiedad destinada a indicar éxito tenga un valor distinto de la rama resuelta. La razón del rechazo también puede representarse mediante un objeto.

Para atender ambas rutas vistas en clase:

```javascript
const resultadoEdad = await validarEdad(16).catch(error => error);
```

### Ejercicio 2 — Validar número par

```javascript
const validarNumero = numero => new Promise((resolve, reject) => {
    if (numero % 2 === 0) {
        resolve(`Resuelta, el numero ${numero} es par`);
    } else {
        reject(`No resuelta, el numero ${numero} es impar`);
    }
});
```

`numero % 2` calcula el residuo de dividir entre 2. Un residuo estricto igual a cero indica un número par.

### Ejercicio 3 — Resolver después de un tiempo

```javascript
const funcionResolverTiempo = tiempo => new Promise((resolve, reject) => {
    console.log('Resolviendo funcion...');

    setTimeout(() => {
        resolve('Promesa resuelta');
    }, tiempo);
});

const resultado = await funcionResolverTiempo(3000);
```

#### Flujo temporal

```text
imprime "Resolviendo funcion..."
        ↓
programa el callback para después de 3000 ms
        ↓
al ejecutarse el callback, llama resolve
        ↓
await continúa y obtiene "Promesa resuelta"
```

Un `try/catch` que rodea la llamada a `setTimeout` no captura un error que ocurra posteriormente dentro del callback. En este ejemplo el callback solo llama `resolve`, por lo que la promesa se cumple normalmente.

### Ejercicio 4 — Simular descarga

```javascript
const descargar = id => new Promise((resolve, reject) => {
    console.log('Validando descarga...');

    setTimeout(() => {
        if (id === 1) {
            resolve({ id: 1, nombre: 'Alexandro' });
        } else {
            reject('Descarga inválida');
        }
    }, 2000);
});
```

- `id === 1` cumple con un objeto.
- Cualquier otro ID rechaza con una cadena.
- La decisión se toma cuando se ejecuta el callback del temporizador.

Para convertir el objeto en texto JSON:

```javascript
JSON.stringify({ id: 1, nombre: 'Alexandro' });
// '{"id":1,"nombre":"Alexandro"}'
```

### Ejercicio 5 — Varias solicitudes con `map` y `Promise.all`

```javascript
const descargasIds = [2, 3, 1, 4];

const promesas = descargasIds.map(id =>
    descargar(id).catch(error => error)
);

const resultadosDescargas = await Promise.all(promesas);
```

#### `map`

Ejecuta el callback una vez por cada ID y construye un arreglo nuevo:

```text
2 → promesa de descargar(2)
3 → promesa de descargar(3)
1 → promesa de descargar(1)
4 → promesa de descargar(4)
```

#### `catch(error => error)`

Si una descarga se rechaza, el handler devuelve el error como resultado normal. Sin estos `catch`, `Promise.all` se rechazaría al encontrar la primera promesa rechazada.

#### `Promise.all`

Espera todas las promesas y conserva el orden de `descargasIds`, aunque no necesariamente terminen en ese orden.

Resultado conceptual:

```javascript
[
    'Descarga inválida',
    'Descarga inválida',
    { id: 1, nombre: 'Alexandro' },
    'Descarga inválida'
]
```

### Ejercicio 6 — Encadenar handlers

```javascript
const multiplicarPorDos = numero => {
    return new Promise(resolve => {
        numero *= 2;
        resolve(numero);
    })
    .then(resultado => {
        return new Promise(resolve => {
            resultado += 10;
            resolve(resultado);
        });
    })
    .then(resultado => {
        return new Promise(resolve => {
            resultado /= 2;
            resolve(resultado);
        });
    });
};

const resultado = await multiplicarPorDos(2); // 7
```

Seguimiento del valor:

| Etapa | Operación | Resultado |
|---|---:|---:|
| Inicio | `2` | 2 |
| Primera promesa | `2 * 2` | 4 |
| Primer `.then` | `4 + 10` | 14 |
| Segundo `.then` | `14 / 2` | 7 |

Cada `.then` recibe el valor con el que se resolvió la promesa anterior. El `return` conserva la cadena para que el `await` final espere todo el proceso.

---

## 5. Práctica 4 — Panel de Lavadora y DOM

### Estructura HTML utilizada

| Elemento o atributo | Función dentro del panel |
|---|---|
| `<table>` | Agrupa las opciones en una tabla |
| `<tr>` | Crea una fila |
| `<td>` | Crea una celda |
| `<input type="checkbox">` | Crea cada opción marcable |
| `<label for="id">` | Asocia un texto con el checkbox cuyo ID coincide |
| `<button type="button">` | Crea un botón que no envía formularios |
| `id="..."` | Proporciona el identificador que JavaScript busca |
| `onclick="funcion();"` | Ejecuta el handler al hacer clic |
| `<strong>` | Resalta la palabra «Estado» |
| `<div>` | Contiene el texto cambiante del estado |
| `<br>` | Inserta un salto visual |
| `<script src="codigo.js">` | Carga y ejecuta JavaScript externo |

### Estado del programa

```javascript
const numNivelLavado = 5;
const numNivelTemperatura = 3;
const numNivelVelocidad = 3;

const nombreNivelLavado = 'tl-cbox';
const nombreNivelTemperatura = 'ta-cbox';
const nombreNivelVelocidad = 'vc-cbox';

let lavadoPosicion = 1;
let temperaturaPosicion = 1;
let velocidadPosicion = 1;
```

- Las constantes `numNivel...` son los límites.
- Las constantes `nombreNivel...` son prefijos de IDs.
- Las variables `...Posicion` guardan la opción actual y cambian con cada clic.

### `formarId(id, numero)`

```javascript
const formarId = (id, numero) => {
    return `${id}${numero}`;
};
```

Concatena el prefijo y la posición mediante interpolación:

```javascript
formarId('tl-cbox', 1); // 'tl-cbox1'
formarId('ta-cbox', 3); // 'ta-cbox3'
```

### `cambiarLavado()`

```javascript
const cambiarLavado = () => {
    document.getElementById(
        formarId(nombreNivelLavado, lavadoPosicion)
    ).checked = false;

    if (lavadoPosicion >= numNivelLavado) {
        lavadoPosicion = 1;
    } else {
        lavadoPosicion += 1;
    }

    const nuevoId = formarId(nombreNivelLavado, lavadoPosicion);
    document.getElementById(nuevoId).checked = true;
};
```

#### Flujo

1. Forma el ID de la opción actual.
2. Busca ese checkbox.
3. Lo desmarca con `checked = false`.
4. Si estaba en el último nivel, vuelve a 1.
5. Si no, incrementa la posición.
6. Forma el nuevo ID.
7. Busca el checkbox siguiente y lo marca.

Secuencia: `1 → 2 → 3 → 4 → 5 → 1`.

### `cambiarTemperatura()`

Repite el mismo algoritmo con:

- prefijo `ta-cbox`;
- límite `3`;
- estado `temperaturaPosicion`.

Secuencia: `1 → 2 → 3 → 1`.

### `cambiarVelocidad()`

Repite el algoritmo con:

- prefijo `vc-cbox`;
- límite `3`;
- estado `velocidadPosicion`.

### `ponerEstadoLavadora(texto)`

```javascript
const ponerEstadoLavadora = texto => {
    const estado = document.getElementById('estado-texto');

    if (estado) {
        estado.textContent = texto;
    }
};
```

#### Funcionamiento

- Busca el elemento `estado-texto`.
- Si existe, el objeto es truthy y entra al `if`.
- Cambia su texto visible.
- La validación evita intentar usar `textContent` sobre `null`.

### `iniciarLavado()` y `pausarLavado()`

```javascript
const iniciarLavado = () => {
    ponerEstadoLavadora('Lavando');
};

const pausarLavado = () => {
    ponerEstadoLavadora('Pausada');
};
```

Estas funciones reutilizan `ponerEstadoLavadora`; cada una decide solamente qué texto enviar.

### Función autoejecutable de inicialización

```javascript
(() => {
    document.getElementById('tl-cbox1').checked = true;
    document.getElementById('ta-cbox1').checked = true;
    document.getElementById('vc-cbox1').checked = true;
    ponerEstadoLavadora('Pausada');
})();
```

Se ejecuta en cuanto se carga el script. Deja seleccionada la primera opción de cada grupo y establece el estado inicial.

### Conexión de botones

```html
<button onclick="cambiarLavado();">Cambiar tipo de lavado</button>
<button onclick="iniciarLavado();">Lavar</button>
<button onclick="pausarLavado();">Pausar</button>
```

`onclick` contiene el handler del evento. Cada clic llama a la función indicada.

---

## 6. Referencia de Todas las Funciones y Métodos Vistos

### Salida y conversión

#### `console.log(valor1, valor2, ...)`

Muestra valores en la consola. Acepta varios argumentos:

```javascript
console.log('Nombre:', nombre);
```

No devuelve el valor mostrado; se usa para inspección y resultados de los ejercicios.

#### `JSON.stringify(valor)`

Convierte un objeto o arreglo compatible en una cadena JSON:

```javascript
JSON.stringify({ id: 1, nombre: 'Alexandro' });
```

Se usa para que el template literal muestre las propiedades en lugar de `[object Object]`.

### Arreglos

#### `arreglo.sort(comparador)`

Ordena el mismo arreglo. El callback `(a, b) => a - b` produce orden numérico ascendente.

#### `arreglo.map(callback)`

Llama al callback por cada elemento y devuelve un arreglo nuevo con lo retornado:

```javascript
const promesas = ids.map(id => descargar(id));
```

#### `arreglo.filter(callback)`

Fue mencionado dentro de ES5. Construye un arreglo con los elementos cuyo callback se evalúa como truthy.

#### `arreglo.forEach(callback)`

Fue mencionado dentro de ES5. Ejecuta el callback para cada elemento y se usa cuando interesa la acción, no construir otro arreglo con retornos.

#### `arreglo.push(valor)`

Agrega un elemento al final del arreglo y devuelve la nueva longitud:

```javascript
promesas.push(unaPromesa);
```

### Contexto

#### `funcion.bind(contexto)`

Crea otra función cuyo `this` queda ligado al contexto recibido. No ejecuta inmediatamente la función; devuelve la versión ligada.

### Promesas

#### `new Promise(executor)`

Crea una promesa. El executor se ejecuta inmediatamente y recibe `resolve` y `reject`.

#### `resolve(valor)`

Cumple la promesa y entrega un valor a `.then` o `await`.

#### `reject(razon)`

Rechaza la promesa y entrega la razón a `.catch` o al manejo de error del consumidor.

#### `promesa.then(handler)`

Registra la función que recibirá el resultado exitoso. Devuelve otra promesa, lo que permite encadenar.

#### `promesa.catch(handler)`

Registra la función que recibirá el rechazo. Si el handler retorna un valor, la cadena continúa cumplida con ese valor.

#### `Promise.all(iterable)`

Combina varias promesas. Conserva el orden de entrada en el arreglo de resultados y, si los rechazos no fueron atendidos individualmente, se rechaza al fallar una.

### Tiempo, red y eventos mostrados

#### `setTimeout(callback, milisegundos)`

Programa el callback para una ejecución futura; no bloquea el hilo esperando.

#### `fetch(url, config)`

Aparece en las diapositivas de callbacks y promesas. Inicia una solicitud y devuelve una promesa con una respuesta.

#### `response.json()`

Lee el cuerpo de la respuesta como JSON y devuelve una promesa con el dato interpretado.

#### `window.location.replace(url)`

Aparece en el callback de autorización. Sustituye la ubicación actual por la URL recibida.

#### `elemento.addEventListener(evento, callback)`

Aparece como ejemplo de programación por eventos. Registra un callback que se ejecutará cuando ocurra un evento como `'click'`.

El panel usa el mecanismo alternativo visto en HTML: el atributo `onclick`.

### DOM

#### `document.getElementById(id)`

Devuelve el elemento con ese ID o `null` si no se encuentra.

#### `elemento.checked`

Propiedad booleana de un checkbox. `true` lo marca y `false` lo desmarca.

#### `elemento.textContent`

Propiedad con el texto del elemento. Asignar una cadena reemplaza el texto visible.

### Palabras y objetos especiales

#### `return`

Termina la función actual y entrega un valor. Es indispensable en la cadena de promesas para devolver la siguiente promesa.

#### `arguments`

Objeto disponible dentro de funciones tradicionales. Contiene los argumentos por posición y ofrece `length`.

#### `async`

Declara que una función trabaja con un resultado asíncrono y hace que retorne una promesa.

#### `await`

Espera la resolución de una promesa dentro de un contexto asíncrono y obtiene su valor.

---

## 7. Aclaraciones Importantes

### Declaraciones repetidas

Si se combinan ejemplos independientes que reutilizan identificadores, JavaScript detecta las declaraciones repetidas antes de ejecutar:

```text
SyntaxError: Identifier 'usuario' has already been declared
```

### `0` no es truthy

El número `0` debe estudiarse como un valor **falsy**.

### Resultado de `sort`

El código con `(a, b) => a - b` sí ordena numéricamente. El resultado sin ordenar escrito en el comentario es incorrecto.

### Interpolar un objeto

```javascript
console.log(`Nuevo objeto: ${venta}`);
```

no imprime una representación literal de propiedades. Para inspeccionarlo se utiliza `console.log(venta)`; para convertirlo a texto, `JSON.stringify(venta)`.

### Propiedades duplicadas con spread

En `{ ...producto, ...usuario }`, la propiedad `nombre` de `usuario` sustituye la de `producto` por aparecer después.

### Estructura de `direccion`

Una dirección anidada y las propiedades colocadas en el nivel principal requieren patrones de destructuración distintos y no deben mezclarse.

### `reject` recibe una razón

Una llamada como:

```javascript
reject('Algo falló', error);
```

solo conserva el primer argumento como razón de rechazo. Si se desea conservar más información, debe ir reunida en un solo valor, como una cadena u objeto.

### `try/catch` exterior y `setTimeout`

El callback de `setTimeout` se ejecuta después. Un `try/catch` que rodea solamente la programación del temporizador no captura un error lanzado más tarde dentro de ese callback.

### Etiqueta incorrecta del quinto checkbox

El HTML del nivel 5 usa:

```html
<label for="tl-cbox4">Nivel 5 (colchas)</label>
```

aunque el checkbox se llama `tl-cbox5`. El ciclo JavaScript funciona porque busca el ID del `input`; sin embargo, el `for` del label debería corresponder al control que describe.

---

## 8. Ejercicios de Repaso

### Funciones y contexto

1. Predice la salida de un método tradicional que usa `this.name`.
2. Sustitúyelo por una flecha y explica el cambio.
3. Corrige el contador usando una flecha interna.
4. Corrígelo otra vez guardando `this` en una variable.
5. Corrígelo mediante `bind(this)`.
6. Suma seis valores con `arguments`.
7. Convierte esa función a flecha con rest.

### Destructuración y spread

1. Extrae la primera y tercera posición de un arreglo.
2. Usa un valor por defecto en una posición ausente.
3. Intercambia dos variables.
4. Extrae `pais`, `municipio` y `cp` de una dirección anidada.
5. Une dos arreglos y ordénalos numéricamente.
6. Combina dos objetos que compartan una propiedad y explica cuál gana.
7. Agrega un elemento al inicio y al final sin modificar el arreglo original.

### Promesas

1. Explica las rutas de `validarEdad(17)` y `validarEdad(18)`.
2. Atiende un rechazo con `.catch(error => error)`.
3. Sigue el orden de salida de una promesa con `setTimeout`.
4. Convierte cuatro IDs en cuatro promesas usando `map`.
5. Explica por qué los `catch` individuales permiten completar `Promise.all`.
6. Sigue paso a paso el valor de `multiplicarPorDos(5)`.
7. Reescribe la espera usando `async`/`await`.

### Panel de lavadora

1. Indica qué checkbox queda marcado al cargar la página.
2. Sigue seis clics sobre «Cambiar tipo de lavado».
3. Explica por qué temperatura regresa a 1 después de 3.
4. Sigue la llamada desde el botón «Lavar» hasta `textContent`.
5. Explica por qué `ponerEstadoLavadora` comprueba `if (estado)`.
6. Describe qué hace cada línea de la función autoejecutable.

### Checklist para examen

- Puedo distinguir declaración y expresión de función.
- Puedo determinar el `this` de una llamada observando quién invoca la función.
- Puedo elegir entre `arguments` y rest.
- Puedo destructurar arreglos, objetos y objetos anidados.
- Puedo explicar rest frente a spread.
- Puedo seguir `resolve`, `reject`, `.then`, `.catch` y `await`.
- Puedo explicar `map` junto con `Promise.all`.
- Puedo seguir el cambio de estado del panel desde `onclick` hasta el DOM.
