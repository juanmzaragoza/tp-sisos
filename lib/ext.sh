#!/bin/bash

#################################################
#
# Interaccion con las entradas y salidas
# * Escribir archivos
# * Leer entradas
#
#################################################

# ----------------------------------------------------------------------
# devuelve true si el path pasado como parametro existe y es una carpeta
# $1: directorio que se quiere corroborar
#
directoryExists(){
	return `test -d "$1"`
}

# ----------------------------------------------------------------------
# devuelve true si el path pasado como parametro es una carpeta vacia
# $1: directorio que se quiere corroborar
#
directoryEmpty(){
	if [ -z "$(ls -A $1)" ]
	then
		return 0
	else
		return 1
	fi
}

#  --------------------------------------------------------------
# devuelve true si el archivo existe y tiene permisos de lectura
# $1: archivo que se quiere corroborar
#
fileExits(){
	return `test -r "$1"`
}

#  ---------------------------------------------------------------
# devuelve true si el archivo existe y tengo permisos de escritura
# $1: archivo que se quiere corroborar
#
canWriteFile(){
	return `test -w "$1"`
}

#
# copia archivos sino termina con error
# $1: archivo a copiar
# $2: carpeta destino
#
cpOrExitOnError(){
	cp "$1" "$2"
	if [ $? != 0 ]; then # contiene el resultado de la ultima ejecucion
		showError "Error al copiar $1 a $2"
		exit 1
	else
		showInfo "Copiado archivo $1 a $2"
	fi	
}

#
# mueve archivos sino termina con error
# $1: archivo a mover
# $2: carpeta destino
# Retorna 0 en caso de éxito 
# 		  1 en caso de fallo
mvOrFail(){
	mv "$1" "$2"
	if [ $? != 0 ]; then # contiene el resultado de la ultima ejecucion
		showError "Error al copiar $1 a $2"
		return 1
	else
		showInfo "Movido archivo $1 a $2"
		return 0
	fi	
}