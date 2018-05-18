#!/bin/bash

source "lib/ext.sh"
source "lib/logger.sh"
source "lib/requirement.sh"

COMANDOACTUAL="INICIO"
LOGFILE="$GRUPO/$CONFIGDIR/inicio.log"
REGEX="^\(.*\)-\(.*\)-.*-.*$"


############# 1 VERIFICAR ARCHIVO CONFIGURACION #############
verificarArchivoConfiguracion(){
	if ! verifyConfigFile
	then
		showError "No se puede continuar ya que no se encontro el archivo de configuracion." true
		exit 1
	fi	
}

############# 2 VERIFICAR INICIALIZACION #############
verificarInicializacion(){
	verifyFoldersConfig
	verifyFoldersExists
	#verifyTablesAndMasters
	verifyComandos
	permissionToDetecto
}


############# 2.1 VERIFICACION COMANDOS #############
verifyComandos(){

	COMANDOS=("detectO.sh" "interpretO.sh" "reportO.sh" "stopO.sh")
	showInfo "Corroborando que todas los comandos existan..."
	COUNT=0
	for COMANDO in ${COMANDOS[@]}
		do
			if [ ! -f "$COMANDO" ]
			then
				showError "El comando $COMANDO no existe" true
				showInfo ""
				exit 1
			fi
		done
	showInfo "Se encontraron todos los comandos"
	showInfo ""

	echo "verify comandos ok"
}


############# 2.2 PERMISO A DETECTO #############
permissionToDetecto(){
	chmod +x "detectO.sh"

	showInfo "Se otorgo permiso de ejecucion a detectO.sh" true

}


############# 3 VERIFICACION DE PERMISOS DE LECTURA/EJECUCION #############
checkFilesPermission(){
	#1 Tipo de archivos a buscar en el config file (maestros o ejecutables)
	#2 Expresion para obtener permiso de archivo
	#3 Permiso a comparar
	#4 Nombre del permiso verificado
	
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
	while read -r lineConfig
	do
		NOMBRE=`echo "$lineConfig" | sed "s/^\(.*\)-.*-.*-.*/\1/"`
		VALOR=`echo "$lineConfig" | sed "s/^.*-\(.*\)-.*-.*/\1/"`

		eval "$NOMBRE"="$VALOR"
		export NOMBRE
	done <  "$CONFIGFILE"
}


############# 5 EJECUCION DE DEMONIO #############
executeDemonio(){
	PID=`pgrep -f "detectO.sh"`
	if [ -z "$PID" ];
	then
		bash detectO.sh &
		showInfo "Demonio inicializado" true
		showInfo "Para detener demonio escribir en la consola 'bash stopO.sh $!'" true
		PID=$! 
	fi

	showInfo "Demonio corriendo bajo process id: $PID" true
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
	verificarArchivoConfiguracion
	
	#2
	verificarInicializacion

	#3
	checkFilesPermission 'maestros' 's/.\(.\).\+/\1/' 'r' 'lectura'
	checkFilesPermission 'ejecutables' 's/...\(.\).\+/\1/' 'x' 'ejecucion'
	
	#5
	declareVariables
	
	#6
	executeDemonio
}

main $@

# el sistema nunca fue inicializado
#	verificar existencia del config, existencia de todos los directorios en el config y verificar las carpetas
#	verificar existencia: comandos(detecto, stopO, interpretO, reportO), archivos (maestros, dirconf/install.conf)
#	dar permiso de ejecucion al detectO
#	verificar permisos
#	setear variables de ambientes necesarias en el demonio y guardarlas en el profile (no olvidar >>) (borrarlas en el stopO)
#	preguntar si corre domonio (grep detecto devuelve la linea con PID)
		#si corre, logueo process id
		#sino, inicializar demonio, mostrar y loguear pid

# Crear stopO: consulta si existe demonio corriendo, si existe darle kill -9 PID, loguear y mostrar por pantalla
