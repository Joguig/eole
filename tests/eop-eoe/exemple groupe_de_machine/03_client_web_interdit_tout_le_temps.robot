*** Settings ***
Resource	./datas/datas-${ETB}.robot
Library		Remote    ${REMOTE_SERVER}
Library         XvfbRobot

*** Test Cases ***
#Lancer_Xvfb
#    Run Keyword If	${xvfb}=="True"		Start Virtual Display    640	480
#
Navigatin impossible vers pcll.ac-dijon
    Open Firefox    ${BASE URL}		${xvfb}
    Page Should Contain		Adresse refusée

Navigation impossible vers ${URL THROUGH HTTP PROXY}
    Go To	${URL THROUGH HTTP PROXY}
    Page Should Contain 	Adresse refusée

#Navigation impossible vers ${URL THROUGH HTTP PROXY}
#    Go To	${URL THROUGH HTTPS PROXY}
#    Page Should Contain 	Adresse refusée
#
Close Firefox
    Close Browser
