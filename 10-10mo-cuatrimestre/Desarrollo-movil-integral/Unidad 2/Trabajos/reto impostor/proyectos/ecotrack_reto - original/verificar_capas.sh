#!/usr/bin/env bash
# Reto "El Impostor" — verificación de capas
#
#   bash verificar_capas.sh
#
# Se puede correr desde la raíz del repositorio o desde ecotrack_reto/.
# Revisa que existan los archivos del contrato y que las dependencias
# apunten en la dirección legal. Las pruebas (flutter test) revisan que
# la app FUNCIONE; este script revisa que esté BIEN SEPARADA.
#
# NO EDITAR: el docente vuelve a correr una copia limpia de este archivo.
#
# Si el archivo llegó con saltos de línea de Windows (CRLF), se corre una copia limpia. Esta línea debe terminar en "#".
if grep -q $'\r' "$0" 2>/dev/null; then d=$(cd "$(dirname "$0")" && pwd); limpio="${TMPDIR:-/tmp}/verificar_capas_lf.sh"; tr -d '\r' < "$0" > "$limpio"; VERIFICAR_DIR="$d" exec bash "$limpio" "$@"; fi #

aqui="${VERIFICAR_DIR:-$(cd "$(dirname "$0")" && pwd)}"

proyecto=""
for candidato in "$aqui" "$aqui/ecotrack_reto" "$PWD" "$PWD/ecotrack_reto"; do
  if [ -f "$candidato/pubspec.yaml" ] && grep -q "^name: ecotrack_reto" "$candidato/pubspec.yaml"; then
    proyecto="$candidato"
    break
  fi
done

if [ -z "$proyecto" ]; then
  echo "No encuentro el proyecto ecotrack_reto (falta pubspec.yaml)."
  echo "Corran el script desde la raíz del repositorio o desde ecotrack_reto/."
  exit 1
fi

cd "$proyecto" || exit 1
echo "Proyecto: $proyecto"

fallas=0

ok()    { echo "  OK     $1"; }
falta() { echo "  FALTA  $1"; fallas=$((fallas + 1)); }

# Solo cuentan las líneas import, no los comentarios que mencionan el paquete.
importa() { grep -rqnE "^[[:space:]]*import[[:space:]]+['\"].*$1" "$2"; }

echo
echo "1) Archivos del contrato"
for f in \
  lib/dominio/consumo.dart \
  lib/dominio/regla_consumo.dart \
  lib/datos/consumo_repository.dart \
  lib/datos/memoria_consumo_repository.dart \
  lib/datos/consumo_service.dart \
  lib/datos/nube_consumo_repository.dart \
  lib/presentacion/registro_view_model.dart \
  lib/presentacion/registro_page.dart \
  lib/main.dart; do
  if [ -f "$f" ]; then ok "$f"; else falta "$f no existe"; fi
done

echo
echo "2) El dominio no conoce Flutter"
if [ -d lib/dominio ] && ! importa "package:flutter" lib/dominio; then
  ok "lib/dominio no importa package:flutter"
else
  falta "lib/dominio no existe o importa package:flutter"
fi

echo
echo "3) El ViewModel no pinta y no sabe de dónde salen los datos"
vm=lib/presentacion/registro_view_model.dart
if [ -f "$vm" ]; then
  if importa "material.dart" "$vm"; then
    falta "$vm importa material.dart"
  else
    ok "$vm no importa material.dart"
  fi
  if grep -vE "^[[:space:]]*//" "$vm" | grep -qE "ConsumoService|consumo_service|NubeConsumoRepository|MemoriaConsumoRepository|nube_consumo|memoria_consumo"; then
    falta "$vm conoce una implementación concreta (servicio, nube o memoria)"
  else
    ok "$vm solo conoce el contrato ConsumoRepository"
  fi
else
  falta "$vm no existe"
fi

echo
echo "4) La vista no sabe de dónde salen los datos"
vista=lib/presentacion/registro_page.dart
if [ -f "$vista" ]; then
  if importa "datos/" "$vista"; then
    falta "$vista importa algo de lib/datos"
  else
    ok "$vista no importa nada de lib/datos"
  fi
else
  falta "$vista no existe"
fi

echo
echo "5) El servicio solo lo conocen la nube y main.dart"
intrusos=$(grep -rnE "ConsumoService|consumo_service" lib 2>/dev/null \
  | grep -vE "^[^:]+:[0-9]+:[[:space:]]*//" \
  | cut -d: -f1 | sort -u \
  | grep -vE "lib/datos/consumo_service.dart|lib/datos/nube_consumo_repository.dart|lib/main.dart|lib/main_mezclado.dart")
if [ -z "$intrusos" ]; then
  ok "ConsumoService no aparece fuera de su lugar"
else
  for i in $intrusos; do falta "ConsumoService aparece en $i"; done
fi

echo
echo "6) Un solo lugar elige la fuente de datos"
if [ -f lib/main.dart ] && grep -qn "usarNube" lib/main.dart; then
  ok "lib/main.dart tiene usarNube"
else
  falta "lib/main.dart no existe o no tiene usarNube"
fi

echo
if [ "$fallas" -eq 0 ]; then
  echo "Resultado: todo OK. Ahora corran: flutter test"
  exit 0
else
  echo "Resultado: $fallas punto(s) en FALTA."
  exit 1
fi
