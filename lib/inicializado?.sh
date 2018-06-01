#!/bin/bash

# Verifica que el ambiente haya sido inicializado, chequeando que las variables necesarias estén seteadas.
# Devuelve 0 si el ambiente fue inicializado correctamente, 1 en caso contrario.

ARCHIVO_DESCRIPCION_AMBIENTE="ambiente.sh"

#TODO(Iván): loggear esta información en alguna bitácora.

if
  [ -n "${GRUPO:+"ESTA_SETEADA"}" ] &&
  [ -n "${LIBDIR:+"ESTA_SETEADA"}" ] &&
  [ -r "${GRUPO}/${LIBDIR}/${ARCHIVO_DESCRIPCION_AMBIENTE}" ]
  then
    source "${GRUPO}/${LIBDIR}/${ARCHIVO_DESCRIPCION_AMBIENTE}" #Cargo la "LISTA_DE_VARIABLES".
  else
    exit 1 #No se puede cargar la "LISTA_DE_VARIABLES".
fi

#Chequea que las variables de "LISTA_DE_VARIABLES" estén seteadas y no sean "NULL".
for VARIABLE in "${LISTA_DE_VARIABLES[@]}"; do
  if [ -z "${!VARIABLE:+"ESTA_SETEADA"}" ]
    then
      exit 1 #Si no está seteada o es "NULL".
  fi
done
exit 0 #Si todas están seteadas y ninguna es "NULL".
