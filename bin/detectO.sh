#!/bin/bash

# *************
# INCLUDES
# *************

source "lib/logger.sh"
ARRIVEDIR="arrive"
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
validateEnvironment() {
	return 0
}

# Dispara en back-ground el interprete
# Debe verificar antes que haya archivos aceptados, sino ni lo llama
callInterpreter() {
}

# Pone a dormir al demonio segun la configuracion de sleep
rest() {

}

# Procesa la validacion y deteccion de archivos aceptados
processFiles() {
	# for each file..		
	if verifyName and verifyEmpty and verifyTextFile # paso x argumento de archivo
		acceptFile 
}


main() {
	# Primer paso, llamar a la funcion que va a validar el ambiente.
	if ! validateEnvironment
	then
		showError "Ambiente invalido"
		return 1
	fi

	if directoryEmpty $ARRIVEDIR
	then
		showAlert $ARRIVEDIR" has no files"
	else
		processFiles
	fi
	callInterpreter
	rest
	
}

main


