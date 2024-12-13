*** Settings **
Library         Selenium2Library
Library         XvfbRobot

*** Variables ***
&{etab}		etb1=EoleAdmin2 Etb1
...		etb3=EoleAdmin2 Etb3

&{politics}	aucune=Le groupe de machine squash n'est plus soumis à des interdictions web 
...		web=Le groupe de machine squash est désormais interdit de navigation web. 
...		horaire=Le groupe de machine squash est désormais interdit de navigation web selon les horaires spécifiés.
...		all=Le groupe de machine squash est désormais interdit de toute activité réseau.



*** Keyword ***

EAD2 Admin Login
    [Arguments]	    ${EAD2}
    [Documentation] 	 Login ${EAD2} 
    Log		${politics}
    Run Keyword If	'${xvfb}' == 'True'	Start Virtual Display    640        480
    Open Browser    ${EAD2}    ${BROWSER}		ff_profile_dir=${FF_PROFILE}
    Title Should Be		&{etab}[${ETB}]
    Set Selenium Speed		2
    Go To 	${EAD2}/connect/?server=1
    Input Text  username     admin
    Input Text  password     eole
    Submit Form
    Page Should Contain		EN TANT QUE ADMIN
    Set Selenium Speed		1

Select Computer Group
    Execute Javascript      toggle('menuFiltre web 1')
    Execute Javascript      call_action('1', 'groupe_machine_admin')
    Page Should Contain            Nouveau groupe de machine

Create Computer Group
    [Arguments]	    ${GROUPE_NAME}	${GROUPE_IP_FROM}	${GROUPE_IP_TO}
    [Documentation] 	 Création d'un groupe ${GROUPE_NAME} pour la plage ${GROUPE_IP_FROM} - ${GROUPE_IP_TO}
    #Set Selenium Speed		2
    Execute Javascript		call_action('1','groupe_machine_create_admin', 'ip_set_workspace')
    Page Should Contain Element		id=set_name
    Input Text		set_name	${GROUPE_NAME}
    Input Text		ip_from		${GROUPE_IP_FROM}
    Input Text		ip_to		${GROUPE_IP_TO}
    Run Keyword If 	'${etb}' == "etb1"	Select From List	interface	ens6
    Execute Javascript	formValidForm('1', 'groupe_machine_create_admin', ['set_create'],'set_create_msg')
    Wait Until Page Contains 	${GROUPE_NAME} plage IP: ${GROUPE_IP_FROM} à ${GROUPE_IP_TO}

Check Computer Group is Absent
    [Arguments] 	${GROUPE_NAME}=${GROUPE_NAME}	${GROUPE_IP_FROM}=${GROUPE_IP_FROM}	${GROUPE_IP_TO}=${GROUPE_IP_TO}
    [Documentation] 	Vérification de la présence d'un groupe de machine ${GROUPE_NAME}
    Page Should Not Contain	${GROUPE_NAME} plage IP: ${GROUPE_IP_FROM} à ${GROUPE_IP_TO}

Check Computer Group is Present
    [Arguments] 	${GROUPE_NAME}=${GROUPE_NAME}	${GROUPE_IP_FROM}=${GROUPE_IP_FROM}	${GROUPE_IP_TO}=${GROUPE_IP_TO}
    [Documentation] 	Vérification de la présence d'un groupe de machine ${GROUPE_NAME}
    Page Should Contain		${GROUPE_NAME} plage IP: ${GROUPE_IP_FROM} à ${GROUPE_IP_TO}

Delete Computer Group
    [Arguments]	    		${GROUPE_NAME}
    [Documentation] 	 	Suppression du groupe ${GROUPE_NAME}
    #Set Selenium Speed		2
    Select Computer Group
    Page Should Contain		${GROUPE_NAME} plage IP: 
    Execute Javascript		call_plugin('1','groupe_machine_admin',[['delete','${GROUPE_NAME}']], 'ip_set_del_msg')
    Page Should Not Contain	une erreur s'est produite
    Select Computer Group	

Set Filter Forbid To 
    # politic: 'aucune', 'web', 'horaire', 'all'
    [Documentation]    ${politic}
    [Arguments]		${politic}	${GRP_NAME}=${GROUPE_NAME}	
    ${orig timeout} = 	Set Selenium Timeout 	60 seconds
    Log	 "" &{politics}[${politic}]
    Execute Javascript		return call_plugin('1', 'groupe_machine_admin',[['forbid', '${politic}'],['ip_set', '${GRP_NAME}']], 'ip_set_del_msg')
    Wait Until Element Is Not Visible	id=small_message_box
    Alert Should Be Present	text=&{politics}[${politic}]
    Set Selenium Timeout 	${orig timeout}

Set Filter Policy To 
    #policy: 1: Défault | 2: modérateur | 3: interdits| 4: mode liste blanche | 5: 1 | 6: 2 | 7: 3
    [Documentation]    ${policy}
    [Arguments]		${policy}	${GRP_NAME}=${GROUPE_NAME}
    ${orig timeout} = 	Set Selenium Timeout 	60 seconds
    Execute Javascript		call_plugin('1', 'groupe_machine_admin',[['policy', ${policy}],['ip_set', '${GRP_NAME}']], 'ip_set_del_msg')
    Wait Until Element Is Not Visible	id=small_message_box
    Set Selenium Timeout 	${orig timeout}


Close Firefox
    [Documentation]	Close Firefox
    Close Browser
