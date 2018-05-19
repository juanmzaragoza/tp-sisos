#!/bin/bash

prueba() {
	ARCHIVO="../mae/T2.tab"
	LISTA=`grep "A-6-.*$" "$ARCHIVO"`
	while read -r linea
	do
		echo "LEI $linea"
	done <<< "$LISTA"
}

prueba 