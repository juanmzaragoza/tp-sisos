#!/bin/bash

source "ext.sh"

#################################################
#
# Loguea resultados de sistema
# * Informativos
# * Alertas
# * Errores
#
#################################################

# ----------------------------------------
# genera una fila para el registro de log
# $1: Comando, función o rutina que produce el evento que se registra en el log. Ej.: InstalO
# $2: Tipo de mensaje: Informativo (INF), Alerta (ALE) Error (ERR)
# $3: Mensaje de log
#
generateRow(){
	$DATE=`date '+%Y-%m-%d %H:%M:%S'`
	$USER=`echo $USER`
	$ORIGIN=$1
	$ERRORTYPE=$2
	$MESSAGE=$3
	echo "$DATE-$USER-$ORIGIN-$ERRORTYPE-$MESSAGE"
}

# ---------------------------------------------------
# graba un registro en el archivo de log especificado
# $1: Archivo en el cual grabar
# $2: Comando, función o rutina que produce el evento que se registra en el log. Ej.: InstalO
# $3: Tipo de mensaje: Informativo (INF), Alerta (ALE) Error (ERR)
# $4: Mensaje de log
#
saveLog(){

	if canWriteFile
	then
		generateRow $2 $3 $4 > $1
	fi
}