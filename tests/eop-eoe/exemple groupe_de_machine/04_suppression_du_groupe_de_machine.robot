*** Settings ***
Library         Selenium2Library
Library         XvfbRobot
Resource	./keywords/keywords.robot
Resource    	./datas/datas-${ETB}.robot
Suite Setup	EAD2 Admin Login  ${EAD2_URL}
Suite Teardown	Close Firefox


*** Test Cases ***

Go To Filtre Web 1
    [Documentation]	Dans le sous menu filtre web1
    Select Computer Group

Le groupe ${GROUPE_NAME} doit exister
    [Documentation]	Le groupe de machine ${GROUPE_NAME} doit exister
    Check Computer Group is Present

Suppression du groupe de machine
    [Documentation] 	${GROUPE_NAME}	${GROUPE_IP_FROM} ${GROUPE_IP_TO}
    Delete Computer Group	${GROUPE_NAME}

