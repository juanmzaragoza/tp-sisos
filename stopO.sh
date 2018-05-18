#!/bin/bash

source "lib/logger.sh"
source "lib/requirement.sh"

COMANDOACTUAL="STOPO"
LOGFILE="$GRUPO/$CONFIGDIR/inicio.log"

main(){

	PROCESS=`ps -p "$1" | sed -n 2p`
	if [ -z "$PROCESS" ];
	then
		saveLog "$LOGFILE" "$COMANDOACTUAL" "$INF" "No se encontro ningun proceso demonio corriendo" true
	else
		kill -9 "$1"
		saveLog "$LOGFILE" "$COMANDOACTUAL" "$INF" "Se detuvo el demonio con process ID $1" true
	fi

	exit 0
}

main $@