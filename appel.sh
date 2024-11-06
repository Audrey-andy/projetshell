#!/bin/bash

source ./fonctions.sh


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
        echo "3- Affichages des tâches "
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
