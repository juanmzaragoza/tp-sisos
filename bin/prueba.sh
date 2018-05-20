#!/bin/bash

prueba() {
	ARCHIVO="../mae/T2.tab"
	LISTA=`grep "A-6-.*$" "$ARCHIVO"`
	while read -r linea
	do
		echo "LEI $linea"
	done <<< "$LISTA"
}



extractDate() {
			SEPARATORS=`grep "^$COUNTRY_CODE-$SYSTEM_CODE-.*-.*$" "$T1_FILE"`
			if [ -z $SEPARATORS ]
			then
				showError "No se encontro en $T1_FILE los separadores para $COUNTRY_CODE - $SYSTEM_CODE"
			else
				FIELD_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-\(.*\)-.*$/\1/'`
				DECIMAL_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-.*-\(.*\)$/\1/'` 
}

extractValues() {
	CTB_ANIO=""
	CTB_MES=""
	CTB_DIA=""
	extractDate 
	CTB_ANIO=""
}

prueba 