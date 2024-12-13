/*
 * EoleCi
 * Copyright © 2014-2023 Pôle de Compétence Logiciels Libres EOLE <eole@ac-dijon.fr>
 * 
 * LICENCE PUBLIQUE DE L'UNION EUROPÉENNE v. 1.2 :
 * in french: https://joinup.ec.europa.eu/sites/default/files/inline-files/EUPL%20v1_2%20FR.txt
 * in english https://joinup.ec.europa.eu/sites/default/files/custom-page/attachment/2020-03/EUPL-1.2%20EN.txt
 */
//evaluate( new File("/var/lib/jenkins/userContent/EoleNebula/EoleCiScripts2.groovy") )

//@GrabExclude("org.codehaus.groovy:groovy")
//@GrabResolver(name='local', root='file:/media/gilles/Data/.m2/repository/', m2Compatible='true')
//@GrabResolver(name='local', root='file:${user.home}/.m2/repository/', m2Compatible='true')
//@Grab(group='javax.servlet', module='servlet-api', version='2.3') 

//@Grab("javax.servlet:javax.servlet-api:3.1.0")

import jenkins.*
import jenkins.model.*
import jenkins.branch.OrganizationFolder
import hudson.util.RemotingDiagnostics
import hudson.*
import hudson.model.*
import hudson.model.AbstractItem
import hudson.tasks.*
import hudson.console.HyperlinkNote
import hudson.plugins.git.*
import java.util.Date
import java.util.regex.*
import java.util.regex.Matcher
import java.util.regex.Pattern
import java.util.concurrent.*
import java.util.concurrent.CancellationException
import java.text.SimpleDateFormat
import java.lang.String
import java.io.InputStream
import java.io.BufferedReader
import java.io.FileInputStream
import java.io.File
import java.nio.file.Files
import javax.xml.transform.stream.StreamSource
import java.util.concurrent.CancellationException
import org.apache.commons.io.FileUtils

//@Grab("org.jenkins-ci.plugins:nodelabelparameter")
import org.jvnet.jenkins.plugins.nodelabelparameter.LabelParameterValue

//@Grab("org.jenkins-ci.plugins:credentials")

//@Grab("org.jenkins-ci.plugins:categorized-view")
import org.jenkinsci.plugins.categorizedview.CategorizedJobsView
import org.jenkinsci.plugins.categorizedview.GroupingRule

//@Grab("org.jenkins-ci.plugins:cloudbees-folder")
import com.cloudbees.hudson.plugins.folder.Folder

//@Grab("org.codehaus.groovy:groovy-json")
import groovy.json.JsonSlurper
import groovy.json.JsonBuilder
import groovy.time.*

def formatDate( date )
{
    return date.format("dd/MM/yyyy HH:mm")
}

def formatDateLong( ts )
{
    return formatDate( new Date(ts))
}

def debug( texte )
{
    if( this.debugLevel > 0 ) out.print( texte )
}

def debugln( texte )
{
    if( this.debugLevel > 0 ) out.println( texte )
}
    
def debug2( texte )
{
    if( this.debugLevel > 1 ) out.print( texte )
}

def debug2ln( texte )
{
    if( this.debugLevel > 1 ) out.println( texte )
}

def debug3( texte )
{
    if( this.debugLevel > 2 ) out.print( texte )
}

def debug3ln( texte )
{
    if( this.debugLevel > 2 ) out.println( texte )
}

def pause( nbSecondes, texte )
{
    out.println( texte )
    try
    {
        Thread.sleep(nbSecondes * 1000)
    }
    catch(e)
    {
        out.println( e )
        if (e in InterruptedException)
        {
          this.build.setResult(hudson.model.Result.ABORTED)
          throw(e)
        }
    }
}

def processFolder(items)
{
    def allItems = []
    items.each {
        allItems.add( it )
        if( it instanceof Folder)
            allItems.addAll( processFolder( it.items ) )
    }
    return allItems
}

def getItem( jobName )
{
    def trouve = []
    this.allItems.findAll{ item -> if ( item.name.equals( jobName ) ) trouve.add( item ) }
    //out.print( trouve.size() )
    return trouve[0]
}
    
def getScheduleJSon()
{
    if ( scheduleJson == null )
         scheduleJson = new JsonSlurper().parseText( new File(this.mntEoleCiTest + '/jenkins/schedule.json').getText() )
    return scheduleJson
}
    
def getVersionsJSon()
{
    if( versionsJson == null )
        versionsJson = new JsonSlurper().parseText( new File(this.mntEoleCiTest + '/jenkins/liste_version.json').getText() )
    return versionsJson
}
    
def getEoleVersion( versionMajeur )
{
    def eoleVersions = getVersionsJSon().findAll{ eoleVersion -> versionMajeur.equals( eoleVersion.versionMajeurAsString ) }
    if ( eoleVersions != null && eoleVersions.size() > 0)
         return eoleVersions[0]
    else
         return null
}
    
def displayParameters( item )
{
  def prop = item.getProperty( ParametersDefinitionProperty.class )
  if(prop != null)
  {
    out.println("--- Parameters for " + item.name + " ---")
    for(param in prop.getParameterDefinitions())
    {
      try
      {
        out.println(param.name + " " + param.defaultValue)
      }
      catch(Exception e)
      {
        out.println(param.name)
      }
    }
    out.println()
  }
}
    
// sets build parameters based on the given map
// only supports StringParameterValue
def setBuildParameters(map)
{
    def npl = new ArrayList<StringParameterValue>()
    for (e in map)
    {
        npl.add(new StringParameterValue(e.key.toString(), e.value.toString()))
    }
    def newPa = null
    def oldPa = build.getAction(ParametersAction.class)
    if (oldPa != null)
    {
        build.actions.remove(oldPa)
        newPa = oldPa.createUpdated(npl)
    }
    else
    {
        newPa = new ParametersAction(npl)
    }
    build.actions.add(newPa)
}
        
def createJobsAExecuter()
{
    return new ArrayList();
}
    
def getTodoFile( jobName )
{
    return new File( this.mntEoleCiTest + "/jenkins/todo", jobName )
}
    
def deleteTodo( todoFile )
{
    // archive
    def fileSavTodo = new File( this.mntEoleCiTest + "/jenkins/todo/sav", todoFile.getName() )
    if ( fileSavTodo.exists() )
    {
        hudson.Util.deleteFile( fileSavTodo )
    }
    
    if ( todoFile.exists() )
    {
        hudson.Util.copyFile( todoFile, fileSavTodo )
        
        // delete
        hudson.Util.deleteFile( todoFile )
    }
}

def createTodo( item )
{
    if ( item == null )
    {
        debugln( "  createTodo: item NULL !" )
        return
    }
    if ( item instanceof Folder )
    {
        out.println( "  createTodo: " + item.name + " is folder ! " )
        return
    }
    //if ( item.isBuildable() == false )
    //{
    //    out.println( "  createTodo: " + item.name + " n'est pas buildable ! " )
    //    return
    //}

    def jobJSon = getScheduleJSon().find{ it -> it.jenkinsJobName.equals( item.name ) }
    if ( jobJSon == null )
    {
        out.println( "  createTodo: " + item.name + " n'existe pas dans schedule.json ! " )
        return
    }
    def fileTodo = getTodoFile( item.name )
    deleteTodo( fileTodo )
    out.println( "  createTodo: " +  fileTodo.getAbsolutePath() )
    fileTodo.createNewFile()
} 
    
def addJobAExecuter( jobsAExecuter, item )
{
    if ( item == null )
    {
        debugln( "addJobAExecuter: item NULL !" )
        return -1
    }
    if ( item instanceof Folder )
    {
        out.println( item.name + " is folder ! " )
        return -1
    }
    //if ( item.isBuildable() == false )
    //{
    //    out.println( item.name + " n'est pas buildable ! " )
    //    return -1
    //}

    def lastBuild = item.lastBuild
    if ( lastBuild != null )
    {
         def fileTodo = getTodoFile( item.name )
         if ( fileTodo.exists() )
         {
            def timestampFichierTodo = fileTodo.lastModified()
            if ( lastBuild.timestamp.time.time > timestampFichierTodo )
            {
                // a été executer apres le fichier 'Todo' ==> a supprimer
                out.println( "  todo antérieur à " + fileTodo.getAbsolutePath() + " donc j'ignore !")
                deleteTodo( fileTodo )
                return -2
            }
         }
    }

    debug2ln( "addJobAExecuter: " + jobsAExecuter.size() + " " + item.name )
    def jobAExecuter = [:]
    jobAExecuter.'item' = item
    jobAExecuter.'jenkinsJobName' = item.name
    jobAExecuter.'status' = 'TODO'
    jobAExecuter.'future' = null
    jobAExecuter.'jobJSon' = getScheduleJSon().find{ it -> it.jenkinsJobName.equals( jobAExecuter.jenkinsJobName ) }
    if ( jobAExecuter.jobJSon == null )
    {
        jobAExecuter.'ordre' = 1000
        debugln( "addJobAExecuter: " + jobAExecuter.jenkinsJobName + " inconnu!")
        return 1
    }
    else
    {
        jobAExecuter.'ordre' = jobAExecuter.jobJSon.ordre
        debug3ln( "AddJobAExecuter: " + jobAExecuter.jenkinsJobName + " " + jobAExecuter.ordre)
    }
    jobsAExecuter.add( jobAExecuter )
    return 0
}
   

def estCeQueLesJobsDependantSontOk( item )
{
   debugln("  estCeQueLesJobsDependantSontOk : ")
   if ( item == null )
   {
      debugln( " (item NULL) !" )
      return false
   }
   def job = getScheduleJSon().find{ it -> it.jenkinsJobName.equals( item.name ) }
   if ( job == null )
   {
      debugln( " : inconnu, ok  par defaut " )
      return true
   }
      
   def msg = "  [ "
   
   def result = true
   job.depends.each{ depen ->
        def dep = depen.depend
        def depJob = getItem( dep )
        if ( depJob != null && ! depJob.disabled )
        {
            def lastBuild = depJob?.lastBuild
            if ( lastBuild == null )
            {
                msg = msg + "("+HyperlinkNote.encodeTo('/' + depJob.getUrl(), depJob.getFullDisplayName()) + " : jamais lancé) "
            }
            else
            { 
                def Result lastResult = lastBuild?.result
                def String buildNumber = lastBuild?.number
                def String lastBuildResult = lastResult?.toString()
                msg = msg + "("+HyperlinkNote.encodeTo('/' + depJob.getUrl(), depJob.getFullDisplayName()) + " : " + lastBuildResult + ") "
                if ( lastBuildResult == "FAILURE" )
                    result = false
            }
        }
    }
    msg = msg + " ] ==> " + result
    if ( result == false )
        out.println( msg )
    else
        debugln( msg )
    return result
}

def checkStatusJobDependant()
{
    getScheduleJSon().each{ job ->
           def item = getItem( job.jenkinsJobName )
           estCeQueLesJobsDependantSontOk( item )
    }
    return 0
}

def checkMntEoleCiTests()
{
    def date = new Date()
    def long limite = date.getTime() + 10 * 60000L ; // 10 minutes comme le timer sur jenkins
    while( date.getTime() < limite )
    {
        if ( new File( "/mnt/eole-ci-tests/ModulesEole.yaml" ).exists() )
        {
            //debug2ln("/mnt/eole-ci-tests présent")
            return true
        }
        pause( 10, "/mnt/eole-ci-tests: ne semble plus monté, annulation ...")
    }
    out.println( "/mnt/eole-ci-tests: Timeout , stop...")
    this.mntEoleCiTest = "/mnt/eole-ci-tests" 
    return false
}

def doScheduleWithNode( noJob, item, nodeSelfLabel, checkDepends)
{
    if ( item == null )
        return 0
    try
    {
        out.println("  ===============================================")
        out.println("  Schedule " + noJob + " : " + item.fullDisplayName + " à " + formatDate(new Date()) )
        
        def parametersDefinitionProperty = item.getProperty('hudson.model.ParametersDefinitionProperty')
        if ( parametersDefinitionProperty != null )
        {
            def paramsJob = parametersDefinitionProperty.parameterDefinitions
            paramsJob.each { p ->
                 debug2ln( "  param du Job à executer : " + p.name + " " + p.type)
            }
        }
        
        def npl = new ArrayList<StringParameterValue>()
        def params = ""
        this.envvars.each {
            debug2ln( "  inject envvar: " + it )
            params = params + it.getKey() + "='" + it.getValue() + "' "
            npl.add(new StringParameterValue( it.getKey(), it.getValue().toString() ))
        }
        def isSetted = false
        this.parameters.each {
            debug2ln( "  inject parameter: " + it + " " + it.class)
            def v = it.value
            if ( "NEBULA_PASSWORD".equals( it.name ) )
                v = "*******"
            if ( it instanceof LabelParameterValue )
            {
                def labelParameterValue = (LabelParameterValue) it
                isSetted = true
                params = params + it.name + "='" + nodeSelfLabel + "' "
                npl.add(new LabelParameterValue( it.name, nodeSelfLabel ))
            }
            else
            {
                params = params + it.name + "='" + v + "' "
                npl.add(new StringParameterValue( it.name, v.toString() ))
                }
            }
        if ( nodeSelfLabel != null && isSetted == false)
      	{
            out.println( "  inject BUILD_ON: " + nodeSelfLabel )
            npl.add( new LabelParameterValue( "BUILD_ON", nodeSelfLabel ) )
        }

        def todoFile = getTodoFile( item.name )
        if (todoFile.exists() )
        {
            npl.each {
                debug2ln( "  npl: " + it + " " + it.class)
                todoFile.eachLine { line -> 
                    int eqlsign = line.indexOf('=');
                    if (eqlsign != -1)
                    {
                        k = line.substring(0,eqlsign)
                        v = line.substring(eqlsign+1)
                        if ( it.name.equals( k ) )
                        {
                            debug2ln( "Surcharge de todo: ${line} ==> " + it )
                            it.value = v
                            params = params + it.name + "='" + it.value + "' "
                        }
                    }
                } 
            }
        }

        if ( checkDepends == true && estCeQueLesJobsDependantSontOk( item ) == false )
        {
            out.println("  ==> IGNORE CAR L'UN DES JOBS DEPENDANTS EST EN ERREUR !" )
            return 0;
        }
        else
        {
            if ( checkMntEoleCiTests() == false )
            {
                return 0
            }
                
            if ( try_pattern == false )
            {
                out.println("  start with parm : [" + params + "]" )
                out.println("  see: " + item.getAbsoluteUrl() )
                def parametersAction = new hudson.model.ParametersAction(npl)
                def future = item.scheduleBuild2(0, new hudson.model.Cause.UpstreamCause( build ), parametersAction )
                out.println("  future: " + future )
                return 1
            }
            else
            {
                out.println("  TRY: start with parm : [" + params + "] " )
                // je ments pour lui faire croire que c'est ok. sinon, il y a un risque de boucle infinie
                return 1
            }
        }
    }
    catch (CancellationException x)
    {
        out.println( x.getMessage() )
        return 0
    }
    catch (Exception x)
    {
        x.printStackTrace( out )
        return 0
    }
}


