#!/bin/bash

# Envole 6 au 08/09/2017
# OK 
#  * balado
#  * calendrier
#  * cdc
#  * cdt
#  * dokuwiki
#  * econnecteur
#  * edispatcher
#  * envole-themes
#  * eportail
#  * fluxbb
#  * gepi
#  * grr
#  * limesurvey
#  * mahara
#  * mindmaps
#  * moodle
#  * opensondage
#  * owncloud
#  * piwik
#  * posh
#  * posh-profil
#  * profilcache
#  * pydio
#  * roundcube
#  * sacoche
#  * sap
#  * sondepiwik
#  * taskfreak
#  * wordpress
#  * xdesktop
#  * zephir-racvision
#  
# Applications non encore disponibles
# 
#  * bergamote
#  * envole-mobile
#  * ethercalc
#  * etherdraw
#  * etherhome
#  * etherpad
#  * piwigo
#  * scrumblr
#
# Applications qui ne seront pas portées en Envole 6
#  * Ajaxplorer
#  * CDC
#  * Iconito
#  * Fengoffice
#  * Spip
#  * Webcalendar
 
if ciVersionMajeurAvant "2.6.1"
then
   PAQUETS="eole-cdt eole-cdc eole-bergamote eole-balado eole-gepi eole-limesurvey eole-mahara eole-opensondage eole-piwigo eole-wordpress eole-piwik eole-posh eole-posh-profil eole-envole-themes eole-xdesktop eole-owncloud eole-envole-connecteur eole-sap eole-jappix eole-moodle-update eole-iconito eole-etherpad eole-ethercalc eole-dokuwiki eole-fluxbb eole-calendrier eole-envole-mobile eole-pydio eole-roundcube eole-grr eole-taskfreak eole-spipeva"
elif ciVersionMajeurAvant "2.7.1"
then
   #Envole 6
   PAQUETS="eole-cdt eole-balado eole-gepi eole-limesurvey eole-mahara eole-opensondage eole-wordpress eole-piwik eole-posh eole-posh-profil eole-envole-themes eole-xdesktop eole-envole-connecteur eole-sap eole-moodle-update eole-nineboard eole-ninegate eole-dokuwiki eole-fluxbb eole-calendrier eole-envole-mobile eole-pydio eole-roundcube eole-grr eole-taskfreak"
   #eole-owncloud
elif ciVersionMajeurAvant "2.8.0"
then
   #Envole 7
   PAQUETS="eole-balado eole-cdt eole-dispatcher eole-dokuwiki eole-envole-connecteur eole-envole-migration eole-eportail eole-fluxbb eole-gepi eole-grr eole-kanboard eole-limesurvey eole-mahara eole-mindmaps eole-moodle-update eole-nextcloud eole-nineboard eole-ninegate eole-nineschool eole-ninesurvey eole-opensondage eole-phpldapadmin eole-piwigo eole-piwik eole-roundcube eole-sacoche eole-wordpress eole-xdesktop eole-zephir-racvision eole-ethercalc eole-etherdraw eole-etherhome eole-etherpad eole-scrumblr"
elif ciVersionMajeurAvant "2.9.0"
then
   #Envole 8
   PAQUETS="eole-balado eole-cdt eole-dispatcher eole-dokuwiki eole-envole-migration eole-eportail eole-fluxbb eole-gepi eole-grr eole-kanboard eole-limesurvey eole-mahara eole-mindmaps eole-moodle-update eole-nextcloud eole-nineboard eole-ninegate eole-nineschool eole-ninesurvey eole-opensondage eole-phpldapadmin eole-piwigo eole-piwik eole-roundcube eole-sacoche eole-wordpress eole-xdesktop eole-zephir-racvision eole-ethercalc eole-etherdraw eole-etherpad eole-scrumblr"
   # eole-envole-connecteur #31490
   # eole-etherhome #33188
else
   #Envole 9
   PAQUETS="eole-balado eole-cdt eole-dispatcher eole-dokuwiki eole-envole-migration eole-eportail eole-fluxbb eole-grr eole-kanboard eole-limesurvey eole-mahara eole-mindmaps  eole-nextcloud  eole-opensondage eole-phpldapadmin eole-piwigo eole-piwik eole-roundcube eole-sacoche eole-xdesktop eole-zephir-racvision eole-scrumblr"
   # pas compatible : eole- moodle, eole-gepi, eole-ninegate eole-nineschool eole-nineboard eole-ninesurvey eole-wordpress
   # eole-ethercalc eole-etherdraw eole-etherpad #34691
fi
          
for pq in ${PAQUETS};
do
    echo "******************************************************"
    echo "* install $pq"
    apt-eole install "$pq"
    RESULT="$?"
    echo "* install $pq ==> $RESULT"
    if [ "$RESULT" -ne 0 ]
    then
       echo "ERREUR: install $pq ==> $RESULT"
    fi    
done

if [ "$VM_VERSIONMAJEUR" == "2.8.0" ]
then
    ciSignalHack "CreoleSet activer_piwik non (#31475)"
    CreoleSet activer_piwik non
fi

exit 0
