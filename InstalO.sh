#!/bin/bash

source "lib/ext.sh"
source "lib/logger.sh"
source "lib/requirement.sh"

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# VARIABLES
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
OPT_REPAIR="-r"

PRODUCT="InstalO"
INTALLLOGS="$GRUPO/$CONFIGDIR/install.log"

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# FUNCIONES
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

#
# Devuelve si la instalacion es valid 
# 1 = false 0 = true
#
installIsValid() {
	
	showInfo "Se procederá con la verificación de archivos y carpetas necesarios para el sistema"

	# corroboro si existe el archivo de confiuracion
	if ! verifyConfigFile
	then
		return 1
	fi

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
		showPartialConfiguration

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

	# mover librerias auxiliares de /lib a $GRUPO/lib
	moveToLib

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

#
# leer la configuracion que eligio el usuario
# $1 carpeta de ejecutables, maestros, etc
# $2 directorio de $1 
# $3 posicion del parametros de los arrays NAMES Y DIRS
# $4 si es 0 no consulta por un directorio a definir por el usuario
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

		# checkear que no se ingrese lib (nombre reservado por nosotros)
		elif [[ "$userfolder" == "$LIBDIR" ]]
		then

			showAlert "El directorio no se puede llamar lib"

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
showPartialConfiguration(){
	printHeaderConfig
	COUNT=0
	for i in ${DIRS[@]}; do
        showInfo "Directorio para ${NAMES[$COUNT]}: $i"
        COUNT=`expr $COUNT + 1`
	done
	showInfo "Estado de instalación: LISTA"

}

# mostrar configuracion del sistema
showConfiguration(){
	printHeaderConfig
	showInfo "Archivo de configuracion: $CONFIGFILE"
	COUNT=0
	while read -r lineConfig
	do
		FILESDIR=`echo "$lineConfig" | sed "s/^\(.*\)-.*-.*-.*/\1/"`
		DIR=`echo "$lineConfig" | sed "s/^.*-\(.*\)-.*-.*/\1/"`
		showInfo "Directorio para $FILESDIR: $DIR"
        COUNT=`expr $COUNT + 1`
	done <  "$CONFIGFILE"

}

printHeaderConfig(){
	showInfo ""
	showInfo "==============================================================================="
	showInfo " Configuracion TP SO7508 Primer Cuatrimestre 2018. Tema O Copyright © Grupo 02 "
	showInfo "==============================================================================="
	showInfo "Librería del Sistema: $CONFIGDIR"
	showInfo "Librerías auxiliares del Sistema: $LIBDIR"
}

# crear estructura de directorios
createDirectories(){

	showInfo ""
	COUNT=0
	# creacion carpetas del sistema
	for i in ${DIRS[@]}
	do
        mkdir "$GRUPO/$i" 
        showInfo "Se creó el directorio de ${NAMES[$COUNT]} en $GRUPO/$i"
        COUNT=`expr $COUNT + 1`
	done

	# creacion carpeta de librerias auxiliares
	mkdir "$GRUPO/$LIBDIR" 
	showInfo "Se creó el directorio de librerias auxiliares en $GRUPO/$LIBDIR"

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

	# dar permisos de ejecucion a IniciO.sh
	`chmod +x "$GRUPO/${DIRS[$INDEXBINDIR]}/${EXECUTABLES[$INDEXINICIOEXEC]}" 2>/dev/null`
	if [[ -x "$GRUPO/${DIRS[$INDEXBINDIR]}/${EXECUTABLES[$INDEXINICIOEXEC]}" ]]
	then
		showInfo "Permisos a IniciO.sh OK"
	else
		showError "ERROR - No se pudo dar permisos a IniciO.sh"
		exit 1
	fi	

	showInfo "Finalizada con exito la copia de archivos ejecutables"
	showInfo ""
	

}

# mover librerias auxiliares de /lib a $GRUPO/lib
moveToLib(){

	RESULT=`ls lib/* 2>/dev/null`
	if [ $? != 0 ]
	then
	   	showAlert "La carpeta $LIBDIR/ se encuentra vacia"
	else
		for i in $RESULT
		do
			cpOrExitOnError "$i" "$GRUPO/$LIBDIR/"
		done
	fi
	showInfo "Finalizada con exito la copia de archivos de librerias auxiliares"
	showInfo ""
}

# guardar archivo de configuracion
# notar que corrobora si el archivo existe y en ese caso solo inserto la linea si no hay ninguna configurada
saveConfigurationFile(){
	
	SAVECONFIGURATIONDATE=`date '+%Y/%m/%d %H:%M:%S'`

	COUNT=0
	for i in ${DIRS[@]}
	do
		LINE="${NAMES[$COUNT]}-$GRUPO/$i-$USER-$SAVECONFIGURATIONDATE"
		if ! fileExits "$CONFIGFILE" # si el archivo no existe
		then
			echo "$LINE" > "$CONFIGFILE"		
		else # si el archivo existe
			LINEXISTS=`grep "^${NAMES[$COUNT]}-.*-.*-.*$" "$CONFIGFILE"`
			if [[ -z "$LINEXISTS" ]] # si no hay ninguna linea ya configurada
			then
				echo "$LINE" >> "$CONFIGFILE"
			fi
		fi
        showInfo "Agregado ${NAMES[$COUNT]} a la configuracion "
        COUNT=`expr $COUNT + 1`
	done

	# linea para librerias de auxiliares
	LINE="librerias-$GRUPO/$LIBDIR-$USER-$SAVECONFIGURATIONDATE"
	LINEXISTS=`grep "^librerias-.*-.*-.*$" "$CONFIGFILE"`
	if [[ -z "$LINEXISTS" ]] # si no hay ninguna linea ya configurada
	then
		echo "$LINE" >> "$CONFIGFILE"
	fi
	showInfo "Agregada librerias a la configuracion "

	showInfo "Finalizada con exito la configuracion del sistema"
	showInfo ""

}

########################
# realizar reparacion
########################
repairSystem(){	## TODO: repara el borrado de todos los archivos excepto lo que hay en dirconf

	showInfo ""

	# corroborar version de perl
	checkPerlVersion

	# elimina y crea la carpeta de grupo
	restartDiretories

	# crear estructura de directorios
	createDirectories

	# mover tablas de /mae a $GRUPO/maestros
	moveToMaster

	# mover ejecutables de /bin a $GRUPO/ejecutables
	moveToBin

	# mover librerias auxiliares de /lib a $GRUPO/lib
	moveToLib

	# guardar configuracion
	saveConfigurationFile

	showInfo "Felicitaciones! Ha finalizado con exito la reparacion del sistema!!!"
	showInfo ""
}

restartDiretories(){
	rm "$GRUPO"/* -rf
	mkdir "$GRUPO/dirconf"
	# solo para el respositorio
	touch "$GRUPO/dirconf/.gitkeep"
}

########################
# el sistema ya se encuentra instalado
########################
showInfoSystem(){
	showInfo ""
	showConfiguration
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# MAIN
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
main(){

	# obtener parametros
	if [[ "$1" = "$OPT_REPAIR" ]]
	then
		REPAIR_SYSTEM=0
	else
		REPAIR_SYSTEM=1
	fi

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

	elif ! installIsValid  #si la instalacion no es valida
	then

		if [[ "$REPAIR_SYSTEM" -eq 0 ]] # y eligio reparar el sistema
		then
			showInfo "Se procedera con la reparacion "
			repairSystem
		else # sino muestra ayuda
			showAlert "El sistema contiene errores en sus configuración"
			showAlert "Ejecute la opción -r para reparar el sistema"
			showAlert "Ejemplo: $GRUPO/InstalO.sh -r"
		fi

	else

		showAlert "Ya posee una versión del sistema instalada en su entorno"
		showInfoSystem

	fi

	echo ""
}

main $@