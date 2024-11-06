#!/bin/bash

#Fonction pour lire le fichier input

lecture() {

	while IFS= read -r line; do

		#Extraire la partie après les deux points ":" dans la ligne
		#La deuxième partie sépare la ligne avec ":" comme séparateur et prends la seconde partie
		#'xargs' supprime les espaces supplémentaires en début et fin de chaine

		choix=$(echo "$line" | awk -F':' '{print $2}' | xargs)

		#Vérifie si le choix est non vide
		if [[ -n "$choix" ]]; then

			#Affiche la valeur de choix et quitte la fonction
			echo "$choix"
			exit 0
		fi

	#Redirige le contenu de input.txt en tant qu'entrée de la boucle
	done < input.txt

}

# Fonction pour envoyer une notification et exécuter une commande

notification() {

	#Déclare une variable locale nommée commande qui prends le premier argument de la fonction
        local commande=$1

	#Utilise la commande notify-send pour envoyer une notification
        notify-send "$commande"
}


# Fonction pour exécuter une tâche et enregistrer l'historique

journal() {
	
	read -p "Entrer l'évenement : " evenement


	#Boucle pour s'assurer que le PID entré est un entier positif
	while true; do

		read -p "Entrer le PID (doit être un entier positif) : " pid

		#Vérifie si le PID est un entier positif
		if [[ "$pid" =~ ^[0-9]+$ ]]; then
			break 
		else
			echo "Erreur. Le PID doit être un entier positif"
		fi
	done


	#Demande a l'utilisateur de saisir dess infos supplémentaires
	read -p "Entrer les informations (max 100 caractères)" info

	{
		echo "--------------------------------------------"
		echo "Evenement : "$evenement""
		echo "PID : "$pid""
		echo "Informations : "$info""

		#Ajoute la date et l'heure actuelle
		echo "Date : $(date)"
		echo "--------------------------------------------"
	} > output.txt

	cat output.txt
}

#Fonction pour gérer les tyâches

gestion_taches() {

	#Afficher les options disponibles pour la gestion des tâches
	echo "1- Lancer une tâche en arrière-plan"
	echo "2- Afficher les tâches en arrière plan"
	echo "3- Arrêter une tâche"
	echo "4- Suspendre une tâche"
	echo "5- Reprendre une tâche"
	echo "6- Quitter"

	read -p "Choisissez une option : " option

        
	#Utilise une structure case pour gérer chaque option
        case $option in 
		1)
			#Lancer une tâche en arrière-plan
			read -p "Entrer la commande à exécuter : " cmd

			# Exécute la commande en arrière-plan et redirige la sortie vers output.txt
            		{ $cmd; echo "Résultats de la commande :"; } >> output.txt 2>&1 &

			#Exécute la commande en arrière plan et stocke le PID de la tâche
			pid=$!
			echo "La tâche est lancée avec le PID $pid" > output.txt

			echo "Résultats dans output.txt"
			;;

		2)
			#Affichier les têches en arrière plan
			jobs   
			;;

		3)
			#Arrêter une tâche
			read -p "Entrer le numéro de la tâche à arrêter : " task_id

			#Envoie le signal SIGTERM pour arrêter la tâche spécifiée
			kill $task_id
			echo "La tâche avec le PID $task_id a été arrêtée" > output.txt

			echo "Résultats dans output.txt"
			;;

		4)
			#Suspendre une tâche
			read -p "Entrer le numéro de la tâche à suspendre : " job_number

			#Envoie le signal STOP pour suspendre la tâche spécifiée
			kill -STOP %$job_number
			echo "La tâche avec le numéro $job_number a été suspendue" > output.txt
			
			echo "Résultats dans output.txt"
			;;

		5)
			#Reprendre une tâche suspendue
			read -p "Entrer le numéro de la tâche à reprendre : " job_number

			#Envoie le signal CONT pour reprendre la tâche spécifiée
			kill -CONT %$job_number
			echo "La tâche avec le numéro $job_number a été reprise" > output.txt

			echo "Résultats dans output.txt"
			;;

		6)
			#Quitter
			echo "Fin de la gestion de la tâche." > output.txt
			echo "Fin de la gestion de la tâche."

			exit 0
			;;

		*)
			echo "Option non valide. Entrer une option valide."
			;;

	esac
}



#Fonction pour lancer une tâche avec une priorité donnée

lancer_tache() {
	read -p "Entrer la commande à lancer : " commande
	read -p "Entrer la priorite : " priorite

	#Vérifier que le priorité est dans la plage valide, entre -20 et 19
	
	if [ "$priorite" -lt -20 ] || [ "$priorite" -gt 19 ]; then
		echo "Erreur : le priorité doit être comprise entre -20 (priorité la plus haute) et 19 (priorite la plus basse)." > output.txt
		return 1
	fi

	#Lancer la commande avec la priorité spécifiée en arrière-plan
	nice -n $priorite $commande &
	local pid=$!


	#Vérifie si la tâche a bien été lancée et utilise lma fonction notification pour le retour
	if [ $? -ne 0 ]; then

       		 echo "Erreur lors du lancement de la tâche : $commande" > output.txt
        	 notification "Erreur : échec du lancement de la tâche '$commande'."
        	 return 1
    	fi	

	echo "Tâche lancée : "$commande" avec le PID "$pid" et la priorité "$priorite"." > output.txt
	echo "Tâche lancée."
	notification "Tâche lancée : $commande avec le PID $pid."

}


