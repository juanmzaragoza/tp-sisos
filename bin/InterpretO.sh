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

# Deberia llamar a la funcion de ivan para validar ambiente
# Devolver 0 (true) o 1 (false)
validateEnvironment() {
	return 0
}

# Valida si el archivo $1 existe
# Devolver 0 (true) o 1 (false)
checkIfProcessed() {
	if fileExits "$1"
	then
		return 0
	else
		return 1
	fi
}

# Arma en la variable ROWS la tupla "NOMBRE DE CAMPO"-"TIPO DE CAMPO"
# Ejemplo : MT_IMPAGO-commax16.2
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

# $1 : Path al archivo con informacion del sistema (Ejemplo "A-6-2017-05")
# $2 : Separador de campos extraido de T1
# Hay que definir antes de llamar al array VALUES
buildValues() {
	LENGHT=${#ROWS[@]}
	while read -r LINE
	do
		i=0
		while (( i < "$LENGHT" ))
		do
			VALUE=`echo	"$LINE" | sed "s/^\([^$2]*\)"$2".*/\1/"`
			LINE=`echo "$LINE" | sed "s/^\([^$2]*\)$2\(.*\)/\2/"`
			VALUES+=("$VALUE")
			((i++))
		done
	done < "$1"
}

processFiles() {
	CURRENT_DATE=`date +%F`
	# Checkeo o creo en la carpeta procesados, la sub-carpeta referida a los procesados en el dia current
	if ! directoryExists "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE"
	then
		chmod +w "$GRUPO/$PROCESSEDDIR"
		mkdir "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE"
	fi
	# Recorro todos los archivos aceptados, listos para procesar
	for FILE_PATH in "${1}/"*; do
		y=${FILE_PATH%.*}
		CLEANED_NAME=`echo ${y##*/}`
		CHECKED_NAME=`echo $CLEANED_NAME | grep '^.*-.*-.*-.*$'`
		if [ -z "$CHECKED_NAME" ]
		then
			showError "Novedad $1 Rechazada. Motivo: El nombre no cumple el patron"
			return 1
		fi
		# Habiendo limpiado el nombre (A-6-2017-05 , por ejemplo, me fijo si ya lo procese en este dia)
		if checkIfProcessed "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE/$CHECKED_NAME"
		then
			mvOrFail "$FILE_PATH" "$GRUPO/$REJECTEDDIR"
		else
			# Con el codigo pais y el codigo de sistema, voy a T1 a buscar los separadores de ese sistema
			COUNTRY_CODE=`echo "$CHECKED_NAME" | sed 's/\(.*\)-.*-.*-.*/\1/'`
			SYSTEM_CODE=`echo "$CHECKED_NAME" | sed 's/.*-\(.*\)-.*-.*/\1/'`
			SEPARATORS=`grep "^$COUNTRY_CODE-$SYSTEM_CODE-.*-.*$" "$T1_FILE"`
			if [ -z "$SEPARATORS" ]
			then
				showError "No se encontro en $T1_FILE los separadores para $COUNTRY_CODE - $SYSTEM_CODE"
			else
				FIELD_SEPARATOR=`echo "$SEPARATORS" | sed 's/^.*-.*-\(.*\)-.*$/\1/'`
				DECIMAL_SEPARATOR=`echo "$SEPARATORS" | sed 's/^.*-.*-.*-\(.*\)$/\1/'` 
				# Con el codigo pais y el codigo sistema, armo el header de T2 (es decir, que campos voy a leer y de que tipo son)
				ROWS=()
				buildHeader "$COUNTRY_CODE" "$SYSTEM_CODE"
				# Con los separadores, leo los valores del archivo. Quedna mapeados en el mismo index
				VALUES=()
				buildValues "$FILE_PATH" "$FIELD_SEPARATOR"
				# LA IDEA SERIA LLAMAR AL METODO QUE FORMATEA EL REGISTRO DE SALIDA Y ESCRIBIRLO EN EL ARCHIVO QUE DICE EL ENUNCIADO
				# EN PRUEBA.SH HAY UNOS INTENTOS QUE ESTUVE HACIENDO, EL METODO OUTPUT REGISTER
				# DEBERIA MAPEAR EN CADA VARIABLE QUE NECESITA SER ESCRITA, SU VALOR. TENIENDO EN CUENTA EL TIPO DE DATO
			fi
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
		processFiles "$GRUPO/$ACCEPTEDDIR"
	fi
}

main
