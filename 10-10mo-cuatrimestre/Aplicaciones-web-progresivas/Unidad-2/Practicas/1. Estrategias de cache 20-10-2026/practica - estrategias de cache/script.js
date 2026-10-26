
const API_URL = "https://fakestoreapi.com/products";

const contenedor = document.getElementById("productos");
const mensaje = document.getElementById("mensaje");

const modal = document.getElementById("modal");
const cerrarModal = document.getElementById("cerrar-modal");
const modalMensaje = document.getElementById("modal-mensaje");
const detalleProducto = document.getElementById("detalle-producto");

// Cargar todos los productos
async function cargarProductos() {
    try {
        mensaje.textContent = "Cargando productos...";

        const respuesta = await fetch(API_URL);

        if (!respuesta.ok) {
            throw new Error("Error al cargar los productos");
        }

        const productos = await respuesta.json();

        contenedor.innerHTML = "";

        productos.forEach(producto => {
            contenedor.innerHTML += `
                <article class="producto">
                    <img src="${producto.image}" alt="${producto.title}" loading="lazy">

                    <h3>${producto.title}</h3>

                    <p class="categoria">${producto.category}</p>

                    <p class="precio">$${producto.price.toFixed(2)}</p>

                    <p class="valoracion">
                        ★ ${producto.rating.rate} (${producto.rating.count} opiniones)
                    </p>

                    <button class="boton-ver" onclick="verProducto(${producto.id})">
                        Ver producto
                    </button>
                </article>
            `;
        });

        mensaje.textContent = `Se encontraron ${productos.length} productos.`;

    } catch (error) {
        console.error(error);
        mensaje.textContent = "No se pudieron cargar los productos.";
    }
}

// Consultar un producto por ID y mostrarlo en el modal
async function verProducto(id) {
    modal.hidden = false;
    modalMensaje.textContent = "Cargando producto...";
    detalleProducto.innerHTML = "";

    cerrarModal.focus();

    try {
        const respuesta = await fetch(`${API_URL}/${id}`);

        if (!respuesta.ok) {
            throw new Error("Error al consultar el producto");
        }

        const producto = await respuesta.json();

        detalleProducto.innerHTML = `
            <div class="detalle">
                <img src="${producto.image}" alt="${producto.title}">

                <h2 id="modal-titulo">${producto.title}</h2>

                <p class="categoria">
                    Categoría: ${producto.category}
                </p>

                <p class="precio">
                    $${producto.price.toFixed(2)}
                </p>

                <p>${producto.description}</p>

                <p class="valoracion">
                    ★ ${producto.rating.rate} / 5
                    (${producto.rating.count} opiniones)
                </p>
            </div>
        `;

        modalMensaje.textContent = "";

    } catch (error) {
        console.error(error);
        modalMensaje.textContent =
            "No se pudo cargar el producto. Intenta nuevamente.";
    }
}

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
cargarProductos();
