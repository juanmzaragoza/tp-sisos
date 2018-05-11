#!/bin/bash

source "lib/ext.sh"

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

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# FUNCIONES
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# devuelve true si es valida
installIsValid() {
	# 1 = false 0 = true
	return 0
}

########################
# realizar instalacion
########################
installSystem(){

	echo ""
	echo "El sistema será instalado por primera vez en su entorno"

	# corroborar version de perl
	checkPerlVersion

	# mientras que el usuario no acepte la configuracion
	while true
	do

		echo "Para poder continuar, se le solicita que configure cada uno de los siguientes directorios"
		# configurar con los valores ingresados por el usuario
		configure

		# mostrar configuracion
		showConfiguration

		# confirmacion de instalacion
		if confirmPrompt "¿Confirma la instalación? (SI-NO): " "SI"
		then
			break
		fi
		echo ""

	done
	
	
}

# verifica la version de bash instalada
checkPerlVersion(){

	echo ""
	echo "Comprobando version de Perl...."

	PERL_VERSION=`perl -v`
	RE_PERL_VERSION="This is perl [5-9].*$"
	if [[ ! "$PERL_VERSION" =~ $RE_PERL_VERSION ]]
	then
		# TODO: loggear
		echo "La versión instalada no cumple con los requerimientos de sistema [Perl >=5 ]"
		exit 1
	else
		echo $PERL_VERSION
		echo ""
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
		TEMPDIR="$GRUPO/$userfolder"

		# checkear que el directorio no existe
		if directoryExists "$TEMPDIR"
		then

			echo "El directorio ingresado ya existe"

		# checkear que no se ingrese dirconfig
		elif [[ "$userfolder" == "$CONFIGDIR" ]]
		then

			echo "El directorio no se puede llamar dirconf"

		# dejo por defecto el que estaba
		elif [[ -z "$userfolder" ]]
		then

			echo "Directorio configurado: $GRUPO/$2"
			break

		else

			DIRS[$3]=$userfolder
			echo "Directorio configurado: $GRUPO/${DIRS[$3]}"
			break

		fi
	done
	

}

# mostrar configuracion parcial
showConfiguration(){
	echo ""
	echo "==============================================================================="
	echo " Configuracion TP SO7508 Primer Cuatrimestre 2018. Tema O Copyright © Grupo 02 "
	echo "==============================================================================="
	echo "Librería del Sistema: dirconf"
	COUNT=0
	for i in ${DIRS[@]}; do
        echo "Directorio para ${NAMES[$COUNT]}: $i"
        COUNT=`expr $COUNT + 1`
	done
	echo "Estado de instalación: LISTA"

}

# realizar reparacion
repairSystem(){
	echo "Necesitar reparar el sistema"
}

# el sistema ya se encuentra instalado
showInfoSystem(){
	echo ""
	echo "Ya posee una versión del sistema instalada en su entorno"
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# MAIN
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
main(){
	echo ""
	echo "============================================================================================================="
	echo "    Bienvenido a la instalacion del sistema TP SO7508 Primer Cuatrimestre 2018. Tema O Copyright © Grupo 02"
	echo "============================================================================================================="
	echo ""

	echo "Este sistema lo guiará en la instalación de TPSO en su sistema operativo"
	echo ""
	echo "Asegurese de tener los permisos necesario para el directorio donde va a "
	echo "realizar la instalación como una version de PERL 5 o superior"
	read -n 1 -p "Presione una tecla para continuar..." continueinput
	echo ""

	# iniciar instalacion
	if ! directoryExists "$GRUPO"
	then

		installSystem

	elif ! installIsValid
	then

		repairSystem

	else

		showInfoSystem

	fi

	echo ""
}

main