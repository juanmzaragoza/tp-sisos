#!/bin/bash

# A-6-MT_IMPAGO-1-commax16.2
prueba() {
	ARCHIVO="../mae/T2.tab"
	LISTA=`grep "A-6-.*$" "$ARCHIVO"`
	while read -r linea
	do
		FIELD_NAME=`echo "$linea" | sed "s/^A-6-\(.*\)-.*-.*$/\1/"`
		FIELD_TYPE=`echo "$linea" | sed "s/^A-6-.*-.*-\(.*\)$/\1/"`
		REGISTROS+=("$FIELD_NAME"-"$FIELD_TYPE")
	done <<< "$LISTA"
	# echo "${REGISTROS[2]}"
	# echo "${#REGISTROS[@]}"
}

prueba2() {
	COUNTRY_CODE="A"
	SYSTEM_CODE="6"		
	SEPARATORS=`grep "^$COUNTRY_CODE-$SYSTEM_CODE-.*-.*$" "$T1_FILE"`
	if [ -z $SEPARATORS ]
	then
		showError "No se encontro en $T1_FILE los separadores para $COUNTRY_CODE - $SYSTEM_CODE"
	else
		FIELD_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-\(.*\)-.*$/\1/'`
		DECIMAL_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-.*-\(.*\)$/\1/'` 
	fi
	echo "FIELD SEP = $FIELD_SEPARATOR"
	echo "DEC SEP = $DECIMAL_SEPARATOR"
	echo ""
	ARCHIVO="../data/A-6-2017-05"
	LENGHT=${#REGISTROS[@]}
	echo "ACA TOY"
	while read -r linea
	do
		LOOP_END=$LENGHT-1
		echo "LOOP END $LOOP_END"
		for i in {0.."$LOOP_END"}
		do
			VALUE=`echo	"$linea" | sed "s/^\(.*\)$FIELD_SEPARATOR/\1/"`
			linea=`echo "$linea" | sed "s/^.*$FIELD_SEPARATOR\(.*\)$/\1/"`  
			AUX="${REGISTROS[i]}-$VALUE"
			REGISTROS[i]="$AUX"
			echo "AUX IS $AUX"
		done
		
	done << "$ARCHIVO"
}

extractValues() {
	COUNTRY_CODE="A"
	SYSTEM_CODE="6"		
	SEPARATORS=`grep "^$COUNTRY_CODE-$SYSTEM_CODE-.*-.*$" "$T1_FILE"`
	if [ -z $SEPARATORS ]
	then
		showError "No se encontro en $T1_FILE los separadores para $COUNTRY_CODE - $SYSTEM_CODE"
	else
		FIELD_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-\(.*\)-.*$/\1/'`
		DECIMAL_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-.*-\(.*\)$/\1/'` 
	fi
	CTB_ANIO=""
	CTB_MES=""
	CTB_DIA=""
	extractDate 
	CTB_ANIO=""
}

REGISTROS=()
prueba;
prueba2;
