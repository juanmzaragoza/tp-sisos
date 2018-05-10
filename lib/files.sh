#!/bin/bash

#
# devuelve true si el path pasado como parametro existe y es una carpeta
#
directoryExists() {
	return [ -d "$1" ] #TODO: no funciona
}