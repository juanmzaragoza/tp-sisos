#!/bin/bash

source "lib/ext.sh"
source "lib/logger.sh"

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# VARIABLES
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
GRUPO="$PWD/grupo02"

CONFIGDIR="dirconf" # directorio del archivo de configuracion
BINDIR="bin" # directorio de ejecutables
MASTERDIR="master" # directorio de archivos maestros y tablas del sistema
ARRIVEDIR="arrive" # directorio de arribo de archivos externos, es decir, los archivos que remiten las subsidiarias
ACCEPTEDDIR="accepted" # directorio donde se depositan temporalmente las novedades aceptadas
REJECTEDDIR="rejected" # directorio donde se depositan todos los archivos rechazados
PROCESSEDDIR="processed" # directorio donde se depositan los archivos procesados 
REPORTDIR="report" # Directorio donde se depositan los reportes
LOGDIR="log" # directorio donde se depositan los logs de los comandos

DIRS=($BINDIR $MASTERDIR $ARRIVEDIR $ACCEPTEDDIR $REJECTEDDIR $PROCESSEDDIR $REPORTDIR $LOGDIR)
NAMES=(ejecutables maestros arribos aceptados rechazados procesados reportes logs)
INDEXBINDIR=0
INDEXMASTERDIR=1

PRODUCT="InstalO"
INTALLLOGS="$GRUPO/$CONFIGDIR/install.log"
INFOLOG="INF"
ALERTLOG="ALE"
ERRORLOG="ERR"
CONFIGFILE="$GRUPO/$CONFIGDIR/install.conf"

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# FUNCIONES
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# devuelve true si es valida
installIsValid() {
	# 1 = false 0 = true
	return 0
}

# $1: mensaje
# $2: si es false no muestra el resultado por consola
showInfo(){
	saveLog "$INTALLLOGS" "$PRODUCT" "$INFOLOG" "$1" $2
}

showError(){
	saveLog "$INTALLLOGS" "$PRODUCT" "$ERRORLOG" "$1" $2
}

showAlert(){
	saveLog "$INTALLLOGS" "$PRODUCT" "$ALERTLOG" "$1" $2
}

# ------------------------------------------------------
# devuelve true si el usuario ha confirmado la operacion
# $1: mensaje a mostrar
# $2: respuesta que se esperamos como afirmativa
#
confirmPrompt(){
	read -p "$1" userinput
	showInfo "$1 $userinput" false
	if [[ "$userinput" == "$2" ]]
	then
		return 0
	else
		return 1
	fi
}

########################
# realizar instalacion
########################
installSystem(){

	showInfo ""
	showInfo "El sistema será instalado por primera vez en su entorno"

	# corroborar version de perl
	checkPerlVersion

	# mientras que el usuario no acepte la configuracion
	while true
	do

		showInfo "Para poder continuar, se le solicita que configure cada uno de los siguientes directorios"
		# configurar con los valores ingresados por el usuario
		configure

		# mostrar configuracion
		showConfiguration

		# confirmacion de instalacion
		if confirmPrompt "¿Confirma la instalación? (SI-NO): " "SI"
		then
			break
		fi
		showInfo ""

	done

	# crear estructura de directorios
	createDirectories

	# mover tablas de /mae a $GRUPO/maestros
	moveToMaster

	# mover ejecutables de /bin a $GRUPO/ejecutables
	moveToBin

	# guardar configuracion
	saveConfigurationFile

	showInfo "Felicitaciones! Ha finalizado con exito la instalacion del sistema!!!"
	showInfo ""
	
}

# verifica la version de bash instalada
checkPerlVersion(){

	showInfo ""
	showInfo "Comprobando version de Perl...."

	PERL_VERSION=`perl -v`
	RE_PERL_VERSION="This is perl [5-9].*$"
	if [[ ! "$PERL_VERSION" =~ $RE_PERL_VERSION ]]
	then
		showError "La versión instalada no cumple con los requerimientos de sistema [Perl >=5 ]"
		exit 1
	else
		showInfo "$PERL_VERSION"
		showInfo ""
	fi
}

# establece la configuracion de directorios
configure(){

	COUNT=0
	for i in ${DIRS[@]}; do
        readConfiguration ${NAMES[$COUNT]} $i $COUNT
        COUNT=`expr $COUNT + 1`
	done
	
}

