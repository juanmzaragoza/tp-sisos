#!/bin/bash

# A-6-MT_IMPAGO-1-commax16.2
prueba() {
	ARCHIVO="../mae/T2.tab"
	LISTA=`grep "A-6-.*$" "$ARCHIVO"`
	array=("${@}")
	while read -r linea
	do
		FIELD_NAME=`echo "$linea" | sed "s/^A-6-\(.*\)-.*-.*$/\1/"`
		FIELD_TYPE=`echo "$linea" | sed "s/^A-6-.*-.*-\(.*\)$/\1/"`
		array+=("$FIELD_NAME"-"$FIELD_TYPE")
	done <<< "$LISTA"
	# echo "${REGISTROS[2]}"
	# echo "${#REGISTROS[@]}"
}

prueba2() {
	COUNTRY_CODE="A"
	SYSTEM_CODE="6"		
	SEPARATORS=`grep "^$COUNTRY_CODE-$SYSTEM_CODE-.*-.*$" "../mae/T1.tab"`
	if [ -z $SEPARATORS ]
	then
		echo "No se encontro en $T1_FILE los separadores para $COUNTRY_CODE - $SYSTEM_CODE"
	else
		FIELD_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-\(.*\)-.*$/\1/'`
		DECIMAL_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-.*-\(.*\)$/\1/'` 
	fi
	ARCHIVO="../data/A-6-2017-05"
	LENGHT=${#REGISTROS[@]}
	echo "ACA TOY"
	while read -r linea
	do
		i=0
		while (( i < "$LENGHT" ))
		do
			VALUE=`echo	"$linea" | sed "s/^\([^$FIELD_SEPARATOR]*\)$FIELD_SEPARATOR.*/\1/"`
			echo "VALUE IS $VALUE"
			linea=`echo "$linea" | sed "s/^\([^$FIELD_SEPARATOR]*\)$FIELD_SEPARATOR\(.*\)/\2/"`
			VALORES+=("$VALUE")
			((i++))
		done
		
	done < "$ARCHIVO"
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
prueba "${REGISTROS[@]}"
echo "sale ${REGISTROS[2]}"
VALORES=()
prueba2
i=0
while (( i < "${#REGISTROS[@]}" ))
do
	echo "Campo: ${REGISTROS[i]}"
	echo "Valor: ${VALORES[i]}"
	echo ""
	((i++))
done
