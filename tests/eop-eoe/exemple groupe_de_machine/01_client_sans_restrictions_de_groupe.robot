*** Settings ***
Resource	./datas/datas-${ETB}.robot
Library		Remote    ${REMOTE_SERVER}
Library         XvfbRobot

*** Test Cases ***
#Lancer_Xvfb
#    Run Keyword If 	${xvfb}=='True'		Start Virtual Display    640	480
#
Open Browser To pcll.ac-dijon
    Open Firefox    ${BASE URL}		${xvfb}
    Title Should Be		Accueil - Pôle Logiciels Libres | Pôle Logiciels Libres		

Nav through http proxy
    Go To	${URL THROUGH HTTP PROXY}
    Page Should Contain 	${EXTERNAL IP}
    Page Should Contain		Proxy detecté / Proxy detected
    Page Should Contain		ORG_IP : ${INTERNAL IP PART}
    Capture Page Screenshot	/var/www/html/paf.png

Nav through https proxy
    Go To	${URL THROUGH HTTPS PROXY}
    Title Should Be 	Accueil - LinuxFr.org

Nav denied http url
    Go To			http://${DENIED URL HTTP PROXY}
    Page Should Contain		ACCÈS INTERDIT
    Page Should Contain		Utilisateur : ${USER}
    Page Should Contain		Site interdit : ${DENIED URL HTTP PROXY}
    Capture Page Screenshot

#Nav denied https url
#    Go To			https://${DENIED URL HTTPS PROXY}
#    Page Should Contain		ACCÈS INTERDIT
#    Page Should Contain		Utilisateur : ${USER}
#    Page Should Contain		Site interdit : ${DENIED URL HTTPS PROXY}

Nav site authentification exception
    Go To	${EXCEPTION SITE AUTH}
    Page Should Contain		Ensemble Ouvert Libre Evolutif

Syntaxic filtering
    Go To	${PONDERATION URL}
    Page Should Not Contain    Could not perform content scan!
    Page Should Contain    Limite de pondération dépassée

Nav proxy antivirus
    Go To    ${EICAR URL}
    Page Should Contain    Logiciel malveillant détecté. Eicar-Test-Signature

Close Firefox
    Close Browser
