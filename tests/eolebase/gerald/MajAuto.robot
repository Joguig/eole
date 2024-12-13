*** Settings ***

Documentation    Test suite for MajAuto options
Library         SSHLibrary
# http://robotframework.org/SSHLibrary/latest/SSHLibrary.html
#Resource       ead_keywords.robot
#Resource       datas.robot

*** Variables ***
${HOST}                eolebase.ac-test.fr
${USERNAME}            root
${PASSWORD}            eole

*** Test Cases ***

Connect with SSH
    [Documentation]    Connect to server with SSH
    [Tags]	connexion
    #Set Default Configuration	prompt=#	timeout=5
    Open Connection    ${HOST}
    Login    ${USERNAME}    ${PASSWORD}
    Log	Connexion réussie
Test witch server
    [Documentation]    Test witch server
    Set Client Configuration	prompt=#	timeout=5
    Write 	echo hello 		# consumes written echo hello
    ${stdout}= 	Read Until 	hello 	# consumes read hello and everything before it
    Should Contain 	${stdout} 	hello 	
    ${output}=	Read Until Prompt
    Log	${output}
    Should End With 	${output}	root@eolebase:~#
    Log	${output}
    #${output}= 	Read Until 	@
    #Should End With 	${output} 	root@
    #${output}=    Execute Command    ssh ${USERNAME}@${HOST}
    #Should Be Equal    ${output}    root@eolebase:~#

Execute Command And Verify Output
    [Documentation]    Execute Command can be used to ran commands on the remote machine.
    ...                The keyword returns the standard output by default.
    [Tags]	connexion
    Log	test

    #${output}=    Execute Command    echo Maj-Auto --help
    #Should Be Equal    ${output}    Hello SSHLibrary!
#SC-T04-001
