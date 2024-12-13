#!/bin/bash

ADH="/home/adhomes"
HOME="/home/c"

VerifyEleve() {
    login="$1"
    [ -L "$HOME/$login" ] || ciSignalAlerte "Erreur : $HOME/$login n'est pas un lien"
    [ -L "$ADH/$login" ] && ciSignalAlerte "Erreur : $ADH/$login est un lien"
    [ -d "$ADH/$login/perso/prive" ] || ciSignalAlerte "Erreur : $ADH/$login/perso/prive manquant"
    [ -d "$ADH/$login/groupes" ] || ciSignalWarning "Erreur : $ADH/$login/groupes manquant"
    [ "$(getfacl "$ADH/$login" 2>/dev/null| grep "^# owner:" | cut -d' ' -f3)" = "$login" ] || ciSignalAlerte "Erreur : vérifier le propriétaire de $ADH/$login"
}

#1 répertoire ADH supprimé
rm -rf "$ADH/c31e1"

#2 lien vers ADH supprimé
rm -f "$HOME/c31e2"

#3 répertoire dans /home uniquement
rm -f "$HOME/c31e3"
mv "$ADH/c31e3" "$HOME/c31e3"

#4 répertoire dans les deux
rm -f "$HOME/c32e4"
cp -a "$ADH/c32e4" "$HOME/c32e4"

/usr/share/eole/backend/droits_user.py --fix
/usr/share/eole/backend/droits_user.py "c31e2" --fix

VerifyEleve "c31e1" # partiellement géré
VerifyEleve "c31e2"
VerifyEleve "c31e3"
VerifyEleve "c32e4"