def getOneAccountDefaultForComputer( computer )
{
    if ( "MasterComputer".equals(computer.getClass().getSimpleName()) )
    {
        return "jenkins"
    }
    if ( computer.getClass().getSimpleName().startsWith("win" ) )
    {
        return "jenkins"
    }
    return computer.getNode().getDisplayName().replace("gw-","")
}

def getComputerName( computer )
{
    if ( "MasterComputer".equals(computer.getClass().getSimpleName()) )
    {
        return this.labelControler
    }
    return computer.getNode().getDisplayName()
}

def getResourcesToLockForJob( item )
{
    def name = item.name
    debug3ln( "    getResourcesToLockForJob : " + name )
    def folder = item.parent
    //out.println( name +" " + folder.name + " " + item.fullDisplayName )
    if ( folder.name.equals("infra") )
        job1JSon = getScheduleJSon().find{ it -> it.jenkinsJobName.equals( item.name ) }
    else
        job1JSon = getScheduleJSon().find{ it -> it.versionMajeur.equals( folder.name ) && it.jenkinsJobName.equals( item.name ) }
    if ( job1JSon == null )
    {
        out.println( "    getCurrentResourcesToLock: " + name + " inconnu!")
        return []
    }
    debug3ln( "    getResourcesToLockForJob ==> job: " + name + " resourcesToLock = " + job1JSon.resourcesToLock )
    return job1JSon.resourcesToLock
}

def getBuildsByAccount()
{
    debug2ln("  getBuildsByAccount" )

    def oneAccounts = [:]
    Jenkins.instance.computers.each { computer ->
        def computerName = getComputerName( computer )
        if ( computer.isOffline() )
        {
            debug2ln( "    " + computerName + ' offline ignore')
            return;
        }

        if ( ! computer.isAcceptingTasks()  )
        {
            debug2ln( "    " + computerName + ' n accept pas les taches, ignore')
            return;
        }
        
        debug3ln("    " + computerName + ' scan')
        def account = getOneAccountDefaultForComputer( computer )
        debug3ln("    " + computerName + ' account = ' + account)
        def agentsForAccount = oneAccounts.get( account )
        if( agentsForAccount == null )
        {
            agentsForAccount = [:]
            agentsForAccount.'agents' = []
            agentsForAccount.'jobs' = []
            agentsForAccount.'resourcesToLockForAccount' = []
            oneAccounts.put( account, agentsForAccount )
        }
        agentsForAccount.agents.add( computer )
    
        computer.executors.each { executor ->
             def currentBuild = executor.getCurrentExecutable()
             if ( ! executor.isBusy()
                || (currentBuild == null)
                || (currentBuild instanceof hudson.model.FreeStyleBuild == false) )
                return // continue!
             
             def job = currentBuild.getProject()
             def folder = job.parent
             if( folder.name.equals("Internes") || folder.name.equals("trigger") )
                return // continue!
                
             def fileTodo = getTodoFile( job.name )
             if ( fileTodo.exists() )
             {
                 out.println( "  suppression todo " + fileTodo.getAbsolutePath() + " car le buils est en cours")
                 deleteTodo( fileTodo )
             }

             def resourcesToLockForJob = getResourcesToLockForJob( job )
             debug2ln( "    " + computerName + " resource lock : " + resourcesToLockForJob )
             agentsForAccount.jobs.add( job )
             agentsForAccount.resourcesToLockForAccount.addAll( resourcesToLockForJob )
         }
         agentsForAccount.resourcesToLockForAccount = agentsForAccount.resourcesToLockForAccount.unique()
    }
    
    if( this.debugLevel > 1 )
    {
        debug2ln( "  getBuildsByAccount result : " )
        oneAccounts.each { account, agentsForAccount ->
            debug2ln( "    -> " + account + " : " + agentsForAccount.resourcesToLockForAccount )
        }
    } 
    return oneAccounts
}

def isAgentForLabels( computer, labels)
{
    def computerLabelString = computer.getNode().getLabelString()
    def allLabels = labels.split(',')
    debug2ln( "isAgentForLabels " + allLabels + " computer="+ computerLabelString )
    def forLabel = allLabels.findAll{ label -> computerLabelString.contains( label ) }
    debug2ln( "isAgentForLabels " + (forLabel.size() > 0) )
    return forLabel.size() > 0
}

// call from Jenkins http://jenkins.eole.lan/jenkins/job/Internes/job/template-TriggerVersion
// attention: c'est le template !
def updateDailys()
{
    debugLevel = 1
    def versionAActualiser = this.argVersionMajeur
    if ( "{{VERSION_MAJEUR}}".equals( versionAActualiser ) )
        return 1
    def eoleVersion = getEoleVersion( versionAActualiser )
    if ( eoleVersion == null)
    {
        out.println( "Version inconnu '" + versionAActualiser +"'" )
        return 1
    }

    def majAuto = eoleVersion.majAuto
    def source = this.source
    out.println( "versionAActualiser: " + versionAActualiser + " " + majAuto )
    out.println( "source: " + this.source)
    out.println( "checkTriggerTime: " + this.checkTriggerTime)
    out.println( "try_pattern: " + this.try_pattern)

    def folder = getItem( versionAActualiser )
    if ( folder == null )
    {
        out.println( "  folder inexistant '" + versionAActualiser +"'" )
        return 1
    }

    folder.getAllJobs().each{ item ->
          if ( item.name.startsWith("day-") )
          {
              if ( (this.checkTriggerTime == false) || checkDailyFromTrigger( item, eoleVersion, source) )
              {
                  createTodo( item )
              }
          }
    }
    return 0
}

// call from Jenkins http://jenkins.eole.lan/jenkins/job/Internes/job/run-all-jobs-with-pattern
def runAllJobWithPattern()
{
    out.println( "patternLogs : " + this.patternLogs)
    out.println( "patternJobs : " + this.patternJobs)
    out.println( "try_pattern : " + this.try_pattern)
    out.println( "dansMonContexte : " + this.dansMonContexte)
    out.println( "seulementCeuxEnErreur : " + this.seulementCeuxEnErreur)
    out.println( "Cloud : " + this.cloudToUse)
    out.println( "forceRebuild : " + this.forceRebuild)
    out.println( "nbJours : " + this.nbJours)

    long afterDate = System.currentTimeMillis() - (this.nbJours * 24l * 60l * 60l * 1000l)
    out.println( "=========================================================" )
    out.println( "Filtre Build depuis le " + new Date( afterDate ).format("dd/MM/yyyy HH:mm") )
    out.println( "=========================================================" )
    patternLogsCompiled = Pattern.compile(this.patternLogs)
    patternJobsCompiled = Pattern.compile(this.patternJobs)
    
    this.allItems.each{ job -> 
        if ( job instanceof FreeStyleProject == false )
        {
            debug2ln( job.name + " : pas freestyle ==> ignore" )
            return
        }
        if ( job instanceof Folder )
        {
            debug2ln( job.name + " : folder ==> ignore" )
            return
        }
        //if ( job.isBuildable() == false )
        //{
        //    debug2ln( job.name + " : buildable ==> ignore" )
        //    return
        //}
     
        if( job.fullName.startsWith("Internes") || job.name.startsWith("trigger"))
        {
            debug2ln( job.name + " : internes ou trigger ==> ignore" )
            return
        }
        
        def jobJSon = getScheduleJSon().find{ it -> it.jenkinsJobName.equals( job.name ) }
        if ( jobJSon == null )
        {
            debug2ln( job.name + " : pas dans json ==> ignore" )
            return
        }
    
        if ( this.seulementCeuxEnErreur )
        {
            if ( job.lastBuild?.result != hudson.model.Result.FAILURE )
            {
                debug2ln( job.name + " : last != FAILURE ==> ignore" )
                return
            }
        }
    
        if ( "".equals(this.patternJobs) == false )
        {
            Matcher matcher = patternJobsCompiled.matcher(job.name)
            if (matcher.find() == false ) 
            {
                debugln( job.name + " : pas de pattern Jobs / name ==> ignore" )
                return 
            }
        }
        
        if( "".equals(this.patternLogs) == false )
        {
            allBuilds = job.getBuilds().byTimestamp(afterDate, System.currentTimeMillis()).findAll{ buildJob -> analyseLog( buildJob, patternLogsCompiled ) }
            if ( allBuilds.size() == 0) 
            {
                debug2ln( job.name + " : pas de pattern Logs ==> ignore" )
                return
            }
            allBuilds.each{ buildJob ->
                    out.println( "  " + HyperlinkNote.encodeTo('/' + buildJob.url, buildJob.fullDisplayName) + " " + buildJob.result + " " + buildJob.duration + "s " + buildJob.timestampString )
                    }
        }

        if ( this.try_pattern == true )
        {
            out.println( job.fullName + " ==> TRY")
            return
        }

        out.println( job.name + " ==> à executer" )
        createTodo( job )
    }

}

def getConfigXmlString( templateName )
{
    def item = getItem( templateName )
    if ( item == null )
    {
        out.println( "  template " + templateName + " manquant")
        retur null;
    }
    return new String( Files.readAllBytes( item
                                            .getConfigFile()
                                            .getFile()
                                            .toPath()
                                           ),
                         "UTF-8")
}

def createOrUpdateJobWithConfig( nom, config, folderName)
{
    if ( config == null )
        return null
        
    def folder = getItem( folderName )
    if ( folder == null )
    {
        out.println( "  folder inexistant '" + folderName +"'" )
        return null
    }
               
    def AbstractItem job = getItem( nom )
    if ( job == null )
    {
        out.println( "  Create job '" + nom +"'" )
        job = folder.createProjectFromXML( nom, new ByteArrayInputStream( config.getBytes("UTF-8") ));
        job.save()
        out.println( "  fullname = '" + job.fullName +"'")
    }
    else
    {
        out.println( "  Update job '" + nom +"'")
        def StreamSource s = new StreamSource( new ByteArrayInputStream( config.getBytes("UTF-8") ) )
        job.updateByXml( s );
        job.save()
    }
    return job
}

def estRenseigne( object )
{
    if (object == null)
        return false
    else
        return object.toString().length() > 0
}
    
def updateSource( sourceTemplate, nomArgument, abreviationArgument, valeur)
{
    if (estRenseigne( valeur ))
    {
        sourceTemplate = sourceTemplate.replaceAll("\\{\\{" + nomArgument + "\\}\\}", valeur)
        if ( estRenseigne( abreviationArgument ) )
        {
            sourceTemplate = sourceTemplate.replaceAll("\\{\\{ARG_" + nomArgument + "\\}\\}", " -" + abreviationArgument + " " + valeur)
        }
    }
    else
        sourceTemplate = sourceTemplate.replaceAll("\\{\\{ARG_" + nomArgument + "\\}\\}", "")
    return sourceTemplate
}

def updateTemplate( nom, mainCmd, templateName, arguments )
{
    out.println( "updateTemplate " + nom + " " + mainCmd + " " + templateName + " " + arguments)
    def doitSauvegarder = false
   
    if ( templateName == null || templateName.equals( "" ) )
    {
        out.println( "updateJob " + nom  + " templateName incorrecte");
        return
    }
          
    def sourceTemplate = getConfigXmlString( templateName )
    if ( sourceTemplate == null )
        return

    def sourceTemplateInitial = sourceTemplate
    sourceTemplate = updateSource( sourceTemplate, "ARGUMENTS", "", arguments)
    
    job = createOrUpdateJobWithConfig( nom, sourceTemplate, "infra" )
    if ( job == null )
    {
        out.println( "  " + nom  + " annulé")
        return
    }

    if( job instanceof Folder )
    {
        out.println( "  le job  " + jobName  + " est un Folder !")
        return
    }
    if( job instanceof FreeStyleProject == false)
    {
        out.println ( "  " + job + " n'est pas FreeStyleProject !" )
        return
    }
    
    def repertoireJob = job.getConfigFile().getFile().getParent()
    out.println( "  repertoireJob = " + repertoireJob )
    out.println("  Sauvegarde ...")
    job.save()
}

