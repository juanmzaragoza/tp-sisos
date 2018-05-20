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

# $1: Codigo Pais
# $2: Codigo sistema
# Hay que definir antes de llamar al array ROWS
buildHeader() {
	HEADER_LIST=`grep "$1-$2-.*$" "$T2_FILE"`
	while read -r line
	do
		FIELD_NAME=`echo "$line" | sed "s/^$1-$2-\(.*\)-.*-.*$/\1/"`
		FIELD_TYPE=`echo "$line" | sed "s/^$1-$2-.*-.*-\(.*\)$/\1/"`
		ROWS+=("$FIELD_NAME"-"$FIELD_TYPE")
	done <<< "$HEADER_LIST"
}

# $1 : Path al archivo
# $2 : Separador de campos
# Hay que definir antes de llamar al array VALUES
buildValues() {
	LENGHT=${#REGISTROS[@]}
	while read -r LINE
	do
		i=0
		while (( i < "$LENGHT" ))
		do
			VALUE=`echo	"$LINE" | sed "s/^\([^$2]*\)$2.*/\1/"`
			LINE=`echo "$LINE" | sed "s/^\([^$2]*\)$2\(.*\)/\2/"`
			VALUES+=("$VALUE")
			((i++))
		done
	done < "$1"
}

processFiles() {
	CURRENT_DATE=`date +%F`
	if ! directoryExists "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE"
	then
		chmod +w "$GRUPO/$PROCESSEDDIR"
		mkdir "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE"
	fi
	for FILE_PATH in "${1}/"*; do
		
		y=${1%.*}
		CLEANED_NAME=`echo ${y##*/}`
		echo "CLEANED_NAMEis $CLEANED_NAME"
		CHECKED_NAME=`echo $CLEANED_NAME | grep '^.*-.*-.*-.*$'`
		echo "CHECKED_NAME is $CHECKED_NAME"
		if [ -z "$CHECKED_NAME" ]
		then
			showError "Novedad $1 Rechazada. Motivo: El nombre no cumple el patron"
			return 1
		fi
		if checkIfProcessed "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE/$CHECKED_NAME"
		then
			mvOrFail "$FILE_PATH" "$GRUPO/$REJECTEDDIR"
		else
			COUNTRY_CODE=`echo "$CHECKED_NAME" | sed 's/\(.*\)-.*-.*-.*/\1/'`
			SYSTEM_CODE=`echo "$CHECKED_NAME" | sed 's/.*-\(.*\)-.*-.*/\1/'`
			SEPARATORS=`grep "^$COUNTRY_CODE-$SYSTEM_CODE-.*-.*$" "$T1_FILE"`
			if [ -z "$SEPARATORS" ]
			then
				showError "No se encontro en $T1_FILE los separadores para $COUNTRY_CODE - $SYSTEM_CODE"
			else
				FIELD_SEPARATOR=`echo "$SEPARATORS" | sed 's/^.*-.*-\(.*\)-.*$/\1/'`
				DECIMAL_SEPARATOR=`echo "$SEPARATORS" | sed 's/^.*-.*-.*-\(.*\)$/\1/'` 
				ROWS=()
				buildHeader "$COUNTRY_CODE" "$SYSTEM_CODE"
				VALUES=()
				buildValues
			fi


			i=0
			while (( i < "${#ROWS[@]}" ))
			do
				echo "Campo: ${ROWS[i]}"
				echo "Valor: ${VALUES[i]}"
				echo ""
				((i++))
			done
		fi
	done
}

main() {
	if ! validateEnvironment
	then
		showError "Ambiente invalido"
		return 1
	fi
	if directoryEmpty "$GRUPO/$ACCEPTEDDIR"
	then
		showAlert "$GRUPO/$ACCEPTEDDIR has no files"
	else
		echo "ARRANCA PROCES para $GRUPO/$ACCEPTEDDIR"
		processFiles "$GRUPO/$ACCEPTEDDIR"
		echo "FINALIZA PROCES"
	fi
}

main
