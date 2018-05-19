#!/bin/bash

GRUPO="$PWD/grupo02"

CONFIGDIR="dirconf" # directorio del archivo de configuracion
LIBDIR="lib" # directorio donde se depositan las librerias
BINDIR="bin" # directorio de ejecutables
MASTERDIR="master" # directorio de archivos maestros y tablas del sistema
ARRIVEDIR="arrive" # directorio de arribo de archivos externos, es decir, los archivos que remiten las subsidiarias
ACCEPTEDDIR="accepted" # directorio donde se depositan temporalmente las novedades aceptadas
REJECTEDDIR="rejected" # directorio donde se depositan todos los archivos rechazados
PROCESSEDDIR="processed" # directorio donde se depositan los archivos procesados 
REPORTDIR="report" # Directorio donde se depositan los reportes
LOGDIR="log" # directorio donde se depositan los logs de los comandos

EXECUTABLES=("IniciO.sh" "DetectO.sh" "StopO.sh" "InterpretO.sh" "ReportO.pl")
INDEXINICIOEXEC=0

DIRS=($BINDIR $MASTERDIR $ARRIVEDIR $ACCEPTEDDIR $REJECTEDDIR $PROCESSEDDIR $REPORTDIR $LOGDIR) # directorios a configurar
NAMES=(ejecutables maestros arribos aceptados rechazados procesados reportes logs) # nombre de los directorios a configurar en el install.conf
# indices de los arrays de arriba
INDEXBINDIR=0 
INDEXMASTERDIR=1
INDEXARRIVEDIR=2

INFOLOG="INF"
ALERTLOG="ALE"
ERRORLOG="ERR"
CONFIGFILE="$GRUPO/$CONFIGDIR/install.conf" # config file

DETECTOSLEEP=60 # tiempo que duerme DetectO.sh

# verifica que existe el config file
verifyConfigFile(){
	showInfo "Corroborando si existe el archivo de configuración..."
	if ! fileExits "$CONFIGFILE"
	then
		showAlert "El archivo de $CONFIGFILE no existe"
		showInfo ""
		return 1
	fi
	showInfo "Existe $CONFIGFILE OK"
	showInfo ""
	return 0
}
# verifica que existan todas las carpetas en el config file
verifyFoldersConfig(){
	showInfo "Corroborando que todas las carpetas se encuentren configuradas..."
	COUNT=0
	for i in ${NAMES[@]}
	do
		LINECOUNT=`grep -c "^${NAMES[$COUNT]}-.*" "$CONFIGFILE"`
		if [[ "$LINECOUNT" -eq 0 ]]
		then
			showAlert "El directorio de ${NAMES[$COUNT]} no se encuentra definido"
			showInfo ""
			return 1
		fi
		showInfo "Carpeta ${NAMES[$COUNT]} configurada en config OK"
        COUNT=`expr $COUNT + 1`
	done
	showInfo "Carpetas del sistema configuradas OK"
	showInfo ""
	return 0
}
# verifica que se encuentren todas las carpetas del config file
verifyFoldersExists(){
	showInfo "Corroborando si existe las carpetas configuradas en el archivo de configuración..."
	while read -r lineConfig
	do

		LINECONFIG=`echo "$lineConfig" | sed "s/^.*-\(.*\)-.*-.*/\1/"`
		if ! directoryExists "$LINECONFIG"
		then
			showAlert "La carpeta $LINECONFIG no existe"
			showInfo ""
			return 1
		fi
		showInfo "Carpeta $LINECONFIG OK"

	done < "$CONFIGFILE"
	showInfo "Carpetas OK"
	showInfo ""
	return 0
}
# verifica si los tablas y archivos maestros existen
verifyTablesAndMasters(){
	showInfo "Corroborando si se encuentran las tablas y archivos maestros..."
	MASTERDIRCONFIG=`grep "^maestros-\(.*\)-.*-.*$" "$CONFIGFILE" | sed "s/^\(maestros\)-\(.*\)-.*-.*$/\2/"`

	if ! fileExits "$MASTERDIRCONFIG/PPI.mae"
	then
		showAlert "No existe el archivo $MASTERDIRCONFIG/PPI.mae"
		showAlert ""
		return 1
	fi
	showInfo "Archivo $MASTERDIRCONFIG/PPI.mae OK"

	if ! fileExits "$MASTERDIRCONFIG/p-s.mae"
	then
		showAlert "No existe el archivo $MASTERDIRCONFIG/p-s.mae"
		showAlert ""
		return 1
	fi
	showInfo "Archivo $MASTERDIRCONFIG/p-s.mae OK"

	if ! fileExits "$MASTERDIRCONFIG/T1.tab"
	then
		showAlert "No existe el archivo $MASTERDIRCONFIG/T1.tab"
		showAlert ""
		return 1
	fi
	showInfo "Archivo $MASTERDIRCONFIG/T1.tab OK"

	if ! fileExits "$MASTERDIRCONFIG/T2.tab"
	then
		showAlert "No existe el archivo $MASTERDIRCONFIG/T2.tab"
		showAlert ""
		return 1
	fi
	showInfo "Archivo $MASTERDIRCONFIG/T2.tab OK"
	showInfo "Archivos maestros OK"
	showInfo ""
	return 0
}
# verifica si los ejecutables existen
verifyBins(){
	showInfo "Corroborando si se encuentran los archivos ejecutables..."
	LIBBINFULL="$GRUPO/$BINDIR"
	for i in ${EXECUTABLES[@]}
	do
		if ! fileExits "$LIBBINFULL/$i"
		then
			showAlert "No existe el archivo $LIBBINFULL/$i"
			showAlert ""
			return 1
		fi
		showInfo "Archivo $LIBBINFULL/$i OK"
	done
	showInfo "Archivos ejecutables OK"
	showInfo ""
	return 0
}
# verifica si las librerias auxialiares existen
verifyLibs(){
	showInfo "Corroborando si se encuentran las librerias auxialiares..."
	LIBDIRFULL="$GRUPO/$LIBDIR"

	if ! fileExits "$LIBDIRFULL/ext.sh"
	then
		showAlert "No existe el archivo $LIBDIRFULL/ext.sh"
		showAlert ""
		return 1
	fi
	showInfo "Archivo $LIBDIRFULL/ext.sh OK"

	if ! fileExits "$LIBDIRFULL/logger.sh"
	then
		showAlert "No existe el archivo $LIBDIRFULL/logger.sh"
		showAlert ""
		return 1
	fi
	showInfo "Archivo $LIBDIRFULL/logger.sh OK"

	if ! fileExits "$LIBDIRFULL/requirement.sh"
	then
		showAlert "No existe el archivo $LIBDIRFULL/requirement.sh"
		showAlert ""
		return 1
	fi
	showInfo "Archivo $LIBDIRFULL/requirement.sh OK"
	showInfo "Archivos de librerias auxialiares OK"
	showInfo ""
	return 0
}