def updateTemplates()
{
    //controler
    updateTemplate( "template-CreateIsoEtDisk"               , "CreateIsoEtDisk"               , "template-EoleCi-ControlerOnly"   , "{{ARG_MAIN_CMD}} {{ARG_VERSION_MAJEUR}} {{ARG_ARCHITECTURE}} {{ARG_MODULE}} " )
    updateTemplate( "template-CreateFreshInstall"            , "CreateFreshInstall"            , "template-EoleCi-ControlerOnly"   , "{{ARG_MAIN_CMD}} {{ARG_MODULE}} {{ARG_VERSION_MAJEUR}} {{ARG_ARCHITECTURE}}" )
    updateTemplate( "template-CreateDailyFreshInstall"       , "CreateDailyFreshInstall"       , "template-EoleCi"              , "{{ARG_MAIN_CMD}} {{ARG_MODULE}} {{ARG_VERSION_MAJEUR}} {{ARG_ARCHITECTURE}}" )
    updateTemplate( "template-CreateMarketImage"             , "CreateMarketImage"             , "template-EoleCi-Market"          , "{{ARG_MAIN_CMD}} {{ARG_MODULE}} {{ARG_VERSION_MAJEUR}} {{ARG_ARCHITECTURE}}" )

    updateTemplate( "template-CheckImageExterne"             , "CheckImageExterne"             , "template-EoleCi-ControlerOnly"   , "{{ARG_MAIN_CMD}} {{ARG_IMAGE_NAME}} {{ARG_ARCHITECTURE}}" )
    updateTemplate( "template-BuildFreshInstallImageExterne" , "BuildFreshInstallImageExterne" , "template-EoleCi"              , "{{ARG_MAIN_CMD}} {{ARG_IMAGE_NAME}} {{ARG_ARCHITECTURE}}" )
    updateTemplate( "template-BuildImagePrepare"             , "BuildImagePrepare"             , "template-EoleCi"              , "{{ARG_MAIN_CMD}} {{ARG_IMAGE_NAME}} {{ARG_ARCHITECTURE}}" )
    updateTemplate( "template-BuildImageFinale"              , "BuildImageFinale"              , "template-EoleCi"              , "{{ARG_MAIN_CMD}} {{ARG_IMAGE_NAME}} {{ARG_ARCHITECTURE}}" )
    
    updateTemplate( "template-UpdateImageIntermediaire"      , "UpdateImageIntermediaire"      , "template-EoleCi"              , "{{ARG_MAIN_CMD}} {{ARG_IMAGE_NAME}} {{ARG_ARCHITECTURE}}" )
    updateTemplate( "template-UpdateImageFinale"             , "UpdateImageFinale"             , "template-EoleCi"              , "{{ARG_MAIN_CMD}} {{ARG_IMAGE_NAME}} {{ARG_ARCHITECTURE}}" )
    updateTemplate( "template-UpdateImageExterne"            , "UpdateImageExterne"            , "template-EoleCi"              , "{{ARG_MAIN_CMD}} {{ARG_IMAGE_NAME}} {{ARG_ARCHITECTURE}}" )
    
    updateTemplate( "template-CreateFreshInstallFromUbuntu"  , "CreateFreshInstallFromUbuntu"  , "template-EoleCi-ControlerOnly"   , "{{ARG_MAIN_CMD}} {{ARG_MODULE}} {{ARG_VERSION_MAJEUR}} {{ARG_ARCHITECTURE}}" )
    // tests
    // specialisé : updateTemplate( "template-TestEoleCi", "TestEoleCi", "template-EoleCi", "{{ARG_MAIN_CMD}} {{ARG_NOM_TEST}} {{ARG_ARCHITECTURE}} {{ARG_VERSION_MAJEUR}} {{ARG_IMAGE_NAME}}" )
    // specialisé : updateTemplate( "template-TestEoleCi-runner", "TestEoleCi", "template-TestEoleCi", "{{ARG_MAIN_CMD}} {{ARG_NOM_TEST}} {{ARG_ARCHITECTURE}} {{ARG_VERSION_MAJEUR}} {{ARG_IMAGE_NAME}}" )
    //template-TestEoleCi-GG
    //template-run-eole-ci-test
    //template-run-tests
    //template-TriggerVersion
}

def updateJob( jobJSon )
{
    def nom = jobJSon.jenkinsJobName
    def mainCmd = jobJSon.mainCmd
    def phaseBuild = jobJSon.level
    def versionMajeur = jobJSon.versionMajeur
    def architecture = jobJSon.architecture
    def frequence = jobJSon.frequence
    def templateName = jobJSon.template
    def genereImage = jobJSon.genereImage
    def imageName = jobJSon.imageName
    def nomTest = jobJSon.nomTest
    def idTest = jobJSon.idTest
    def stageTest = jobJSon.stageTest
    def module = jobJSon.module
    def status = jobJSon.status
    def regroupement = jobJSon.regroupement
    def titre = jobJSon.titre
    def description = jobJSon.description
    def label = jobJSon.label

    out.println( "updateJob " + nom + " " + mainCmd + " " + phaseBuild + " " + versionMajeur + " " + architecture + " " + templateName + " label=" + label)
    def doitSauvegarder = false
   
    if ( templateName == null || templateName.equals( "" ) )
    {
        out.println( "updateJob " + nom  + " templateName incorrecte");
        return
    }
          
    def sourceTemplate = getConfigXmlString( templateName )
    if ( sourceTemplate == null )
        return

    def sourceTemplateInitial = sourceTemplate
    out.println( "  utilise template " + templateName )
    def job = null
    
    sourceTemplate = updateSource( sourceTemplate, "LEVEL", "", "" + phaseBuild )
    sourceTemplate = updateSource( sourceTemplate, "MAIN_CMD", "c", mainCmd)
    sourceTemplate = updateSource( sourceTemplate, "ARCHITECTURE", "a", architecture)
    sourceTemplate = updateSource( sourceTemplate, "NOM_TEST", "t", nomTest)
    sourceTemplate = updateSource( sourceTemplate, "STAGE_TEST", "s", stageTest)
    sourceTemplate = updateSource( sourceTemplate, "ID_TEST", "i", idTest)
    sourceTemplate = updateSource( sourceTemplate, "IMAGE_NAME", "I", imageName)
    sourceTemplate = updateSource( sourceTemplate, "TITRE", "", titre)
    sourceTemplate = updateSource( sourceTemplate, "REGROUPEMENT", "", regroupement)
    sourceTemplate = updateSource( sourceTemplate, "LABELS", "", label)
    sourceTemplate = updateSource( sourceTemplate, "STATUS", "", status)
    sourceTemplate = updateSource( sourceTemplate, "MODULE", "m", module)
    sourceTemplate = updateSource( sourceTemplate, "VERSION_MAJEUR", "v", versionMajeur)
    if ( estRenseigne( versionMajeur ) )
    {
        def eoleVersion = getEoleVersion( versionMajeur )
        if ( eoleVersion != null)
        {
            // cas EOLE
            sourceTemplate = updateSource( sourceTemplate, "MAJ_AUTO", "", eoleVersion.majAuto)
            sourceTemplate = updateSource( sourceTemplate, "UBUNTU_NOM", "", eoleVersion.distributionNom)
        }
        else
        {
            // cas non EOLE !
        }
    }
    
    if ( estRenseigne( versionMajeur ) == false )
    {
        job = createOrUpdateJobWithConfig( nom, sourceTemplate, "infra" )
    }
    else
    {
        job = createOrUpdateJobWithConfig( nom, sourceTemplate, versionMajeur )
    }
     
    if ( job == null )
    {
        out.println( "  " + nom  + " annulé")
        return
    }

    doitSauvegarder = true
            
    if( job instanceof Folder )
    {
        out.println( "  le job  " + jobName  + " est un Folder ")
        return
    }
    if( job instanceof FreeStyleProject == false)
    {
        out.println ( "  " + job + " n'est pas FreeStyleProject !" )
        return
    }
    
    if ( "".equals(job.description) )
    {
        job.description = "Généré depuis '" + templateName + "'"
         
        if ( estRenseigne( description ) )
        {
            job.description = job.description + "\n\n" + description
        }
            
        doitSauvegarder = true
    }

    if ( "".equals(job.displayName) )
    {
        if ( estRenseigne( titre ) )
        {
            if ( job.displayName.equals( titre ) == false )
            {
                job.displayName = titre
                doitSauvegarder = true
            }
        }
    }
        
    def repertoireJob = job.getConfigFile().getFile().getParent()
    out.println( "  repertoireJob = " + repertoireJob )
    
    if ( job.disabled )
    {
        out.println( "  active job : " + frequence )
        job.enable()
        doitSauvegarder = true
    }
  
    def builders = job.getBuildersList()
    if ( builders.size() == 0 )
    {
        out.println("  ERREUR **** aps de builder ! ")
        return
    }
    
    if ( doitSauvegarder )
    {
        out.println("  Sauvegarde ...")
        job.save()
    }
    else
    {
        out.println("  A jour ...")
    }
}

def updateTriggerVersionSource( sourceName, versionMajeur, majAuto, distributionNom)
{
    def nom = "trigger-" + versionMajeur
    def lastDiffFile = versionMajeur
    if ( sourceName.equals("") == false && sourceName.equals("eole") == false )
    {
        nom = "trigger-" + versionMajeur + "-" + sourceName ;
        lastDiffFile = versionMajeur + "-" + sourceName 
    }
    else
    {
        sourceName = "eole"
    }

    out.println( "updateTriggerVersion " + nom + " - " + versionMajeur + " - " + distributionNom  +" - " + sourceName)
    def doitSauvegarder = false

    def templateName = "template-TriggerVersion"
    def sourceTemplate = getConfigXmlString( templateName )
    if ( sourceTemplate == null )
        return

    sourceTemplate = updateSource( sourceTemplate, "VERSION_MAJEUR", "v", versionMajeur)
    sourceTemplate = updateSource( sourceTemplate, "MAJ_AUTO", "", majAuto)
    sourceTemplate = updateSource( sourceTemplate, "SOURCE", "", sourceName)
    sourceTemplate = updateSource( sourceTemplate, "DISTRIBUTION_NOM", "", distributionNom)
    sourceTemplate = updateSource( sourceTemplate, "LASTDIFF_FILE", "", lastDiffFile)
    
    def job = createOrUpdateJobWithConfig( nom, sourceTemplate, versionMajeur )
    if ( job == null )
    {
        out.println( "  " + nom  + " annulé")
        return
    }
    doitSauvegarder = true
            
    if( job instanceof Folder )
    {
        out.println( "  le job  " + jobName  + " est un Folder ")
        return
    }
    if( job instanceof FreeStyleProject == false)
    {
        out.println ( "  " + job + " n'est pas FreeStyleProject !" )
        return
    }

    if ( "".equals(job.description) )
    {
        job.description = "Généré depuis '" + templateName + "'";
        doitSauvegarder = true
    }

    def repertoireJob = job.getConfigFile().getFile().getParent()
    out.println( "  " + repertoireJob )
    
    if ( job.disabled )
    {
        out.println( "  activation trigger" )
        job.disabled = false
        doitSauvegarder = true
    }
    
    if ( doitSauvegarder )
    {
        out.println("  Sauvegarde ...")
        job.save()
    }
    else
    {
        out.println("  A jour ...")
    }
}
def updateTriggerVersion( eoleVersion )
{
    def versionMajeur = eoleVersion.versionMajeurAsString
    def majAuto = eoleVersion.majAuto
    eoleVersion.sources.each{ source -> updateTriggerVersionSource( source.name, versionMajeur, majAuto, source.distributionNom ) }
}


// call from Jenkins http://jenkins.eole.lan/jenkins/job/Internes/job/run-update-jenkins-jobs
def updateAllJobs()
{
    getVersionsJSon().each{ eoleVersion -> checkFolderVersion( eoleVersion ) }
    getVersionsJSon().each{ eoleVersion -> updateTriggerVersion( eoleVersion ) }
    updateTemplates()
    getScheduleJSon().each{ jobJSon -> updateJob( jobJSon ) }
    createViewVersionArchitecture()
    return 0
}


def createViewCategorisation( versionMajeur, versionView, regroupementJobs)
{
    if ( versionView == null )
        return
        
    out.println( "Creation des CategorizationCriteria pour " + versionView.name );
                        
    def mapRegroupe = [
        '00':[ groupement:'00 : Check ISO'],
        '01':[ groupement:'01 : Check ISO Image Externe' ],
        '02':[ groupement:'02 : Trigger Change Depot' ],
        '10':[ groupement:'10 : FreshInstall' ],
        '11':[ groupement:'11 : FreshInstallFromUbuntu' ],
        '17':[ groupement:'17 : Build Image Externe FreshInstall (fi)' ],
        '18':[ groupement:'18 : Build Image Externe intermédiaire (daily)' ],
        '19':[ groupement:'19 : Build Image Externe finale (vm)' ],
        '20':[ groupement:'20 : Daily' ],
        '21':[ groupement:'21 : Market' ],
        '22':[ groupement:'22 : Genconteneur avec CROM' ],
        '27':[ groupement:'27 : Update Image Externe (fi)' ],
        '28':[ groupement:'28 : Update Image Intermediaire (daily)' ],
        '29':[ groupement:'29 : Update Image Finale (vm)' ],
        '30':[ groupement:'30 : Instance' ],
        '31':[ groupement:'31 : Importation base' ],
        '50':[ groupement:'50 : Check Instance' ],
        '51':[ groupement:'51 : Creole Lint' ],
        '52':[ groupement:'52 : Module tests' ],
        '53':[ groupement:'53 : Certificats' ],
        '54':[ groupement:'54 : Pylint' ],
        '55':[ groupement:'55 : Reconfigure et Diagnose' ],
        '60':[ groupement:'60 : Upgrade Auto' ],
        '61':[ groupement:'61 : Maj Release' ],
        '61':[ groupement:'60 : Migration Sh' ],
        '70':[ groupement:'70 : Sauvegarde' ],
        '89':[ groupement:'89 : Scribe' ],
        '90':[ groupement:'90 : Zephir' ],
        '91':[ groupement:'91 : Eolebase divers' ],
        '92':[ groupement:'92 : Sphynx' ],
        '93':[ groupement:'93 : EAD' ],
        '94':[ groupement:'94 : Thot' ],
        '95':[ groupement:'95 : Era' ],
        '96':[ groupement:'96 : Seth' ],
        '97':[ groupement:'97 : Hapy' ],
        '98':[ groupement:'98 : Eclair' ],
        '99':[ groupement:'99 : Etablissement' ],
        '9A':[ groupement:'9A : AmonEcole' ],
        'E0':[ groupement:'E0 : Ecologie' ],
        'EN':[ groupement:'EN : ENVOLE' ],
        'SE':[ groupement:'SE : Seth Education (Contribution CADOLES)' ],
        'W0':[ groupement:'W0 : Postes Clients Windows' ],
        'X0':[ groupement:'X0 : Postes Clients Linux' ],
        'Z2':[ groupement:'Z2 : Zephir 2' ],
        '?':[ groupement:'100 : Autres' ],
       ]
       
    versionView.categorizationCriteria.add( new GroupingRule("^trigger-.*", "02 : Trigger Change Depot") )
    debugln( "regroupementJobs size=" + regroupementJobs.keySet().size());
    for( r in regroupementJobs.keySet())
    {
       def listPattern = regroupementJobs.get( r )
       if ( listPattern == null || listPattern.size() < 1 )
       {
           debugln( "group r=" + r + " listPatterne null ou vide !");
           continue
       }
        
       def categorie = mapRegroupe.get( r )
       if( categorie == null )
       {
           debugln( "group r=" + r + " inconnu !");
           continue
       }
       def categorieName = categorie.groupement
       for( p in listPattern )
       {
           if( p == null || p.size() == 0 )
           {
               debugln( "pattern p=" + p + " null ou vide !")
               continue
           }
           
           debug3ln( "pattern p=" + p + " pour r=" + categorieName);
           versionView.categorizationCriteria.add( new GroupingRule(p, categorieName ) )
       }
    }
}