# leer la configuracion que eligio el usuario
readConfiguration(){

	while true
	do
		read -p "Establecer directorio de $1 ($GRUPO/$2): " userfolder
		showInfo "Establecer directorio de $1 ($GRUPO/$2):  $userfolder" false

		TEMPDIR="$GRUPO/$userfolder"

		# dejo por defecto el que estaba
		if [[ -z "$userfolder" ]]
		then

			showInfo "Directorio configurado: $GRUPO/$2"
			break

		# checkear que el directorio no existe
		elif directoryExists "$TEMPDIR"
		then

			showAlert "El directorio ingresado ya existe"

		# checkear que no se ingrese dirconfig
		elif [[ "$userfolder" == "$CONFIGDIR" ]]
		then

			showAlert "El directorio no se puede llamar dirconf"

		# no puedeo haber nombres de directorios duplicados
		elif [[ " ${DIRS[*]} " == *" $userfolder "* ]]
		then

			showAlert "El directorio ya ha sido elegido para otro directorio. Repita con uno diferente"

		else

			DIRS[$3]=$userfolder
			showInfo "Directorio configurado: $GRUPO/${DIRS[$3]}"
			break

		fi
	done
	

}

# mostrar configuracion parcial
showConfiguration(){
	showInfo ""
	showInfo "==============================================================================="
	showInfo " Configuracion TP SO7508 Primer Cuatrimestre 2018. Tema O Copyright © Grupo 02 "
	showInfo "==============================================================================="
	showInfo "Librería del Sistema: dirconf"
	COUNT=0
	for i in ${DIRS[@]}; do
        showInfo "Directorio para ${NAMES[$COUNT]}: $i"
        COUNT=`expr $COUNT + 1`
	done
	showInfo "Estado de instalación: LISTA"

}

# crear estructura de directorios
createDirectories(){

	showInfo ""
	COUNT=0
	for i in ${DIRS[@]}
	do
        mkdir "$GRUPO/$i" 
        showInfo "Se creó el directorio de ${NAMES[$COUNT]} en $GRUPO/$i"
        COUNT=`expr $COUNT + 1`
	done
	showInfo "Finalizada con exito la creacion de directorios"
	showInfo ""

}

# mover tablas de /mae a $GRUPO/maestros
moveToMaster(){

	RESULT=`ls mae/* 2>/dev/null`
	if [ $? != 0 ]
	then
	   	showAlert "La carpeta mae/ se encuentra vacia"
	else
		for i in $RESULT
		do
			cpOrExitOnError "$i" "$GRUPO/${DIRS[$INDEXMASTERDIR]}/"
		done
	fi
	showInfo "Finalizada con exito la copia de archivos maestros"
	showInfo ""
}

# mover ejecutables de /bin a $GRUPO/ejecutables
moveToBin(){

	RESULT=`ls bin/* 2>/dev/null`
	if [ $? != 0 ]
	then
	   	showAlert "La carpeta bin/ se encuentra vacia"
	else
		for i in $RESULT
		do
			cpOrExitOnError "$i" "$GRUPO/${DIRS[$INDEXBINDIR]}/"
		done
	fi
	showInfo "Finalizada con exito la copia de archivos ejecutables"
	showInfo ""
	

}

# guardar archivo de configuracion
saveConfigurationFile(){
	
	SAVECONFIGURATIONDATE=`date '+%Y/%m/%d %H:%M:%S'`

	COUNT=0
	for i in ${DIRS[@]}
	do
		LINE="${NAMES[$COUNT]}-$GRUPO/$i-$USER-$SAVECONFIGURATIONDATE"
		if ! fileExits "$CONFIGFILE"
		then
			echo "$LINE" > "$CONFIGFILE"
		else
			echo "$LINE" >> "$CONFIGFILE"
		fi
        showInfo "Agregado ${NAMES[$COUNT]} a la configuracion "
        COUNT=`expr $COUNT + 1`
	done
	showInfo "Finalizada con exito la configuracion del sistema"
	showInfo ""

}

# realizar reparacion
repairSystem(){
	echo "Necesitar reparar el sistema"
}

# el sistema ya se encuentra instalado
showInfoSystem(){
	showInfo ""
	showAlert "Ya posee una versión del sistema instalada en su entorno"
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# MAIN
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
main(){
	showInfo ""
	showInfo "============================================================================================================="
	showInfo "    Bienvenido a la instalacion del sistema TP SO7508 Primer Cuatrimestre 2018. Tema O Copyright © Grupo 02"
	showInfo "============================================================================================================="
	showInfo ""

	showInfo "Este sistema lo guiará en la instalación de TPSO en su sistema operativo"
	showInfo ""
	showInfo "Asegurese de tener los permisos necesario para el directorio donde va a "
	showInfo "realizar la instalación como una version de PERL 5 o superior"
	
	read -n 1 -p "Presione una tecla para continuar... $continueinput" continueinput
	showInfo "Presione una tecla para continuar... $continueinput" false
	showInfo ""

	# iniciar instalacion
	if ! fileExits "$CONFIGFILE"
	then

		showInfo "Se procedera con la instalacion"
		installSystem

	elif ! installIsValid
	then

		showInfo "Se procedera con la reparacion"
		repairSystem

	else

		showInfoSystem

	fi

	echo ""
}

main