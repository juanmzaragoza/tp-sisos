# TP 75.08 Sistemas Operativos

## Que encontraremos en este archivo?

Instrucciones de descarga, los requisitos del sistema, las instrucciones de instalación, las instrucciones de ejecución y cualquier aclaración que se considere necesaria para asegurar el éxito de la revisión. 
* Una explicación de cómo descargar el paquete
* Una explicación de cómo descomprimir, crear directorio del grupo, etc
* Una explicación de lo que se crea a partir de la descompresión
* Una explicación sobre que se requiere para poder instalar y/o ejecutar el sistema 
* Instrucciones de instalación del sistema 
* Una explicación de cómo se hace una instalación o reparación de la instalación
* Que nos deja la instalación y dónde
* Cuáles son los primeros pasos para poder ejecutar el sistema
* Como arrancar o detener comandos 
* Cualquier otra indicación, diagrama, cuadro que considere adecuada

## Requisitos del sistema

Para utilizar el sistema se recomienda utilizar `Ubuntu 14.04` en adelante que cuente con

* PERL@>=v5
* bash@>=v4
* tar@>=1.2.x
* pgrep@>=3.3.x
 
## Descarga del paquete

Para descargar el paquete puede realizar un clone de este proyecto

	git clone https://github.com/juanmzaragoza/tp-sisos.git tpsisos

O bien, descargar el paquete `tpsisos.tgz` desde [aqui](CompletarConURL)

## Descompresión del paquete

En caso de haber descargado la versión comprimida del mismo, ejecutar

	tar zxvf tpsisos.tgz -C /folder/where/to/save/tpsisos

**Nota:** tenga en cuenta que debe descomprimir dentro de la carpeta `tpsisos/`.

### Que obtenemos de la descompresión?

Al descomprimir el paquete, encontraremos dentro del directorio creado las siguientes carpetas y archivos

* `bin`: carpeta que contiene todos los ejecutables del sistema (IniciO.sh, DetectO.sh, StopO.sh, InterpretO, ReportO.sh)
* `data`: los archivos de arribos, tanto los entregados por las especificaciones como los generados por nosotros
* `grupo02`: la carpeta donde irá instalado el sistema. Por defecto, contiene creada la carpeta `dirconf`
* `lib`: archivos de librerias auxiliares utilizadas por todos los comandos
* `mae`: archivos de tablas y maestros necesarios para que el sistema funcione correctamente
* `InstalO.sh`: archivo de instalacion

## Instalación

### Requerimientos previos

Para poder instalar el sistema, debe encontrarse dentro de la carpeta que ha descompimido. A este carpeta la denominaremos `ROOT_FOLDER` de ahora en más.

Luego, necesita tener permisos para escribir la carpeta `grupo02/` (con permisos de administrador):

	sudo chmod 777 grupo02/* -R

y que el archivo `InstalO.sh` tenga permisos de ejecución:

	sudo chmod +x InstalO.sh

### Pasos

Para instalar el sistema, debe moverse a `ROOT_FOLDER` y ejecutar

	./InstalO.sh

Seguir los pasos mencionados en el proceso del mismo. 

**Nota:** los directorios solo serán creados cuando ingrese como respuesta "SI" a la pregunta si le parece correcta la configuración establecida.

Si todo funciona bien, el sistema le devolverá "Felicitaciones! Ha finalizado con exito la instalacion del sistema!!!".
En caso de que algo haya fallado, el sistema le dará instrucciones para reparar el mismo (opcion -r)
En caso de que el sistema ya se encuentre instalado, el sistema le devolverá la configuración del sistema establecida.

### Reparacion

Para reparar el sistema, ejecute:

	./InstalO.sh -r

Esta opción dejará su sistema configurado con las opciones por defecto.

### Qué obtenemos con la instalación?

La instalación se realiza dentro de la carpeta `ROOT_DIR/grupo02/` con:

* la carpeta de arribos configurada en la instalación (en su defecto `arrive/`);
* la carpeta de aceptados configurada en la instalación (en su defecto `accepted/`);
* la carpeta de ejecutablas configurada en la instalación (en su defecto `bin/`) con todos los comandos del sistema;
* la carpeta de logs configurada en la instalación (en su defecto `log/`);
* la carpeta de maestros y tablas configurada en la instalación (en su defecto `master/`) con todos las tablas y archivos de maestros;
* la carpeta de procesados configurada en la instalación (en su defecto `processed/`);
* la carpeta de rechazados configurada en la instalación (en su defecto `rejected/`);
* la carpeta de reportes configurada en la instalación (en su defecto `report/`);

Además dentro de la carpeta `dirconf/` se encontrará el archivo `install.conf` con los parámetros de configuración del sistema y el archivo `install.log` con todos los logs de la instalación (comando `InstalO.sh`).

También, dentro de la carpeta `lib/` se encontrará todas las librerías auxiliares para la ejecución de los comandos.

## Ejecutar el sistema por primera vez

Para ejecutar el sistema por primera vez, debe ejecutar desde el `ROOT_DIR` (teniendo en cuenta que la carpeta configurada para ejecutables en la instalación fue `BIN_DIR`):

	./grupo02/BIN_DIR/IniciO.sh

o bien, desde cualquier path:

	ROOT_DIR/grupo02/BIN_DIR/IniciO.sh

Este comando validará que los archivos de configuración y carpetas se encuentren bien configuradas, con los permisos correspondientes. En caso de que la validación falle, el sistema mostrará un error indicando como reparar el sistema.

En caso de que el sistema no haya sido nunca ejecutado, mostrará el PID del procesado ejecutado o del proceso que se ya se estaba ejecutando.

**Nota:** Anotar el PID devuelto por el comando para luego poder pararlo con `StopO.sh`.

## Detener el comandoo

El comando anterior ejecuta un demonio que debe ser detenido (en caso de que asi se lo requiera) de la siguiente forma:
	
	./grupo02/BIN_DIR/StopO.sh PID

o bien, desde cualquier path

	ROOT_DIR/grupo02/BIN_DIR/StopO.sh PID

donde `PID` es el devuelto por el `Inicio.sh`.

### Ejecutar comandos

### Detener comandos