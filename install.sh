#!/bin/bash

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# VARIABLES
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
GRUPO="$PWD/grupo02"

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

	checkPerlVersion

	echo "Para poder continuar, se le solicita que configure cada uno de los siguientes directorios"

	read -n 1 -p "Establer directorio de ejecutables ($GRUPO/bin): " userinput
	# checkear que el directorio no existe
	# checkear que no se ingrese dirconfig
	

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
echo ""
echo "====================================================="
echo "    Bienvenido a la instalacion del sistema TPSO     "
echo "====================================================="
echo ""

echo "Este sistema lo guiará en la instalación de TPSO en su sistema operativo"
echo ""
echo "Asegurese de tener los permisos necesario para el directorio donde va a "
echo "realizar la instalación como una version de PERL 5 o superior"
read -n 1 -p "Presione una tecla para continuar..." mainmenuinput
echo ""

# crear directorio de instalacion
if [ ! -d "$GRUPO" ]
then

	installSystem

elif ! installIsValid
then

	repairSystem

else

	showInfoSystem

fi













echo ""