def populateRegroupementJobs( regroupementJobs, jobJSon, folder, versionMajeur)
{
    def groupe = jobJSon.regroupement
    def nom = jobJSon.jenkinsJobName
    //debugln( "populateRegroupementJobs " + jobJSon.versionMajeur + " " + nom + " "  + folder);
    if( "infra".equals(folder) )
    {
        if( jobJSon.versionMajeur != null )
            return;
    }
    else
        if( versionMajeur.equals( jobJSon.versionMajeur) == false )
            return;

    //nom = nom.replace("-" + jobJSon.architecture, "")
    if ( groupe == null || groupe.equals("" ))
      groupe = "?"
    def listeJob = regroupementJobs.get( groupe )
    if ( listeJob == null )
    {
        listeJob = new ArrayList()
        regroupementJobs.put( groupe, listeJob )
    }
    if ( listeJob.contains( nom ) == false )
       listeJob.add( nom )

}

def createView( folder, versionMajeur, viewName, filtre, regroupementJobs)
{
    out.println( "*** create View : " + viewName + " dans " + folder.name + " filtre=" + filtre );
    
    def commonsJobsView = folder.getView( "Tous" )
    if ( commonsJobsView == null )
    {
        commonsJobsView = folder.getView( "All" )
        if ( commonsJobsView == null )
        {
            return
        }
        else
        {
            commonsJobsView.name = "Tous"
        }
    }
    
    def ownerCommonsJobsView = commonsJobsView.getOwner()

    // suppression view Folder
    def versionView = folder.getView( viewName )
    if ( versionView != null )
    {
        debugln( "  Suppression de folder View : " + viewName );
        ownerCommonsJobsView.deleteView( versionView );
    }

    out.println( "  Enumere les job devant être dans la vue : " + viewName );
    def joblist = new ArrayList()
    folder.getAllJobs().each{ item ->
          debug3ln( "    * " + item.name + " " + folder.name)
          if( item.name.startsWith( "trigger" ) )
          {
              if( "production".equals( viewName ) )
              {
                   debugln( "    " + item.name + " -> " + viewName)
                   joblist.add( item )
              }
          }
          else
          {
              def jobJSon
              if ( folder.name.equals("infra") )
                   jobJSon = getScheduleJSon().find{ it -> it.jenkinsJobName.equals( item.name ) }
              else
                   jobJSon = getScheduleJSon().find{ it -> it.versionMajeur.equals( folder.name ) && it.jenkinsJobName.equals( item.name ) }
                                 
              if ( jobJSon != null )
              {
                  if( "obsoletes".equals( viewName ) == false )
                  {
                      if ( filtre == null || filtre.contains( jobJSon.status ) )
                      {
                            debugln( "    " + jobJSon.jenkinsJobName + " " + jobJSon.status + " -> " + viewName)
                            joblist.add( item )
                      }
                  }
              }
              else
              {
                  if( "obsoletes".equals( viewName ) )
                  {
                      debugln( "    " + item.name + " (obsolete ?) -> " + viewName )
                      joblist.add( item )
                      item.disabled = true
                      item.save()
                  }
              }
          }
       }
    out.println( "  " + joblist.size() + " job(s) trouvé(s)" );

    out.println( "  Creation de " + viewName );
    versionView = new org.jenkinsci.plugins.categorizedview.CategorizedJobsView( viewName );
    folder.addView( versionView ) ;
    joblist.each{ versionView.add ( it ) }
    
    out.println( "  create catégorie pour " + viewName );
    createViewCategorisation( versionMajeur, versionView, regroupementJobs)
    out.println( "  Ok");
    return versionView
}

def createViews( folderName, versionMajeur, majAuto )
{
    out.println( "***************** Create Views pour '" + folderName +"' *****************" )
    def folder = getItem( folderName )
    if ( folder == null )
    {
        out.println( "  folder inexistant '" + folderName +"'" )
        return null
    }
    
    debugln( "  getRegroupements " + folder);
    def regroupementJobs = new TreeMap<String,ArrayList>();
    getScheduleJSon().each{ jobJSon ->
            populateRegroupementJobs( regroupementJobs, jobJSon, folder.name, versionMajeur )
            }
    
    createView( folder, versionMajeur, "obsoletes", null , regroupementJobs)
    folder.primaryView = createView( folder, versionMajeur, "production", [ "PRODUCTION", "PUBLIQUE" ] , regroupementJobs)
    createView( folder, versionMajeur, "developpement", [ "DEVELOPPEMENT" ] , regroupementJobs)
}

def createViewVersionArchitecture()
{
    getVersionsJSon().each { eoleVersion -> createViews( eoleVersion.versionMajeurAsString, eoleVersion.versionMajeurAsString, eoleVersion.majAuto ) }
    createViews( "infra", "", "DEV")
    return 0
}


def createViewTestVersionArchitecture()
{
    out.println( "*** create View ParTests ");
    
    def folder = jenkins.model.Jenkins.get()
    def commonsJobsView = folder.getView( "EOLE" )
    debugln( "  Views : " + folder.getViews() );
    def ownerCommonsJobsView = commonsJobsView.getOwner()

    def viewName = "ParTests"
    def view = folder.getView(viewName);
    if( view != null )
    {
        debugln( "  Suppression de folder View : " + viewName );
        ownerCommonsJobsView.deleteView( view );
    }

    view = new org.jenkinsci.plugins.categorizedview.CategorizedJobsView( viewName );
    folder.addView( view ) ;
    
    out.println( "  Enumere les job: ")
    def listNomTest = new ArrayList()
    def jobList = new ArrayList()
    getScheduleJSon().each{ jobJSon ->
        def jobName = jobJSon.jenkinsJobName
        if ( estRenseigne( jobJSon.versionMajeur ) == false ) { return }
        
        def item = getItem( jobName )
        if ( item == null )
        {
            out.println( "  le job  " + jobName  + " manquant")
            return
        }
        if( item instanceof Folder )
        {
            out.println( "  le job  " + jobName  + " est un Folder ")
            return
        }
        
        jobList.add( item )
        //debugln( "    * " + jobJSon)
        def nomTest = jobJSon.nomTest
        if ( nomTest.equals("") )
        {
            nomTest = jobJSon.mainCmd + "-" + jobJSon.module 
        } 
        debugln( "    * " + nomTest)
        if ( ! listNomTest.contains(nomTest) )
        {
            listNomTest.add(nomTest)
            view.categorizationCriteria.add( new GroupingRule(".*" + nomTest + "-.*", nomTest ) )
        } 
    }
    out.println( "  " + listNomTest.size() + " NomTest(s) trouvé(s)" );
    out.println( "  " + jobList.size() + " job(s) trouvé(s)" );

    jobList.each{ it -> view.add( it ) }
    listNomTest.each{ nomTest -> 
            
    }
    return 0
}

def getDureeInterval( diff1 )
{
    def long diff = diff1
    if ( diff == 0 )
        return "0s"
        
    if ( diff > 0 )
    {
        diff = diff / 60000
        def long minutes = diff % 60
        diff = diff / 60
        def long heures = diff % 24
        def long jours = diff / 24
        def s = Util.getTimeSpanString( diff1 )
        //debug2( " delta/trigger=" + s )
        return s
    }
    else
        return getDureeInterval( - diff )
}

def getDureeSiSuperieur( timeATester, timereference)
{
    def long diff = (timereference - timeATester)
    if ( diff > 0 )
        return getDureeInterval( diff )
    else
        return null
}
    
    
def deleteFolder( dir )
{
    if ( dir == null )
        return
    dir.list().each{ f ->
        def file = new File( dir, f )
        if ( file.isDirectory() )
        {
            deleteFolder( file )
            hudson.Util.deleteRecursive( file )
            out.println file.getAbsolutePath() + " = " + file.deleteDir()
        }
        else
        {
            hudson.Util.deleteFile( file )
            out.println file.getAbsolutePath() + " = " + file.delete()
        }
    }
}
    
def deleteWorkspaceJob( job )
{
    out.print("  deleteWorkspaceJob : " + job )
    def long ilya3jours = new Date().getTime() - 86400000L * 3
    
    def String jobName = job?.name
    def AbstractBuild lastBuild = job?.lastBuild
    if ( lastBuild == null )
    {
        //out.println( "  pas lancé !")
        return
    }
    
    def newFile = new File( lastBuild.workspace.toString() )
    if ( newFile.exists() == false )
    {
        // déjà fait
        //out.println( "  ws = " + newFile.getAbsolutePath()  + " n existe pas !")
        return
    }
    
    def Result lastResult = lastBuild.result
    if ( lastResult == null )
    {
        out.println( "  ws = " + newFile.getAbsolutePath() + " pas de resultat !")
        return
    }
        
    def diff = getDureeSiSuperieur( build?.timestamp.time.time, ilya3jours)
    if ( diff != null )
    {
        out.println( "  ws = " + newFile.getAbsolutePath()  + " trop récent , attente 3 jours" )
        return
    }
    def result = newFile.deleteDir()
    deleteFolder( newFile )
    out.println( "  ws = " + newFile.getAbsolutePath()  + " " + result)
}
    
def enableDisableJob( jobName, state)
{
    out.print( "CheckJob " + jobName + " " + state + " " )

    if ( jobName.startsWith("template")  )
    {
        out.println( "  le job " + jobName  + " ne doit pas être désactivé !")
        return
    }

    def job = getItem( jobName )
    if ( job == null )
    {
        out.println( "  le job  " + jobName  + " manquant")
        return
    }
    if( job instanceof Folder )
    {
        out.println( "  le job  " + jobName  + " est un Folder ")
        return
    }
    if( job instanceof FreeStyleProject == false)
    {
        out.println( "  le job  " + jobName  + " n'est pas FreeStyleProject, no Folder !")
        return
    }

    if ( job.description.startsWith("Généré depuis") == false )
    {
        out.println( "  Le job " + jobName  + " n'est pas un job auto généré par EOLE")
        // pas "Généré" ! ignore
        return
    }

    def FreeStyleProject project = (FreeStyleProject) job
    if ( state == false )
    {
        if (  jobName.startsWith("trigger" ) )
        {
            out.println( "  les triggers doivent rester enable " + jobName )
            return 0
        }
        
        if ( project.disabled )
        {
            out.println( "  le project  " + jobName  + " est déjà désactivé")
        }
        out.println("  Disable : " + jobName )
        //doUpdate = true
        project.disable()
        project.save()
        deleteWorkspaceJob( project )
    }
    else
    {
        if ( project.disabled == false )
        {
            if (  jobName.startsWith("trigger" ) )
            {
                out.println( "  les triggers doivent etre enable " + jobName )
                project.enable()
                project.save()
                return 0
            }
            
            //out.println( "  le project  " + jobName  + " est déjà activé")
            out.println( "")
            return
        }
        out.print("  Enable : " + jobName )
        //doUpdate = true
        project.enable()
        project.save()
    }
    out.println("")
    return 0
}


def deleteUnusedWorkspace(FilePath root, String path)
{
    root.list().sort { child -> child.name }.each{ child ->
    String fullName = path + child.name

    def item = Jenkins.instance.getItemByFullName(fullName);
    if( item instanceof Folder)
    {
      deleteUnusedWorkspace(root.child(child.name), "$fullName/")
    }
    else if (item == null)
    {
      out.println "Deleting (no such job): '$fullName'"
      //child.deleteRecursive()
    }
    else if (item instanceof Job && !item.isBuildable()) {
      out.println "Deleting (job disabled): '$fullName'"
      //child.deleteRecursive()
    }
    else
    {
      out.println "Leaving: '$fullName'"
    }
  }
}

def wipeOldWorkspaceFolder( folderName )
{
    Jenkins.instance.get().getNodes().each { node ->
      out.println "Processing $node.displayName"
      def workspaceRoot = node.rootPath.child("workspace");
      deleteUnusedWorkspace(workspaceRoot, "")
    }
}

