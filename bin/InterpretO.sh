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
P_S_FILE="$GRUPO/$MASTERDIR/p-s.mae"
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
# $3 : Nombre limpio del archivo
# Hay que definir antes de llamar al array VALUES
buildValues() {
	LENGHT=${#ROWS[@]}
	TOTAL_LINES=0
	GOOD_LINES=0
	BAD_LINES=0
	READING_FILE="$1"
	echo "" >> "$READING_FILE"
	while read -r LINE
	do
		if [ -n "$LINE" ]
		then
			((TOTAL_LINES++))
			LOCAL_LINE=${LINE::-1}
			i=0
			while (( i < "$LENGHT" ))
			do
				VALUE=`echo	"$LOCAL_LINE" | sed "s/^\([^$2]*\)"$2".*/\1/"`
				LOCAL_LINE=`echo "$LOCAL_LINE" | sed "s/^\([^$2]*\)$2\(.*\)/\2/"`
				VALUES+=("$VALUE")
				((i++))
			done
			OUTPUT=""
			buildOutput "$COUNTRY_CODE" "$SYSTEM_CODE" "$DECIMAL_SEPARATOR"
			if [ -n "$OUTPUT" ]
				then
				(( GOOD_LINES++ ))
				showInfo "Registro $TOTAL_LINES de novedad $CHECKED_NAME procesado correctamente" false
				OUTPUT_FILENAME="PRESTAMOS.$COUNTRY_CODE"
				if checkIfProcessed "$GRUPO/$PROCESSEDDIR/$OUTPUT_FILENAME"
					then
					echo "$OUTPUT" >> "$GRUPO/$PROCESSEDDIR/$OUTPUT_FILENAME"
				else
					echo "$OUTPUT" > "$GRUPO/$PROCESSEDDIR/$OUTPUT_FILENAME"
				fi
			else
				(( BAD_LINES++ ))
				showInfo "Registro $TOTAL_LINES de novedad $CHECKED_NAME procesado con error: No se pudo generar el output" false
			fi
		fi
	done < "$READING_FILE"
	showInfo "Novedad $3 proceso un total de $TOTAL_LINES lineas ($GOOD_LINES correctas y $BAD_LINES erroneas)" false
	if (( $GOOD_LINES > 0 ))
		then
		mvOrFail "$1" "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE/" false
	else
		mvOrFail "$1" "$GRUPO/$REJECTEDDIR" false
	fi
}

# $1 - el formateo de fecha
# $2 - el valor a leer
# $3 - variable CTB_DIA
# $4 - variable CTB_MES
# $5 - variable CTB_ANIO
getDate() {
	LONG=`echo "$1" | sed "s/^......\(.*\)$/\1/"`
	LONG="${LONG::-2}" # SACO ESE PUNTO FEO
	if (( "$LONG" == 8 )) # No tiene separador
		then
		DAY=`echo "$1" | grep "^dd.*$"`
		if [ -n "$DAY" ]
			then
			DAY=`echo "$2" | sed "s/^\(..\).*$/\1/"`
			eval "$3=$DAY"
			MONTH=`echo "$2" | sed "s/^..\(..\).*$/\1/"`
			eval "$4=$MONTH"
			YEAR=`echo "$2" | sed "s/^....\(.*\)$/\1/"`
			eval "$5=${YEAR}"
			return
		else
			YEAR=`echo "$2" | sed "s/^\(....\).*$/\1/"`
			eval "$5=$YEAR"
			MONTH=`echo "$2" | sed "s/^....\(..\).*$/\1/"`
			eval "$4=$MONTH"
			DAY=`echo "$2" | sed "s/^......\(.*\)$/\1/"`
			eval "$3=${DAY}"
			return
		fi
	else
		DAY=`echo "$1" | grep "^dd.*$"` # EN LA REGEX AGREGO UN CARACTER MAS POR EL SEPARADOR
		if [ -n "$DAY" ]
			then
			DAY=`echo "$2" | sed "s/^\(..\).*$/\1/"`
			eval "$3=$DAY"
			MONTH=`echo "$2" | sed "s/^...\(..\).*$/\1/"`
			eval "$4=$MONTH"
			YEAR=`echo "$2" | sed "s/^......\(.*\)$/\1/"`
			eval "$5=${YEAR}"
			return
		else
			YEAR=`echo "$2" | sed "s/^\(....\).*$/\1/"`
			eval "$5=$YEAR"
			MONTH=`echo "$2" | sed "s/^.....\(..\).*$/\1/"`
			eval "$4=$MONTH"
			DAY=`echo "$2" | sed "s/^........\(.*\)$/\1/"`
			eval "$3=${DAY}"
			return
		fi
	fi
}

# $1 - el formateo de campo
# $2 - el separador de coma
# $3 - valor a leer
# $4 - valor a asignar
getNum () {
	if [ -z "$3" ]
		then
		eval "$4=0"
		return
	fi
	INT_LONG=`echo "$1" | sed "s/^commax\([^.]*\).*$/\1/"` # Como lo uso?
	DECIMAL_LONG=`echo "$1" | sed "s/^\([^.]*\)\.\(.*\)$/\2/1"` # Como lo uso?
	INT_VALUE=`echo "$3" | sed "s/^\([^$2]*\).*$/\1/"`
	DECIMAL_VALUE=`echo "$3" | sed "s/^\([^$2]*\).\(.*\)$/\2/"`
	NEW_VALUE="$INT_VALUE,$DECIMAL_VALUE"
	eval "$4=$NEW_VALUE"
}

# $1 : Valor
# $2 : Variable a asignar
getAlphaNum() {
	if [ -z "$1" ]
		then
		eval "$2=''"
	else
		eval "$2='$1'"
	fi
}


# $1: nombre del campo que busca obtenerse
# $2: separador de decimales
# $3..$n : variables a asignar
getValue() {
	ELEMENT_INDEX=0
	for i in "${ROWS[@]}"
	do
		FIELD_NAME=`echo "$i" | grep "^$1-"`
		if [ -n "$FIELD_NAME" ]
		then
			FIELD_TYPE=`echo "$i" | sed "s/^.*-\(.*\)$/\1/"`
			DATE_FIELD=`echo "$FIELD_TYPE" | grep "yy"`
			if [ -n "$DATE_FIELD" ]
			then
				FIELD_TYPE=`echo "$i" | sed "s/^$1-\(.*\)$/\1/"`
				getDate "$FIELD_TYPE" "${VALUES[ELEMENT_INDEX]}" $3 $4 $5
				break
			fi
			ALPH_NUM_FIELD=`echo "$FIELD_TYPE" | grep -F "$"`
			if [ -n "$ALPH_NUM_FIELD" ]
			then
				getAlphaNum "${VALUES[ELEMENT_INDEX]}" $3  
				break
			fi
			NUM_FIELD=`echo "$FIELD_TYPE" | grep "commax"`
			if [ -n "$NUM_FIELD" ]
			then
				getNum "$FIELD_TYPE" "$DECIMAL_SEPARATOR" "${VALUES[ELEMENT_INDEX]}" $3
				break
			fi
			((VALUE_ERRORS++))	
		fi
		((ELEMENT_INDEX++))
	done
}

calculateRest() {
	ARRAY_AUX=("${array[@]}")
	TOTAL=0
	for i in "${ARRAY_AUX[@]}"
	do
		tmp=`echo "$i" | sed "s|\,|\.|"` # Necesito pasar del estándar al separador "." para bc
		TOTAL=$(echo "$TOTAL+$tmp" | bc)
	done
	tmp=`echo "$1" | sed "s|\,|\.|"`
	TOTAL=$(echo "$TOTAL-$tmp" | bc)
	eval "$2='$TOTAL'"
}

# $1 : Codigo pais
# $2 : Codigo Sistema
# $3 : Separador de decimales
# $4 : Output variable
buildOutput() {
	SIS_ID="$2"
	CTB_ANIO=""
	CTB_MES=""
	CTB_DIA=""
	CTB_ESTADO=""
	PRES_ID=""
	MT_PRES=""
	MT_IMP=""
	MT_INDE=""
	MT_INNODE=""
	MT_DEB=""
	MT_REST=""
	PRES_CLI=""
	PRES_CLI_ID=""
	CURR_DATE=`date +%d/%m/%Y`
	CURR_USER="$USER"
	VALUE_ERRORS=0
	getValue "CTB_FE" "$3" CTB_DIA CTB_MES CTB_ANIO
	getValue "CTB_ESTADO" "$3" CTB_ESTADO
	getValue "PRES_ID" "$3" PRES_ID
	getValue "PRES_CLI" "$3" PRES_CLI
	getValue "PRES_CLI_ID" "$3" PRES_CLI_ID
	getValue "MT_PRES" "$3" MT_PRES
	getValue "MT_IMPAGO" "$3" MT_IMP
	getValue "MT_INDE" "$3" MT_INDE
	getValue "MT_INNODE" "$3" MT_INNODE
	getValue "MT_DEB" "$3" MT_DEB
	array=("$MT_PRES" "$MT_IMP" "$MT_INDE" "$MT_INNODE")
	calculateRest "$MT_DEB" MT_REST
	if (( $VALUE_ERRORS > 0 ))
	then
		OUTPUT=""
	else
		OUTPUT="$SIS_ID;$CTB_ANIO;$CTB_MES;$CTB_DIA;$CTB_ESTADO;$PRES_ID;$MT_PRES;$MT_IMP;$MT_INDE;$MT_INNODE;$MT_DEB;$MT_REST;$PRES_CLI_ID;$PRES_CLI;$CURR_DATE;$CURR_USER"
	fi
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
			showError "Novedad $1 Rechazada. Motivo: El nombre no cumple el patron" false
			return 1
		fi
		# Habiendo limpiado el nombre (A-6-2017-05 , por ejemplo) me fijo si ya lo procese en este dia)
		if checkIfProcessed "$GRUPO/$PROCESSEDDIR/$CURRENT_DATE/$CHECKED_NAME"
		then
			mvOrFail "$FILE_PATH" "$GRUPO/$REJECTEDDIR" false
			showError "Novedad $CHECKED_NAME rechazada por encontrarse duplicada" false
		else
			# Con el codigo pais y el codigo de sistema, voy a T1 a buscar los separadores de ese sistema
			COUNTRY_CODE=`echo "$CHECKED_NAME" | sed 's/\(.*\)-.*-.*-.*/\1/'`
			SYSTEM_CODE=`echo "$CHECKED_NAME" | sed 's/.*-\(.*\)-.*-.*/\1/'`
			SEPARATORS=`grep "^$COUNTRY_CODE-$SYSTEM_CODE-.*-.*$" "$T1_FILE"`
			if [ -z "$SEPARATORS" ]
			then
				showError "No se encontro en $T1_FILE los separadores para $COUNTRY_CODE - $SYSTEM_CODE" false
			else
				FIELD_SEPARATOR=`echo "$SEPARATORS" | sed 's/^.*-.*-\(.*\)-.*$/\1/'`
				DECIMAL_SEPARATOR=`echo "$SEPARATORS" | sed 's/^.*-.*-.*-\(.*\)$/\1/'` 
				# Con el codigo pais y el codigo sistema, armo el header de T2 (es decir, que campos voy a leer y de que tipo son)
				ROWS=()
				buildHeader "$COUNTRY_CODE" "$SYSTEM_CODE"
				if (( ${#ROWS[@]} == 0 ))
					then
					showError "Novedad $CHECKED_NAME no pudo interpretar bien el archivo $T1_FILE" false
				fi
				# Con los separadores, leo los valores del archivo. Quedna mapeados en el mismo index
				VALUES=()
				buildValues "$FILE_PATH" "$FIELD_SEPARATOR" "$CHECKED_NAME"
			fi
		fi
	done
}

main() {
	if ! validateEnvironment
	then
		showError "Ambiente invalido" false
		return 1
	fi
	if directoryEmpty "$GRUPO/$ACCEPTEDDIR"
	then
		showAlert "$GRUPO/$ACCEPTEDDIR has no files" false
	else
		processFiles "$GRUPO/$ACCEPTEDDIR"
	fi
}

main