#Fonction pour modifier la priorité d'une tâche en cours
modifier() {
	read -p "Entrer la valeur du pid : " pid
	read -p "Entrer la nouvelle valeur de la priorité, une valeur comprise -20 et 19 : " nouv     #La nouvelle priorité à attribuer

	#Vérifier que la priorité est dans la plage valide

	if [ "$nouv" -lt -20 ] || [ "$nouv" -gt 19 ]; then
		echo "Entrer une valeur de priorité comprise entre -20 et 19." > output.txt
		return 1
	fi

	# Modifie la priorité de la tâche avec le PID spécifié en utilisant renice
	renice -n $nouv -p $pid

	#Vérification de la réussite de la commande
	if [ $? -eq 0 ]; then
		echo "La priorité de la tâche "$pid" a été modifiée à "$nouv"." > output.txt
		notification "Tâche modifiée avec succès"
	else
		echo "Erreur"
		notification "Erreur lors de l'exécution de la commande"
	fi
}


#Fonction pour afficher et filtrer les tâches en cours

afficher() {

	# Demande à l'utilisateur de fournir des filtres d'état pour les tâches
        # Si plusieurs filtres sont fournis, ils doivent être séparés par des espaces (ex: "S R T") S pour Sleeping R pour Running et T pour stopped
        # Les filtres sont stockés dans un tableau `etat_filtres`

	read -p "Entrer les filitres d'états (séparés par des espaces, ex: S R T) ou laissez vide pour afficher toutes les tâches : " -a etat_filtres

	echo "********  Tâches en cours *********" > output.txt
	echo "*** ID   | Etat   | Prorité | Utilisation CPU | Utilisation mémoire" >> output.txt
	echo "----------------------------------------------------------------" >> output.txt
	
	#Récupère les infosdes processus
	tasks=$(ps -e -o pid,stat,ni,%cpu,%mem --no-headers)

	echo "Les tâches sont dans le fichier de sortie"

	#Si aucune tâche n'est récupéré, affiche un message et quitte la fonction

	if [ -z "$tasks" ]; then
		echo "Aucune tâche en cours"
		return
	fi

	#Boucle sur les têches en cours

	while read -r tache etat priorite cpu mem; do     #Pour récuper les ids des tâches en arrière-plan

		if [[ ${#etat_filtres[@]} -eq 0 || " ${etat_filtres[@]} " =~ " ${etat:0:1} " ]]; then
			echo " $tache | $etat | $priorite | ${cpu}% | ${mem}% " >> output.txt
		fi	
	
	done <<< "$tasks"
}	



#Fonction pour ajouter une tâche planifiée avec crontab

planifier_tache() {
	local commande="$1"        #La commande à exécuter
	local minute="$2"          # Minute (0-59)
	local heure="$3"           # Heure (0-23)
	local jour_mois="$4"       # Jour du mois (1-31)
	local mois="$5"            # Mois (1-12)
	local jour_semaine="$6"    # Jour de la semaine (0-7 ou 0 et 7 représentent dimanche)

	#Prepare l'entrée crontab
	tache_cron="$minute $heure $jour_mois $mois $jour_semaine $commande"

	# Ajoute la tâche au fichier crontab de l'utilisateur
	(crontab -l 2>/dev/null; echo "$tache_cron") | crontab -


	echo "Tâche planifiée : $tache_cron"
	
	# Envoie une notification indiquant que la tâche est planifiée
	notification "Tâche lancée : $commande"
}



appel1() {

	# Appelle la fonction `lecture` pour obtenir le choix de l'utilisateur
        local choix=$(lecture)

	# Utilisation d'un bloc `case` pour exécuter différentes actions en fonction du choix de l'utilisateur
        case $choix in
                1)
                        gestion_taches
                        exit
                        ;;
                2)
                        read -p "Entrer la commande à planifier" commande
                        read -p "Entrer la minute (0-59)" minute
                        read -p "Entrer l'heure (0-23)" heure
                        read -p "Entrer le jour du mois (1-31 ou * pour chaque jour ) : " jour_mois
                        read -p "Entrer le mois (1-12 ou * pour chaque mois) : " mois
                        read -p "Entrer le jour de la semaine (0-7 ou * pour chaque jour) : " jour_semaine

                        planifier_tache "$commande" "$minute" "$heure" "$jour_mois" "$mois" "$jour_semaine"
                        exit
                        ;;
                3)
                        afficher
                        exit
                        ;;
                4)
                        lancer_tache
                        exit
                        ;;
                5)
                        modifier
                        exit
                        ;;
                6)
                        journal
                        exit
                        ;;
                *)
                        echo "Option non valide"
                        ;;

        esac
}


appel2() {
        echo "1- Gestions des tâches"
        echo "2- Planification des taches dans cron et notification"
        echo "3- Affichages des tâches "
        echo "4- Lancer tâches avec notification"
        echo "5- Modifier la priorite d'une tâche avec notification"
        echo "6- Afficher la journalisation des tâches"

        read -p "Choississez une option : " choix

	# Utilisation d'un bloc `case` pour exécuter différentes actions en fonction du choix de l'utilisateur
        case $choix in
                1)
                        gestion_taches
                        ;;
                2)
                        read -p "Entrer la commande à planifier" commande
                        read -p "Entrer la minute (0-59)" minute
                        read -p "Entrer l'heure (0-23)" heure
                        read -p "Entrer le jour du mois (1-31 ou * pour chaque jour ) : " jour_mois
                        read -p "Entrer le mois (1-12 ou * pour chaque mois) : " mois
                        read -p "Entrer le jour de la semaine (0-7 ou * pour chaque jour) : " jour_semaine

                        planifier_tache "$commande" "$minute" "$heure" "$jour_mois" "$mois" "$jour_semaine"
                        ;;
                3)
                        afficher
                        ;;
                4)
                        lancer_tache
                        ;;
                5)
                        modifier
                        ;;
                6)
                        journal
                        ;;
                *)
                        echo "Option non valide"
                        ;;

        esac
}
