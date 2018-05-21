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
	while read -r linea
	do
		i=0
		while (( i < "$LENGHT" ))
		do
			VALUE=`echo	"$linea" | sed "s/^\([^$FIELD_SEPARATOR]*\)$FIELD_SEPARATOR.*/\1/"`
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

getValue() {
	# en $1 me viene el campo que se busca
	ELEMENT_INDEX=0
	for i in "${REGISTROS[@]}"
	do
		FIELD_NAME=`echo "$i" | grep "^$1-"`
		if [ -z "$FIELD_NAME" ]
			then
			echo "NOT FOUND!"
		else
			eval "$2=${VALORES[ELEMENT_INDEX]}"
			break
		fi
		((ELEMENT_INDEX++))
	done
}

# Codigo del sistema : SIS_ID 
# CTB_ANIO : de CTB_FECHA
# CTB_MES : de CTB_FECHA
# CTB_DIA : de CTB_FECHA
# estado contable : CTB_ESTADO
# codigo prestamo : PRES_ID
# monto prestamos : MT_PRES
# monto impago : MT_IMP
# monto intereses devengados : MT_INDE
# monto intereses no devengaods : MT_INNODE
# monto debitado : MT_DEB
# monto restante : MT_PRES + MT_IMP + MT_INDE + MT_INNODE - MT_DEB
# codigo cliente : PRES_CLI_ID
# nombre cliente : PRES_CLI
# fecha corriente : dd/mm/yyyy
# usuario corriente :
outputRegister() {
	SIS_ID="$SYSTEM_CODE"
	CTB_ANIO=""
	CTB_MES=""
	CTB_DIA=""
	CTB_ESTADO=""
	PRES_ID=""
	MT_PRES=""
	MT_IMP=""
	MT_INDE=""
	MT_INNODE=""
	MT_DEB=""
	MT_REST=""
	PRES_CLI_ID=""
	PRES_CLI=""
	CURRENT_DATE=""
	CURRENT_USER=""
	getValue "CTB_ESTADO" CTB_ESTADO
	getValue "PRES_ID" PRES_ID
	getValue "MT_PRES" MT_PRES
	getValue "MT_IMP" MT_IMP
	getValue "MT_INDE" MT_INDE
	getValue "MT_INNODE" MT_INNODE
	getValue "MT_DEB" MT_DEB
	# getValue "MT_REST" MT_REST
	echo "CTB ESTADO = $CTB_ESTADO"
	echo "PRES_ID = $PRES_ID"
	echo "MT_PRES = $MT_PRES"
	echo "MT_IMP = $MT_IMP"
	echo "MT_INDE = $MT_INDE"
	echo "MT_INNODE = $MT_INNODE"
	echo "MT_DEB = $MT_DEB"
}

REGISTROS=()
prueba 
VALORES=()
prueba2
outputRegister