// call from Jenkins http://jenkins.eole.lan/jenkins/job/Internes/job/run-disable-old-jobs
def disableOldJobs()
{
    def jobOk = []
    def allJobs = []

    getScheduleJSon().each{job -> jobOk.add( job.jenkinsJobName ) }
    jobOk.each { jobName -> enableDisableJob( jobName, true ) }
    this.allItems.findAll{ job -> allJobs.add( job.name ) }
    allJobs.removeAll( jobOk )
    allJobs.each { jobName -> enableDisableJob( jobName, false ) }

    //getVersionsJSon().each { eoleVersion -> wipeOldWorkspaceFolder( eoleVersion.versionMajeurAsString ) }
    //wipeOldWorkspaceFolder( "infra")
    return 0
}

def checkFolderVersion( eoleVersion )
{
    def versionMajeur = eoleVersion.versionMajeurAsString
    
    def folder = getItem( versionMajeur )
    if ( folder == null )
    {
        out.println( versionMajeur + " n'existe pas")
        folder = jenkins.model.Jenkins.get().createProjet( com.cloudbees.hudson.plugins.folder.Folder.class, versionMajeur )
        out.println( "dossier " + versionMajeur + " crée : " +  folder )
    }
    else
        out.println( "dossier " + versionMajeur + " existe")
}

def getLastDiffTrigger( versionAActualiser, sourceName )
{
    def lastDiffFileName = versionAActualiser
    if ( sourceName.equals("") == false && sourceName.equals("eole") == false )
    {
        lastDiffFileName = versionAActualiser + "-" + sourceName 
    }

    def fichierTrigger = "/mnt/eole-ci-tests/depots/" + lastDiffFileName + ".lastDiff";
    if ( checkMntEoleCiTests() == false )
    {
        return null
    }
    
    def File lastDiffFile = new File( fichierTrigger )
    def long lastDiffTrigger
    if ( lastDiffFile.exists() )
    {
        lastDiffTrigger = lastDiffFile.lastModified()
        out.println( "fichierTrigger = " + fichierTrigger + " " + formatDateLong(lastDiffTrigger))
    }
    else
    {
        out.println( "fichierTrigger = " + fichierTrigger + " inexistant")
        lastDiffTrigger = 0
    }
    return lastDiffTrigger
}

def checkDailyFromTrigger( item, eoleVersion, sourceName)
{
    def boolean aLancer = false
    
    out.println(" ")
    out.print( item.name )
    out.println(" : ")
    if ( item.name.endsWith("-i386") )
    {
        out.println( "  i386 ignore" )
        return false
    }

    def jobJSon = getScheduleJSon().find{ it -> it.jenkinsJobName.equals( item.name ) }
    if ( jobJSon == null )
    {
        out.println( "  " + item.name + " n'existe pas dans schedule.json ! " )
        return
    }
    def m = jobJSon.module
    if (sourceName == null || sourceName.equals("") || sourceName.equals("eole"))
    {
        out.println( "  source eole")
    }
    else
    {
        def modulesVersion = eoleVersion.sources.findResult { source -> source.name.equals(sourceName) ? source.modulesVersion : null }
        if ( modulesVersion?.findResult { moduleVersion -> moduleVersion.module.equals(m) ? true : false } == false )
        {
            out.println( "  pas la bonne source, stop ")
            return false
        }
    }

    def long lastDiffTrigger = getLastDiffTrigger( eoleVersion.versionMajeurAsString, source)
    out.println( "  trigger   = " + formatDateLong( lastDiffTrigger ) )

    def AbstractBuild lastBuild = item?.lastBuild
    if ( lastBuild == null )
    {
        out.println( "  jamais lancé ==> A LANCER ")
        return true
    }

    def diff = getDureeSiSuperieur( lastBuild.timestamp.time.time, lastDiffTrigger)
    if ( diff == null )
    {
        out.println("  ==> OK, pas besoin ")
        return false
    }
    out.println( "  delta/trigger = " + diff)
            
    
    out.println( "  " + HyperlinkNote.encodeTo('/' + lastBuild?.url, lastBuild?.fullDisplayName) )
    out.println( "  lastBuild = " + formatDate( lastBuild.time ) )
     
    def Result lastResult = lastBuild?.result
    if ( lastResult == null )
    {
        //out.println " jamais lancé jusqu'au bout ==> A LANCER "
        out.println( "  En cours ?" )
        return false
    }

    def String lastBuildResult = lastResult?.toString()
    if ( lastBuildResult == "FAILURE" )
    {
        out.println( "  dernier=FAILURE ==> A LANCER" )
        return true
    }

            
    if ( eoleVersion.majAuto.equals("DEV" ) )
    {
        def long buildPlus12h = lastBuild.timestamp.time.time + 12*3600*1000L
        diff = getDureeSiSuperieur( buildPlus12h, lastDiffTrigger)
        if ( diff == null )
        {
            out.println("  moins de 12h ==> OK, pas besoin")
            return false
        }
        out.println( "  " + diff + " delta trigger supérieur à 12h ==> A LANCER" )
    }
    else
    {
    def long buildPlus1jour = lastBuild.timestamp.time.time + 86400000L
    diff = getDureeSiSuperieur( buildPlus1jour, lastDiffTrigger)
    if ( diff == null )
    {
            out.println("  moins de 1j ==> OK, pas besoin")
        return false
    }
        out.println( "  " + diff + " delta trigger supérieur à 1j ==> A LANCER" )
    }
    
    return true
}

def checkIfNeedToRunDailyFromTrigger()
{
    getVersionsJSon().each { eoleVersion ->
            getScheduleJSon().each{ job ->
                  if ( job.mainCmd.equals("CreateDailyFreshInstall") && job.versionMajeur.equals( eoleVersion.versionMajeurAsString ) )
                  {
                     def item = getItem( job.jenkinsJobName )
                     eoleVersion.sources.each { source ->
                         if ( checkDailyFromTrigger( item, eoleVersion, source) )
                         {
                            createTodo( item )
                         }
                     }
                  }
            }
    }
    return 0
}

def checkNeedToRun()
{
    def jobsAExecuter = createJobsAExecuter()
    getScheduleJSon().each{ job ->
        
        if ( estRenseigne( job.versionMajeur ) == false ) { return }
        if ( "manuel".equals(job.frequence ) ) { return }
        
        def item = getItem( job.jenkinsJobName )
        if ( item == null ) { return }
        if ( item.name.endsWith("-i386") ) { return }
        if ( item.disabled ) { return }
        
        def msg = item.name + " ("+ job.frequence +", "+ job.doitEtreLance +"): "
        
        def long lastDiffJob
        def AbstractBuild lastBuildJob = item?.lastBuild
        def dernierExec = ""
        def aExecuter = false

        if ( lastBuildJob != null )
        {
            lastDiffJob = lastBuildJob.timestamp.time.time
            dernierExec = lastBuildJob.timestamp.time.format('YYYY/MM/dd-hh:mm') + " (" + Util.getTimeSpanString( System.currentTimeMillis() - lastBuildJob.timestamp.time.time ) + ")"
            msg = msg + " " + dernierExec
            job.depends.each{ depen ->
                def dep = depen.depend
                def depJob = getItem( dep )
                def AbstractBuild lastBuildDep = depJob?.lastBuild
                if ( lastBuildDep != null )
                {
                    def Result lastResultDep = lastBuildDep?.result
                    def String lastBuildDepResult = lastResultDep?.toString()
                    if ( lastBuildDepResult != "FAILURE" )
                    {
                        msg = msg + "\n   depend "+ dep + " : " + lastBuildDep.timestamp.time.format('YYYY/MM/dd-hh:mm') + " "
                        def long diffLong = (lastBuildDep.timestamp.time.time - lastDiffJob)
                        if ( diffLong > 3600*24 )
                        {
                            aExecuter = true
                            msg = msg + " postérieur de " + Util.getTimeSpanString( diffLong ) + " -> go..."
                        }
                        else
                        {
                            msg = msg + " antérieur (stop) -> nok doit etre executer avant"
                            aExecuter = false
                            return // exit closure
                        }
                    }
                    else
                        if ( lastBuildDepResult == "FAILURE" )
                        {
                            msg = msg + "\n   depend "+ dep + " : FAILURE ==> nok "
                            aExecuter = false
                            return // exit closure
                        }
                }
            }
        }
        else
        {
            lastDiffJob = 0
            msg = msg + " "
            aExecuter = true
            job.depends.each{ depen ->
                def dep = depen.depend
                def depJob = getItem( dep )
                def AbstractBuild lastBuildDep = depJob?.lastBuild
                if ( lastBuildDep != null )
                {
                    def Result lastResultDep = lastBuildDep?.result
                    def String lastBuildDepResult = lastResultDep?.toString()
                    if ( lastBuildDepResult == "FAILURE" )
                    {
                        msg = msg + "\n   depend "+ dep + " : FAILURE ==> nok"
                        aExecuter = false
                        return // exit closure
                    }
                }
            }
        }
            
        if ( aExecuter )
        {
            if ( this.try_pattern == false )
            {
                out.println( msg + "\n   ==> " + aExecuter )
                createTodo( item )
            }
            else
            {
                out.println( msg + "\nTRY   ==> " + aExecuter )
            }
        }
    }
    out.println "----------------------"
    jobsAExecuter.each { out.println it.jenkinsJobName }
    out.println "----------------------"
    out.println "Nb a lancer = " + jobsAExecuter.size()
    return 0
}

def traiteBuild( job, jobJSon)
{
    if( job instanceof Folder)
        return
    if( jobJSon == null )
        return
    def buildDiscarder = job.buildDiscarder
    if( buildDiscarder == null)
        return

    out.println("=====================")
    out.println("JOB: " + job.name)
    out.println("   type: " + job.getClass())
    out.println("   BuildDiscarder: " + buildDiscarder.getClass())
    out.println("   days to keep=" + buildDiscarder.daysToKeepStr )
    out.println("   num to keep=" + buildDiscarder.numToKeepStr )
    out.println("   artifact day to keep=" + buildDiscarder.artifactDaysToKeepStr )
    out.println("   artifact num to keep=" + buildDiscarder.artifactNumToKeepStr)
    out.println("   builds: " + job.builds.size())
      
    job.builds.each { bld ->
        out.println( "     " + HyperlinkNote.encodeTo('/' + bld.url, bld.fullDisplayName) + " " + bld.result + " " + bld.duration + " " + bld.timestampString )
    }
}
    

def analyseLog( buildJob, pattern ) 
{
	reader = null;
	try
	{
	  reader = new BufferedReader(buildJob.getLogReader())
	  while ((line = reader.readLine()) != null) 
	  {
	    Matcher matcher = pattern.matcher(line)
	    if (matcher.find()) 
	    {
    	   return true
	    }
	  }
	}
	finally
	{
	  if (reader != null) 
	  {
	    reader.close();
	  }
	}
	return false 
}

def effaceBuild() {

    int count = 0
    out.println( "nbJours : " + this.nbJours)

    long afterDate = System.currentTimeMillis() - (this.nbJours * 24l * 60l * 60l * 1000l)
    out.println( "=========================================================" )
    out.println( "Build depuis le " + new Date( afterDate ).format("dd/MM/yyyy HH:mm") )
    out.println( "=========================================================" )
    def allJobs = this.allItems.findAll{ job -> (job instanceof hudson.model.AbstractProject && job.disabled == false && job.fullName.indexOf("Internes") < 0 ) }
    
    if( this.patternLogs == "" )
    {
        out.println( "effaceBuild : protection pattern vide, stop !" )
        return
    }

    // Define the regex to extract the value you want
    pattern = Pattern.compile(this.patternLogs)

    allJobs.each { job -> job.getBuilds().byTimestamp(afterDate, System.currentTimeMillis()).each
                                    { buildJob ->
                                        if ( analyseLog( buildJob, pattern ) )
                                        {
                                            out.println( HyperlinkNote.encodeTo('/' + buildJob.url, buildJob.fullDisplayName) + " " + buildJob.result + " " + buildJob.duration + "s " + buildJob.timestampString )
                                            if ( this.try_pattern == false )
                                            {
                                            	buildJob.delete()
                                            }
                                            else
                                            {
                                                out.println( "delete désactivé car try_pattern !" )
                                            }
                                        }
                                    }
                                }
                                
}


def displayClass( o )
{
    out.println ""
    out.println o.getClass().getSimpleName()
    out.println ""
    out.println " methods"
    for( i in o.getClass().getMethods() )
    {
        out.println i.toString().replace( "hudson.PluginWrapper.", "" ).replace( "java.lang.", "" ).replace( "java.util.",""). replace( " ","\t" )
    }
     
    out.println ""
    out.println " fields"
    for( i in o.getClass().getFields() )
    {
        out.println i.toString().replace( "hudson.PluginWrapper.", "" ).replace( "java.lang.", "" ).replace( "java.util.",""). replace( " ","\t" )
    }
}

def getFilePath(path) {
    if (this.build.workspace.isRemote()) 
    {
        return new FilePath(this.build.workspace.channel, path);
        //   FilePath projectWorkspaceOnAgent = new FilePath(this.launcher.getChannel(), workspacePath);
        // projectWorkspaceOnAgent.mkdirs();
        //return projectWorkspaceOnAgent.absolutize();
    }
    else
    {
        return new FilePath(path);
    }
}

def listFiles(rootPath) 
{
    out.println( "Files in ${rootPath}:" )
    for (subPath in rootPath.list()) 
    {
        out.println( "  ${subPath.getName()}")
    }
}

FilePath getControlerLogDirectory(AbstractBuild build1) throws IOException, InterruptedException 
{
  String buildDir = build1.getRootDir().getAbsolutePath();
  FilePath controlerLogDirectory = new FilePath(new File(buildDir + File.separator + "junitResult.xml"));
  return controlerLogDirectory;
}

