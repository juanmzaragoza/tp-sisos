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
