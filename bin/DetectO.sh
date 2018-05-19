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

PRODUCT="DetectO"
CHILD_PRODUCT="InterpretO"
LOGFILE="$GRUPO/$LOGDIR/detect.log"
MASTER_FILE="p-s.mae"
MASTER_FILE_KIND="ASCII"
INFOLOG="INF"
ALERTLOG="ALE"
ERRORLOG="ERR"
CYCLE_COUNTER=0

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


# 1 = false 0 = true
validateEnvironment(){
	# if ! verifyConfigFile
	# then
	# 	showError "No se puede continuar ya que no se encontro el archivo de configuracion."
	# 	exit 1
	# fi	
	return 0
}

# Dispara en back-ground el interprete
# Debe verificar antes que haya archivos aceptados, sino ni lo llama
callInterpreter(){
	# if directoryEmpty "$GRUPO/$ACCEPTEDDIR"
	# then
	# 	showInfo "No hay archivos aceptados para interpretar"
	# 	return
	# fi
	# PID=`pgrep -f "$CHILD_PRODUCT"`
	# if [ -z "$PID" ];
	# then
	# 	bash "$GRUPO/$BINDIR/$CHILD_PRODUCT" &
	# 	PID=$!
	# 	showInfo "Interprete inicializado con id $PID"
	# else
	# 	showInfo "Invocacion del interprete pospuesta para el siguiente ciclo"
	# fi
	echo "INTERPRETE"
}

# Pone a dormir al demonio segun la configuracion de sleep
rest(){
	sleep "$DETECTOSLEEP"
}

#Verifica nombre de archivo
#$1 : Path del archivo
#return 0 : valid
#		1 : invalid
verifyName(){
	y=${1%.*}
	CLEANED_NAME=`echo ${y##*/}`
	CHECKED_NAME=`echo $CLEANED_NAME | grep '^.*-.*-.*-.*$'`
	if [ -z "$CHECKED_NAME" ]
	then
		showError "Novedad $1 Rechazada. Motivo: El nombre no cumple el patron"
		return 1
	fi
	COUNTRY_CODE=`echo $CHECKED_NAME | sed 's/\(.*\)-.*-.*-.*/\1/'`
	SYSTEM_CODE=`echo $CHECKED_NAME | sed 's/.*-\(.*\)-.*-.*/\1/'`
	MASTER="$GRUPO/$MASTERDIR/$MASTER_FILE"
	RESULT=`grep "$COUNTRY_CODE-.*-$SYSTEM_CODE-.*" $MASTER`
	if [ -z "$RESULT" ]
	then
		showError "Novedad $CHECKED_NAME Rechazada. Motivo: El maestro no tiene registros con la combinacion $COUNTRY_CODE y $SYSTEM_CODE"
		return 1
	fi
	YEAR=`echo $CHECKED_NAME | sed 's/.*-.*-\(.*\)-.*/\1/' | grep "[0-9][0-9][0-9][0-9]"`
	if [ -z $YEAR ]
	then
		showError "Novedad $CHECKED_NAME Rechazada. Motivo: Error obteniendo el año de la novedad"
		return 1
	fi
	MONTH=`echo $CHECKED_NAME | sed 's/.*-.*-.*-\(.*\)/\1/' | grep "[0-1][0-9]"`
	if [ -z $MONTH ]
	then
		showError "Novedad $CHECKED_NAME Rechazada. Motivo: Error obteniendo el mes de la novedad"
		return 1 
	fi
	CURRENT_YEAR=`date +%Y`
	CURRENT_MONTH=`date +%m`
	if (( $YEAR <= 2016 || $YEAR > $CURRENT_YEAR ))
	then
		showError "Novedad $CHECKED_NAME Rechazada. Motivo: El año del período esta fuera del rango"
		return 1
	elif (( $YEAR != $CURRENT_YEAR )) ;	then
		return 0
	elif (( $YEAR == $CURRENT_YEAR && $MONTH > $CURRENT_MONTH )) ; then
		showError "Novedad $CHECKED_NAME Rechazada. Motivo: El período es incorrecto"
		return 1
	else
		return 0
	fi
}

#Verifica vacio de archivo
#$1 : Path del archivo
verifyEmpty(){
	if [ -s $1 ]
	then
		return 0
	else
		showError "Novedad $1 Rechazada. Motivo: El archivo esta vacio"
		return 1
	fi
}

#Verifica que el archivo sea de texto
#$1 : Path del archivo
verifyTextFile(){
	TYPE=$(file "$1" | cut -d' ' -f2)
	if [ $TYPE = "$MASTER_FILE_KIND" ]
	then
		return 0
	else
		showError "Novedad $1 Rechazada. Motivo: El archivo no es de texto"
		return 1
	fi
}

#Acepta o rechaza el archivo
#$1 : Path del archivo
#$2 : 1 si se rechaza, 0 si se acepta
manageFile(){
	if [ "$2" = 0 ]
	then
		mvOrFail "$1" "$GRUPO/$ACCEPTEDDIR"
		showInfo "Novedad $1 Aceptada"
	else
		mvOrFail "$1" "$GRUPO/$REJECTEDDIR"
	fi
}

# Procesa la validacion y deteccion de archivos aceptados
processFiles() {
	for FILE_PATH in "${1}/"*; do
		if fileExits "$FILE_PATH"
		then
			if verifyName "$FILE_PATH"
			then
				if verifyEmpty "$FILE_PATH"
				then
					if verifyTextFile "$FILE_PATH"
					then
						manageFile "$FILE_PATH" 0
					else
						manageFile "$FILE_PATH" 1
					fi
				else
					manageFile "$FILE_PATH" 1
				fi
			else
				manageFile "$FILE_PATH" 1
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
	while true
	do			
		CYCLE_COUNTER=$(( CYCLE_COUNTER + 1))
		showInfo "Ciclo Numero $CYCLE_COUNTER" 
		if directoryEmpty "$GRUPO/$ARRIVEDIR"
		then
			showAlert "$GRUPO/$ARRIVEDIR has no files"
		else
			processFiles "$GRUPO/$ARRIVEDIR"
		fi
		callInterpreter
		rest
	done
}

main


