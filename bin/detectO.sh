#!/bin/bash

# *************
# INCLUDES
# *************

source "lib/logger.sh"
ARRIVEDIR="test/arrive"
MAEDIR="mae/"
GRUPO="$PWD/grupo02"
CONFIGDIR="dirconf" # directorio del archivo de configuracion
PRODUCT="DetectO"
DETECTLOGS="$GRUPO/$CONFIGDIR/detect.log"
INFOLOG="INF"
ALERTLOG="ALE"
ERRORLOG="ERR"

# *************
# VARIABLES
# *************

CYCLE_COUNTER=0
DEMON_RUNNING=0

# *************
# LOG AUXILIAR
# *************

# $1: mensaje
# $2: si es false no muestra el resultado por consola
showInfo(){
	saveLog "$DETECTLOGS" "$PRODUCT" "$INFOLOG" "$1" $2
}

showError(){
	saveLog "$DETECTLOGS" "$PRODUCT" "$ERRORLOG" "$1" $2
}

showAlert(){
	saveLog "$DETECTLOGS" "$PRODUCT" "$ALERTLOG" "$1" $2
}

# *************
# FUNCTIONS
# *************


# 1 = false 0 = true
validateEnvironment(){
	return 0
}

# Dispara en back-ground el interprete
# Debe verificar antes que haya archivos aceptados, sino ni lo llama
callInterpreter(){
	echo "Interprete"
}

# Pone a dormir al demonio segun la configuracion de sleep
rest(){
	sleep 5
}

#Verifica nombre de archivo
#$1 : Path del archivo
#return 0 : valid
#		1 : invalid
verifyName(){
	y=${1%.*}
	CLEANED_NAME=`echo ${y##*/}`
	CHECKED_NAME=`echo $CLEANED_NAME | grep '.*-.*-.*-.*'`
	if [ -z "$CHECKED_NAME" ]
	then
		return 1
	fi
	COUNTRY_CODE=`echo $CHECKED_NAME | sed 's/\(.*\)-.*-.*-.*/\1/'`
	SYSTEM_CODE=`echo $CHECKED_NAME | sed 's/.*-\(.*\)-.*-.*/\1/'`
	MASTER_FILE="mae/p-s.mae"
	RESULT=`grep "$COUNTRY_CODE-.*-$SYSTEM_CODE-.*" $MASTER_FILE`
	if [ -z "$RESULT" ]
	then
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
		return 1
	fi
}

#Verifica que el archivo sea de texto
#$1 : Path del archivo
verifyTextFile(){
	TYPE=$(file "$1" | cut -d' ' -f2)
	if [ $TYPE = "ASCII" ]
	then
		return 0
	else
		return 1
	fi
}

#Acepta o rechaza el archivo
#$1 : Path del archivo
#$2 : 1 si se rechaza, 0 si se acepta
manageFile(){
	if [ $2 = 0 ]
	then
		# mvOrFail "$1" "$ACCEPTEDDIR"
		mvOrFail "$1" "test/accepted"
	else
		# mvOrFail "$1" "$REJECTEDDIR"
		mvOrFail "$1" "test/rejected"
	fi
}

# Procesa la validacion y deteccion de archivos aceptados
processFiles() {
	for FILE_PATH in $1/*; do
		if fileExits "$FILE_PATH"
		then
			if verifyName $FILE_PATH
			then
				if verifyEmpty $FILE_PATH
				then
					if verifyTextFile $FILE_PATH
					then
						manageFile $FILE_PATH 0
					else
						manageFile $FILE_PATH 1
					fi
				else
					manageFile $FILE_PATH 1
				fi
			else
				manageFile $FILE_PATH 1
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
	while [ $DEMON_RUNNING = 0 ]
	do			
		if directoryEmpty $ARRIVEDIR
		then
			showAlert $ARRIVEDIR" has no files"
		else
			processFiles $ARRIVEDIR
		fi
		callInterpreter
		rest
	done
}

main


