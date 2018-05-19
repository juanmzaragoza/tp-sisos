#!/bin/bash

# Lista las variables de ambiente que el script "IniciO.sh" debe setear, para poder ejecutar sin errores los scripts "DetectO.sh", "InterpretO.sh", y "ReportO.sh".

LISTA_DE_VARIABLES=(
  BINDIR       #Ruta relativa desde el directorio del TP, hasta el directorio de archivos binarios.
  MASTERDIR    #Ruta relativa desde el directorio del TP, hasta el directorio de archivos maestros.
  ARRIVEDIR    #Ruta relativa desde el directorio del TP, hasta el directorio de novedades arribadas.
  ACCEPTEDDIR  #Ruta relativa desde el directorio del TP, hasta el directorio de novedades aceptadas.
  REJECTEDDIR  #Ruta relativa desde el directorio del TP, hasta el directorio de novedades rechazadas.
  PROCESSEDDIR #Ruta relativa desde el directorio del TP, hasta el directorio de novedades procesadas.
  REPORTDIR    #Ruta relativa desde el directorio del TP, hasta el directorio de reportes.
  LOGDIR       #Ruta relativa desde el directorio del TP, hasta el directorio de bitácoras.
)
