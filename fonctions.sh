#!/bin/bash

#Fonction pour lire le fichier input

lecture() {

	while IFS= read -r line; do

		choix=$(echo "$line" | awk -F':' '{print $2}' | xargs)
		if [[ -n "$choix" ]]; then
			echo "$choix"
			exit 0
		fi
	done < input.txt

}

# Fonction pour envoyer une notification et exécuter une commande

notification() {
        local commande=$1

        eval "$commande"

        #Vérification du statut de la commande
        if [ $? -eq 0 ]; then
                notify-send "Tâche réussie" "La tâche '$commande' est terminée avec succès"
        else
                notify-send "Tâche échouée" "La tâche '$commande' a échoué"
        fi

}


# Fonction pour exécuter une tâche et enregistrer l'historique

journal() {
	
	read -p "Entrer l'évenement : " evenement

	while true; do
		read -p "Entrer le PID (doit être un entier positif) : " pid
		if [[ "$pid" =~ ^[0-9]+$ ]]; then
			break
		else
			echo "Erreur. Le PID doit être un entier positif"
		fi
	done

	read -p "Entrer les informations (max 100 caractères)" info


	echo "--------------------------------------------" > output.txt
	echo "Evenement : "$evenement"" >> output.txt
	echo "PID : "$pid"" >> output.txt
	echo "Informations : "$info"" >> output.txt
	echo "Date : $(date)" >> output.txt
	echo "--------------------------------------------" >> output.txt

	cat output.txt
}

#Fonction pour gérer les tyâches

gestion_taches() {
	echo "1- Lancer une tâche en arrière-plan"
	echo "2- Afficher les tâches en arrière plan"
	echo "3- Arrêter une tâche"
	echo "4- Suspendre une tâche"
	echo "5- Reprendre une tâche"
	echo "6- Quitter"

	read -p "Choisissez une option : " option

        
        case $option in 
		1)
			#Lancer une tâche en arrière-plan
			read -p "Entrer la commande à exécuter : " cmd
			$cmd &
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
			kill $task_id
			echo "La tâche avec le PID $task_id a été arrêtée" > output.txt

			echo "Résultats dans output.txt"
			;;

		4)
			#Suspendre une tâche
			read -p "Entrer le numéro de la tâche à suspendre : " job_number
			kill -STOP %$job_number
			echo "La tâche avec le numéro $job_number a été suspendue" > output.txt
			
			echo "Résultats dans output.txt"
			;;

		5)
			#Reprendre une tâche suspendue
			read -p "Entrer le numéro de la tâche à reprendre : " job_number
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

	#Vérifier que le priorité est dans la plage valide
	
	if [ "$priorite" -lt -20 ] || [ "$priorite" -gt 19 ]; then
		echo "Erreur : le priorité doit être comprise entre -20 (priorité la plus haute) et 19 (priorite la plus basse)." > output.txt
		return 1
	fi

	#Lancer la commande avec la priorité spécifiée en arrière-plan
	nice -n $priorite $commande &
	local pid=$!   

	echo "Tâche lancée : "$commande" avec le PID "$pid" et la priorité "$priorite"." > output.txt
	echo "Tâche lancée."
	notification "$commande"

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

	#Modifier la priorité avec la commande renice
	renice -n $nouv -p $pid
	if [ $? -eq 0 ]; then
		echo "La priorité de la tâche "$pid" a été modifiée à "$nouv"." > output.txt
	else
		echo "Erreur"
	fi
}


#Fonction pour afficher et filtrer les tâches en cours

afficher() {
	read -p "Entrer les filitres d'états (séparés par des espaces, ex: S R T) ou laissez vide pour afficher toutes les tâches : " -a etat_filtres

	echo "********  Tâches en cours *********" > output.txt
	echo "*** ID   | Etat   | Prorité | Utilisation CPU | Utilisation mémoire" >> output.txt
	echo "----------------------------------------------------------------" >> output.txt
	
	tasks=$(ps -e -o pid,stat,ni,%cpu,%mem --no-headers)

	echo "Les tâches sont dans le fichier de sortie"

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

	notification "$commande"
}


appel1() {
	local choix=$(lecture)

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
        echo "3- Affichages des tâches en arrière plan"
        echo "4- Lancer tâches avec notification"
        echo "5- Modifier la priorite d'une tâche avec notification"
        echo "6- Afficher la journalisation des tâches"

        read -p "Choississez une option : " choix

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
