#!/bin/bash

# *************
# INCLUDES
# *************

source "$GRUPO/$LIBDIR/logger.sh"

# *************
# VARIABLES DE INICIO
# *************

# GRUPO # directorio de instalacion
# CONFIGDIR # directorio del archivo de configuracion
# LIBDIR # directorio donde se depositan las librerias
# BINDIR # directorio de ejecutables
# MASTERDIR # directorio de archivos maestros y tablas del sistema
# ARRIVEDIR # directorio de arribo de archivos externos, es decir, los archivos que remiten las subsidiarias
# ACCEPTEDDIR # directorio donde se depositan temporalmente las novedades aceptadas
# REJECTEDDIR # directorio donde se depositan todos los archivos rechazados
# PROCESSEDDIR # directorio donde se depositan los archivos procesados 
# REPORTDIR # Directorio donde se depositan los reportes
# LOGDIR # directorio donde se depositan los logs de los comandos

# *************
# VARIABLES LOCALES
# *************

PRODUCT="InterpretO"
LOGFILE="$GRUPO/$LOGDIR/interpreto.log"
T1_FILE="$GRUPO/$MASTERDIR/T1.tab"
T2_FILE="$GRUPO/$MASTERDIR/T2.tab"
INFOLOG="INF"
ALERTLOG="ALE"
ERRORLOG="ERR"

# *************
# LOG AUXILIAR
# *************

# $1: mensaje
# $2: si es false no muestra el resultado por consola
showInfo(){
	saveLog "$LOGFILE" "$PRODUCT" "$INFOLOG" "$1" $2
}

showError(){
	saveLog "$LOGFILE" "$PRODUCT" "$ERRORLOG" "$1" $2
}

showAlert(){
	saveLog "$LOGFILE" "$PRODUCT" "$ALERTLOG" "$1" $2
}

# *************
# FUNCTIONS
# *************

validateEnvironment() {
	return 0
}

checkIfProcessed() {
	if fileExits "$1"
	then
		return 0
	else
		return 1
	fi
}

processFiles() {
	CURRENT_DATE=`date +%F`
	if ! directoryExists "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE"
	then
		mkdir "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE"
	fi
	for FILE_PATH in "${1}/"*; do
		y=${1%.*}
		CLEANED_NAME=`echo ${y##*/}`
		CHECKED_NAME=`echo $CLEANED_NAME | grep '^.*-.*-.*-.*$'`
		if [ -z "$CHECKED_NAME" ]
		then
			showError "Novedad $1 Rechazada. Motivo: El nombre no cumple el patron"
			return 1
		fi
		if checkIfProcessed "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE/$CHECKED_NAME"
		then
			mvOrFail "$FILE_PATH" "$GRUPO/$REJECTEDDIR"
		else
			COUNTRY_CODE=`echo $CHECKED_NAME | sed 's/\(.*\)-.*-.*-.*/\1/'`
			SYSTEM_CODE=`echo $CHECKED_NAME | sed 's/.*-\(.*\)-.*-.*/\1/'`
			SEPARATORS=`grep "^$COUNTRY_CODE-$SYSTEM_CODE-.*-.*$" "$T1_FILE"`
			if [ -z $SEPARATORS ]
			then
				showError "No se encontro en $T1_FILE los separadores para $COUNTRY_CODE - $SYSTEM_CODE"
			else
				FIELD_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-\(.*\)-.*$/\1/'`
				DECIMAL_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-.*-\(.*\)$/\1/'` 


	done
}

main() {
	if ! validateEnvironment
	then
		showError "Ambiente invalido"
		return 1
	fi
	while true
	do			
		if directoryEmpty "$GRUPO/$ACCEPTEDDIR"
		then
			showAlert "$GRUPO/$ACCEPTEDDIR has no files"
		else
			processFiles "$GRUPO/$ACCEPTEDIR"
		fi
	done
}

main
