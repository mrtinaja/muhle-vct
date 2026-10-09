"""Separa db/_dump/DUMP_OBJETOS.txt (salida de db/DUMP_OBJETOS.sql) en un .sql por objeto.

Uso:  python tools/split_dump.py
Deja db/objetos/<tipo>/<schema>.<nombre>.sql. Los objetos que ya no existen en el
servidor se borran de la carpeta, asi git muestra altas, bajas y cambios.
"""
import io
import pathlib
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
ORIGEN = RAIZ / "db" / "_dump" / "DUMP_OBJETOS.txt"
DESTINO = RAIZ / "db" / "objetos"
CARPETA = {"P": "procedimientos", "FN": "funciones", "IF": "funciones",
           "TF": "funciones", "V": "vistas", "TR": "triggers"}


def leer(path):
    datos = path.read_bytes()
    for cod in ("utf-16", "utf-8-sig", "cp1252"):
        try:
            texto = datos.decode(cod)
            if "--@@" in texto:
                return texto
        except UnicodeDecodeError:
            continue
    sys.exit(f"No pude leer {path}")


def main():
    if not ORIGEN.exists():
        sys.exit(f"Falta {ORIGEN}: correr antes db/DUMP_OBJETOS.sql en SSMS (SQLCMD Mode).")
    texto = leer(ORIGEN)
    if "--@@DUMP OK" not in texto:
        sys.exit("El dump esta incompleto (no termina en --@@DUMP OK). No se cambia nada.")

    objetos, actual, lineas, larga = {}, None, [], None
    for linea in texto.splitlines():
        if linea.startswith("--@@OBJ "):
            _, tipo, nombre = linea.split(" ", 2)
            actual, lineas = (tipo, nombre.strip()), []
        elif linea == "--@@FINOBJ":
            objetos[actual] = "\n".join(lineas).strip("\n") + "\n"
            actual = None
        elif actual is None:
            continue
        elif linea == "--@@LARGA":
            larga = []
        elif linea == "--@@FINLARGA":
            lineas.append("".join(larga))
            larga = None
        elif larga is not None:
            larga.append(linea)
        else:
            lineas.append(linea)

    escritos = set()
    for (tipo, nombre), cuerpo in objetos.items():
        archivo = DESTINO / CARPETA.get(tipo, "otros") / f"{nombre}.sql"
        archivo.parent.mkdir(parents=True, exist_ok=True)
        with io.open(archivo, "w", encoding="utf-8", newline="\r\n") as f:
            f.write(cuerpo)
        escritos.add(archivo.resolve())

    borrados = 0
    for viejo in DESTINO.rglob("*.sql"):
        if viejo.resolve() not in escritos:
            viejo.unlink()
            borrados += 1
    print(f"{len(objetos)} objetos escritos en {DESTINO.relative_to(RAIZ)}; {borrados} borrados (ya no existen).")


if __name__ == "__main__":
    main()
