
const API_URL = "https://dragonball-api.com/api/characters";

const contenedor = document.getElementById("personajes");
const mensaje = document.getElementById("mensaje");

const modal = document.getElementById("modal");
const cerrarModal = document.getElementById("cerrar-modal");
const modalMensaje = document.getElementById("modal-mensaje");
const detallePersonaje = document.getElementById("detalle-personaje");

const botonAnterior = document.getElementById("anterior");
const botonSiguiente = document.getElementById("siguiente");
const paginaTexto = document.getElementById("pagina");

let paginaActual = 1;
const limite = 20;

// Cargar todos los personajes
async function cargarPersonajes() {
    try {
        mensaje.textContent = "Cargando personajes...";

        contenedor.innerHTML = "";

        botonAnterior.disabled = true;
        botonSiguiente.disabled = true;

        const respuesta = await fetch(
            `${API_URL}?page=${paginaActual}&limit=${limite}`
        );

        if (!respuesta.ok) {
            throw new Error("Error al cargar los personajes");
        }

        const datos = await respuesta.json();

        // Obtener los personajes
        const personajes = datos.items;

        // Mostrar los personajes
        personajes.forEach(personaje => {

            contenedor.innerHTML += `
                <article class="personaje">

                    <img
                        src="${personaje.image}"
                        alt="${personaje.name}"
                        loading="lazy"
                    >

                    <h3>${personaje.name}</h3>

                    <p class="raza">
                        ${personaje.race}
                    </p>

                    <p class="ki">
                        Ki: ${personaje.ki}
                    </p>

                    <button class="boton-ver"
                        onclick="verPersonaje(${personaje.id})">
                        Ver detalles
                    </button>

                </article>
            `;
        });

        mensaje.textContent =
            `Se encontraron ${datos.meta.totalItems} personajes en total.`;

        paginaTexto.textContent =
            `Página ${datos.meta.currentPage} de ${datos.meta.totalPages}`;

        // Controlar los botones de paginación
        botonAnterior.disabled =
            datos.meta.currentPage === 1;

        botonSiguiente.disabled =
            datos.meta.currentPage === datos.meta.totalPages;

    } catch (error) {
        console.error(error);

        mensaje.textContent =
            "No se pudieron cargar los personajes.";
    }
}

// Consultar un personaje por ID y mostrarlo en el modal
async function verPersonaje(id) {
    modal.hidden = false;

    modalMensaje.textContent = "Cargando información...";
    detallePersonaje.innerHTML = "";

    cerrarModal.focus();

    try {
        const respuesta = await fetch(`${API_URL}/${id}`);

        if (!respuesta.ok) {
            throw new Error("Error al consultar el personaje");
        }

        const personaje = await respuesta.json();

        detallePersonaje.innerHTML = `
            <div class="detalle">

                <img
                    src="${personaje.image}"
                    alt="${personaje.name}"
                >

                <h2 id="modal-titulo">
                    ${personaje.name}
                </h2>

                <p>
                    <strong>Raza:</strong>
                    ${personaje.race}
                </p>

                <p>
                    <strong>Género:</strong>
                    ${personaje.gender}
                </p>

                <p>
                    <strong>Ki:</strong>
                    ${personaje.ki}
                </p>

                <p>
                    <strong>Ki máximo:</strong>
                    ${personaje.maxKi}
                </p>

                <p>
                    <strong>Afiliación:</strong>
                    ${personaje.affiliation}
                </p>

                <p>
                    <strong>Descripción:</strong>
                    ${personaje.description}
                </p>

            </div>
        `;

        modalMensaje.textContent = "";

    } catch (error) {
        console.error(error);

        modalMensaje.textContent =
            "No se pudo cargar el personaje. Intenta nuevamente.";
    }
}

// Mostrar la página anterior
botonAnterior.addEventListener("click", () => {
    if (paginaActual > 1) {
        paginaActual--;
        cargarPersonajes();
    }
});

// Mostrar la página siguiente
botonSiguiente.addEventListener("click", () => {
    paginaActual++;
    cargarPersonajes();
});

// Cerrar el modal con el botón X
cerrarModal.addEventListener("click", () => {
    modal.hidden = true;
});

// Cerrar al hacer clic fuera del contenido
modal.addEventListener("click", event => {
    if (event.target === modal) {
        modal.hidden = true;
    }
});

// Cerrar con la tecla Escape
document.addEventListener("keydown", event => {
    if (event.key === "Escape" && !modal.hidden) {
        modal.hidden = true;
    }
});

// Iniciar aplicación
cargarPersonajes();


//Registrar el service worker
if('serviceWorker' in navigator){
    navigator.serviceWorker.register('./sw.js')
}
