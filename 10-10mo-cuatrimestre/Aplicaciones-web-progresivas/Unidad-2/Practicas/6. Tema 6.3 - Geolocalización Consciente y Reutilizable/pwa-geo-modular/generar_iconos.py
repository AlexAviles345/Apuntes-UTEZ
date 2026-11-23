# generar_iconos.py - Genera icon-192.png e icon-512.png sin librerías externas
import os
import struct
import zlib

AZUL = (11, 95, 255)      # #0b5fff
BLANCO = (255, 255, 255)
SUBMUESTREO = 3           # 3x3 muestras por píxel (suavizado de bordes)


def es_blanco(x, y):
    """Devuelve True si el punto (x, y) en [0, 1] pertenece al pin blanco."""
    # Cabeza circular del pin
    cx, cy, radio = 0.5, 0.42, 0.22
    en_circulo = (x - cx) ** 2 + (y - cy) ** 2 <= radio ** 2

    # Cola triangular que apunta hacia abajo
    y_base, y_punta, semi_ancho = 0.50, 0.78, 0.19
    en_triangulo = False
    if y_base <= y <= y_punta:
        limite = semi_ancho * (y_punta - y) / (y_punta - y_base)
        en_triangulo = abs(x - 0.5) <= limite

    # Agujero interior (se ve del color del fondo)
    en_agujero = (x - cx) ** 2 + (y - cy) ** 2 <= 0.09 ** 2

    return (en_circulo or en_triangulo) and not en_agujero


def generar_pixeles(tam):
    filas = []
    total = SUBMUESTREO * SUBMUESTREO
    for py in range(tam):
        fila = bytearray([0])  # byte de filtro PNG (0 = sin filtro)
        for px in range(tam):
            aciertos = 0
            for sy in range(SUBMUESTREO):
                for sx in range(SUBMUESTREO):
                    x = (px + (sx + 0.5) / SUBMUESTREO) / tam
                    y = (py + (sy + 0.5) / SUBMUESTREO) / tam
                    if es_blanco(x, y):
                        aciertos += 1
            c = aciertos / total
            for i in range(3):
                fila.append(round(AZUL[i] * (1 - c) + BLANCO[i] * c))
        filas.append(bytes(fila))
    return b"".join(filas)


def chunk(tipo, datos):
    cuerpo = tipo + datos
    return (struct.pack(">I", len(datos)) + cuerpo +
            struct.pack(">I", zlib.crc32(cuerpo) & 0xFFFFFFFF))


def guardar_png(ruta, tam):
    crudo = generar_pixeles(tam)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", tam, tam, 8, 2, 0, 0, 0))  # RGB 8 bits
    png += chunk(b"IDAT", zlib.compress(crudo, 9))
    png += chunk(b"IEND", b"")
    with open(ruta, "wb") as f:
        f.write(png)
    print(f"✔ {ruta} ({tam}x{tam}, {len(png)} bytes)")


if __name__ == "__main__":
    os.makedirs("icons", exist_ok=True)
    guardar_png(os.path.join("icons", "icon-192.png"), 192)
    guardar_png(os.path.join("icons", "icon-512.png"), 512)
    print("Listo. Los íconos están en la carpeta icons/")