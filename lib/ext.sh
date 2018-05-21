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
# $3: si es false, los mensajes no serán mostrados por consola
# Retorna 0 en caso de éxito 
# 		  1 en caso de fallo
mvOrFail(){

	# extraigo nombre del archivo
	NAMEFILE="${1##*/}"
	DESTNAMEFILE="$2/$NAMEFILE"
	DUPLICATEDDIR="$2/dup"

	# si el archivo ya existe en destino
	if fileExits "$DESTNAMEFILE"
	then
		showAlert "Archivo $NAMEFILE duplicado en $2. Será movido a $DUPLICATEDDIR" $3

		# si no existe la carpeta /dup la creo
		if ! directoryExists "$DUPLICATEDDIR"
		then
			mkdir "$DUPLICATEDDIR"
			showInfo "Se creó el directorio $DUPLICATEDDIR" $3
		fi

		# corroboro cual es el ultimo archivo duplicado en esa carpeta
		# listo todo lo que tiene el duplicado busco nombre tipo A-6-2017-05(7) y obtengo solo el 7 (veces duplicado)
		SECUENCE=`ls "$DUPLICATEDDIR" | grep "$NAMEFILE\(.*\)" | sort -n -t '(' -k 2 | tail -1 | sed "s/$NAMEFILE(\(.*\))/\1/g"`
		if [ -z "$SECUENCE" ]
		then # si no hay secuencia, deberia ser la primera
			LASTSECUENCE=1
		else
			# si hay secuencia, agarro la ultima y le sumo 1
			LASTSECUENCE=${SECUENCE[${#SECUENCE[@]} - 1]}
			LASTSECUENCE=`expr $LASTSECUENCE + 1`
		fi

		mv "$1" "$DUPLICATEDDIR/$NAMEFILE($LASTSECUENCE)"
		showInfo "Movido archivo $1 a $DUPLICATEDDIR con el nombre $NAMEFILE($LASTSECUENCE)" $3
		return 0
	else # si el archivo no existe en destino
		mv "$1" "$2"
		if [ $? != 0 ]; then # contiene el resultado de la ultima ejecucion
			showError "Error al copiar $1 a $2" $3
			return 1
		else
			showInfo "Movido archivo $1 a $2" $3
			return 0
		fi	
	fi
}