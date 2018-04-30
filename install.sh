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

# realizar instalacion
installSystem(){

	echo "El sistema será instalado por primera vez en su entorno"
	mkdir "$GRUPO"

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