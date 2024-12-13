$vmConfiguration = 'domseth'
$vmVersionMajeurCible = '2.8.1'
. c:\eole\EoleCiFunctions.ps1
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

Set-Location c:\eole

try
{
   Write-Output "REALM=$adRealm" 

   $cn = $env:COMPUTERNAME
   Write-Output "COMPUTERNAME=$cn"
   
   Write-Output "test-veyon: Query DN of me" 
   $DN = ([adsisearcher]"(&(objectCategory=computer)(objectClass=computer)(cn=$env:COMPUTERNAME)(!(iscriticalsystemobject=True)))").FindOne().Properties.distinguishedname 
   Write-Output "DN = $DN"
   
   $UO = $DN.Replace( "CN=${cn},", '' )
   Write-Output "UO salle = $UO"
   
   Write-Output "test-veyon: Query AD Computers (REALM=$adRealm)" 
   $Search = [adsisearcher]"(&(objectCategory=Computer)(!(iscriticalsystemobject=True)))"
   $search.searchRoot = [adsi]"LDAP://$adRealm"
   $search.PropertiesToLoad.AddRange(('cn','distinguishedname', 'location','operatingsystem','operatingsystemversion', 'msds-supportedencryptiontypes','serviceprincipalname'))
   $Search.FindAll() | Foreach-Object {
   
        #objectcategory                 {CN=Computer,CN=Schema,CN=Configuration,DC=domseth,DC=ac-test,DC=fr}                                           
        #objectclass                    {top, person, organizationalPerson, user...}                                                                   
        #usnchanged                     {4014}                                                                                                         
        #usncreated                     {3479}                                                                                                         
        #objectguid                     {76 149 205 193 129 11 49 79 171 155 83 226 156 109 122 174}                                                   
        #whencreated                    {09/02/2022 15:00:41}                                                                                          
        #whenchanged                    {09/02/2022 15:00:51}                                                                                          
        #instancetype                   {4}                                                                                                            
        #objectsid                      {1 5 0 0 0 0 0 5 21 0 0 0 241 247 86 190 239 58 109 116 33 231 77 223 127 4 0 0}                               
        #serverreferencebl              {CN=DC2,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=domseth,DC=ac-test,DC=fr}           
        #ridsetreferences               {CN=RID Set,CN=DC2,OU=Domain Controllers,DC=domseth,DC=ac-test,DC=fr}                                          
        #iscriticalsystemobject         {True}                                                                                                         
        #serviceprincipalname           {HOST/DC2, GC/dc2.domseth.ac-test.fr/domseth.ac-test.fr, E3514235-4B06-11D1-AB04-00C04FC2DCD2/e64def42-434e-...
        #adspath                        {LDAP://domseth.ac-test.fr/CN=DC2,OU=Domain Controllers,DC=domseth,DC=ac-test,DC=fr}                           
        #distinguishedname              {CN=DC2,OU=Domain Controllers,DC=domseth,DC=ac-test,DC=fr}                                                     
        #dnshostname                    {dc2.domseth.ac-test.fr}                                                                                       
        #displayname                    {DC2$}                                                                                                         
        #samaccountname                 {DC2$}                                                                                                         
        #name                           {DC2}                                                                                                          
        #cn                             {DC2}                                                                                                          
        #logoncount                     {6}                                                                                                            
        #pwdlastset                     {132888924421185040}                                                                                           
        #lastlogontimestamp             {132888924509941500}                                                                                           
        #lastlogon                      {132888924785540700}                                                                                           
        #useraccountcontrol             {532480}                                                                                                       
        #codepage                       {0}                                                                                                            
        #msds-supportedencryptiontypes  {28}                                                                                                           
        #countrycode                    {0}                                                                                                            
        #primarygroupid                 {516}                                                                                                          
        #samaccounttype                 {805306369}                                                                                                    
        #accountexpires                 {9223372036854775807}                                                                                          
   
        #Cas PC Win :
        #logoncount                     {8}                                                                                                            
        #codepage                       {0}                                                                                                            
        #operatingsystem                {Windows 11 Professionnel}                                                                                     
        #name                           {PC-761315}                                                                                                    
        #msds-supportedencryptiontypes  {28}                                                                                                           
        #serviceprincipalname           {HOST/PC-761315.domseth.ac-test.fr, RestrictedKrbHost/PC-761315.domseth.ac-test.fr, HOST/PC-761315, Restrict...
        #iscriticalsystemobject         {False}                                                                                                        
        #useraccountcontrol             {4096}                                                                                                         
        #cn                             {PC-761315}                                                                                                    
        #countrycode                    {0}                                                                                                            
        #primarygroupid                 {515}                                                                                                          
        #operatingsystemversion         {10.0 (22000)}                                                                                                 
        #dnshostname                    {PC-761315.domseth.ac-test.fr}                                                                                 
        #distinguishedname              {CN=PC-761315,CN=Computers,DC=domseth,DC=ac-test,DC=fr}                                                        
        #samaccountname                 {PC-761315$}                                                                                                   
        #samaccounttype                 {805306369}                                                                                                    
        #accountexpires                 {9223372036854775807}     
   
        $prop=$_.properties
        $prop
        $prop.serviceprincipalname | Format-List 
        Write-Output "--------------------"
   }
   
}
catch
{
    $Error | Write-Output
    Write-Output "Caught an exception:"
    Write-Output "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Output "Exception Message: $($_.Exception.Message)"
    exit -1
}
finally 
{
    Write-Output "test-salt-minion: fin"
    Set-PSDebug -Trace 0
}
