#!/bin/bash


source ./fonctions.sh

main() {
	bash ./fonctions.sh lecture
	choice=$(lecture)
	if [[ -n "$choice" && "$choice" =~ ^[0-9]+$ ]]; then
		appel1
		echo
	else
		appel2
		echo
	fi
	main
}

main