FilePath getAgentWorkspace(AbstractBuild build1, Launcher launcher1, BuildListener listener1) throws IOException, InterruptedException 
{
   String workspacePath = build1.getEnvironment(listener1).get("WORKSPACE");
   if (workspacePath == null) 
   {
      throw new IOException(Messages.TcTestBuilder_InternalError());
   }

   FilePath projectWorkspaceOnAgent = new FilePath(launcher1.getChannel(), workspacePath);
   projectWorkspaceOnAgent.mkdirs();
   return projectWorkspaceOnAgent.absolutize();
}

def runCmd( cmd1 )
{
    def value = -1
    def process = cmd1.execute()
    // cf. : https://github.com/groovy/groovy-core/blob/master/src/main/org/codehaus/groovy/runtime/ProcessGroovyMethods.java
    def tout = process.consumeProcessOutputStream( out )
    def terr = process.consumeProcessErrorStream( out )
    try 
    { 
        tout.join()
        terr.join()
        while( process.isAlive() )
        {
                process.waitFor( 1, java.util.concurrent.TimeUnit.SECONDS)
        }
        value = process.exitValue()
    }
    catch (InterruptedException ie)
    {
        out.println ("InterruptedException ! arret process...")
        process.closeStreams()
        process.destroy()
    }
    debug2ln( "Exit value: $value" )
    return value
}

def runEoleCiSh( environements, arguments )
{
    def env = ""

    out.println( "runEoleCiSh on controler !" )
    this.environment.each {
        // process MAIL
        if( "HOME LANG LOGNAME SHELL PWD SHLVL USER ".indexOf( it.getKey() + " ") >= 0 )
        {
            env += " " + it.getKey() + "=" + it.getValue()
        }
        // jenkins 
        else if( "BUILD_CAUSE BUILD_ID BUILD_URL BUILD_USER HUDSON_HOME JOB_NAME JOB_URL NODE_NAME ROOT_BUILD_CAUSE WORKSPACE ".indexOf( it.getKey() + " ") >= 0 )
        {
            env += " " + it.getKey() + "=" + it.getValue()
        }
        // eoleci
        // ignore STAGE_TEST=(test)
        if( "ARCHITECTURE DANS_MON_CONTEXTE ID_TEST IMAGE_NAME JNLPMAC MAIN_CMD MODULE NOM_JENKINS ONE REPERTOIRE_EOLE_CI_TESTS  VERSION ".indexOf( it.getKey() + " ") >= 0 )
        {
            env += " " + it.getKey() + "=" + it.getValue() 
        }
    }

    if ( this.debugLevel > 1 )
        arguments += " -d"+ this.debugLevel
    if ( this.forceRebuild )
        arguments += " -f"
    // execution sur Jenkins.eole.lan !! 
    home = "/var/lib/jenkins"
    
    if ( estRenseigne( this.user ) == false )
    {
        if ( environements.indexOf("ONE_AUTH=") < 0 )
        {
            env += " ONE_AUTH="+ home + "/.one/one_auth"
        }
    }
    else
    {
        arguments += " -u " + this.user
        env += " ONE_AUTH="+ home + "/.one/one_auth." + this.user
    }

    def customWorkspace = this.build.getParent().getCustomWorkspace()
    println("customWorkspace = " + customWorkspace)
    if (customWorkspace != null) 
    {
        workspacePath = this.build.builtOn.getRootPath().child(customWorkspace)
        println("workspacePath 1 = " + workspacePath)
    }
    else
    {
        workspacePath = this.build.workspace.toString();
        println("workspacePath 2 = " + workspacePath)
    }
    if (workspacePath == null) 
    {
        println(".... could not get workspace path")
        return
    }
    println(".... workspace = " + workspacePath)
    FilePath projectWorkspaceOnAgent = new FilePath(this.launcher.getChannel(), workspacePath);
    projectWorkspaceOnAgent.mkdirs();
    def workspaceOnAgent = projectWorkspaceOnAgent.absolutize();
    out.println(workspaceOnAgent)
    
    def cmd1 = "/usr/bin/env " + env + " /bin/bash -x /mnt/eole-ci-tests/jenkins/EoleNebula/runEoleCi.sh " + arguments
    debug2ln( "cmd1 : ${cmd1}" )

    def value = -1
    value = runCmd( cmd1 )
    return value
}

def runEoleCiOnControler( environements, arguments )
{
    def env = ""

    out.println( "runEoleCiOnControler on controler !" )
    home = "/var/lib/jenkins"
    this.environment.each {
        // process MAIL
        if( "HOME ".indexOf( it.getKey() + " ") >= 0 )
        {
            env += " HOME=" + home
        }
        if( "LANG LOGNAME SHELL PWD SHLVL USER ".indexOf( it.getKey() + " ") >= 0 )
        {
            env += " " + it.getKey() + "=" + it.getValue()
        }
        // jenkins 
        else if( "BUILD_CAUSE BUILD_ID BUILD_URL BUILD_USER HUDSON_HOME JOB_NAME JOB_URL NODE_NAME ROOT_BUILD_CAUSE WORKSPACE ".indexOf( it.getKey() + " ") >= 0 )
        {
            env += " " + it.getKey() + "=" + it.getValue()
        }
        // eoleci
        // ignore STAGE_TEST=(test)
        if( "ARCHITECTURE DANS_MON_CONTEXTE ID_TEST IMAGE_NAME JNLPMAC MAIN_CMD MODULE NOM_JENKINS ONE REPERTOIRE_EOLE_CI_TESTS  VERSION ".indexOf( it.getKey() + " ") >= 0 )
        {
            env += " " + it.getKey() + "=" + it.getValue() 
        }
    }

    if ( this.debugLevel > 1 )
        arguments += " -d"+ this.debugLevel
    if ( this.forceRebuild )
        arguments += " -f"
            
    if ( this.user == null )
    {
        // default arguments += " -u jenkins"
        if ( environements.indexOf("ONE_AUTH=") < 0 )
        {
            env += " ONE_AUTH=" + home + "/.one/one_auth"
        }
    }
    else
    {
        arguments += " -u " + this.user
        env += " ONE_AUTH=" + home + "/.one/one_auth." + this.user
    }
    env += " " + environements

    debug2ln( "env : ${env}" )
    
    def FilePath destination
    FilePath pathEoleNebula = new FilePath( new File("/mnt/eole-ci-tests/jenkins/EoleNebula/") )
    //listFiles(pathEoleNebula)
    //FilePath source = new FilePath( new File("/var/lib/jenkins/userContent/EoleNebula/") )
    //destination = new FilePath( new File( this.build.workspace.toString(), ""+ this.build.number ) )
    //source.copyRecursiveTo( destination  );
    //def pathEoleNebula = "" + destination
    debugln( "pathEoleNebula : ${pathEoleNebula}" )

    value = runCmd( "hostname")
    debugln( "hostname : ${value}" )

    cmd = "/usr/lib/jvm/java-21-openjdk-amd64/bin/java"
    cmd += " -XX:+UseG1GC -XX:+UseStringDeduplication --add-modules=ALL-SYSTEM -Dfile.encoding=UTF-8 -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true "
    cmd += " -Djava.util.logging.config.file=" + pathEoleNebula + "/logging.properties"
    cmd += " -Duser.home=" + pathEoleNebula
    cmd += " -Duser.dir=" + pathEoleNebula
    cmd += " -classpath " + pathEoleNebula + "/lib/*"
    cmd += " org.eole.Main -e /mnt/eole-ci-tests " + arguments

    value = runCmd( "/usr/bin/env -i " + env  + " " + cmd )
    return value
}


def runEoleCi( environements, arguments )
{
//   // system    
//   HOME=/var/lib/jenkins
//   LANG=fr_FR.UTF-8
//   LIBVIRT_DEFAULT_URI=qemu:///system
//   LOGNAME=jenkins
//   MAIL=/var/mail/jenkins
//   SHELL=/bin/bash
//   PWD=/var/lib/jenkins
//   SHLVL=1
//   USER=jenkins
//   XDG_RUNTIME_DIR=/run/user/106 
//   XDG_SESSION_ID=c3
//       
//   // jenkins
//   BUILD_CAUSE
//   BUILD_CAUSE_MANUALTRIGGER
//   BUILD_DISPLAY_NAME
//   BUILD_ID
//   BUILD_NUMBER
//   BUILD_TAG
//   BUILD_URL
//   BUILD_USER
//   BUILD_USER_EMAIL
//   BUILD_USER_FIRST_NAME
//   BUILD_USER_ID
//   CLASSPATH
//   EXECUTOR_NUMBER
//   HUDSON_HOME
//   HUDSON_SERVER_COOKIE
//   HUDSON_URL
//   JAVA_HOME
//   JENKINS_HOME
//   JENKINS_SERVER_COOKIE
//   JENKINS_URL
//   JOB_BASE_NAME
//   JOB_DISPLAY_URL
//   JOB_NAME
//   JOB_URL
//   NODE_LABELS
//   NODE_NAME
//   PATH
//   PATH+JDK
//   ROOT_BUILD_CAUSE
//   ROOT_BUILD_CAUSE_MANUALTRIGGER
//   RUN_CHANGES_DISPLAY_URL
//   RUN_DISPLAY_URL
//   WORKSPACE
//   
//   // eoleci
//   PATTERN= 
//   FORCE_REBUILD
//   DANS_MON_CONTEXTE
//   DEBUG
//   TRY_PATTERN
//   SEULEMENT_CEUX_EN_ERREUR
//   NEBULA_PASSWORD=

// utilisé par l'automate
//   ONE_AUTH
//   ONE_XMLRPC
//   BUILD_USER -U // forUser
//   DANS_MON_CONTEXTE -p 
//   NOM_TEST -t 
//   STAGE_TEST -s
//   ID_TEST -i
//   MODULE -m
//   MAIN_CMD -c 
//   IMAGE_NAME -I
//   VERSION -v
//   ARCHITECTURE -a
//   ONE -o 
//   REPERTOIRE_EOLE_CI_TESTS -e
//   NOM_JENKINS  -yj

    if ( this.debugLevel > 1 )
        arguments += " -d"+ this.debugLevel
    if ( this.forceRebuild )
        arguments += " -f"
    if(this.build.workspace.isRemote())
    {
        home = "/home/jenkins"
    }
    else
    {
        home = "/var/lib/jenkins"
    }
    
    if ( estRenseigne( this.user ) == false )
    {
        if ( environements.indexOf("ONE_AUTH=") < 0 )
        {
            environements += " ONE_AUTH="+ home + "/.one/one_auth"
        }
    }
    else
    {
        arguments += " -u " + this.user
        environements += " ONE_AUTH="+ home + "/.one/one_auth." + this.user
    }

    def customWorkspace = this.build.getParent().getCustomWorkspace()
    if (customWorkspace != null) 
    {
        workspacePath = this.build.builtOn.getRootPath().child(customWorkspace)
    }
    else
    {
        workspacePath = this.build.workspace.toString();
    }
    if (workspacePath == null) 
    {
        println(".... could not get workspace path")
        return
    }
    println(".... workspace = " + workspacePath)
    FilePath projectWorkspaceOnAgent = new FilePath(this.launcher.getChannel(), workspacePath);
    projectWorkspaceOnAgent.mkdirs();
    def workspaceOnAgent = projectWorkspaceOnAgent.absolutize();
    out.println(workspaceOnAgent)
    
    def FilePath source = new FilePath( new File("/var/lib/jenkins/userContent/EoleNebula/") )
    def FilePath destination = new FilePath(workspaceOnAgent, "" + this.build.number )
    source.copyRecursiveTo( destination  );
    def pathEoleNebula = "" + destination
    debugln( "pathEoleNebula : ${pathEoleNebula}" )

    def v = pathEoleNebula
    def s = """
def ProcessBuilder pb = new ProcessBuilder()
pb.command('/usr/lib/jvm/java-21-openjdk-amd64/bin/java')
pb.directory( new File('${v}') );
def cmd = pb.command()
def env = pb.environment()
cmd.add('-Xms128m')
cmd.add('-Xmx1024m')
cmd.add('-XX:+UseG1GC')
cmd.add('-XX:+UseStringDeduplication')
cmd.add('--add-modules=ALL-SYSTEM')
cmd.add('-Dfile.encoding=UTF-8')
cmd.add('-Djava.awt.headless=true')
cmd.add('-Djava.net.preferIPv4Stack=true')
cmd.add('-Djava.util.logging.config.file=${v}/logging.properties')
cmd.add('-Duser.home=${v}')
cmd.add('-Duser.dir=${v}')
cmd.add('-classpath')
cmd.add('${v}/lib/*')
cmd.add('org.eole.Main')
cmd.add('-e')
cmd.add('/mnt/eole-ci-tests')
"""  
    out.println("arguments: " + arguments)
    arguments.split("\\s+").each{ argument -> 
               if ( argument.length() > 0 )
               {
                   s+="\ncmd.add('" + argument + "')" 
               } 
              }

    this.environment.each {
        // process MAIL
        //if( "HOME LANG LOGNAME SHELL SHLVL USER ".indexOf( it.getKey() + " ") >= 0 )
        //{
        //    env += " " + it.getKey() + "=" + it.getValue()
        //    envCmd.add(it)
        //}
        // jenkins 
        if( "BUILD_CAUSE BUILD_ID BUILD_URL BUILD_USER HUDSON_HOME JOB_NAME JOB_URL NODE_NAME ROOT_BUILD_CAUSE WORKSPACE ".indexOf( it.getKey() + " ") >= 0 )
        {
            s += "\nenv.put('" + it.getKey() + "','" + it.getValue() + "')"
        }
        // eoleci
        // ignore STAGE_TEST=(test)
        if( "ARCHITECTURE DANS_MON_CONTEXTE ID_TEST IMAGE_NAME JNLPMAC MAIN_CMD MODULE NOM_JENKINS ONE REPERTOIRE_EOLE_CI_TESTS  VERSION ".indexOf( it.getKey() + " ") >= 0 )
        {
            s += "\nenv.put('" + it.getKey() + "','" + it.getValue() + "')"
        }
    }

    environements.split("\\s+").each{ envstring -> 
                int eqlsign = envstring.indexOf('=', ProcessEnvironment.MIN_NAME_LENGTH);
                if (eqlsign != -1)
                {
                    k = envstring.substring(0,eqlsign)
                    v = envstring.substring(eqlsign+1)
                    s += "\nenv.put('" + k + "','" + v + "')"
                }
    }

    s += """
out.println(env)

def Process process = pb.start();
try
{ 
  def tout = process.consumeProcessOutputStream( out )
  def terr = process.consumeProcessErrorStream( out )
  tout.join()
  terr.join()
  while( process.isAlive() )
  {
    out.println('Zzz...')
    process.waitFor( 1, java.util.concurrent.TimeUnit.SECONDS)
  }
  value = process.exitValue()
  out.println( 'Exit value: ' + value )
}
catch (InterruptedException ie)
{
  out.println ('InterruptedException ! arret process...')
  ie.printStackTrace(out)
}
finally
{
  process.closeStreams()
  process.destroy()
}
"""
    s = s.replace("'","\"" )
    debugln( s)
    
    try {
       out.println( RemotingDiagnostics.executeGroovy(s, this.launcher.getChannel()) )
    } catch (all) {
       all.printStackTrace();
       return 1
    }
   
    if ( destination.exists() )
    {
        //if( value == 0)
        //{
        //    debug2ln( "deleteRecursive " + destination)
        //    destination.deleteRecursive()              
        //}
    }
    return value
}

