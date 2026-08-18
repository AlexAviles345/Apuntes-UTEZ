# Teoría — Unidad 2: Fundamentos y Desarrollo de Skills de Alexa

Esta guía explica los conceptos estudiados para crear una *custom skill* de Alexa con un modelo de interacción y un backend en Node.js. También presenta el uso de DynamoDB tal como se trabajó durante la unidad.

---

## Tabla de Contenidos

1. [Panorama de la Unidad](#1-panorama-de-la-unidad)
2. [Qué es Alexa y Cómo Procesa una Solicitud](#2-qué-es-alexa-y-cómo-procesa-una-solicitud)
3. [Qué es una Skill](#3-qué-es-una-skill)
4. [Creación y Configuración Inicial de la Skill](#4-creación-y-configuración-inicial-de-la-skill)
5. [Nombre de Invocación](#5-nombre-de-invocación)
6. [Modelo de Interacción](#6-modelo-de-interacción)
7. [Intents y su Nomenclatura](#7-intents-y-su-nomenclatura)
8. [Utterances o Frases de Ejemplo](#8-utterances-o-frases-de-ejemplo)
9. [Slots y Tipos de Slot](#9-slots-y-tipos-de-slot)
10. [Diálogo: Filling, Validation y Confirmation](#10-diálogo-filling-validation-y-confirmation)
11. [Cómo Interpretar el Diagrama del Modelo](#11-cómo-interpretar-el-diagrama-del-modelo)
12. [Backend de una Skill con Node.js](#12-backend-de-una-skill-con-nodejs)
13. [Handlers y Ciclo de una Solicitud](#13-handlers-y-ciclo-de-una-solicitud)
14. [Construcción de la Respuesta](#14-construcción-de-la-respuesta)
15. [Handlers Predeterminados](#15-handlers-predeterminados)
16. [Asincronía y Manejo de Errores](#16-asincronía-y-manejo-de-errores)
17. [Persistencia con DynamoDB](#17-persistencia-con-dynamodb)
18. [Operaciones put, get y update](#18-operaciones-put-get-y-update)
19. [Procesamiento de los Registros con JavaScript](#19-procesamiento-de-los-registros-con-javascript)
20. [Flujo Completo de una Operación](#20-flujo-completo-de-una-operación)
21. [Diferencias que Debes Memorizar](#21-diferencias-que-debes-memorizar)
22. [Preguntas de Repaso](#22-preguntas-de-repaso)

---

## 1. Panorama de la Unidad

El propósito de la unidad es comprender cómo una frase pronunciada por el usuario termina ejecutando código dentro de una skill.

```text
Usuario habla
    ↓
Alexa reconoce la voz y obtiene texto
    ↓
El modelo de interacción identifica el intent y sus slots
    ↓
El backend selecciona un handler
    ↓
El handler ejecuta la lógica y, si hace falta, consulta DynamoDB
    ↓
Alexa responde al usuario
```

La construcción se estudia en este orden:

1. crear la skill con la configuración indicada;
2. establecer un nombre de invocación;
3. configurar el modelo de interacción;
4. programar el backend;
5. conectar el backend con DynamoDB cuando se necesita persistencia;
6. probar las diferentes rutas de conversación.

Los conocimientos de JavaScript de la Unidad 1 son la base del backend: objetos, funciones, destructuración, *template literals*, arreglos, funciones flecha, `async`, `await`, promesas y manejo de errores.

---

## 2. Qué es Alexa y Cómo Procesa una Solicitud

Alexa es el asistente virtual de Amazon. Está integrado en dispositivos como los altavoces Echo y permite realizar acciones mediante la voz, por ejemplo:

- reproducir música;
- consultar el clima;
- configurar alarmas y recordatorios;
- responder preguntas;
- controlar dispositivos inteligentes.

Alexa no es solamente el dispositivo físico. El funcionamiento combina:

- hardware que recibe la voz;
- software de reconocimiento de voz;
- procesamiento en la nube;
- comprensión del lenguaje natural;
- servicios externos y código creado por desarrolladores.

### Flujo de interpretación

Ante una frase como:

```text
Alexa, agrega el número cinco a la lista
```

ocurre lo siguiente:

1. Alexa escucha la palabra de activación.
2. Convierte el audio en texto.
3. Analiza qué desea hacer el usuario.
4. Relaciona la frase con una intención, por ejemplo `AddNumberToListIntent`.
5. extrae el valor dinámico `cinco` y lo coloca en un slot.
6. Envía una solicitud estructurada al backend.
7. El backend produce una respuesta.
8. Alexa transforma la respuesta en voz.

La comprensión de lenguaje natural permite que distintas frases representen la misma acción. “Dime la hora”, “¿Qué hora es?” y “¿Me puedes decir la hora?” pueden dirigirse al mismo intent.

---

## 3. Qué es una Skill

Una **skill** es una capacidad que amplía lo que Alexa puede hacer. Agrupa intenciones relacionadas con un propósito.

Por ejemplo, una skill de alarmas podría contener:

- `SetAlarmIntent` para crear una alarma;
- otro intent para consultarla;
- otro intent para cancelarla.

Una skill posee dos partes esenciales:

| Parte | Pregunta que responde | Contenido |
|---|---|---|
| Modelo de interacción | ¿Cómo habla el usuario con la skill? | Nombre de invocación, intents, utterances, slots, diálogo y prompts |
| Backend | ¿Qué debe hacer Alexa al reconocer cada intención? | Handlers, reglas, consultas, modificaciones de datos y respuestas |

El modelo de interacción **reconoce y estructura** la petición. El backend **ejecuta** su comportamiento.

---

## 4. Creación y Configuración Inicial de la Skill

La configuración empleada en la unidad se resume en la siguiente captura:

![Configuración inicial de una skill de Alexa](imagenes/Configuracion%20inicial%20de%20skill%20de%20Alexa.webp)

### Selecciones de creación

| Paso | Selección | Función |
|---|---|---|
| Nombre de la skill | Un nombre descriptivo del proyecto | Identifica el proyecto en la consola; no es necesariamente el nombre que dirá el usuario |
| *Primary locale* | **Spanish (Mexico)** | Establece el idioma y región del modelo de voz |
| *Type of experience* | **Other** | Indica que no se usará una categoría especializada |
| Modelo | **Custom** | Permite definir intents, frases y slots propios |
| Servicio de alojamiento | **Alexa-hosted (Node.js)** | Alexa aloja el backend y proporciona una plantilla de Node.js |
| Región | **US East (N. Virginia)** | Región usada para los recursos alojados |
| Plantilla | **Start from Scratch** | Genera la estructura mínima para comenzar desde cero |

Después se revisan las selecciones y se pulsa **Create Skill**.

### Nombre de la skill frente a nombre de invocación

No deben confundirse:

- el **nombre de la skill** sirve para localizar el proyecto en la consola;
- el **nombre de invocación** forma parte de la frase con la que el usuario abre la skill.

---

## 5. Nombre de Invocación

El nombre de invocación es la expresión que identifica la skill durante una conversación. Ejemplos trabajados con nombres en inglés son:

```text
listed numbers
user registration
```

En las prácticas se prefieren nombres en inglés y que describan la función de la skill. El nombre debe ser fácil de pronunciar y distinguir.

Ejemplo conceptual:

```text
Alexa, abre user registration
```

El orden de configuración recomendado durante la unidad es:

```text
1. Nombre de invocación
2. Modelo de interacción
3. Backend
```

Esta secuencia evita escribir un handler sin haber definido primero qué intent lo activará y qué datos recibirá.

---

## 6. Modelo de Interacción

El **modelo de interacción** es toda la estructura que enseña a Alexa cómo puede comunicarse el usuario con la skill.

```text
Modelo de interacción
├── Nombre de invocación
├── Intents
│   ├── Utterances
│   └── Slots
└── Diálogo
    ├── Slot filling
    ├── Slot validation
    ├── Slot confirmation
    └── Intent confirmation
```

En el editor JSON, la estructura principal se organiza así:

```json
{
  "interactionModel": {
    "languageModel": {
      "invocationName": "listed numbers",
      "intents": [],
      "types": []
    },
    "dialog": {
      "intents": [],
      "delegationStrategy": "ALWAYS"
    },
    "prompts": []
  }
}
```

- `languageModel` describe las frases que Alexa debe reconocer.
- `dialog` establece cómo recopilar, validar o confirmar datos.
- `prompts` almacena las preguntas que Alexa pronuncia durante el diálogo.
- `delegationStrategy: "ALWAYS"` permite que Alexa conduzca el diálogo configurado.

---

## 7. Intents y su Nomenclatura

Un **intent** representa una acción. Si se compara con un CRUD de usuarios:

| Acción | Intent |
|---|---|
| Crear | `AddUserIntent` |
| Leer | `ReadUserIntent` |
| Actualizar | `UpdateUserIntent` |
| Eliminar | `DeleteUserIntent` |

### Nomenclatura estudiada

El nombre debe comunicar:

```text
Acción + módulo + objetivo opcional + Intent
```

Ejemplos:

- `UpdateUserIntent`: actualizar un usuario;
- `AddNumberToListIntent`: agregar un número a una lista;
- `AssignRoleToUserIntent`: asignar un rol a un usuario;
- `RetrieveDataFromUserIntent`: recuperar datos de un usuario;
- `SetAlarmIntent`: establecer una alarma;
- `DepositIntent`: realizar un depósito;
- `WithdrawalIntent`: realizar un retiro;
- `TransferIntent`: transferir saldo.

Se usa inglés y se agrega `Intent` al final por buena práctica. Las preposiciones `to`, `from`, `on` o `in` ayudan a precisar origen, destino o ubicación de la acción.

---

## 8. Utterances o Frases de Ejemplo

Una **utterance** es una frase que el usuario podría pronunciar para activar un intent. También puede llamarse frase detonante o frase modelo.

Para `AddNumberToListIntent`:

```text
agrega un número
quiero agregar un número
agrega el número {number} a la lista
```

Las tres frases expresan la misma acción, aunque una ya incluye el dato.

### Frases del intent y frases del slot

- Las frases del **intent** ayudan a decidir qué acción se desea ejecutar.
- Las frases del **slot** ayudan a reconocer la respuesta cuando Alexa ya preguntó por un dato.

Ejemplo de frase del slot:

```text
el número es {number}
```

Los valores dinámicos siempre se escriben entre llaves: `{number}`, `{username}` o `{phone}`.

---

## 9. Slots y Tipos de Slot

Un **slot** es una variable incluida en la conversación. Permite que una misma frase funcione con valores diferentes.

```text
Agrega el número {number} a la lista
```

El intent permanece igual, pero `{number}` podría ser 5, 20 o 150.

Cada slot posee:

- un nombre;
- un tipo;
- frases opcionales para reconocer su valor;
- configuración opcional de llenado, validación o confirmación.

### Tipos empleados

| Tipo | Uso |
|---|---|
| `AMAZON.NUMBER` | Cantidades, números y edades |
| `AMAZON.FirstName` | Nombres o cadenas cortas similares a nombres |
| `AMAZON.PhoneNumber` | Números telefónicos |
| `AMAZON.Corporation` | Nombres de empresas o bancos |
| `AMAZON.SearchQuery` | Texto abierto que no se ajusta bien a un tipo más específico |

### Cadenas en las prácticas

Para capturar cadenas se trabajó principalmente con:

- `AMAZON.FirstName`, cuando el valor se comporta como un nombre o alias;
- `AMAZON.Corporation`, cuando el valor es una empresa o banco.

Estos tipos ofrecen un contexto reconocible para Alexa y, en los casos estudiados, causaron menos problemas que un texto completamente abierto.

### Restricción de `AMAZON.SearchQuery`

`AMAZON.SearchQuery` se usa cuando el contenido es impredecible, como una consulta o un texto libre. Debe recordarse la regla exacta:

- solo puede existir **un slot `AMAZON.SearchQuery` por intent**;
- en una frase de ejemplo que incluya ese slot no puede aparecer otro slot;
- la frase del intent debe contener palabras de contexto, por ejemplo `busca {query}`;
- una frase que contenga únicamente `{query}` puede reservarse para las muestras del slot, no para las frases generales del intent.

Por tanto, el problema no es que el intent pueda tener una sola utterance. La restricción es que una utterance con `AMAZON.SearchQuery` no puede mezclar otro slot. La referencia oficial se encuentra en [Slot Type Reference](https://developer.amazon.com/en-US/docs/alexa/custom-skills/slot-type-reference.html).

### Acceso al valor en el backend

El valor reconocido se encuentra en `.value`:

```javascript
const { intent } = handlerInput.requestEnvelope.request;
const { username, phone } = intent.slots;

const nombre = username.value;
const telefono = phone.value;
```

La destructuración recupera primero `intent`, después los slots y finalmente se usa la propiedad `value`.

---

## 10. Diálogo: Filling, Validation y Confirmation

Los slots pueden tener tres configuraciones especiales.

### Slot Filling — F

Indica que el dato es obligatorio. Si el usuario activa el intent sin proporcionarlo, Alexa pregunta por él.

```text
Usuario: agrega un número a la lista
Alexa: ¿Qué número deseas agregar?
Usuario: cinco
```

En JSON corresponde a:

```json
"elicitationRequired": true
```

El prompt asociado comienza normalmente con `Elicit.Slot`.

### Slot Validation — V

Comprueba que el valor cumpla una condición antes de continuar. En la unidad se valida que un número sea mayor o igual que cero:

```json
"validations": [
  {
    "type": "isGreaterThanOrEqualTo",
    "prompt": "Slot.Validation.number",
    "value": "0"
  }
]
```

Si el dato falla, Alexa pronuncia un mensaje como:

```text
El valor debe ser mayor a cero.
```

### Slot Confirmation — C

Alexa repite el valor y pregunta si es correcto:

```text
Alexa: Agregaré el número cinco. ¿Es correcto?
Usuario: sí
```

En JSON:

```json
"confirmationRequired": true
```

El prompt asociado comienza normalmente con `Confirm.Slot`.

### Intent Confirmation

La confirmación del intent se aplica a la acción completa, después de recopilar los datos necesarios:

```text
Alexa: ¿Confirmas que se agregue el valor cinco a la lista?
```

El backend consulta el resultado mediante:

```javascript
if (intent.confirmationStatus === 'CONFIRMED') {
    // Ejecutar la operación
} else {
    // Cancelarla
}
```

No debe confundirse la confirmación de un slot con la confirmación del intent:

- la primera pregunta si **un dato** es correcto;
- la segunda pregunta si **la operación completa** debe ejecutarse.

---

## 11. Cómo Interpretar el Diagrama del Modelo

![Ejemplo de diagrama de modelo de interacción](imagenes/Ejemplo%20diagrama%20de%20modelo%20de%20interacci%C3%B3n.webp)

El diagrama se lee de izquierda a derecha.

### 1. Capa de usuario

Contiene las distintas frases que podría pronunciar la persona:

```text
Programa una alarma
Crea una alarma al rato
Avísame al ratito
Despiértame a tal hora
```

Todas convergen en la misma intención porque describen la misma acción.

### 2. Capa de intención

Las frases se dirigen a `SetAlarmIntent`. El intent contiene dos slots:

- `hour`;
- `day`.

Junto a cada slot aparecen letras de colores:

| Símbolo | Color | Significado |
|---|---|---|
| F | Rojo | *Slot filling*: el dato debe solicitarse si falta |
| V | Amarillo | *Slot validation*: el dato debe cumplir reglas |
| C | Verde | *Slot confirmation*: Alexa debe confirmar el dato |

El bloque `IntentConfirmation` representa la confirmación de la operación completa.

### 3. Capa de acción

`SetAlarmIntentHandler` es el objeto de backend que atiende esa intención. El nombre conserva la relación visible:

```text
SetAlarmIntent → SetAlarmIntentHandler
```

### 4. Capa de ejecución

La flecha final representa la respuesta o efecto que regresa a Alexa.

### Regla para leer otros diagramas

Para cualquier diagrama de este estilo, identifique en orden:

1. qué frases puede decir el usuario;
2. a qué intent llegan;
3. qué slots necesita ese intent;
4. cuáles slots tienen F, V o C;
5. si se confirma todo el intent;
6. qué handler ejecuta la acción;
7. qué resultado se devuelve a Alexa.

---

## 12. Backend de una Skill con Node.js

El backend estudiado utiliza Alexa Skills Kit SDK v2:

```javascript
const Alexa = require('ask-sdk-core');
```

`require` carga el paquete y `Alexa` conserva las funciones que permiten reconocer solicitudes, obtener nombres de intents y construir la skill.

Cuando se trabaja directamente con DynamoDB también aparece:

```javascript
const AWS = require('aws-sdk');
const dynamoDB = new AWS.DynamoDB.DocumentClient();
```

- `aws-sdk` proporciona acceso a servicios de AWS.
- `AWS.DynamoDB.DocumentClient` crea un cliente que trabaja con objetos JavaScript.
- `dynamoDB` se reutiliza para guardar, leer y actualizar datos.

### `handlerInput`

Cada handler recibe `handlerInput`, que concentra:

- la solicitud enviada por Alexa en `requestEnvelope`;
- el constructor de respuesta en `responseBuilder`;
- datos del intent y sus slots.

Ruta frecuente:

```text
handlerInput
└── requestEnvelope
    └── request
        └── intent
            ├── name
            ├── confirmationStatus
            └── slots
```

---

## 13. Handlers y Ciclo de una Solicitud

Un handler es un objeto con dos métodos principales:

```javascript
const ExampleIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'ExampleIntent';
    },

    handle(handlerInput) {
        const speakOutput = 'Operación realizada';

        return handlerInput.responseBuilder
            .speak(speakOutput)
            .getResponse();
    }
};
```

### `canHandle(handlerInput)`

Responde si ese objeto puede atender la solicitud actual.

- `Alexa.getRequestType(...)` obtiene el tipo general de solicitud.
- `Alexa.getIntentName(...)` obtiene el intent reconocido.
- `===` exige coincidencia exacta.
- `&&` requiere que se cumplan ambas condiciones.

Para un intent personalizado normalmente se comprueban:

```text
tipo = IntentRequest
Y
nombre = nombre exacto del intent
```

### `handle(handlerInput)`

Se ejecuta cuando `canHandle` devuelve `true`. Aquí se recuperan slots, se aplican condiciones, se accede a DynamoDB y se construye la respuesta.

### Registro y orden de handlers

```javascript
exports.handler = Alexa.SkillBuilders.custom()
    .addRequestHandlers(
        LaunchRequestHandler,
        AddNumberToListIntentHandler,
        HelpIntentHandler,
        CancelAndStopIntentHandler,
        FallbackIntentHandler,
        SessionEndedRequestHandler,
        IntentReflectorHandler
    )
    .addErrorHandlers(ErrorHandler)
    .withCustomUserAgent('sample/hello-world/v1.2')
    .lambda();
```

- `Alexa.SkillBuilders.custom()` inicia el constructor de una skill personalizada.
- `.addRequestHandlers(...)` registra los handlers de solicitudes.
- `.addErrorHandlers(...)` registra el handler de errores.
- `.withCustomUserAgent(...)` añade una identificación del proyecto a las solicitudes del SDK.
- `.lambda()` genera la función que AWS Lambda puede ejecutar.
- `exports.handler` expone esa función como punto de entrada.

El orden importa. `IntentReflectorHandler` acepta cualquier `IntentRequest`, por lo que debe ir después de los handlers específicos; de lo contrario, interceptaría sus solicitudes.

---

## 14. Construcción de la Respuesta

La forma común es:

```javascript
return handlerInput.responseBuilder
    .speak(speakOutput)
    .reprompt(speakOutput)
    .getResponse();
```

### `.speak(texto)`

Define lo que Alexa dirá inmediatamente.

### `.reprompt(texto)`

Define lo que Alexa repetirá si espera otra respuesta y el usuario guarda silencio. Ayuda a mantener la sesión conversacional abierta.

### `.getResponse()`

Finaliza la construcción y devuelve el objeto de respuesta que entiende Alexa.

Sin `reprompt`, una respuesta puede terminar la interacción. En `SessionEndedRequestHandler` se devuelve una respuesta vacía porque la sesión ya acabó:

```javascript
return handlerInput.responseBuilder.getResponse();
```

---

## 15. Handlers Predeterminados

Las plantillas contienen handlers generales que acompañan a los personalizados.

| Handler | Qué reconoce | Función |
|---|---|---|
| `LaunchRequestHandler` | `LaunchRequest` | Responde cuando se abre la skill sin pedir una acción concreta |
| `HelloWorldIntentHandler` | `HelloWorldIntent` | Ejemplo inicial de un intent personalizado |
| `HelpIntentHandler` | `AMAZON.HelpIntent` | Explica qué puede hacer el usuario |
| `CancelAndStopIntentHandler` | `AMAZON.CancelIntent` o `AMAZON.StopIntent` | Finaliza o cancela la interacción |
| `FallbackIntentHandler` | `AMAZON.FallbackIntent` | Atiende frases que no coinciden con intents conocidos |
| `SessionEndedRequestHandler` | `SessionEndedRequest` | Recibe la notificación de cierre de sesión |
| `IntentReflectorHandler` | Cualquier `IntentRequest` restante | Repite el nombre del intent para apoyar pruebas y depuración |
| `ErrorHandler` | Cualquier error | Evita que un fallo quede sin respuesta controlada |

`AMAZON.NavigateHomeIntent` también aparece en el modelo de interacción como intent integrado, aunque no requiere lógica personalizada en los ejemplos estudiados.

---

## 16. Asincronía y Manejo de Errores

Las operaciones con DynamoDB no terminan de inmediato. Por eso los handlers se declaran con `async` y esperan el resultado con `await`:

```javascript
async handle(handlerInput) {
    const result = await dynamoDB.get(params).promise();
}
```

### `.promise()`

Los métodos del cliente usado devuelven una solicitud de AWS. `.promise()` la transforma en una promesa para poder esperarla con `await`.

### `try...catch`

```javascript
try {
    await dynamoDB.update(params).promise();
    speakOutput = 'Datos actualizados';
} catch (err) {
    speakOutput = 'No se pudieron actualizar los datos';
    console.log(err);
    console.error(err);
}
```

- `try` contiene la operación que podría fallar.
- `catch` recibe el error.
- `console.log` y `console.error` permiten revisar el problema en los registros.
- `speakOutput` conserva una respuesta comprensible para el usuario.

---

## 17. Persistencia con DynamoDB

DynamoDB es la base de datos utilizada para conservar información entre invocaciones de la skill. Al crear una skill alojada, se genera una tabla cuyo nombre tiene formato UUID.

![Ubicación del nombre de la tabla de DynamoDB](imagenes/DynamoDB.webp)

### Dónde localizar la tabla

Desde la skill:

1. abra la pestaña **Code**;
2. pulse el icono **Database**;
3. se abrirá la consola de DynamoDB;
4. seleccione la tabla generada;
5. identifique el nombre UUID mostrado en la parte superior.

La documentación oficial también describe este acceso desde el icono de base de datos y ofrece el código de persistencia para Node.js en [Use DynamoDB for Data Persistence with Your Alexa-hosted Skill](https://developer.amazon.com/en-US/docs/alexa/hosted-skills/alexa-hosted-skills-session-persistence.html).

### Forma usada durante la unidad

La tabla real de DynamoDB posee la clave de partición `id`. Dentro de ella se crea un elemento como:

```javascript
{
    id: 'userTable',
    data: [
        { username: 'alex', email: '...', phone: '...' },
        { username: 'raul', email: '...', phone: '...' }
    ]
}
```

En las prácticas se habla de este elemento como si fuera una “tabla lógica”:

- `id` identifica esa colección lógica;
- `data` guarda un arreglo con todos sus registros;
- otro elemento, como `cardTable`, representa otra colección.

Es indispensable distinguir los niveles:

```text
Tabla real de DynamoDB con nombre UUID
└── Elemento de DynamoDB
    ├── id: "cardTable"
    └── data: [tarjeta, tarjeta, ...]
```

Por tanto, un elemento **no es literalmente otra tabla de DynamoDB**. La equivalencia “un registro es una tabla” es una simplificación pedagógica usada en esta unidad. Permite practicar lectura y escritura, pero no representa la organización óptima de DynamoDB.

---

## 18. Operaciones put, get y update

### `dynamoDB.put`

Guarda un elemento completo:

```javascript
await dynamoDB.put({
    TableName: 'UUID_DE_LA_TABLA',
    Item: {
        id: 'userTable',
        data: []
    }
}).promise();
```

- `TableName` es el nombre de la tabla real.
- `Item` es el elemento que se guardará.
- `id` funciona como clave.
- `data` inicia el arreglo.

Si se vuelve a ejecutar `put` con el mismo `id`, se sustituye el elemento existente. Por ello, usarlo en `LaunchRequestHandler` reinicializa los datos cada vez que se abre la skill; en la práctica debe ejecutarse solamente cuando se desea preparar o reiniciar la colección.

### `dynamoDB.get`

Recupera un elemento mediante su clave:

```javascript
const result = await dynamoDB.get({
    TableName: 'UUID_DE_LA_TABLA',
    Key: {
        id: 'userTable'
    }
}).promise();
```

AWS devuelve un objeto con una propiedad `Item`. La destructuración puede renombrarla:

```javascript
let { Item: table } = await dynamoDB.get(params).promise();
```

Esto significa: tomar `Item` y guardarlo en una variable local llamada `table`.

### `dynamoDB.update`

Actualiza el atributo `data` del elemento:

```javascript
await dynamoDB.update({
    TableName: 'UUID_DE_LA_TABLA',
    Key: {
        id: 'userTable'
    },
    UpdateExpression: 'SET #dataField = :newData',
    ExpressionAttributeNames: {
        '#dataField': 'data'
    },
    ExpressionAttributeValues: {
        ':newData': newData
    }
}).promise();
```

Interpretación:

- `Key` localiza el elemento;
- `UpdateExpression` dice qué atributo cambiar;
- `#dataField` es un alias para el nombre real `data`;
- `:newData` es un marcador para el nuevo arreglo;
- los dos mapas separan los nombres y valores de la expresión.

El patrón completo de la unidad es:

```text
get → modificar el arreglo en JavaScript → update
```

---

## 19. Procesamiento de los Registros con JavaScript

### Agregar con spread

```javascript
const newData = [...table.data, userObj];
```

El operador spread copia los elementos existentes y agrega `userObj` al final. No modifica directamente el arreglo recuperado.

### Actualizar con `map`

```javascript
const newData = table.data.map((obj) => {
    if (obj.nickname === nickname.value) {
        return {
            ...obj,
            amount: obj.amount + Number(depositAmount.value)
        };
    }

    return obj;
});
```

`map` recorre todo el arreglo y construye otro de la misma longitud:

- devuelve un objeto nuevo para la tarjeta buscada;
- devuelve el objeto original para las demás.

Después se guarda `newData` con `update`.

### Buscar con `forEach`

```javascript
function buscarPersona(nickname, data) {
    let persona = null;

    data.forEach((obj) => {
        if (obj.nickname === nickname) {
            persona = obj;
        }
    });

    return persona;
}
```

`forEach` ejecuta el callback para cada elemento. La función comienza con `null` y conserva el objeto cuando encuentra una coincidencia.

### Buscar dentro de una transformación con `find`

```javascript
function actualizarListaPersonas(personas, data) {
    return data.map((obj) => {
        const personaActualizada = personas.find(
            (persona) => persona.nickname === obj.nickname
        );

        return personaActualizada || obj;
    });
}
```

- `map` recorre los registros originales.
- `find` busca si existe una versión actualizada con el mismo `nickname`.
- `find` devuelve el objeto encontrado o `undefined`.
- `personaActualizada || obj` selecciona la actualización si existe; de lo contrario conserva el original.

### Conversión con `Number`

Los valores de slot se reciben como texto. Para sumas y restas se convierten:

```javascript
Number(depositAmount.value)
```

Sin conversión, una suma podría concatenar cadenas en lugar de sumar números.

---

## 20. Flujo Completo de una Operación

Una transferencia reúne casi todos los conceptos de la unidad:

1. El usuario pronuncia una utterance del intent de transferencia.
2. Alexa reconoce `TransferIntent`.
3. Recopila `nicknameOrigin`, `nicknameDestination` y `transferAmount`.
4. Confirma los datos y la operación si así se configuró.
5. `TransferIntentHandler.canHandle` acepta la solicitud.
6. `handle` comprueba `confirmationStatus`.
7. `dynamoDB.get` recupera `cardTable`.
8. `buscarPersona` localiza origen y destino.
9. `verificarSaldoDescuento` comprueba que el saldo no quede debajo de cero.
10. Se crean nuevos objetos con los saldos modificados.
11. `actualizarListaPersonas` combina las versiones nuevas con el arreglo original mediante `map` y `find`.
12. `dynamoDB.update` reemplaza `data`.
13. `responseBuilder` informa el resultado al usuario.
14. Si AWS falla, `catch` produce una respuesta de error.

Este flujo muestra la separación de responsabilidades:

```text
Modelo de interacción: entiende y recopila datos
Backend: decide y calcula
DynamoDB: conserva el resultado
```

---

## 21. Diferencias que Debes Memorizar

| Conceptos | Diferencia |
|---|---|
| Nombre de skill / nombre de invocación | El primero identifica el proyecto; el segundo se pronuncia para abrirlo |
| Intent / utterance | El intent es la acción; la utterance es una forma de pedirla |
| Slot / tipo de slot | El slot es la variable concreta; el tipo define qué clase de valor reconoce |
| Filling / validation / confirmation | Solicitar un dato faltante / comprobarlo / preguntar si es correcto |
| Confirmación de slot / confirmación de intent | Confirma un valor / confirma toda la acción |
| Modelo de interacción / backend | Comprende la conversación / ejecuta la lógica |
| `canHandle` / `handle` | Decide si el handler aplica / procesa la solicitud |
| `speak` / `reprompt` | Respuesta inmediata / recordatorio si se espera otra entrada |
| `put` / `get` / `update` | Guardar elemento / obtener elemento / modificar atributos |
| Tabla real / “tabla lógica” de clase | Recurso DynamoDB con UUID / elemento `id` + arreglo `data` |
| `map` / `find` / `forEach` | Transformar todos / obtener la primera coincidencia / ejecutar una acción por elemento |

---

## 22. Preguntas de Repaso

1. ¿Qué pasos ocurren entre la voz del usuario y la respuesta de Alexa?
2. ¿Cuáles son las dos partes esenciales de una skill?
3. ¿Por qué se configura primero el modelo de interacción y después el backend?
4. ¿Qué diferencia existe entre el nombre de la skill y el de invocación?
5. ¿Qué elementos forman el modelo de interacción?
6. ¿Qué representa un intent?
7. ¿Cómo se forma un nombre como `AddNumberToListIntent`?
8. ¿Qué es una utterance?
9. ¿Qué función cumple un slot?
10. ¿Cuándo se usarían `AMAZON.FirstName` y `AMAZON.Corporation`?
11. ¿Cuál es la restricción exacta de `AMAZON.SearchQuery`?
12. ¿Qué significan F, V y C en el diagrama?
13. ¿Qué diferencia existe entre slot confirmation e intent confirmation?
14. ¿Para qué sirven `canHandle` y `handle`?
15. ¿Por qué `IntentReflectorHandler` debe estar al final?
16. ¿Qué hacen `speak`, `reprompt` y `getResponse`?
17. ¿Por qué las operaciones de DynamoDB usan `async`, `await` y `.promise()`?
18. ¿Qué estructura se guardó en `id` y `data`?
19. ¿Por qué esa estructura se considera una simplificación pedagógica?
20. ¿Qué diferencia existe entre `put`, `get` y `update`?
21. ¿Cómo actualiza `map` solamente una tarjeta sin perder las demás?
22. ¿Por qué se usa `Number` con las cantidades recibidas desde slots?
