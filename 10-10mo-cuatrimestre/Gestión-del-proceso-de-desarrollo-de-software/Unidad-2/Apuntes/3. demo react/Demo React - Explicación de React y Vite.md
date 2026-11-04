# Demo React — Explicación de React y Vite

Esta guía explica cómo funciona la aplicación de [`front/`](front/): cómo inicia React, cómo se guarda el estado del formulario, cómo se procesan los cambios y qué función cumplen Vite y Bootstrap.

Para publicar el proyecto en EC2, consulta la [Guía de despliegue — Demo React con Docker](Guia%20de%20despliegue%20-%20Demo%20React%20con%20Docker.md).

---

## Tabla de Contenidos

1. [Objetivo de la Aplicación](#1-objetivo-de-la-aplicación)
2. [Tecnologías Utilizadas](#2-tecnologías-utilizadas)
3. [Organización del Código](#3-organización-del-código)
4. [Recorrido de Inicio](#4-recorrido-de-inicio)
5. [Explicación de main.jsx](#5-explicación-de-mainjsx)
6. [Explicación de App.jsx](#6-explicación-de-appjsx)
7. [Estado con useState](#7-estado-con-usestate)
8. [Eventos y handleChange](#8-eventos-y-handlechange)
9. [Entradas Controladas](#9-entradas-controladas)
10. [JSX y Bootstrap](#10-jsx-y-bootstrap)
11. [Vite y los Scripts de npm](#11-vite-y-los-scripts-de-npm)
12. [Ejecutar en Desarrollo](#12-ejecutar-en-desarrollo)
13. [Qué Hace y Qué no Hace la Práctica](#13-qué-hace-y-qué-no-hace-la-práctica)
14. [Conceptos para Recordar](#14-conceptos-para-recordar)
15. [Preguntas de Repaso](#15-preguntas-de-repaso)

---

## 1. Objetivo de la Aplicación

La pantalla presenta un formulario para capturar:

- nombre;
- apellido paterno;
- apellido materno;
- edad;
- sexo.

La finalidad es practicar cómo React conserva los datos escritos y actualiza la interfaz. La aplicación todavía no envía el formulario a un backend ni lo guarda en una base de datos.

```text
Persona escribe en un campo
          │
          ▼
React recibe el evento onChange
          │
          ▼
handleChange identifica el campo
          │
          ▼
setForm actualiza el estado
          │
          ▼
React vuelve a representar la pantalla
```

---

## 2. Tecnologías Utilizadas

| Tecnología | Función en la práctica |
|---|---|
| React | Construye la interfaz mediante componentes y estado |
| React DOM | Inserta la aplicación React en el documento HTML |
| Vite | Ejecuta el servidor de desarrollo y crea la versión de producción |
| Bootstrap | Proporciona clases visuales para formulario, columnas y tarjeta |
| ESLint | Revisa reglas y posibles problemas del código |
| npm | Instala dependencias y ejecuta scripts |

Las dependencias y scripts están declarados en [`front/package.json`](front/package.json). Las versiones exactas instaladas por `npm ci` se registran en `package-lock.json`.

---

## 3. Organización del Código

```text
front/
├── index.html              documento HTML inicial
├── package.json            dependencias y comandos
├── package-lock.json       versiones exactas
├── vite.config.js          configuración de Vite y React
├── eslint.config.js        reglas de análisis
├── public/                 recursos públicos
└── src/
    ├── main.jsx            punto de entrada de React
    └── App.jsx             componente del formulario
```

Los archivos de despliegue, como `Dockerfile` y `.dockerignore`, se explican en la guía de Docker.

---

## 4. Recorrido de Inicio

```text
index.html
    │ contiene <div id="root">
    │ carga /src/main.jsx
    ▼
main.jsx
    │ busca el elemento root
    │ crea la raíz de React
    ▼
<StrictMode>
    │ ejecuta <App />
    ▼
App.jsx
    └── devuelve el formulario
```

`index.html` no contiene todos los campos. Solo prepara el punto donde React dibujará la aplicación:

```html
<div id="root"></div>
<script type="module" src="/src/main.jsx"></script>
```

`type="module"` permite utilizar `import` y `export`.

---

## 5. Explicación de `main.jsx`

```jsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '/node_modules/bootstrap/dist/css/bootstrap.min.css'
import App from './App.jsx'
```

### Importaciones

- `StrictMode` activa comprobaciones adicionales durante el desarrollo.
- `createRoot` crea el punto donde React controla la interfaz.
- Bootstrap agrega los estilos CSS.
- `App` es el componente principal.

```jsx
createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
```

El recorrido es:

1. `document.getElementById('root')` busca el elemento HTML.
2. `createRoot()` entrega ese elemento a React.
3. `render()` solicita mostrar el componente `App`.
4. `StrictMode` envuelve la aplicación durante el desarrollo.

`StrictMode` puede ejecutar algunas operaciones más de una vez en modo de desarrollo para detectar efectos inesperados. Por eso ciertos mensajes de `console.log` pueden repetirse; la compilación de producción no conserva ese comportamiento de comprobación.

---

## 6. Explicación de `App.jsx`

```jsx
import { useState } from "react";

export default function App() {
  // estado y funciones
  return (/* interfaz */);
}
```

`App` es un **componente funcional**: una función que devuelve JSX.

`export default` permite importarlo en otro archivo sin llaves:

```jsx
import App from './App.jsx'
```

Cada vez que cambia su estado, React vuelve a llamar al componente para calcular la interfaz actualizada.

---

## 7. Estado con `useState`

```jsx
const [form, setForm] = useState({
  name: undefined,
  surname: undefined,
  lastname: undefined,
  age: 0,
  sex: 0
});
```

`useState()` crea un dato que React conserva entre renderizados.

La desestructuración produce dos elementos:

| Nombre | Función |
|---|---|
| `form` | Contiene los valores actuales |
| `setForm` | Solicita reemplazar el estado y volver a renderizar |

En vez de tener cinco estados separados, la práctica usa un solo objeto:

```text
form
├── name
├── surname
├── lastname
├── age
└── sex
```

El objeto inicial se crea una vez cuando el componente aparece. Después React conserva la versión más reciente.

`age` y `sex` comienzan como números, pero los valores leídos desde elementos HTML llegan normalmente como texto. Por eso, después de modificarlos, pueden contener `"18"` o `"1"`. Si una operación futura necesitara números, debería convertirlos explícitamente.

---

## 8. Eventos y `handleChange`

Cada campo llama a la misma función:

```jsx
onChange={(event) => handleChange(event)}
```

El evento contiene información sobre el elemento modificado.

```jsx
const handleChange = (event) => {
  const { target: { name, value } } = event;

  setForm((previous) => {
    console.log(previous);

    return ({
      ...previous,
      [name]: value
    });
  });
}
```

### Desestructuración del evento

```jsx
const { target: { name, value } } = event;
```

Es una forma corta de obtener:

```jsx
const name = event.target.name;
const value = event.target.value;
```

Si se modifica el campo `<input name="surname">`, los valores serán aproximadamente:

```text
name  = "surname"
value = texto escrito
```

### Actualización basada en el estado anterior

```jsx
setForm((previous) => ({
  ...previous,
  [name]: value
}));
```

La función recibe el estado más reciente como `previous`.

- `...previous` copia todos los campos anteriores.
- `[name]` selecciona dinámicamente la propiedad modificada.
- `value` reemplaza únicamente esa propiedad.

Ejemplo:

```text
Estado anterior:
{ name: "Ana", surname: "López", age: 20 }

Evento:
name = "age"
value = "21"

Estado nuevo:
{ name: "Ana", surname: "López", age: "21" }
```

Sin `...previous`, el nuevo objeto conservaría solamente el campo modificado y se perderían los demás.

---

## 9. Entradas Controladas

Un campo controlado recibe su valor desde el estado y notifica cada cambio a React:

```jsx
<input
  value={form.name}
  onChange={(event) => handleChange(event)}
  name="name"
/>
```

```text
form.name ──► value del input
     ▲
     └──── onChange + setForm
```

La propiedad `name` del elemento debe coincidir con la propiedad del objeto `form`:

| Elemento | Propiedad actualizada |
|---|---|
| `name="name"` | `form.name` |
| `name="surname"` | `form.surname` |
| `name="lastname"` | `form.lastname` |
| `name="age"` | `form.age` |
| `name="sex"` | `form.sex` |

Gracias a esa coincidencia, todos los elementos pueden reutilizar `handleChange()`.

---

## 10. JSX y Bootstrap

JSX permite escribir una estructura parecida a HTML dentro de JavaScript. Existen algunas diferencias:

| JSX | HTML tradicional |
|---|---|
| `className` | `class` |
| `htmlFor` | `for` |
| `{expresion}` | texto o atributo estático |
| eventos como `onChange` | atributos o listeners tradicionales |

Ejemplo:

```jsx
<label htmlFor="name">Nombre(s)</label>
<input className="form-control" id="name" />
```

Bootstrap proporciona clases como:

- `m-4`: margen;
- `card` y `card-body`: tarjeta visual;
- `row` y `g-3`: distribución y separación;
- `col-12` y `col-6`: columnas;
- `form-control`: estilo de los inputs;
- `form-select`: estilo del selector.

React genera los elementos; Bootstrap define principalmente su apariencia.

---

## 11. Vite y los Scripts de npm

`vite.config.js` registra el complemento de React:

```javascript
export default defineConfig({
  plugins: [react()],
})
```

Los scripts de `package.json` son:

| Comando | Función |
|---|---|
| `npm run dev` | Servidor de desarrollo con recarga rápida |
| `npm run build` | Genera la carpeta `dist/` para producción |
| `npm run lint` | Ejecuta ESLint |
| `npm run preview` | Previsualiza localmente el contenido construido |

Vite transforma JSX, procesa las importaciones y agrupa los recursos que el navegador necesita.

---

## 12. Ejecutar en Desarrollo

Para ejecutar el proyecto localmente se debe tener **Node.js y npm instalados previamente**. Puede comprobarlo con:

```bash
node --version
npm --version
```

Si no están instalados en Ubuntu o Debian, utilice:

```bash
sudo apt update
sudo apt install -y nodejs npm
```

Desde `front/`:

```bash
npm ci
npm run dev
```

Abra la dirección que muestre Vite, normalmente:

```text
http://localhost:5173/
```

Para comprobar la versión de producción:

```bash
npm run build
npm run preview
```

`npm ci` crea `node_modules/` localmente y `npm run build` crea `dist/`. Ambas carpetas están ignoradas por Git y no deben agregarse al ZIP de despliegue.

El despliegue en EC2 no utiliza `npm run dev`; Nginx sirve el resultado de `npm run build`.

---

## 13. Qué Hace y Qué no Hace la Práctica

Actualmente la aplicación:

- muestra un formulario;
- conserva los cinco campos en el estado;
- actualiza dinámicamente la propiedad modificada;
- aplica estilos de Bootstrap;
- muestra en consola el estado anterior durante los cambios.

Actualmente no:

- valida que los campos estén completos;
- convierte edad y sexo explícitamente a números;
- tiene un botón para enviar el formulario;
- realiza peticiones HTTP;
- guarda información en una base de datos;
- navega entre diferentes páginas.

Estas ausencias delimitan el alcance de la práctica; no impiden estudiar el funcionamiento de React.

---

## 14. Conceptos para Recordar

| Concepto | Explicación breve |
|---|---|
| Componente | Función que devuelve una parte de la interfaz |
| Estado | Información que React conserva entre renderizados |
| Hook | Función de React, como `useState`, que añade capacidades |
| Renderizado | Cálculo de la interfaz correspondiente al estado actual |
| Evento | Objeto que describe una interacción del usuario |
| Entrada controlada | Elemento cuyo valor procede del estado de React |
| Desestructuración | Extracción de valores de un objeto o arreglo |
| Spread `...` | Copia de propiedades dentro de un objeto nuevo |
| Propiedad calculada `[name]` | Selección dinámica del campo que se actualizará |
| JSX | Sintaxis para describir elementos dentro de JavaScript |
| Vite | Herramienta de desarrollo y compilación |
| `dist/` | Archivos finales preparados para un servidor web |

---

## 15. Preguntas de Repaso

1. ¿Qué elemento de `index.html` controla React?
2. ¿Qué diferencia existe entre `form` y `setForm`?
3. ¿Por qué todos los inputs pueden compartir `handleChange()`?
4. ¿Qué información contiene `event.target`?
5. ¿Para qué se utiliza `...previous`?
6. ¿Qué representa `[name]: value`?
7. ¿Por qué `className` sustituye a `class` en JSX?
8. ¿Qué función cumple Bootstrap y cuál cumple React?
9. ¿Qué diferencia existe entre `npm run dev` y `npm run build`?
10. ¿Por qué Nginx solamente necesita la carpeta `dist/`?

---

## Resumen del Flujo

```text
index.html
    └── main.jsx
          └── createRoot(...).render(<App />)
                    └── App.jsx
                          ├── useState(form)
                          ├── handleChange(event)
                          └── JSX + Bootstrap
```

React conserva el objeto `form`, cada campo actualiza una propiedad y Vite prepara el proyecto para desarrollo o producción.
