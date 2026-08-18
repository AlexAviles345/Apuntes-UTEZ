# Guía Complementaria — Recorridos de Arreglos y Diseño de DynamoDB

> **Material complementario:** este documento no forma parte del contenido que debe estudiarse como temario de la Unidad 2. Reúne recursos de JavaScript y una organización alternativa de DynamoDB que pueden facilitar proyectos posteriores.

`map`, `find` y `forEach` se refuerzan aquí porque aparecen en la lógica de la cartera. Las comparaciones con `filter`, `some`, `every`, `reduce`, `for...of`, `for...in` y el diseño recomendado de DynamoDB son ampliaciones.

---

## Tabla de Contenidos

1. [Cómo Elegir un Recorrido](#1-cómo-elegir-un-recorrido)
2. [forEach](#2-foreach)
3. [map](#3-map)
4. [filter](#4-filter)
5. [find](#5-find)
6. [some](#6-some)
7. [every](#7-every)
8. [reduce](#8-reduce)
9. [for...of](#9-forof)
10. [for...in](#10-forin)
11. [Combinaciones Útiles](#11-combinaciones-útiles)
12. [Comparación Rápida](#12-comparación-rápida)
13. [Organización Recomendada de DynamoDB](#13-organización-recomendada-de-dynamodb)
14. [Comparación con el Modelo de Práctica](#14-comparación-con-el-modelo-de-práctica)
15. [Pruebas y Depuración de una Skill](#15-pruebas-y-depuración-de-una-skill)
16. [Ejercicios Complementarios](#16-ejercicios-complementarios)

---

## 1. Cómo Elegir un Recorrido

Antes de recorrer un arreglo, pregunte qué resultado necesita:

```text
¿Ejecutar una acción por elemento?       → forEach
¿Crear un arreglo transformado?          → map
¿Conservar varios que cumplan?           → filter
¿Obtener el primero que cumpla?           → find
¿Saber si al menos uno cumple?            → some
¿Saber si todos cumplen?                  → every
¿Acumular un solo resultado?              → reduce
¿Usar break, continue o await?            → for...of
¿Recorrer claves de un objeto?            → for...in
```

Datos de ejemplo:

```javascript
const tarjetas = [
    { id: 'card-1', nickname: 'alex', amount: 5000, active: true },
    { id: 'card-2', nickname: 'raul', amount: 1200, active: true },
    { id: 'card-3', nickname: 'ana', amount: 0, active: false }
];
```

---

## 2. `forEach`

Ejecuta una función una vez por cada elemento.

```javascript
tarjetas.forEach((tarjeta, indice) => {
    console.log(indice, tarjeta.nickname);
});
```

### Características

- devuelve `undefined`;
- se usa para efectos como imprimir, registrar o modificar una variable externa;
- no crea automáticamente un arreglo nuevo;
- no permite detener el recorrido con `break`.

### Búsqueda manual

```javascript
let encontrada = null;

tarjetas.forEach((tarjeta) => {
    if (tarjeta.nickname === 'raul') {
        encontrada = tarjeta;
    }
});
```

Funciona, pero `find` expresa mejor que solo se necesita una coincidencia.

---

## 3. `map`

Crea un arreglo nuevo aplicando una transformación a cada elemento.

```javascript
const nombres = tarjetas.map((tarjeta) => tarjeta.nickname);
```

Resultado:

```javascript
['alex', 'raul', 'ana']
```

### Actualización sin modificar el arreglo original

```javascript
const actualizadas = tarjetas.map((tarjeta) => {
    if (tarjeta.id === 'card-2') {
        return {
            ...tarjeta,
            amount: tarjeta.amount + 300
        };
    }

    return tarjeta;
});
```

Regla esencial: el callback debe devolver el valor que ocupará cada posición. Si una ruta no ejecuta `return`, esa posición queda como `undefined`.

`map` es apropiado cuando el resultado debe conservar la misma cantidad de elementos.

---

## 4. `filter`

Crea un arreglo con todos los elementos cuyo predicado devuelve `true`.

```javascript
const activas = tarjetas.filter((tarjeta) => tarjeta.active);
```

### Eliminar de forma no destructiva

```javascript
const sinTarjetaDos = tarjetas.filter(
    (tarjeta) => tarjeta.id !== 'card-2'
);
```

El arreglo original no se modifica. El nuevo contiene todos excepto el elemento que se desea excluir.

### Diferencia con `map`

```text
map    → puede cambiar el contenido, conserva la longitud
filter → conserva elementos completos, puede reducir la longitud
```

---

## 5. `find`

Devuelve el primer elemento que cumple una condición.

```javascript
const tarjeta = tarjetas.find(
    (item) => item.nickname === 'raul'
);
```

Si no hay coincidencia, devuelve `undefined`.

```javascript
if (tarjeta === undefined) {
    console.log('No existe');
}
```

### Diferencia con `filter`

```text
find   → primer objeto o undefined
filter → arreglo con cero, uno o varios objetos
```

No use `filter(...)[0]` si solamente necesita la primera coincidencia; `find` comunica mejor la intención y puede dejar de buscar cuando encuentra el elemento.

---

## 6. `some`

Comprueba si al menos un elemento cumple la condición.

```javascript
const existeAlex = tarjetas.some(
    (tarjeta) => tarjeta.nickname === 'alex'
);
```

Devuelve `true` o `false`, no el objeto.

### Evitar aliases repetidos

```javascript
const aliasOcupado = tarjetas.some(
    (tarjeta) => tarjeta.nickname === nuevoAlias
);

if (aliasOcupado) {
    console.log('El alias ya existe');
}
```

Use `some` cuando la pregunta sea “¿existe al menos uno?”, pero no necesite recuperar ese registro.

---

## 7. `every`

Comprueba si todos los elementos cumplen la condición.

```javascript
const todosConSaldoNoNegativo = tarjetas.every(
    (tarjeta) => tarjeta.amount >= 0
);
```

Devuelve un booleano.

```text
some  → al menos uno
every → todos
```

Puede servir para validar un arreglo completo antes de guardarlo.

---

## 8. `reduce`

Convierte el arreglo en un único resultado acumulado.

### Sumar saldos

```javascript
const saldoTotal = tarjetas.reduce(
    (acumulado, tarjeta) => acumulado + tarjeta.amount,
    0
);
```

Funcionamiento:

1. `0` es el valor inicial.
2. En cada vuelta, `acumulado` contiene el resultado anterior.
3. Se suma el saldo actual.
4. Al terminar se devuelve un solo número.

También podría acumular objetos o arreglos, pero conviene usarlo cuando la reducción a un resultado único sea clara.

---

## 9. `for...of`

Recorre directamente los valores de un iterable, como un arreglo.

```javascript
for (const tarjeta of tarjetas) {
    console.log(tarjeta.nickname);
}
```

### Ventajas

- permite `break`;
- permite `continue`;
- funciona bien con `await` dentro de un `async`;
- su lectura es directa.

```javascript
for (const tarjeta of tarjetas) {
    if (tarjeta.nickname === 'raul') {
        console.log(tarjeta);
        break;
    }
}
```

Si solamente busca el primer elemento, `find` sigue siendo más declarativo. `for...of` es útil cuando la operación requiere control explícito del recorrido.

---

## 10. `for...in`

Recorre las claves enumerables de un objeto.

```javascript
const tarjeta = {
    nickname: 'alex',
    bankName: 'Banamex',
    amount: 5000
};

for (const propiedad in tarjeta) {
    console.log(propiedad, tarjeta[propiedad]);
}
```

Salida conceptual:

```text
nickname alex
bankName Banamex
amount 5000
```

### No usarlo como recorrido normal de arreglos

En un arreglo, `for...in` entrega índices como cadenas y también puede incluir otras propiedades enumerables. Para valores use `for...of`:

```text
for...in → claves o nombres de propiedades
for...of → valores del arreglo
```

---

## 11. Combinaciones Útiles

### Filtrar y después transformar

```javascript
const aliasesActivos = tarjetas
    .filter((tarjeta) => tarjeta.active)
    .map((tarjeta) => tarjeta.nickname);
```

Primero quedan las activas y después se extraen sus aliases.

### Buscar y validar

```javascript
const origen = tarjetas.find(
    (tarjeta) => tarjeta.nickname === 'alex'
);

const puedeRetirar = origen !== undefined && origen.amount >= 500;
```

### Eliminar y recalcular

```javascript
const restantes = tarjetas.filter(
    (tarjeta) => tarjeta.id !== 'card-3'
);

const total = restantes.reduce(
    (suma, tarjeta) => suma + tarjeta.amount,
    0
);
```

No encadene métodos solamente por reducir líneas. Cada operación debe corresponder a una intención clara.

---

## 12. Comparación Rápida

| Recurso | Resultado | ¿Puede cambiar longitud? | Se detiene al encontrar | Uso típico |
|---|---|---:|---:|---|
| `forEach` | `undefined` | No aplica | No | Efectos por elemento |
| `map` | Arreglo | No | No | Transformar o actualizar |
| `filter` | Arreglo | Sí | No | Seleccionar o eliminar |
| `find` | Elemento o `undefined` | No aplica | Sí | Obtener una coincidencia |
| `some` | Booleano | No aplica | Sí, al obtener `true` | Saber si existe |
| `every` | Booleano | No aplica | Sí, al obtener `false` | Validar todos |
| `reduce` | Cualquier acumulado | No aplica | No | Totalizar o agrupar |
| `for...of` | No automático | Depende del código | Sí con `break` | Control explícito y `await` |
| `for...in` | No automático | Depende del código | Sí con `break` | Recorrer claves de objetos |

---

## 13. Organización Recomendada de DynamoDB

La estructura practicada guarda una colección completa en un solo elemento:

```javascript
{
    id: 'cardTable',
    data: [tarjeta1, tarjeta2, tarjeta3]
}
```

Una organización más natural en DynamoDB guarda cada entidad como un elemento independiente:

```text
Tabla real
├── { id: "card-1", nickname: "alex", bankName: "Banamex", amount: 5000 }
├── { id: "card-2", nickname: "raul", bankName: "BBVA", amount: 1200 }
└── { id: "card-3", nickname: "ana", bankName: "HSBC", amount: 0 }
```

### Ventajas

- una actualización cambia solo la tarjeta afectada;
- no se lee ni reescribe un arreglo completo;
- disminuye el riesgo de que dos operaciones sobrescriban cambios mutuos;
- cada elemento tiene una identidad propia;
- el tamaño de una colección no queda concentrado en un solo elemento.

### Ejemplo conceptual de alta

```javascript
await dynamoDB.put({
    TableName: TABLE_NAME,
    Item: {
        id: 'card-3',
        nickname: 'ana',
        numberCard: '1111222233334444',
        bankName: 'HSBC',
        amount: 0
    }
}).promise();
```

### Ejemplo conceptual de actualización puntual

```javascript
await dynamoDB.update({
    TableName: TABLE_NAME,
    Key: {
        id: 'card-3'
    },
    UpdateExpression: 'SET #amount = #amount + :deposit',
    ExpressionAttributeNames: {
        '#amount': 'amount'
    },
    ExpressionAttributeValues: {
        ':deposit': 500
    }
}).promise();
```

Aquí no se recuperan todas las tarjetas. DynamoDB localiza `card-3` y modifica solamente su saldo.

### Datos de varios usuarios

Si una skill atiende a diferentes usuarios, una estructura conceptual puede separar propietario y tarjeta:

```text
PK = USER#identificador-del-usuario
SK = CARD#identificador-de-la-tarjeta
```

Ejemplos:

```text
PK = USER#123 | SK = CARD#001 | nickname = alex | amount = 5000
PK = USER#123 | SK = CARD#002 | nickname = raul | amount = 1200
PK = USER#987 | SK = CARD#001 | nickname = ana  | amount = 700
```

La clave de partición agrupa los registros de un usuario y la clave de ordenación distingue sus tarjetas. Este modelado es material posterior y requiere una tabla configurada con ambas claves.

La documentación de Alexa explica que la persistencia alojada normalmente utiliza el `userId` como clave para separar información de usuarios: [Use DynamoDB for Data Persistence with Your Alexa-hosted Skill](https://developer.amazon.com/en-US/docs/alexa/hosted-skills/alexa-hosted-skills-session-persistence.html).

---

## 14. Comparación con el Modelo de Práctica

| Aspecto | Modelo `id` + `data` | Un elemento por entidad |
|---|---|---|
| Objetivo | Aprender `put`, `get`, `update` y arreglos | Aprovechar la estructura de DynamoDB |
| Unidad de almacenamiento | Colección completa | Usuario, tarjeta u otra entidad |
| Lectura para cambiar una tarjeta | Recupera todo `data` | Recupera o actualiza la tarjeta concreta |
| Escritura | Sustituye todo `data` | Modifica un elemento o atributo |
| Concurrencia | Dos cambios pueden sobrescribirse | Los cambios puntuales están mejor aislados |
| Escalabilidad | Limitada por un elemento creciente | Distribuida entre elementos |
| Uso en la Unidad 2 | Sí, como simplificación pedagógica | No; se presenta aquí como ampliación |

La forma de práctica no debe ocultarse ni llamarse “incorrecta” sin contexto: es útil para entender cómo JavaScript transforma un arreglo y luego lo persiste. La limitación aparece cuando ese patrón se intenta llevar a una aplicación real con más datos o usuarios.

---

## 15. Pruebas y Depuración de una Skill

> **Material complementario:** las técnicas de esta sección sirven durante el desarrollo. Hacer que Alexa pronuncie el error interno solamente es aceptable en pruebas; antes de compartir o publicar la skill debe restaurarse una respuesta genérica.

Una prueba útil separa tres niveles:

```text
1. Modelo de interacción
   ¿La frase llega al intent y llena los slots correctos?

2. Simulador de Alexa
   ¿El diálogo completo llama al backend y devuelve una respuesta válida?

3. CloudWatch Logs
   ¿Qué ruta siguió el código y en qué instrucción ocurrió el error?
```

### 15.1 Preparar la skill para probarla

Antes de abrir el simulador:

1. guarde el modelo de interacción;
2. ejecute **Build Model** y confirme que termine sin errores;
3. guarde los cambios de `index.js`;
4. pulse **Deploy** para desplegar el backend;
5. abra **Test**;
6. habilite las pruebas en **Development**;
7. seleccione **Spanish (Mexico)**;
8. abra **Alexa Simulator**.

Puede escribir o pronunciar la invocación y las utterances. La vista **Skill I/O** permite inspeccionar el JSON enviado al backend y el JSON devuelto por este. Esto ayuda a comprobar:

- el tipo de solicitud;
- el nombre del intent;
- los slots recibidos;
- `confirmationStatus`;
- la respuesta generada.

El simulador conserva la sesión para probar conversaciones de varios turnos, incluyendo filling y confirmation. La guía oficial explica estas opciones en [Test with the Alexa Simulator](https://developer.amazon.com/en-US/docs/alexa/devconsole/alexa-simulator.html).

### 15.2 Diferencia entre Skill I/O y los logs

No deben confundirse:

| Herramienta | Qué muestra |
|---|---|
| **Skill I/O** | Solicitud JSON que Alexa envía y respuesta JSON que recibe |
| Respuesta hablada | Contenido colocado en `.speak(...)` |
| `console.log(...)` | Seguimiento escrito por el desarrollador y enviado a CloudWatch |
| `console.error(...)` | Errores escritos por el desarrollador y enviados a CloudWatch |

Un `console.log` no hace que Alexa pronuncie el texto y normalmente no aparece dentro de Skill I/O. Sirve para estudiar la ejecución interna en CloudWatch.

### 15.3 Dónde colocar `console.log`

Coloque registros antes y después de una parte donde el código podría fallar. Use un prefijo constante para identificar el handler.

```javascript
async handle(handlerInput) {
    const requestId = handlerInput.requestEnvelope.request.requestId;
    const { intent } = handlerInput.requestEnvelope.request;
    const { nickname, depositAmount } = intent.slots;

    console.log('[DepositIntent] Inicio', {
        requestId,
        nickname: nickname.value,
        depositAmount: depositAmount.value,
        confirmationStatus: intent.confirmationStatus
    });

    console.log('[DepositIntent] Antes de consultar DynamoDB', {
        requestId,
        logicalTable: 'cardTable'
    });

    const result = await dynamoDB.get({
        TableName: TABLE_NAME,
        Key: { id: 'cardTable' }
    }).promise();

    console.log('[DepositIntent] Consulta terminada', {
        requestId,
        itemFound: result.Item !== undefined,
        recordCount: result.Item?.data?.length
    });
}
```

Estos mensajes permiten responder:

1. ¿Entró al handler correcto?
2. ¿Qué valores llegaron en los slots?
3. ¿La confirmación llegó como `CONFIRMED`?
4. ¿Comenzó la consulta a DynamoDB?
5. ¿La consulta terminó?
6. ¿Se encontró el elemento?

Si aparece “Antes de consultar DynamoDB”, pero nunca “Consulta terminada”, la zona sospechosa es la llamada a DynamoDB.

### 15.4 Registrar decisiones sin llenar los logs

También se pueden marcar las ramas importantes:

```javascript
if (intent.confirmationStatus !== 'CONFIRMED') {
    console.log('[DepositIntent] Operación cancelada', { requestId });
    speakOutput = 'Cancelé el depósito';
} else {
    console.log('[DepositIntent] Operación confirmada', { requestId });
}
```

No es necesario escribir un log después de cada línea. Registre:

- entrada al handler;
- datos necesarios para entender la prueba;
- entrada a una rama importante;
- antes y después de una operación asíncrona;
- resultado resumido;
- error capturado.

El prefijo `[DepositIntent]` permite buscar todos los mensajes relacionados. `requestId` ayuda a reunir los registros de una misma invocación cuando hay varias pruebas cercanas.

### 15.5 Usar `console.error` en un `catch`

Cuando una operación puede fallar:

```javascript
try {
    await dynamoDB.update(params).promise();
    console.log('[DepositIntent] Actualización completada', { requestId });
} catch (error) {
    console.error('[DepositIntent] Falló la actualización', {
        requestId,
        errorName: error.name,
        errorMessage: error.message,
        stack: error.stack
    });

    speakOutput = 'No se pudo realizar el depósito';
}
```

`console.error` debe recibir el error real o, como en el ejemplo, su nombre, mensaje y stack. El stack muestra la cadena de llamadas y normalmente incluye la línea donde se originó el problema.

AWS Lambda envía las salidas de `console.log` y `console.error` a CloudWatch. La documentación de AWS explica los niveles y la información de error disponible en [Log and monitor Node.js Lambda functions](https://docs.aws.amazon.com/lambda/latest/dg/nodejs-logging.html).

### 15.6 No registrar información sensible

Los logs se almacenan y pueden ser revisados después. Evite registrar:

- números completos de tarjeta;
- correos o teléfonos completos si no son indispensables;
- contraseñas, tokens o credenciales;
- todo el contenido de DynamoDB sin necesidad;
- solicitudes completas que contengan datos personales.

En lugar de imprimir una tarjeta completa:

```javascript
console.log(cardObj);
```

registre solamente información suficiente para la prueba:

```javascript
console.log('[AddNewCardIntent] Tarjeta preparada', {
    nickname: cardObj.nickname,
    bankName: cardObj.bankName,
    hasCardNumber: Boolean(cardObj.numberCard)
});
```

### 15.7 Hacer que Alexa diga el error durante las pruebas

El handler global puede modificarse temporalmente para incluir `error.message` en `speakOutput`:

```javascript
const ErrorHandler = {
    canHandle() {
        return true;
    },

    handle(handlerInput, error) {
        const requestId = handlerInput.requestEnvelope.request.requestId;
        const errorMessage = error?.message || String(error);

        console.error('[ErrorHandler] Error no controlado', {
            requestId,
            errorName: error?.name,
            errorMessage,
            stack: error?.stack
        });

        const speakOutput = `Error de prueba: ${errorMessage}`;

        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt('Corrige el error y vuelve a intentarlo')
            .getResponse();
    }
};
```

Funcionamiento:

1. `canHandle()` devuelve `true`, por lo que acepta cualquier error que no se haya manejado antes.
2. `error?.message` intenta obtener el mensaje sin provocar otro fallo si `error` no tiene la forma esperada.
3. `String(error)` sirve como respaldo.
4. `console.error` conserva mensaje y stack en CloudWatch.
5. `.speak(...)` permite escuchar el mensaje desde el simulador.

Esta técnica acelera pruebas, pero puede pronunciar nombres técnicos, rutas o datos internos. Antes de dejar la skill lista, restaure una respuesta genérica:

```javascript
const speakOutput = 'Ocurrió un problema al realizar la operación. Intenta nuevamente.';
```

El detalle debe permanecer en `console.error`, no en la respuesta de producción.

### 15.8 Por qué a veces no se activa el ErrorHandler global

Si un handler captura el error y no vuelve a lanzarlo, el error ya se considera atendido:

```javascript
try {
    await dynamoDB.get(params).promise();
} catch (error) {
    console.error(error);
    speakOutput = 'No pude consultar los datos';
}
```

En ese caso el `ErrorHandler` global **no se ejecuta**. Para probar específicamente el handler global, puede volver a lanzar el error de manera temporal:

```javascript
try {
    await dynamoDB.get(params).promise();
} catch (error) {
    console.error('[DepositIntent] El error se enviará al handler global', error);
    throw error;
}
```

El flujo queda así:

```text
DynamoDB falla
    ↓
catch local registra el error
    ↓
throw error vuelve a lanzarlo
    ↓
ErrorHandler global lo recibe
    ↓
Alexa pronuncia el mensaje de prueba
```

Al terminar la depuración, decida una sola estrategia para cada error:

- resolverlo en el `catch` local con una respuesta específica; o
- dejar que llegue al handler global.

No conviene registrar y relanzar indefinidamente ni hacer que errores esperados terminen siempre como fallos globales.

### 15.9 Provocar un error controlado para comprobar la configuración

Durante una prueba temporal puede crear un intent o una condición que lance:

```javascript
throw new Error('Prueba del handler global');
```

Resultado esperado:

1. Alexa ejecuta el handler.
2. La ejecución llega a `throw`.
3. El `ErrorHandler` global recibe el objeto `Error`.
4. En el simulador se escucha “Error de prueba: Prueba del handler global”.
5. En CloudWatch aparecen el prefijo, `requestId`, mensaje y stack.

Retire el `throw` deliberado cuando termine la comprobación.

### 15.10 Abrir CloudWatch Logs desde la skill

Para una skill Alexa-hosted:

1. abra Alexa Developer Console;
2. seleccione la skill;
3. entre a **Code**;
4. pulse la flecha situada junto al icono **Logs**;
5. seleccione la región donde hizo la prueba, en este caso **US East (N. Virginia)**;
6. la consola de AWS abrirá CloudWatch;
7. seleccione el flujo de logs más reciente;
8. busque el prefijo del handler o el `requestId`.

Las invocaciones realizadas desde **Test** se registran en la región de alojamiento predeterminada. Si la skill tiene endpoints en varias regiones, cada región puede mostrar logs distintos. Este acceso está descrito en [Create and Manage Alexa-Hosted Skills](https://developer.amazon.com/en-AU/docs/alexa/hosted-skills/alexa-hosted-skills-create.html#view-amazon-cloudwatch-logs).

En la consola general de CloudWatch, los logs de una función Lambda suelen organizarse así:

```text
Log group:  /aws/lambda/nombre-de-la-función
└── Log stream más reciente
    ├── inicio de invocación
    ├── console.log
    ├── console.error
    └── fin de invocación
```

### 15.11 Procedimiento sencillo de diagnóstico

Use siempre una frase conocida y siga este orden:

1. agregue un prefijo y `requestId` a los logs del handler sospechoso;
2. pulse **Deploy**;
3. ejecute una sola prueba desde **Test**;
4. abra **Skill I/O** y confirme intent, slots y respuesta;
5. abra los logs de la región correcta;
6. entre al flujo más reciente;
7. busque el prefijo, por ejemplo `[TransferIntent]`;
8. identifique el último mensaje que sí apareció;
9. revise la operación que debía ejecutarse inmediatamente después;
10. corrija, despliegue y repita la misma frase.

Ejemplo:

```text
Sí aparece: [TransferIntent] Personas encontradas
No aparece: [TransferIntent] Actualización completada

Zona que debe revisarse:
cálculo de saldos, construcción de newData o dynamoDB.update
```

### 15.12 Si no aparece ningún log

Compruebe:

- que pulsó **Deploy** después de modificar el código;
- que la prueba realmente invocó el backend;
- que está viendo **US East (N. Virginia)**;
- que abrió el flujo más reciente;
- que actualizó la vista después de ejecutar la prueba;
- que el modelo reconoció un intent existente;
- que el handler se encuentra antes de `IntentReflectorHandler`.

Si Skill I/O muestra una respuesta, pero no encuentra sus mensajes, normalmente se está consultando otra región, otro flujo o un despliegue anterior.

### 15.13 Lista final antes de terminar la depuración

- [ ] La prueba de éxito funciona.
- [ ] La cancelación funciona.
- [ ] Los slots faltantes activan filling.
- [ ] Las validaciones rechazan datos inválidos.
- [ ] DynamoDB conserva el resultado esperado.
- [ ] `console.error` registra mensaje y stack.
- [ ] El ErrorHandler global responde ante un error no controlado.
- [ ] Se retiraron los `throw` creados solamente para probar.
- [ ] Alexa ya no pronuncia errores internos.
- [ ] Los logs no contienen tarjetas, tokens u otros datos sensibles.
- [ ] Se dejaron únicamente logs útiles y fáciles de buscar.

---

## 16. Ejercicios Complementarios

### Ejercicio 1

Use `filter` para obtener únicamente tarjetas con saldo mayor que cero.

### Ejercicio 2

Use `some` para comprobar si el alias `alex` ya está ocupado.

### Ejercicio 3

Use `every` para asegurar que ningún saldo sea negativo.

### Ejercicio 4

Use `reduce` para calcular el saldo total.

### Ejercicio 5

Explique por qué `find` comunica mejor una búsqueda que `forEach` con una variable externa.

### Ejercicio 6

Escriba un `for...of` que se detenga al encontrar la primera tarjeta inactiva.

### Ejercicio 7

Use `for...in` para imprimir las propiedades de una sola tarjeta.

### Ejercicio 8

Transforme conceptualmente:

```javascript
{
    id: 'cardTable',
    data: [
        { nickname: 'alex', amount: 5000 },
        { nickname: 'raul', amount: 1200 }
    ]
}
```

en dos elementos DynamoDB independientes. Defina un `id` único para cada uno.
