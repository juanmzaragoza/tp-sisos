#!/bin/bash

# A-6-MT_IMPAGO-1-commax16.2
prueba() {
	ARCHIVO="../mae/T2.tab"
	LISTA=`grep "C-7-.*$" "$ARCHIVO"`
	while read -r linea
	do
		FIELD_NAME=`echo "$linea" | sed "s/^C-7-\(.*\)-.*-.*$/\1/"`
		FIELD_TYPE=`echo "$linea" | sed "s/^C-7-.*-.*-\(.*\)$/\1/"`
		REGISTROS+=("$FIELD_NAME"-"$FIELD_TYPE")
	done <<< "$LISTA"
	# echo "${REGISTROS[2]}"
	# echo "${#REGISTROS[@]}"
}

prueba2() {
	COUNTRY_CODE="C"
	SYSTEM_CODE="7"		
	SEPARATORS=`grep "^$COUNTRY_CODE-$SYSTEM_CODE-.*-.*$" "../mae/T1.tab"`
	if [ -z $SEPARATORS ]
	then
		echo "No se encontro en $T1_FILE los separadores para $COUNTRY_CODE - $SYSTEM_CODE"
	else
		FIELD_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-\(.*\)-.*$/\1/'`
		DECIMAL_SEPARATOR=`echo $SEPARATORS | sed 's/^.*-.*-.*-\(.*\)$/\1/'` 
	fi
	ARCHIVO="../data/C-7-2017-04"
	LENGHT=${#REGISTROS[@]}
	while read -r linea
	do
		i=0
		linea=${linea::-1}
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

# $1 - el formateo de campo
# $2 - el separador de coma
# $3 - valor a leer
# $4 - valor a asignar
getNum () {
	if [ -z "$3" ]
		then
		eval "$4=0"
		return
	fi
	INT_LONG=`echo "$1" | sed "s/^commax\([^.]*\).*$/\1/"` # Como lo uso?
	DECIMAL_LONG=`echo "$1" | sed "s/^\([^.]*\)\.\(.*\)$/\2/1"` # Como lo uso?
	INT_VALUE=`echo "$3" | sed "s/^\([^$2]*\).*$/\1/"`
	DECIMAL_VALUE=`echo "$3" | sed "s/^\([^$2]*\)$2\(.*\)$/\2/"`
	NEW_VALUE="$INT_VALUE,$DECIMAL_VALUE"
	eval "$4=$NEW_VALUE"
}


# $1 - el formateo de fecha
# $2 - el valor a leer
# $3 - variable CTB_DIA
# $4 - variable CTB_MES
# $5 - variable CTB_ANIO
getDate() {
	LONG=`echo "$1" | sed "s/^......\(.*\)$/\1/"`
	LONG="${LONG::-2}" # SACO ESE PUNTO FEO
	if (( "$LONG" == 8 )) # No tiene separador
		then
		DAY=`echo "$1" | grep "^dd.*$"`
		if [ -n "$DAY" ]
			then
			DAY=`echo "$2" | sed "s/^\(..\).*$/\1/"`
			eval "$3=$DAY"
			MONTH=`echo "$2" | sed "s/^..\(..\).*$/\1/"`
			eval "$4=$MONTH"
			YEAR=`echo "$2" | sed "s/^....\(.*\)$/\1/"`
			eval "$5=${YEAR}"
			return
		else
			YEAR=`echo "$2" | sed "s/^\(....\).*$/\1/"`
			eval "$5=$YEAR"
			MONTH=`echo "$2" | sed "s/^....\(..\).*$/\1/"`
			eval "$4=$MONTH"
			DAY=`echo "$2" | sed "s/^......\(.*\)$/\1/"`
			eval "$3=${DAY}"
			return
		fi
	else
		DAY=`echo "$1" | grep "^dd.*$"` # EN LA REGEX AGREGO UN CARACTER MAS POR EL SEPARADOR
		if [ -n "$DAY" ]
			then
			DAY=`echo "$2" | sed "s/^\(..\).*$/\1/"`
			eval "$3=$DAY"
			MONTH=`echo "$2" | sed "s/^...\(..\).*$/\1/"`
			eval "$4=$MONTH"
			YEAR=`echo "$2" | sed "s/^......\(.*\)$/\1/"`
			eval "$5=${YEAR}"
			return
		else
			YEAR=`echo "$2" | sed "s/^\(....\).*$/\1/"`
			eval "$5=$YEAR"
			MONTH=`echo "$2" | sed "s/^.....\(..\).*$/\1/"`
			eval "$4=$MONTH"
			DAY=`echo "$2" | sed "s/^........\(.*\)$/\1/"`
			eval "$3=${DAY}"
			return
		fi
	fi
}

getAlphaNum() {
	if [ -z "$1" ]
		then
		eval "$2=''"
	else
		eval "$2='$1'"
	fi
}

getValue() {
	# en $1 me viene el campo que se busca
	ELEMENT_INDEX=0
	for i in "${REGISTROS[@]}"
	do
		FIELD_NAME=`echo "$i" | grep "^$1-"`
		if [ -z "$FIELD_NAME" ]
			then
			sleep 0
		else
			FIELD_TYPE=`echo "$i" | sed "s/^.*-\(.*\)$/\1/"`
			DATE_FIELD=`echo "$FIELD_TYPE" | grep "yy"`
			if [ -n "$DATE_FIELD" ]
				then
				FIELD_TYPE=`echo "$i" | sed "s/^$1-\(.*\)$/\1/"`
				getDate "$FIELD_TYPE" "${VALORES[ELEMENT_INDEX]}" $2 $3 $4
				break
			fi
			ALPH_NUM_FIELD=`echo "$FIELD_TYPE" | grep -F "$"`
			if [ -n "$ALPH_NUM_FIELD" ]
				then
				getAlphaNum "${VALORES[ELEMENT_INDEX]}" $2  
				break
			fi
			NUM_FIELD=`echo "$FIELD_TYPE" | grep "commax"`
			if [ -n "$NUM_FIELD" ]
				then
				getNum "$FIELD_TYPE" "." "${VALORES[ELEMENT_INDEX]}" $2
				break
			fi
		fi
		((ELEMENT_INDEX++))
	done
}

calculateRest() {
	ARRAY_AUX=("${array[@]}")
	TOTAL=0
	for i in "${ARRAY_AUX[@]}"
	do
		echo "$i"
		tmp=`echo "$i" | sed "s|\,|\.|"`
		TOTAL=$(echo "$TOTAL+$tmp" | bc)
	done
	tmp=`echo "$1" | sed "s|\,|\.|"`
	TOTAL=$(echo "$TOTAL-$tmp" | bc)
	eval "$2='$TOTAL'"
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
	PRES_CLI=""
	PRES_CLI_ID=""
	CURRENT_DATE=""
	CURRENT_USER=""
	getValue "CTB_FE" CTB_DIA CTB_MES CTB_ANIO
	getValue "CTB_ESTADO" CTB_ESTADO
	getValue "PRES_ID" PRES_ID
	getValue "PRES_CLI" PRES_CLI
	getValue "PRES_CLI_ID" PRES_CLI_ID
	getValue "MT_PRES" MT_PRES
	getValue "MT_IMPAGO" MT_IMP
	getValue "MT_INDE" MT_INDE
	getValue "MT_INNODE" MT_INNODE
	getValue "MT_DEB" MT_DEB
	array=("$MT_PRES" "$MT_IMP" "$MT_INDE" "$MT_INNODE")
	calculateRest "$MT_DEB" MT_REST
	echo "MT REST $MT_REST"
	# echo "CTB ANIO = $CTB_ANIO"
	# echo "CTB MES = $CTB_MES"
	# echo "CTB DIA = $CTB_DIA"
	# echo "CTB ESTADO = $CTB_ESTADO"
	# echo "PRES_ID = $PRES_ID"
	# echo "PRES_CLI = $PRES_CLI"
	# echo "PRES_CLI_ID = $PRES_CLI_ID"
	# echo "MT_PRES = $MT_PRES"
	# echo "MT_IMP = $MT_IMP"
	# echo "MT_INDE = $MT_INDE"
	# echo "MT_INNODE = $MT_INNODE"
	# echo "MT_DEB = $MT_DEB"
	# echo "MT_REST = $MT_REST"
	OUT_VALUE="$SIS_ID;$CTB_ANIO;$CTB_MES;$CTB_DIA;$CTB_ESTADO;$PRES_ID;$MT_PRES;$MT_IMP;$MT_INDE;$MT_INNODE;$MT_DEB;$MT_REST;$PRES_CLI_ID;$PRES_CLI;$CURRENT_DATE;$CURRENT_USER"
	# echo "OUTPUT VALUE :"
	# echo "$OUT_VALUE"
}

readingTest() {
	ARCHIVO="../data/C-7-2017-04"
	while read -r linea
	do
		echo "line : $linea"
	done < "$ARCHIVO"
}

# REGISTROS=()
# prueba 
# VALORES=()
# prueba2
# outputRegister
readingTest