def getCredential(username)
{ 
    def cred = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials.class,
        jenkins.model.Jenkins.instance,
        null,
        null
    ).findResult { it.id == username ? it : null }
    if ( cred )
    {
        if ( cred.password )
        {
            debugln ("use credential username ${username}")
            return cred
        } 
    }
    debugln( "could not find credential for ${username}" )
    return null
}

def copyCredentialOnAgent( agent, user )
{
        def computer = agent.computer
        def channel = computer.getChannel()
        def cred = getCredential( "one-" + user )
        //displayClass agent

        ws = "" + this.build.workspace
        out.println "build ws " + ws

        def props = computer.getSystemProperties()
        out.println props

        if ( computer.isUnix() )
        {
            homeJenkins  = new FilePath( channel, "/home/jenkins");
        }
        else
        {
            FilePath fp = agent.createPath(agent.getRootPath().toString() + File.separator + "workspace"); 
            out.println "fp " + fp
            
            homeJenkins  = new FilePath( channel, "/Users/pcadmin");
        }
        out.println "homeJenkins " + homeJenkins
        
        homeJenkins  = homeJenkins.absolutize()
        out.println "homeJenkins " + homeJenkins

        FilePath homeJenkinsOne  = new FilePath(homeJenkins, ".one");
        out.println "homeJenkinsOne " + homeJenkinsOne
        if ( ! homeJenkinsOne.exists() )
        {
            homeJenkinsOne.mkdirs()
        }
        def FilePath homeJenkinsOneAuth = new FilePath(homeJenkinsOne, "one_auth"  )
        homeJenkinsOneAuth.write( cred.username +":" + cred.password , null); //writing to file
        listFiles( homeJenkinsOne )
                
        
        FilePath projectWorkspaceOnAgent = new FilePath(channel,ws);
        projectWorkspaceOnAgent.mkdirs();
        out.println "projectWorkspaceOnAgent ${projectWorkspaceOnAgent} "
        
        def workspaceOnAgent = projectWorkspaceOnAgent.absolutize();
        debugln(workspaceOnAgent)
}

def copyCredentialOnAgent()
{
    out.println "copyCredentialOnAgent ${user} "
    
    Jenkins.instance.get().getNodes().each { agent ->
        def computer = agent.computer
        def agentName = agent.name
        def name = computer.name
        if ( agentName.startsWith( "win" ) ) 
        {
            //displayClass agent
            //displayClass computer
            out.println "copyCredentialOnAgent: ${name} ${agentName}"
            out.println "  isUnix: " + computer.isUnix() 
            out.println "  agent.getNodeDescription: " + agent.getNodeDescription()
            out.println "  agent.getNodeProperties: " + agent.getNodeProperties()
            out.println "  agent.getRootPath: " + agent.getRootPath()
            out.println "  agent.getNumExecutors: " + agent.getNumExecutors()
            out.println "  agent.getLabelString: " + agent.getLabelString()
            out.println "  agent.getUserId: " + agent.getUserId()
            out.println "  agent.getRemoteFS: " + agent.getRemoteFS()
            out.println "  agent.getWorkspaceRoot: " + agent.getWorkspaceRoot()
            out.println "  agent.getSearchUrl: " + agent.getSearchUrl()
            out.println "  agent.getFileSystemProvisioner: " + agent.getFileSystemProvisioner()
            copyCredentialOnAgent( agent, user )
        }
        if ( agentName.endsWith( user ) ) 
        {
            out.println "  ${name} est pour ${user}"
            //out.println "  ${name}.isOffline: " + computer.isOffline() 
            //out.println "  ${name}.isTemporarilyOffline: " + computer.isTemporarilyOffline()
            //out.println "  ${name}.countBusy: " + computer.countBusy()
            
            //copyCredentialOnAgent( agent, user )
            // destination = new FilePath(projectWorkspaceOnAgent, "test.sh"  )
            // destination.write( "#!/bin/bash\necho 'OK' ", null); 
            // listFiles( workspaceOnAgent )
            // def envVars = this.build.getEnvironment(this.listener)
            // def workspace = envVars.get("WORKSPACE")
            // def command = "/bin/bash ${workspace}/test.sh"
            // def channel = this.build.workspace.channel
            // def fp = this.build.workspace.toString()
            // def workspacePath = new hudson.FilePath(channel, fp)
            // listFiles( workspacePath )
            
            // def launcher1 = workspacePath.createLauncher(hudson.model.TaskListener.NULL);
            // def starter = launcher1.launch().pwd(workspacePath).stdout(out).stderr(out).cmdAsSingleString(command)
            // starter.join()
        }
    }    
}

def restartAgent( agent )
{
      def computer = agent.computer
      def name = computer.name
      out.println( "${name}.getLabelString: " + agent.getLabelString())
      out.println( "${name}.getNumExectutors: " + agent.getNumExecutors());
      out.println( "${name}.getRemoteFS: " + agent.getRemoteFS());
      out.println( "${name}.getMode: " + agent.getMode());
      out.println( "${name}.getRootPath: " + agent.getRootPath());
      out.println( "${name}.getDescriptor: " + agent.getDescriptor());
      out.println( "${name}.isOffline: " + computer.isOffline() )
      out.println( "${name}.isTemporarilyOffline: " + computer.isTemporarilyOffline())
      out.println( "${name}.countBusy: " + computer.countBusy())
      if ( computer.countBusy() > 0 ) 
      {
          if( this.forceRebuild == false ) // moyen d'ignorer le controle ....
          {
            out.println('build en cours: stop !')    
            return 1
          }
      }
     
      out.println "arret agent ${name}"
      if ( computer.isOnline()) 
      {
          computer.setTemporarilyOffline(true, new hudson.slaves.OfflineCause.ByCLI("arret agent"))
    
          pause( 10, "sleeping 10 seconds" )
          debugln('setTemporarilyOffline ==> isOnline ? : ' + computer.isOnline());    
      }
    
      def exitCode = runEoleCiOnControler(  "JNLPMAC=" + computer.jnlpMac, " -c RestartAgent -o one_eole " + (redemarre ? "-f ": "" ) + " -U " + this.user )
      if ( exitCode != 0)
      {
          return exitCode
      }
    
      if ( redemarre == false )
      {
          out.println "------- Rédémarrage désactivé, STOP ! --------------" 
          return 0
      }
     
      out.println "RE DEMARRAGE AGENT ${user}"
      if ( computer.isOffline()) 
      {
          computer.connect(true)
          if ( computer.isUnix() )
          {
              pause( 10, "sleeping 10 seconds" )
          }
          else
          {
              pause( 30, "sleeping 30 seconds win" )
          }
          debugln('setTemporarilyOffline ==> isOnline ? : ' + computer.isOnline());    
      }
      if (computer.isTemporarilyOffline()) 
          computer.setTemporarilyOffline(false, new hudson.slaves.OfflineCause.ByCLI("restart agent"))
          
      out.println "${name}.isConnecting " +  computer.isConnecting()  
      out.println "${name}.connect(true) " +  computer.connect(true)  
      out.println "${name}.isOnline: " + computer.isOnline() 
      out.println "${name}.isOffline: " + computer.isOffline() 
      out.println "${name}.getOfflineCause: " + computer.getOfflineCause()
      
      if ( computer.isUnix() )
      {
         def cred = getCredential( "one-" + user )
         FilePath homeJenkins  = new FilePath(computer.getChannel(), "/home/jenkins");
         FilePath homeJenkinsOne  = new FilePath(homeJenkins, ".one");
         //def FilePath homeJenkinsOneAuth = new FilePath(homeJenkinsOne, "one_auth"  )
         //homeJenkinsOneAuth.write( cred.username +":" + cred.password.getPlainText() , null); //writing to file
         listFiles( homeJenkinsOne )
      }
      return 0
}

def restartAgentForUser()
{
    def exitCode = 2
    out.println "User ${user} "
    out.println "Redemarre ${redemarre} "
    out.println "Debug ${debugLevel} "
    out.println "forceRebuild ${forceRebuild} "

    Jenkins.instance.get().getNodes().each { agent ->
        if ( agent.name.endsWith( user ) ) 
        {
              exitCode = restartAgent( agent )
              if ( exitCode == 0 )
              {
                  return 0
              } 
        }
    }
    return exitCode
}


def debug2lnJenkinsJob( jenkinsJobName, texte )
{
    debug2ln( texte )
}

def debuglnJenkinsJob( jenkinsJobName, texte )
{
    debugln( texte )
}

def scanNode( jobsAExecuterOrdonnes, oneAccounts, nameEnCours, imagesEnCours, computer )
{
    //displayClass computer
    debugln("----------------------")
    def computerName = getComputerName( computer )
    debugln("Node ${computerName}")
    if ( computer.isOffline() || computer.isTemporarilyOffline())
    {
        out.println ( "  ${computerName}.isOffline: " )
        return 0
    }
      
   
    def computerLabelString = computer.getNode().getLabelString()
    debug2ln("  ${computerName} label= ${computerLabelString}")    
    def selfLabel = computer.getNode().getSelfLabel().toString()
    debug2ln( "  ${computerName} selflabel: " + selfLabel )

    def account = getOneAccountDefaultForComputer( computer )
    debug2ln("  ${computerName} account = " + account)
    def agentsForAccount = oneAccounts.get( account )
    def resourcesToLockForThisComputer = agentsForAccount.resourcesToLockForAccount
    
    debugln("  ${computerName} resource lock : '" + resourcesToLockForThisComputer + "'" )

    debugln("  ${computerName}.countBusy: " + computer.countBusy() )
    if ( computer.countBusy() >= computer.getNumExecutors()) 
    {
        out.println("  ${computerName} est chargé, stop !")    
        return 0
    }

    def nbImagesEnCours = imagesEnCours.size()
    debugln("  nbImagesEnCours="  +nbImagesEnCours )
    def nbJobSchedule = 0
    def result = true
    def jobsASupprimer = new ArrayList()
    for( jobAExecuter in jobsAExecuterOrdonnes )
    {
        def jenkinsJobName = jobAExecuter.jenkinsJobName
        if ( "EN_COURS".equals( jobAExecuter.status ) )
        {
            debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' est en cours")
            continue
        }
                
        def jobJSon = jobAExecuter.jobJSon
        def item = jobAExecuter.item
        def lastbuild = item.getLastBuild()
        if( lastbuild == null || lastbuild.getResult() == null )
        {
            // cas obsolete!
            debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' lastbuild==null pas encore lancé")
            //continue
        }
            
        def jobLabel
        if ( computerLabelString.equals(this.labelControler) && computer.countBusy() <= 1 )
        {
            jobLabel = this.labelControler
            selfLabel = this.labelControler
            debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' peut être executé sur le 'controler' car le 'controler' n'est pas chargé" )
        }
        else
        {
            jobLabel = jobJSon.label
            if ( jobLabel != null )
            {
                if ( computerLabelString.indexOf( jobLabel ) >= 0 ) 
                {
                    debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' peut être executé sur le node : " + computerName + " car " + jobLabel)
                }
                else
                {
                    //debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' ne peut pas être executé sur le node : " + computerName  + " car " + jobLabel)
                    continue
                }
            }
            else
            {
                debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' n'a pas de label ==> go")
            }
        }
                
        if ( resourcesToLockForThisComputer.disjoint (jobJSon.resourcesToLock ) == false )
        {
            debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' est en conflit de ressource. ignore")
            continue
        }
             
        // vérifie que les jobs Upstream sont executer avant de continuer
        def result1 = true
        jobJSon.depends.each{ depen ->
             def dep = depen.depend
             def depJob = getItem( dep )
             if ( depJob != null && ! depJob.disabled )
             {
                  def fileTodo = getTodoFile( dep )
                  if ( fileTodo.exists() )
                  {
                      debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' : Le todo '" + dep + "' est encore présent, il attendre son éxecution ! " )
                      result1 = false
                  }
                  if ( nameEnCours.contains( dep )) 
                  {
                      debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' : Le build '" + dep + "' est en cours, il attendre la fin de son éxecution ! " )
                      result1 = false
                  }
             }
        }
        if ( result1 == false )
        {
            // message ci dessus!
            continue
        }

        // est ce que les resultats des build upstream sont OK
        if ( estCeQueLesJobsDependantSontOk( item ) == false )
        {
            debuglnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' : ==> IGNORE CAR L'UN DES JOBS DEPENDANTS EST EN ERREUR !" )
            
            // je supprime le 'todo' car le job ne pourra pas 
            def fileTodo = getTodoFile( jenkinsJobName )
            deleteTodo( fileTodo )
            debuglnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' : todo supprimé")
            continue
        }
          
        if( jobJSon.genereImage != null )
        {
            if ( nbImagesEnCours + nbJobSchedule > 6 )
            {
                debug2lnJenkinsJob(jenkinsJobName, "  trop de générateur d'images en cours, '" + jenkinsJobName + "' à faire plus tard")
                continue
            }
        }
            
        debug2lnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' : il n'est pas contraint par les ressources VM, les buils upstreams sont executés, et les résultats sont OK, alors Go")
        jobAExecuter.status = "EN_COURS"
             
        if ( doScheduleWithNode( nbJobSchedule, jobAExecuter.item, selfLabel, false ) == 1)
        {
	        nbJobSchedule++
            debuglnJenkinsJob(jenkinsJobName, "  Le build '" + jenkinsJobName + "' : ok")
        }
        jobsASupprimer.add( jobAExecuter )
        
        if( jenkinsJobName.startsWith("day") )
        {
            if ( nbImagesEnCours + nbJobSchedule < 3 )
            {
                pause( 10, "  pause entre daily ..")
            }
            else
            {
                break
            }
        }
        else
       		break 
    }

	jobsAExecuterOrdonnes.removeAll( jobsASupprimer )

    return nbJobSchedule
}



