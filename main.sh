#!/bin/bash

#Charger les fonctions depuis le fichier fonctions.sh
source ./fonctions.sh

main() {
	#Appel de la fonction lecture définie dans fonctions.sh
	bash ./fonctions.sh lecture

	#Récupérer le résultat de lecture
	choice=$(lecture)


	#Vérifier si la variable choice contient un nombre non nul
	if [[ -n "$choice" && "$choice" =~ ^[0-9]+$ ]]; then

		#Appel de la fonction appel1 si choice est un nombre non nul
		echo
		appel1
		echo
	else
		#Sinon appeler appel2
		echo
		echo "Aucun choix trouvé dans le fichier d'entrée"
		echo
		appel2
		echo
	fi

	#Demander a l'utilisateur s'il souhaite continuer
	read -p "Souhaitez-vous continuer la gestion des tâches ? (o/n) : " continue_choice


	#Si la réponse est "o"ou "O", relancer main	
    	if [[ "$continue_choice" =~ ^[oO]$ ]]; then
        	main  # Recommencer
    	else

		#Si la réponse est autre que "o" ou "O", terminer le programme
        	echo "Fin du programme."
        	exit 0
    	fi
}

#Appeler la fonction main pour démarrer le programme

main
