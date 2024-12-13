*** Variables ***
${etb}				etb1
${xvfb}				True
${BROWSER}                  	Firefox
${SERVER}                   	etb1.ac-test.fr
${SSO URL}	                https://${SERVER}/
${EAD2_URL}			https://${SERVER}:4200
${REMOTE_SERVER}		http://10.1.2.50:9000
${USER}		                prof.6a
${PASSWORD}	                eole
${INTERNAL IP PART}	    	10.1.2.
${DELAY}                    	5
${GROUPE_IP_FROM}		10.1.2.50
${GROUPE_IP_TO}			10.1.2.100
${GROUPE_NAME}			squash
${FF_PROFILE}	            	/tmp/test_user_profile/

${EXTERNAL IP}				194.167.18.244
${BASE URL} 	            		http://pcll.ac-dijon.fr
${PONDERATION URL}          		http://jc89.free.fr/squash
${EXCEPTION SITE AUTH}      		http://bp-eole.ac-dijon.fr
${EICAR URL} 	            		http://securite-informatique.info/virus/eicar/download/eicar.zip

# Uri tested with proxy
${URL THROUGH HTTP PROXY}	    	http://monip.org
${URL THROUGH HTTPS PROXY}	    	https://linuxfr.org
${DENIED URL HTTP PROXY}	    	sex.fr
${DENIED URL HTTPS PROXY}	    	sex.com