def scanNodes()
{
    // calcul liste des build en cours par compte
    def oneAccounts = getBuildsByAccount()
        
    // y a t il trop de build en cours ?
    def imagesEnCours = [ ]
    def nameEnCours = [ ]
    oneAccounts.each { account, agentsForAccount -> 
                            agentsForAccount.jobs.each { item -> 
                                nameEnCours.add( item.name ) 
                                def jobJSon = getScheduleJSon().find{ it -> it.jenkinsJobName.equals( item.name ) }
                                if ( jobJSon != null && "".equals(jobJSon.genereImage) == false )
                                {
                                    imagesEnCours.add( jobJSon.genereImage )
                                }
                            }
                     }
    def nbEnCours = nameEnCours.size()
    def nbImagesEnCours = imagesEnCours.size()
    out.println("EnCours : '" + nameEnCours + "'" )
    out.println("ImagesEnCours : '" + imagesEnCours + "'" )

    // prepare la liste des jobs a executer
    def jobsAExecuter = createJobsAExecuter();
    def toBuild = new File( this.mntEoleCiTest + '/jenkins/todo' ).listFiles()
    toBuild.each{f ->
        if ( f.isFile() ) 
        {
            def jobName = f.getName() 
            if( nameEnCours.contains( jobName ) )
            {
                out.println(jobName + " déjà en cours, ignore" )
            }
            else
            {
                def item = getItem( jobName )
                if ( item != null )
	            {
	                cdu = addJobAExecuter( jobsAExecuter, item )
	                if ( cdu > 0 )
	                {
	                   // item hors jobs Eole généré !
                       out.println("Jobs infra : '" + item.name + "' ")
                       doScheduleWithNode( 0, item, 'controler', false)
	                }
	            }
            }
        }   
    }

    def jobsAExecuterOrdonnes = jobsAExecuter.sort { it.ordre }
    def nbJobSchedule = 0
    Jenkins.instance.get().computers.each { it -> 
                    nbJobSchedule += scanNode( jobsAExecuterOrdonnes, oneAccounts, nameEnCours, imagesEnCours, it )
                    }
    
    return nbJobSchedule
}

// call from Jenkins http://jenkins.eole.lan/jenkins/job/Internes/job/EoleCiScriptsGroovy
def testMeta()
{
    //displayClass( this.build.getResult() )
    //pause( 10, "test")
    this.debugLevel = 3
    this.try_pattern = true
    //this.seulementCeuxEnErreur = true
    //this.user = "ggrandgerard"
    //this.redemarre = true 
    //this.patternJobs = "test-thot-aaf-complet-.*"
    //this.patternJobs = ""
    //this.patternLogs = "CommandNotFoundException"
    //debugln( "meta patternlogs = " + this.patternLogs)
    //effaceBuild()
    //def mapJobFuture = [:]
    //this.argVersionMajeur = "2.7.0"
    //updateDailys()
    //this.groupementToBuild= "00,10,20"
    //runAllJobsNeedToBuild()
    //runAllJobWithPattern()
    //out.println getAgentToRunTheBuild( label, jobJSon)
    //disableOldJobs()
    //this.allItems
    //getVersionsJSon().each { eoleVersion -> checkFolderVersion( eoleVersion ) }
    //createViews( "2.8.0", "2.8.0", "DEV" )
    //updateAllJobs()
    //getScheduleJSon().each{ jobJSon -> updateJob( jobJSon ) }
    //createViewVersionArchitecture()
    //this.allItems.each { item ->
    //      def job = getScheduleJSon().find{ it -> it.jenkinsJobName.equals( item.name ) }
    //      traiteBuild( item, job )
    //}
    //this.try_pattern = true
    //monitorBuild( 0, mapJobFuture, 0, "START")
    //checkIfNeedToRunDailyFromTrigger()
    //checkNeedToRun()
    //updateTemplates()
    //createViews( "2.7.1", "2.7.1", "DEV" )
    //createViews( "infra", "", "DEV")
    //this.user = "win10-1"
    //this.redemarre = true
    //def oneAccounts = getBuildsByAccount()
    //scanNodes()
    //restartAgentForUser()
    //copyCredentialOnAgent()
    //runEoleCi( "" , " -c CheckFiles" )
    //getVersionsJSon().each{ eoleVersion -> updateTriggerVersion( eoleVersion ) }
    return 0
}

def displayPercent( texte, valeur )
{
        out.print(texte)
        def int mb = 1024*1024  
        out.print(" ")
        out.print( String.format("%.0f", valeur / mb))
        out.println(" Mo")
}

def displayMem()
{ 
        def runtime = Runtime.getRuntime()
        displayPercent("Total Memory:", runtime.totalMemory() )
        displayPercent("Free Memory:", runtime.freeMemory() )
        displayPercent("Used Memory:", (runtime.totalMemory() - runtime.freeMemory()) )
        displayPercent("Max Memory:" , runtime.maxMemory() )
}


def getVar( origine, key, value)
{
       debug2ln( "getVar ${origine} ${key}: ${value}")
       if ( key.equals("JOB_BASE_NAME" ) )
            this.commandJobName = value
       else if ( key.equals("GROUPEMENT" ) )
            this.groupementToBuild = value
       else if ( key.equals("PATTERN_LOGS" ) )
            this.patternLogs = value
       else if ( key.equals("PATTERN_JOBS" ) )
            this.patternJobs = value
       else if ( key.equals("NB_JOURS" ) )
            this.nbJours = Integer.valueOf(value)
       else if ( key.equals("TRY_PATTERN" ) )
          	this.try_pattern = Boolean.valueOf( value )
       else if ( key.equals("DANS_MON_CONTEXTE" ) )
            this.dansMonContexte = value
       else if ( key.equals("NEBULA_PASSWORD" ) )
            this.passwordNebula = value
       else if ( key.equals("SEULEMENT_CEUX_EN_ERREUR" ) )
            this.seulementCeuxEnErreur = value
       else if ( key.equals("FORCE_REBUILD" ) )
            this.forceRebuild = value
       else if ( key.equals("CHECK_TRIGGER_TIME" ) )
            this.checkTriggerTime = value
       else if ( key.equals("ONE" ) )
            this.cloudToUse = value
       else if ( key.equals("VERSION" ) )
            this.argVersionMajeur = value
       else if ( key.equals("SOURCE" ) )
            this.source = value
       else if ( key.equals("MAJ_AUTO" ) )
            this.argMajAuto = value
       else if ( key.equals("REDEMARRE" ) )
            this.redemarre = value
       else if ( key.equals("BUILD_USER" ) )
            this.user = value
//       else if ( key.equals("DEBUG" ) )
//            this.debugLevel = Integer.parseInt( value )
}

def init()
{
    def scriptVariables = getBinding().getVariables()
    this.out = scriptVariables.get("out")
    this.build = scriptVariables.get("build")
    this.launcher = scriptVariables.get("launcher")
    this.listener = scriptVariables.get("listener")
    this.args = scriptVariables.get("args")
    this.environment = this.build.getEnvironment(this.listener)
    out.println( "Init EoleCiScripts2" )
    this.mntEoleCiTest = "/mnt/eole-ci-tests" 

    // je charge en tout 1er la valeur DEBUG !
    this.debugLevel = 0
    this.parameters = this.build.actions.find{ it instanceof ParametersAction }?.parameters
    this.parameters.each {
        if ( it.name.equals("DEBUG" ) )
             this.debugLevel = Integer.parseInt( it.getValue() )
    }
    
    // rappel : toutes ces variables sont des "scriptsVariables" !
    this.patternLogs = ""
    this.patternJobs = ""
    this.try_pattern = false
    this.seulementCeuxEnErreur = true
    this.dansMonContexte = false
    this.groupementToBuild = null
    this.passwordNebula = null
    this.cloudToUse = null
    this.forceRebuild = false
    this.scheduleJson = null
    this.versionsJson = null
    this.versionMajeurs = null
    this.argVersionMajeur = null
    this.argMajAuto = null
    this.architectures = null
    this.checkTriggerTime = true
    this.redemarre = true
    this.commandJobName = null
    this.source = null
    this.labelControler = "controler"
    this.nbJours = 5
    
    this.userName = "?"
    for (cause in this.build.getCauses())
    {
        if (cause instanceof Cause.UserIdCause) {
            this.userName = cause.getUserName()
        }
    }
    this.user = null
    
    // charge les variables d'environnement du Build
    this.environment.each {
       getVar( "env", it.key, it.value )
    }

    // charge les paramétres du Build, et écrase les varables d'environnement s'il le faut
    this.parameters.each {
       getVar( "parameters", it.name, it.value )
    }

    // charge les variables Binding décrites dans la configuration du Job, et écrase les varables d'environnement s'il le faut
    // remarques: les variables existent dans le context 'scriptVariables', mais elle ne sont pas dans la bonne varaible (ex.: MAJ_AUTO -> argMajAuto)
    scriptVariables.each {
       getVar( "binding", it.getKey(), it.getValue() )
    }

    // je crée une variable 'envvars' qui ne doit contenir que les parametres que je passerais au job que si je doit les executer
    this.envvars = [:]
    this.environment.each {
       if ( it.getKey().equals("VERSION" ) )
       {
           envvars.put( it.getKey(), it.getValue() )
           debugln( "envvars for buiildparam: ${it.key}: ${it.value} ")
       }
       else if ( it.getKey().equals("MAJ_AUTO" ))
       {
           envvars.put( it.getKey(), it.getValue() )
           debugln( "envvars for buiildparam: ${it.key}: ${it.value} ")
       }
    }
    
    if ( checkMntEoleCiTests() == false )
    {
        return
    }

    this.allItems = processFolder( jenkins.model.Jenkins.get().items )
    debug2ln("nb items = " + this.allItems.size() )
}

def doCommande()
{
    try
    {
        if ( this.commandJobName == null )
            return 
        else if ( this.commandJobName.equals("EoleCiScripts2" ) )
            testMeta()
        else if ( this.commandJobName.equals("EoleCiScripts1" ) )
            testMeta()
        else if ( this.commandJobName.equals("pull-scanNodes" ) )
            scanNodes()
        else if ( this.commandJobName.equals("restart-agent" ) )
            restartAgentForUser()
        else if ( this.commandJobName.equals("run-all-jobs-with-pattern" ) )
            runAllJobWithPattern()
        else if ( this.commandJobName.equals("run-disable-old-jobs" ) )
            disableOldJobs()
        else if ( this.commandJobName.equals("run-update-jenkins-jobs" ) )
            updateAllJobs()
        else if ( this.commandJobName.equals("run-createViewVersionArchitecture" ) )
            createViewVersionArchitecture()
        else if ( this.commandJobName.startsWith("trigger-" ) )
            return updateDailys()
        else if ( this.commandJobName.startsWith("template-TriggerVersion" ) )
            return updateDailys()
        else if ( this.commandJobName.equals("delete-all-build-with-pattern-in-log" ) )
            effaceBuild()
//        else if ( this.commandJobName.equals("create-build-list-for-this-day" ) )
//            runEoleCiOnControler( "", " -c CreateBuildList -x ")
//        else if ( this.commandJobName.equals("update-templates-nebula" ) )
//            runEoleCiOnControler( "", " -c CreateTemplates")
//        else if ( this.commandJobName.equals("cleanup-eole-ci-tests-output" ) )
//            runEoleCiOnControler( "", " -c CleanOutput")
//        else if ( this.commandJobName.equals("update-liste-tests" ) )
//            runEoleCiOnControler( "", " -c ListTests")
        else if ( this.commandJobName.equals("genere-modele-reseau-dans-nebula" ) )
            runEoleCiOnControler( "", " -c InitialiseUser")
        else if ( this.args != null )
        {
            out.println("default commande :" + this.args )
            //this.debugLevel = 2
            def argEoleCi = ""
            this.args.each {
                argEoleCi += it + " "
            }   
            runEoleCi( "", argEoleCi)
        }
        else
        	out.println("Job inconnu '" +  this.commandJobName + "'")
    }
    finally 
    {        
        Runtime.getRuntime().gc()
        if( this.debugLevel > 0 )
        {
            displayMem()
        }   
    }   
}

init()
return doCommande()
