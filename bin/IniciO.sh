#!/bin/bash

source "lib/ext.sh"
source "lib/logger.sh"
source "lib/requirement.sh"

COMANDOACTUAL="IniciO"
LOGFILE="$GRUPO/$LOGDIR/inicio.log"
DETECTO="DetectO.sh"

############# 1 VERIFICAR ARCHIVO CONFIGURACION #############
configFileVerification(){
	if ! verifyConfigFile
	then
		showError "No se puede continuar ya que no se encontro el archivo de configuracion."
		exit 1
	fi	
}

############# 2 REALIZAR TODAS LAS VERIFICACIONES #############
performVerifications(){

	# corrobora que esten todas las carpetas del sistema dentro del config
	if ! verifyFoldersConfig
	then
		return 1
	fi

	# corroboro si todas las carpetas se encuentran creadas
	if ! verifyFoldersExists
	then
		return 1
	fi

	# corroboro que se encuentren todos los archivos maestros
	if ! verifyTablesAndMasters
	then
		return 1
	fi

	# corroboro que se encuentren todas los ejecutables
	if ! verifyBins
	then
		return 1
	fi

	# corrobora que se encuentran todas las librerias auxiliares del sistema
	if ! verifyLibs
	then
		return 1
	fi

	permissionToDetecto
}


############# 2.2 PERMISO A DETECTO #############
permissionToDetecto(){
	chmod +x "$GRUPO/$BINDIR/$DETECTO"

	showInfo "Se otorgo permiso de ejecucion a $DETECTO"
}

############# 3 VERIFICACION DE PERMISOS DE LECTURA/EJECUCION #############
# $1 - Tipo de archivos a buscar en el config file (maestros o ejecutables)
# $2 - Expresion para obtener permiso de archivo
# $3 - Permiso a comparar
# $4 - Nombre del permiso verificado
checkFilesPermission(){
	
	
	EXPRESION="s#^""$1""-\([^-]*\)-[^-]*-[^-]*$""#\1#"
	DIRECTORIO=`grep "^$1" "$CONFIGFILE" | sed "$EXPRESION"`
	showInfo "Comprobando permisos de $4 para los archivos de $DIRECTORIO"

	for ARCHIVO in $DIRECTORIO/*;
	do
		NOMBRE=`echo "$ARCHIVO" | sed 's#^.*/\([^/]*\)$#\1#'`
		if [ `stat -c %A "$ARCHIVO" | sed "$2"` == "$3" ] 
		then
			showInfo "El archivo $NOMBRE tiene permiso de $4" true
		else
			chmod +"$3" "$ARCHIVO"
			showInfo "Se le otorgo permiso de $4 a $NOMBRE" true
		fi
	done
}

############# 4 DECLARACION DE VARIABLES DE AMBIENTE #############
declareVariables(){
	export GRUPO # directorio de instalacion
	export CONFIGDIR # directorio del archivo de configuracion
	export LIBDIR # directorio donde se depositan las librerias
	export BINDIR # directorio de ejecutables
	export MASTERDIR # directorio de archivos maestros y tablas del sistema
	export ARRIVEDIR # directorio de arribo de archivos externos, es decir, los archivos que remiten las subsidiarias
	export ACCEPTEDDIR # directorio donde se depositan temporalmente las novedades aceptadas
	export REJECTEDDIR # directorio donde se depositan todos los archivos rechazados
	export PROCESSEDDIR # directorio donde se depositan los archivos procesados 
	export REPORTDIR # Directorio donde se depositan los reportes
	export LOGDIR # directorio donde se depositan los logs de los comandos
	export DETECTOSLEEP # tiempo que duerme DetectO.sh
}


############# 5 EJECUCION DE DEMONIO #############
executeDemonio(){
	PID=`pgrep -f "$DETECTO"`
	if [ -z "$PID" ];
	then
		bash "$GRUPO/$BINDIR/$DETECTO" &
		showInfo "Demonio inicializado"
		showInfo "Para detener demonio escribir en la consola 'bash $GRUPO/$BINDIR/StopO.sh $!'"
		PID=$! 
	fi

	showInfo "Demonio corriendo bajo process id: $PID"
}


############# FUNCIONES DE LOG #############
showError(){
	saveLog "$LOGFILE" "$COMANDOACTUAL" "$ERRORLOG" "$1" "$2"
}

showInfo(){
	saveLog "$LOGFILE" "$COMANDOACTUAL" "$INFOLOG" "$1" "$2"
}

showAlert(){
	saveLog "$LOGFILE" "$COMANDOACTUAL" "$ALERTLOG" "$1" "$2"
}

############# MAIN #############

main(){
	#1
	configFileVerification
	
	#2
	if ! performVerifications
	then
		showError "El sistema contiene errores en sus configuración"
		showError "Ejecute la opción -r para reparar el sistema"
		showError "Ejemplo: $GRUPO/$BINDIR/InstalO.sh -r"
		exit 1
	fi

	#3
	checkFilesPermission 'maestros' 's/.\(.\).\+/\1/' 'r' 'lectura'
	checkFilesPermission 'ejecutables' 's/...\(.\).\+/\1/' 'x' 'ejecucion'
	
	#5
	declareVariables
	
	#6
	executeDemonio

	showInfo "¡Proceso de inicializacion finalizado!" true
}

main $@