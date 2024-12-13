node ('master') { 

    stage ('Checkout') 
    {
       checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '', url: 'ssh://git@dev-eole.ac-dijon.fr/eole-ci-tests.git']]]) 
    }
    
    stage ('Build') 
    {
        ansiColor('xterm') {
            sh """
            /bin/bash -x Jenkinsfile-build.sh
            """
        }
    }

    stage ('Post build actions')
    {
        // Unable to convert a post-build action referring to "com.github.jenkins.lastchanges.LastChangesPublisher". Please verify and convert manually if required.
        // Mailer notification
        step([$class: 'Mailer', notifyEveryUnstableBuild: true, recipients: 'gilles.grandgerard@ac-dijon.fr', sendToIndividuals: true])
    }
}