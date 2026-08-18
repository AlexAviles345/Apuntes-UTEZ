# Práctica — Unidad 2: Creación de Skills de Alexa con Node.js y DynamoDB

Esta guía aplica paso a paso lo estudiado en la Unidad 2. Sigue el orden de trabajo usado en clase: crear la skill, configurar el nombre de invocación, construir el modelo de interacción, programar el backend y finalmente probar la persistencia.

---

## Tabla de Contenidos

1. [Preparación y Orden de Trabajo](#1-preparación-y-orden-de-trabajo)
2. [Práctica 1 — Crear la Skill](#2-práctica-1--crear-la-skill)
3. [Práctica 2 — Configurar el Nombre de Invocación](#3-práctica-2--configurar-el-nombre-de-invocación)
4. [Práctica 3 — Diseñar Intents, Utterances y Slots](#4-práctica-3--diseñar-intents-utterances-y-slots)
5. [Práctica 4 — Configurar Filling, Validation y Confirmation](#5-práctica-4--configurar-filling-validation-y-confirmation)
6. [Práctica 5 — Programar un Handler](#6-práctica-5--programar-un-handler)
7. [Práctica 6 — Validar una Edad](#7-práctica-6--validar-una-edad)
8. [Práctica 7 — Registrar Usuarios en DynamoDB](#8-práctica-7--registrar-usuarios-en-dynamodb)
9. [Práctica 8 — Administrar una Cartera Digital](#9-práctica-8--administrar-una-cartera-digital)
10. [Funciones Auxiliares de la Cartera](#10-funciones-auxiliares-de-la-cartera)
11. [Handlers Generales y Punto de Entrada](#11-handlers-generales-y-punto-de-entrada)
12. [Matriz de Pruebas](#12-matriz-de-pruebas)
13. [Errores Frecuentes y Cómo Rastrearlos](#13-errores-frecuentes-y-cómo-rastrearlos)
14. [Referencia de Funciones y Métodos](#14-referencia-de-funciones-y-métodos)
15. [Ejercicios de Repaso](#15-ejercicios-de-repaso)

---

## 1. Preparación y Orden de Trabajo

No conviene comenzar por el código. El backend depende de los nombres creados en el modelo de interacción.

```text
Crear skill
    ↓
Configurar nombre de invocación
    ↓
Crear intents
    ↓
Agregar utterances
    ↓
Agregar slots y configurar diálogo
    ↓
Guardar y construir el modelo
    ↓
Programar handlers con los mismos nombres
    ↓
Desplegar y probar
```

Antes de programar cada intent, complete esta tabla:

| Pregunta | Ejemplo |
|---|---|
| ¿Qué acción realizará? | Agregar un número a una lista |
| ¿Cómo se llamará? | `AddNumberToListIntent` |
| ¿Cómo podría pedirla el usuario? | “agrega un número a la lista” |
| ¿Qué datos necesita? | `number` |
| ¿Qué tipo tiene cada dato? | `AMAZON.NUMBER` |
| ¿Es obligatorio? | Sí: filling |
| ¿Debe validarse? | Sí: mayor o igual a cero |
| ¿Debe confirmarse? | Sí |
| ¿Qué handler la ejecutará? | `AddNumberToListIntentHandler` |

---

## 2. Práctica 1 — Crear la Skill

### Paso 1. Nombre y configuración regional

1. Entre a Alexa Developer Console.
2. Cree una nueva skill.
3. Escriba un nombre de proyecto que le permita identificarla.
4. En **Primary locale**, seleccione **Spanish (Mexico)**.
5. Pulse **Next**.

El nombre escrito aquí identifica el proyecto. El nombre que se pronunciará se configura después.

### Paso 2. Experiencia, modelo y alojamiento

Seleccione:

1. **Other** en tipo de experiencia.
2. **Custom** en modelo.
3. **Alexa-hosted (Node.js)** en servicio de alojamiento.
4. **US East (N. Virginia)** en región.
5. Pulse **Next**.

`Custom` es necesario para definir intents y slots propios. `Alexa-hosted (Node.js)` proporciona el editor, el despliegue y los recursos de AWS usados en la unidad.

### Paso 3. Plantilla

1. Seleccione **Start from Scratch**.
2. Pulse **Next**.
3. Revise que aparezcan las selecciones anteriores.
4. Pulse **Create Skill**.

Referencia visual del resultado esperado:

![Resumen de configuración inicial](imagenes/Configuracion%20inicial%20de%20skill%20de%20Alexa.webp)

### Lista de comprobación

- [ ] Idioma: Spanish (Mexico)
- [ ] Tipo: Other
- [ ] Modelo: Custom
- [ ] Hosting: Alexa-hosted (Node.js)
- [ ] Región: US East (N. Virginia)
- [ ] Plantilla: Start from Scratch

---

## 3. Práctica 2 — Configurar el Nombre de Invocación

1. Abra la pestaña **Build**.
2. Entre a **Invocation**.
3. Escriba el nombre de invocación.
4. Prefiera una expresión descriptiva en inglés, como `listed numbers` o `user registration`.
5. Guarde el modelo.

El valor aparece en el JSON como:

```json
"languageModel": {
  "invocationName": "listed numbers"
}
```

### Comprobación

La invocación y el nombre visible del proyecto son independientes. Una skill llamada internamente “Práctica de números” puede abrirse con:

```text
Alexa, abre listed numbers
```

No añada todavía lógica al backend. Primero se deben definir las acciones que podrá reconocer el modelo.

---

## 4. Práctica 3 — Diseñar Intents, Utterances y Slots

Se construirá un intent para agregar un número.

### Paso 1. Crear el intent

Nombre:

```text
AddNumberToListIntent
```

Descomposición:

```text
Add       Number       To List       Intent
acción    dato/módulo  objetivo      tipo de componente
```

### Paso 2. Agregar frases de ejemplo

```text
agrega un número
quiero agregar un número
agrega el número {number} a la lista
```

Las dos primeras permiten activar la acción sin proporcionar todavía el valor. La tercera activa la acción y llena el slot desde la misma frase.

### Paso 3. Crear el slot

| Propiedad | Valor |
|---|---|
| Nombre | `number` |
| Tipo | `AMAZON.NUMBER` |

Frases del slot:

```text
el número es {number}
añade {number}
quiero agregar {number}
```

### Representación parcial en JSON

```json
{
  "name": "AddNumberToListIntent",
  "slots": [
    {
      "name": "number",
      "type": "AMAZON.NUMBER",
      "samples": [
        "el número es {number}",
        "añade {number}",
        "quiero agregar {number}"
      ]
    }
  ],
  "samples": [
    "agrega un número",
    "quiero agregar un número",
    "agrega el número {number} a la lista"
  ]
}
```

### Tipos de cadena usados

Cuando el dato es una cadena, seleccione el tipo según su contexto:

```text
Nombre o alias           → AMAZON.FirstName
Empresa o banco          → AMAZON.Corporation
Texto abierto inevitable → AMAZON.SearchQuery
```

Para `AMAZON.SearchQuery`, no coloque otro slot dentro de la misma frase:

```text
Correcto:   busca {query}
Incorrecto: envía {query} al teléfono {phone}
```

El intent puede poseer otros slots, pero deben aparecer en frases de ejemplo separadas. Solo puede tener un `AMAZON.SearchQuery`.

---

## 5. Práctica 4 — Configurar Filling, Validation y Confirmation

Para el slot `number`, active las tres configuraciones.

### Slot filling

Marque el slot como obligatorio y agregue prompts como:

```text
¿Qué número deseas agregar?
Necesito un número para realizar la acción.
```

También agregue frases del usuario que contengan el slot:

```text
el número es {number}
quiero agregar {number}
```

### Slot validation

Configure una regla `isGreaterThanOrEqualTo` con valor `0`.

Prompts:

```text
El valor {number} debe ser mayor a cero.
No puedes añadir valores negativos a la lista.
```

La validación pertenece al modelo de diálogo: Alexa puede rechazar el valor y volver a pedirlo antes de ejecutar el backend.

### Slot confirmation

Active la confirmación del slot y escriba:

```text
Agregaré el número {number} a la lista. ¿Es correcto?
¿Estás seguro de que deseas agregar el número {number}?
```

### Intent confirmation

Active la confirmación del intent:

```text
¿Confirmas que se agregue el valor {number} a la lista?
```

### Lectura gráfica

![Diagrama con filling, validation y confirmation](imagenes/Ejemplo%20diagrama%20de%20modelo%20de%20interacci%C3%B3n.webp)

Al diseñar su propio diagrama:

- coloque una **F roja** junto a todo slot obligatorio;
- coloque una **V amarilla** junto a todo slot validado;
- coloque una **C verde** junto a todo slot que Alexa deba confirmar;
- dibuje `IntentConfirmation` aparte cuando deba confirmarse toda la acción;
- conecte el intent con un handler del mismo nombre más el sufijo `Handler`.

### Guardar y construir

1. Pulse **Save Model**.
2. Pulse **Build Model**.
3. Espere a que la construcción termine sin errores.
4. No pase al backend si los nombres del modelo todavía cambian.

---

## 6. Práctica 5 — Programar un Handler

Abra **Code** y localice `index.js`.

### Cargar el SDK

```javascript
const Alexa = require('ask-sdk-core');
```

### Crear el handler

```javascript
const AddNumberToListIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'AddNumberToListIntent';
    },

    handle(handlerInput) {
        const { intent } = handlerInput.requestEnvelope.request;
        const { number } = intent.slots;
        let speakOutput;

        if (intent.confirmationStatus === 'CONFIRMED') {
            speakOutput = `Agregué el número ${number.value} a la lista`;
        } else {
            speakOutput = 'Cancelé la operación';
        }

        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};
```

### Explicación detallada

1. `AddNumberToListIntentHandler` es un objeto.
2. `canHandle` recibe el contexto de la solicitud.
3. `getRequestType` verifica que Alexa envió un intent y no una apertura o cierre.
4. `getIntentName` compara el nombre exacto con el modelo.
5. La destructuración obtiene `intent` desde `request`.
6. Otra destructuración obtiene `number` desde `intent.slots`.
7. `confirmationStatus` indica la respuesta a la confirmación del intent.
8. `number.value` contiene el dato reconocido.
9. El *template literal* inserta el valor en la respuesta.
10. `speak` define el mensaje principal.
11. `reprompt` conserva un mensaje para una sesión que continúe esperando.
12. `getResponse` devuelve la respuesta completa.

### Registrar el handler

Agregue el objeto a `.addRequestHandlers(...)` antes del reflector:

```javascript
.addRequestHandlers(
    LaunchRequestHandler,
    AddNumberToListIntentHandler,
    HelpIntentHandler,
    CancelAndStopIntentHandler,
    FallbackIntentHandler,
    SessionEndedRequestHandler,
    IntentReflectorHandler
)
```

Si no se registra, el modelo podrá reconocer el intent, pero su handler nunca se ejecutará.

---

## 7. Práctica 6 — Validar una Edad

Esta práctica muestra una decisión en el backend.

### Modelo

| Elemento | Configuración |
|---|---|
| Intent | `AgeValidationIntent` |
| Slot | `agePerson` |
| Tipo | `AMAZON.NUMBER` |
| Filling | Activado |

Utterances:

```text
quiero validar una edad
valida la edad {agePerson}
la edad es {agePerson}
```

### Backend

```javascript
const AgeValidationIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'AgeValidationIntent';
    },

    handle(handlerInput) {
        const { agePerson } = handlerInput.requestEnvelope.request.intent.slots;
        let speakOutput;

        if (agePerson.value >= 18) {
            speakOutput = 'La edad corresponde a una persona mayor de edad';
        } else {
            speakOutput = 'La edad corresponde a una persona menor de edad';
        }

        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};
```

El slot se recupera en una sola destructuración. La condición compara el valor con 18 y selecciona una de dos respuestas.

Para hacer explícita la conversión numérica usada en otras partes de la unidad puede escribirse:

```javascript
if (Number(agePerson.value) >= 18) {
```

---

## 8. Práctica 7 — Registrar Usuarios en DynamoDB

Esta práctica introduce persistencia con un elemento `userTable` y un arreglo `data`.

### 8.1 Modelo de interacción

| Slot | Tipo | Filling | Confirmation |
|---|---|---:|---:|
| `username` | `AMAZON.FirstName` | Sí | Sí |
| `email` | `AMAZON.SearchQuery` | Sí | Sí |
| `phone` | `AMAZON.PhoneNumber` | Sí | Sí |

Intent:

```text
AddUserIntent
```

Frases generales que no mezclan el slot abierto con otros slots:

```text
quiero registrar un usuario
agrega un nuevo usuario
crea un usuario con el nombre {username}
crea un usuario con el número de teléfono {phone}
```

`email` se solicita mediante filling. Al ser `AMAZON.SearchQuery`, se evita combinarlo con `username` o `phone` dentro de una misma frase de ejemplo.

### 8.2 Localizar la tabla

1. Entre a **Code**.
2. Pulse el icono de **Database**.
3. En DynamoDB, abra la tabla generada.
4. Copie con cuidado el nombre UUID de la tabla.

![Nombre UUID de una tabla Alexa-hosted](imagenes/DynamoDB.webp)

### 8.3 Crear el cliente

En la parte superior de `index.js`:

```javascript
const Alexa = require('ask-sdk-core');
const AWS = require('aws-sdk');

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = 'UUID_DE_LA_TABLA';
```

`TABLE_NAME` evita repetir manualmente el UUID en cada operación. El código base para persistencia también puede consultarse en la guía oficial de Alexa sobre [DynamoDB para una skill alojada](https://developer.amazon.com/en-US/docs/alexa/hosted-skills/alexa-hosted-skills-session-persistence.html). Para reproducir exactamente el enfoque de la unidad se utiliza `DocumentClient` con `put`, `get` y `update`.

### 8.4 Inicializar la colección lógica

```javascript
await dynamoDB.put({
    TableName: TABLE_NAME,
    Item: {
        id: 'userTable',
        data: []
    }
}).promise();
```

Esta operación crea un elemento:

```text
id   = userTable
data = arreglo vacío
```

En el ejercicio se le llama “tabla de usuarios”, aunque técnicamente es un elemento dentro de la tabla DynamoDB. Ejecute esta inicialización una vez. Si la coloca en la apertura y vuelve a abrir la skill, `put` con el mismo `id` puede sustituir los datos guardados.

### 8.5 Recuperar slots y formar el usuario

```javascript
const { intent } = handlerInput.requestEnvelope.request;
const { username, email, phone } = intent.slots;

const userObj = {
    username: username.value,
    email: email.value,
    phone: phone.value
};
```

El objeto separa los datos del formato interno de Alexa y deja solamente los valores que se guardarán.

### 8.6 Leer el elemento

```javascript
let { Item: table } = await dynamoDB.get({
    TableName: TABLE_NAME,
    Key: {
        id: 'userTable'
    }
}).promise();
```

El resultado normal sería conceptualmente:

```javascript
{
    Item: {
        id: 'userTable',
        data: []
    }
}
```

`{ Item: table }` renombra `Item` como `table`, de modo que el arreglo queda disponible en `table.data`.

### 8.7 Agregar sin perder usuarios previos

```javascript
const newData = [...table.data, userObj];
```

El spread copia todos los usuarios existentes y añade el nuevo al final.

### 8.8 Actualizar `data`

```javascript
await dynamoDB.update({
    TableName: TABLE_NAME,
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

### 8.9 Handler integrado

```javascript
const AddUserIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'AddUserIntent';
    },

    async handle(handlerInput) {
        const { intent } = handlerInput.requestEnvelope.request;
        const { username, email, phone } = intent.slots;
        let speakOutput;

        const userObj = {
            username: username.value,
            email: email.value,
            phone: phone.value
        };

        try {
            let { Item: table } = await dynamoDB.get({
                TableName: TABLE_NAME,
                Key: { id: 'userTable' }
            }).promise();

            const newData = [...table.data, userObj];

            await dynamoDB.update({
                TableName: TABLE_NAME,
                Key: { id: 'userTable' },
                UpdateExpression: 'SET #dataField = :newData',
                ExpressionAttributeNames: {
                    '#dataField': 'data'
                },
                ExpressionAttributeValues: {
                    ':newData': newData
                }
            }).promise();

            speakOutput = 'Usuario agregado a la lista';
        } catch (err) {
            speakOutput = 'No pude actualizar los usuarios';
            console.log(err);
            console.error(err);
        }

        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};
```

`async` es obligatorio porque el handler usa `await`. `try...catch` separa la respuesta de éxito de la de error.

---

## 9. Práctica 8 — Administrar una Cartera Digital

La colección lógica de tarjetas tiene la forma:

```javascript
{
    id: 'cardTable',
    data: [
        {
            nickname: 'alex',
            numberCard: '1234123412341234',
            bankName: 'Banamex',
            amount: 5000
        }
    ]
}
```

### 9.1 Agregar una tarjeta

Slots necesarios:

- `nickname`;
- `numberCard`;
- `bankName`.

```javascript
const cardObj = {
    nickname: nickname.value,
    numberCard: numberCard.value,
    bankName: bankName.value,
    amount: 0
};
```

La acción se ejecuta solo al confirmarse:

```javascript
if (intent.confirmationStatus === 'CONFIRMED') {
    let { Item: table } = await dynamoDB.get({
        TableName: TABLE_NAME,
        Key: { id: 'cardTable' }
    }).promise();

    const newData = [...table.data, cardObj];

    await dynamoDB.update({
        TableName: TABLE_NAME,
        Key: { id: 'cardTable' },
        UpdateExpression: 'SET #dataField = :newData',
        ExpressionAttributeNames: {
            '#dataField': 'data'
        },
        ExpressionAttributeValues: {
            ':newData': newData
        }
    }).promise();
} else {
    speakOutput = 'Cancelé el registro de la tarjeta';
}
```

### 9.2 Depositar

Slots:

- `nickname` para localizar la tarjeta;
- `depositAmount` para conocer el importe.

```javascript
const newData = table.data.map((obj) => {
    if (obj.nickname === nickname.value) {
        speakOutput = `Realicé el depósito de ${depositAmount.value}`;

        return {
            nickname: obj.nickname,
            numberCard: obj.numberCard,
            bankName: obj.bankName,
            amount: obj.amount + Number(depositAmount.value)
        };
    }

    return obj;
});
```

`map` debe devolver algo en todas sus rutas. Si la tarjeta coincide, devuelve la versión actualizada; si no, devuelve `obj`. Así se conserva la longitud y no desaparecen registros.

### 9.3 Retirar

Slots:

- `nickname`;
- `withdrawalAmount`.

La condición impide un saldo negativo:

```javascript
const newData = table.data.map((obj) => {
    if (obj.nickname !== nickname.value) {
        return obj;
    }

    const nuevoSaldo = Number(obj.amount) - Number(withdrawalAmount.value);

    if (nuevoSaldo < 0) {
        speakOutput = `La cuenta ${nickname.value} tiene saldo insuficiente`;
        return obj;
    }

    speakOutput = `Retiro realizado. El saldo restante es ${nuevoSaldo}`;

    return {
        nickname: obj.nickname,
        numberCard: obj.numberCard,
        bankName: obj.bankName,
        amount: nuevoSaldo
    };
});
```

La resta convierte ambos valores. Aunque `amount` ya suele ser numérico, la conversión explícita deja clara la operación.

### 9.4 Transferir

Slots:

- `nicknameOrigin`;
- `nicknameDestination`;
- `transferAmount`.

Secuencia:

```text
Leer cardTable
    ↓
Buscar tarjeta de origen
    ↓
Buscar tarjeta de destino
    ↓
Comprobar que ambas existen
    ↓
Comprobar saldo del origen
    ↓
Crear dos objetos actualizados
    ↓
Combinar con la lista original
    ↓
Guardar data
```

Núcleo de la operación:

```javascript
const personaOrigen = buscarPersona(nicknameOrigin.value, table.data);
const personaDestino = buscarPersona(nicknameDestination.value, table.data);

if (personaOrigen !== null && personaDestino !== null) {
    const puedeTransferir = verificarSaldoDescuento(
        personaOrigen,
        transferAmount.value
    );

    if (puedeTransferir) {
        const newPersonaOrigen = {
            ...personaOrigen,
            amount: Number(personaOrigen.amount) - Number(transferAmount.value)
        };

        const newPersonaDestino = {
            ...personaDestino,
            amount: Number(personaDestino.amount) + Number(transferAmount.value)
        };

        const newData = actualizarListaPersonas(
            [newPersonaOrigen, newPersonaDestino],
            table.data
        );

        await dynamoDB.update({
            TableName: TABLE_NAME,
            Key: { id: 'cardTable' },
            UpdateExpression: 'SET #dataField = :newData',
            ExpressionAttributeNames: {
                '#dataField': 'data'
            },
            ExpressionAttributeValues: {
                ':newData': newData
            }
        }).promise();
    }
}
```

La transferencia modifica dos objetos, no solamente uno. Por eso se construye un arreglo con ambas versiones actualizadas, se combina con todos los registros y se ejecuta directamente `dynamoDB.update`, igual que en las demás operaciones de la cartera.

---

## 10. Funciones Auxiliares de la Cartera

### `buscarPersona(nickname, data)`

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

Funcionamiento:

1. recibe el alias buscado y el arreglo completo;
2. inicia `persona` con `null`, que significa “sin resultado”;
3. `forEach` visita cada tarjeta;
4. `===` compara los alias;
5. si encuentra coincidencia, guarda el objeto;
6. devuelve el objeto o `null`.

### `verificarSaldoDescuento(obj, amount)`

```javascript
function verificarSaldoDescuento(obj, amount) {
    let tieneSaldo = false;

    if (Number(obj.amount) - Number(amount) >= 0) {
        tieneSaldo = true;
    }

    return tieneSaldo;
}
```

Funcionamiento:

1. recibe la tarjeta y la cantidad;
2. convierte ambos valores a número;
3. simula la resta;
4. devuelve `true` si el resultado no es negativo;
5. devuelve `false` en caso contrario.

### `actualizarListaPersonas(personas, data)`

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

Funcionamiento:

1. `data.map` crea el arreglo que se guardará.
2. Por cada registro original, `find` busca una actualización con el mismo alias.
3. Si la encuentra, `personaActualizada` contiene un objeto y es *truthy*.
4. Si no la encuentra, vale `undefined`, que es *falsy*.
5. `personaActualizada || obj` elige la actualización o conserva el original.
6. El resultado mantiene el orden y la cantidad de elementos.

---

## 11. Handlers Generales y Punto de Entrada

### `LaunchRequestHandler`

Reconoce una apertura sin intent específico:

```javascript
Alexa.getRequestType(handlerInput.requestEnvelope) === 'LaunchRequest'
```

Debe dar la bienvenida o explicar cómo comenzar. Si se usa para inicializar DynamoDB, recuerde que un `put` repetido con la misma clave sustituye el contenido.

### `HelpIntentHandler`

Reconoce `AMAZON.HelpIntent` y ofrece instrucciones. Normalmente usa `reprompt` porque espera que el usuario continúe.

### `CancelAndStopIntentHandler`

Acepta dos intents:

```javascript
Alexa.getIntentName(envelope) === 'AMAZON.CancelIntent'
    || Alexa.getIntentName(envelope) === 'AMAZON.StopIntent'
```

`||` permite que cualquiera de las dos condiciones active el handler.

### `FallbackIntentHandler`

Atiende `AMAZON.FallbackIntent` cuando una frase no se relaciona con las acciones conocidas.

### `SessionEndedRequestHandler`

Reconoce `SessionEndedRequest`, registra el sobre completo y devuelve una respuesta vacía:

```javascript
console.log(JSON.stringify(handlerInput.requestEnvelope));
return handlerInput.responseBuilder.getResponse();
```

`JSON.stringify` convierte el objeto en texto para visualizarlo en los registros.

### `IntentReflectorHandler`

Acepta cualquier `IntentRequest` que no fue atendido antes. Obtiene el nombre y lo dice, por lo que ayuda a detectar intents reconocidos pero sin handler propio.

### `ErrorHandler`

Su `canHandle()` siempre devuelve `true`, porque es el último recurso para errores. `handle(handlerInput, error)` recibe tanto el contexto como el error y devuelve una respuesta controlada.

### Punto de entrada completo

```javascript
exports.handler = Alexa.SkillBuilders.custom()
    .addRequestHandlers(
        LaunchRequestHandler,
        AddNumberToListIntentHandler,
        AgeValidationIntentHandler,
        AddUserIntentHandler,
        AddNewCardIntentHandler,
        DepositIntentHandler,
        WithdrawalIntentHandler,
        TransferIntentHandler,
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

No todas las prácticas tienen que incluir todos esos handlers al mismo tiempo. El ejemplo muestra dónde se colocaría cada uno. Registre solamente los handlers que correspondan a los intents presentes en el modelo, además de los generales necesarios.

---

## 12. Matriz de Pruebas

Después de guardar y desplegar el código, pruebe rutas de éxito, cancelación y error.

### Números

| Entrada | Resultado esperado |
|---|---|
| “agrega el número cinco a la lista” | Alexa recopila y confirma el número |
| “agrega un número” | Alexa solicita el slot faltante |
| número negativo | La validación lo rechaza y vuelve a preguntar |
| responder “no” a la confirmación | El backend informa que canceló |

### Edad

| Entrada | Resultado esperado |
|---|---|
| 18 | Mayor de edad |
| 25 | Mayor de edad |
| 17 | Menor de edad |

### Usuarios

| Caso | Comprobación |
|---|---|
| Alta completa | `data` contiene el nuevo objeto |
| Abrir nuevamente la skill | Los registros no deberían reinicializarse accidentalmente |
| Falla de DynamoDB | Alexa emite el mensaje de `catch` y el error aparece en logs |

### Cartera

| Caso | Resultado esperado |
|---|---|
| Agregar tarjeta confirmada | Se añade con saldo 0 |
| Cancelar alta | No se modifica `data` |
| Depositar en tarjeta existente | Aumenta el saldo |
| Depositar en alias inexistente | Se conserva el mensaje de “no existe” |
| Retirar una cantidad válida | Disminuye el saldo |
| Retirar más que el saldo | No cambia el objeto |
| Transferir entre dos aliases válidos | Resta al origen y suma al destino |
| Origen o destino inexistente | No se guarda la transferencia |

---

## 13. Errores Frecuentes y Cómo Rastrearlos

### El intent llega al reflector

Revise:

1. que el nombre del modelo y el de `getIntentName` sean idénticos;
2. que el handler esté registrado;
3. que esté antes de `IntentReflectorHandler`.

### El slot es `undefined`

Compruebe:

- el nombre exacto del slot;
- que el modelo haya sido guardado y construido;
- que la utterance incluya el slot o que filling esté configurado;
- que se acceda por `intent.slots.nombre.value`.

### `SearchQuery` impide construir el modelo

Revise que:

- exista como máximo uno por intent;
- una misma utterance no lo combine con otro slot;
- la frase general tenga palabras de contexto.

### DynamoDB responde con error

Compruebe:

1. el UUID copiado en `TableName`;
2. el valor de `id` usado en `Key`;
3. que el elemento se haya inicializado;
4. que el handler sea `async`;
5. que la llamada termine en `.promise()`;
6. los registros mostrados por `console.log(err)`.

### Los datos desaparecen al abrir la skill

Un `put` con el mismo `id` sustituye el elemento. No inicialice `userTable` o `cardTable` en cada apertura si necesita conservar los registros.

### La cantidad se concatena

Si el slot entrega `'50'` como cadena:

```javascript
500 + '50' // '50050'
```

Conviértalo:

```javascript
500 + Number('50') // 550
```

### `map` produce elementos `undefined`

El callback debe devolver el registro tanto cuando coincide como cuando no:

```javascript
return objetoActualizado;
// o
return obj;
```

---

## 14. Referencia de Funciones y Métodos

| Elemento | Recibe | Devuelve o produce | Uso en la skill |
|---|---|---|---|
| `require` | Nombre de paquete | Módulo cargado | Cargar ASK SDK y AWS SDK |
| `Alexa.getRequestType` | `requestEnvelope` | Tipo de solicitud | Distinguir apertura, intent y cierre |
| `Alexa.getIntentName` | `requestEnvelope` | Nombre del intent | Elegir el handler específico |
| `canHandle` | `handlerInput` | Booleano | Determinar si un handler aplica |
| `handle` | `handlerInput` | Respuesta o promesa de respuesta | Ejecutar la lógica |
| `.speak` | Texto | El mismo builder | Definir lo que Alexa dice |
| `.reprompt` | Texto | El mismo builder | Definir recordatorio si espera entrada |
| `.getResponse` | Nada | Objeto de respuesta | Terminar la respuesta |
| `Alexa.SkillBuilders.custom` | Nada | Constructor de skill | Iniciar configuración del backend |
| `.addRequestHandlers` | Handlers | Constructor | Registrar solicitudes en orden |
| `.addErrorHandlers` | Handler de error | Constructor | Registrar captura de errores |
| `.withCustomUserAgent` | Identificador | Constructor | Identificar el proyecto ante el SDK |
| `.lambda` | Nada | Función ejecutable | Crear punto de entrada para Lambda |
| `AWS.DynamoDB.DocumentClient` | Configuración opcional | Cliente DynamoDB | Trabajar con objetos JavaScript |
| `dynamoDB.put` | Tabla e item | Solicitud AWS | Guardar o sustituir un elemento |
| `dynamoDB.get` | Tabla y clave | Solicitud AWS | Recuperar un elemento |
| `dynamoDB.update` | Tabla, clave y expresión | Solicitud AWS | Modificar el atributo `data` |
| `.promise` | Nada | Promesa | Usar una solicitud AWS con `await` |
| `Number` | Valor | Número | Convertir cantidades de slots |
| `JSON.stringify` | Objeto | Cadena JSON | Mostrar solicitudes o errores en logs |
| `forEach` | Callback | `undefined` | Recorrer para localizar y asignar |
| `map` | Callback | Nuevo arreglo | Reconstruir `data` con cambios |
| `find` | Predicado | Primer elemento o `undefined` | Localizar una versión actualizada |
| `buscarPersona` | Alias y arreglo | Objeto o `null` | Encontrar una tarjeta |
| `verificarSaldoDescuento` | Tarjeta y monto | Booleano | Evitar saldo negativo |
| `actualizarListaPersonas` | Actualizaciones y arreglo | Nuevo arreglo | Sustituir origen y destino |

---

## 15. Ejercicios de Repaso

### Ejercicio 1 — Diseñar antes de programar

Para una acción “consultar saldo”, escriba únicamente con elementos vistos:

1. nombre del intent en inglés;
2. tres utterances;
3. slot necesario;
4. tipo del slot;
5. configuración F, V o C;
6. nombre del handler.

### Ejercicio 2 — Explicar una solicitud

Trace la frase:

```text
transfiere cien pesos de alex a raul
```

Indique:

- intent;
- tres slots;
- valores;
- handler;
- lectura en DynamoDB;
- funciones auxiliares;
- actualización;
- respuesta.

### Ejercicio 3 — Detectar el error

```javascript
const newData = table.data.map((obj) => {
    if (obj.nickname === nickname.value) {
        return { ...obj, amount: obj.amount + depositAmount.value };
    }
});
```

Explique los dos problemas:

1. falta devolver `obj` cuando no coincide;
2. falta convertir `depositAmount.value` con `Number`.

### Ejercicio 4 — Explicar DynamoDB

Dibuje y explique la diferencia entre:

```text
tabla UUID
elemento id = cardTable
atributo data
objetos de tarjeta
```

### Ejercicio 5 — Confirmación

Describa qué sucede cuando:

1. Alexa confirma un slot;
2. el usuario corrige el valor;
3. Alexa confirma el intent;
4. el usuario responde “no”;
5. el backend revisa `confirmationStatus`.
