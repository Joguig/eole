h1. Compilation de Samba

{{toc}}

h2. Tableau des versions

* Releases Samba : https://www.samba.org/samba/history/
* Version des paquets samba chez Ubuntu : https://packages.ubuntu.com/search?keywords=samba&searchon=names&suite=all&section=all
* Dépôts samba chez EOLE : http://eole.ac-dijon.fr/samba/dists/

| Version EOLE | Version Ubuntu | Samba Ubuntu | Seth EOLE | Source Debian |
| 2.6.0        | xenial         | 4.3.11       | 4.3.11 (ubuntu) | |
| 2.6.1        | xenial         | 4.3.11       | 4.5.12 (eole) | |
| 2.6.2        | xenial         | 4.3.11       | 4.7.12 (eole) | |
| 2.7.0        | bionic         | 4.7.6        | 4.9.5 (eole) | debian buster 2:4.9.5+dfsg-5+deb10u1 |
| 2.7.1        | bionic         | 4.7.6        | 4.9.5 (eole) | debian buster 2:4.9.5+dfsg-5+deb10u1 |
| 2.7.2        | bionic         | 4.7.6        | n/a         | debian buster 2:4.9.5+dfsg-5+deb10u1 |
| 2.8.0        | eoan           | 4.10.7       | n/a         | debian sid 2:2:4.11.1+dfsg-3 |

h2. État des lieux (décembre 2019)

Lors de la rédaction de cet article, la version de samba sur EOLE 2.7.0 2.7.1 et 2.7.2 (bionic) est la 4.9.5-EOLE. 
Le but était d'ajouter tous les commits et patch permettant d'aller jusqu'à "debian buster 2:4.9.5+dfsg-5+deb10u1" (4.9.16)  

La base compilée par "Debian":https://packages.debian.org/sid/samba) avec les patches (CVE) de la "4.9.6":https://www.samba.org/samba/history/samba-4.9.6.html.

Ceci tout en conservant nos deux patches actuels :
* 0035-workaround-bug-when-demoting-RODC.patch
* 0036-dlz-bind-zone-transfer-restriction.patch

prérequis :
- builder sur une EOLEBASE 2.7.0
- installer 'git'
git clone https://salsa.debian.org/samba-team/samba.git
git clone https://salsa.debian.org/debian/cmocka.git
git clone https://salsa.debian.org/samba-team/ldb.git
git clone https://salsa.debian.org/samba-team/talloc.git
git clone https://salsa.debian.org/samba-team/tdb.git
git clone https://salsa.debian.org/samba-team/tevent.git


consulter https://dev-eole.ac-dijon.fr/projects/samba/repository
basculer sur "dist/eole/2.7.0/master
identifier les derniers commits EOLE 

par ex: 
- https://dev-eole.ac-dijon.fr/projects/samba/repository/revisions/598ba92ce8ef043343422e746d7415b383dcb94d
- https://dev-eole.ac-dijon.fr/projects/samba/repository/revisions/411333e7650a3d89fb24b21b13f3be8b11c3f8a5

h2. Dépôts Samba

https://dev-eole.ac-dijon.fr/projects/samba/repository

Sur la forge EOLE, on retrouve le dépôt samba ainsi que des dépôts pour chacune les librairies associées :
*    cmocka 
*    ldb 
*    talloc 
*    tdb 
*    tevent

h3. Dépôts distants

Pour Samba, plusieurs dépôts sont disponibles.
Il est recommandé de commencer par cloner le dépôt Debian (salsa) afin que la branche master pointe vers celui-ci puis de déclarer les autres dépôts distants :
<pre>
git clone https://salsa.debian.org/samba-team/samba.git
cd samba
git remote add dev-eole https://dev-eole.ac-dijon.fr/git/samba.git
</pre>

Une fois ces opérations réalisées, on doit obtenir la configuration suivante :
<pre>
# git remote -v 
dev-eole    ssh://git@dev-eole.ac-dijon.fr/samba.git (fetch)
dev-eole    ssh://git@dev-eole.ac-dijon.fr/samba.git (push)
origin  https://salsa.debian.org/samba-team/samba.git (fetch)
origin  https://salsa.debian.org/samba-team/samba.git (push)
</pre>

Le dépôt officiel de Samba n'est pas utilisé dans les manipulation réalisées ce jour ;)

h3. Branches distantes

Les branches que nous utilisons sont les suivantes :
* @master@ : branche de packaging Debian
* @upstream_4.9@ : sources samba-4.9 importées par Debian (NB : dans cette branche les patches sont déjà appliqués)
* @pristine-tar@ : upstream tarball au format "pristine"
* @dist/eole/2.7.0/master@ : branche de packaging EOLE (NB : dans cette branche les patches sont déjà appliqués)

Forcer l'utilisation du dépôt "origin" pour la branche @pristine-tar@, la commande suivante doit être utilisée :
<pre>
PS: il faut m'expliquer a quoi ça sert !
git checkout -b pristine-tar origin/pristine-tar
</pre>

h2. Préparer le paquet

récupérer la branche @dist/eole/2.7.0/master@, en exécutant :
<pre>
git fetch dev-eole
</pre>

Mettre à jour toutes les branches :
<pre>
git pull
</pre>

Déterminer le tag "final" (debian) :
On utilise La branche 'buster-security'==> donc Basculement sur la nouvelle branche 'buster-security'
<pre>
git checkout -b buster-security origin/buster-security
git describe
TAG_PACKAGING_DEBIAN=$(git describe)
VERSION_TALLOC_DEBIAN=$(grep ^VERSION lib/talloc/wscript)
VERSION_TDB_DEBIAN=$(grep ^VERSION lib/tdb/wscript)
VERSION_TEVENT_DEBIAN=$(grep ^VERSION lib/tevent/wscript)
VERSION_LDB_DEBIAN=$(grep ^VERSION lib/ldb/wscript)
</pre>
==> donne le dernier tag (ex: debian/2%4.9.5+dfsg-5+deb10u1)
 
Déterminer le tag "initial" (eole) :

Se positionner sur la branche de packaging EOLE et déterminer le dernier tag actuel (du paquet EOLE):
<pre>
git checkout dist/eole/2.7.0/master
git describe
TAG_PACKAGING_EOLE=$(git describe)
VERSION_TALLOC_EOLE=$(grep ^VERSION lib/talloc/wscript)
VERSION_TDB_EOLE=$(grep ^VERSION lib/tdb/wscript)
VERSION_TEVENT_EOLE=$(grep ^VERSION lib/tevent/wscript)
VERSION_LDB_EOLE=$(grep ^VERSION lib/ldb/wscript)
</pre>
==> donne le dernier tag (ex: debian/2%4.9.5+dfsg-3-10-g598ba92ce8e)


Lister tous les commits ajoutés depuis le dernier paquet EOLE à l'aide des tags dans l'ordre chronologique:
<pre>
git cherry -v ${TAG_PACKAGING_EOLE} ${TAG_PACKAGING_DEBIAN} 
</pre>

exemple:
<code>
+ 9a309f24c687d1bdbebaa2475528fd2553bba1c8 CVE-2018-16860 selftest: Add test for S4U2Self with unkeyed checksum
+ 8e695f932069113e7165ca6ddac6d8bad060d281 CVE-2018-16860 Heimdal KDC: Reject PA-S4U2Self with unkeyed checksum
+ 0e2bf2546c52018dc74dffd2fe64d2968fa30973 Add patches for CVE-2018-16860 S4U2Self with unkeyed checksum
+ 964bd6a6419583cf457ea39e39fc7cff8ed214f1 Release 2:4.9.5+dfsg-4
+ a3d20ae6bdcb03c0bd893e07943906d3fc91c616 Add missing Breaks+Replace found by piuparts (Closes: #929217)
+ fe8ceb8f4a0b3f73b3878f703dcaa6e9f98268ad CVE-2019-12435 rpc/dns: avoid NULL deference if zone not found in DnssrvOperation
+ fda0327e59302d2da1f786ecf8566bb05b530553 CVE-2019-12435 rpc/dns: avoid NULL deference if zone not found in DnssrvOperation2
+ 08fc5a8b0dba46b44b650d03d8ffbc3b30e21ff4 Add patch for CVE-2019-12435
+ e07803866d495c40e96ceb02f6b07d4d4ee6f39d Release 2:4.9.5+dfsg-5
+ 99ca51a11a4909a0276498e1874d242133eee61c gbp.conf: change debian-branch to buster-security, and merge-mode to merge
+ fccc8d4ce1e7142cd6f4ac56735cdac056371fbb CVE-2019-10197: smbd: separate out impersonation debug info into a new function.
+ ddfbdf3c45d08cb0e82f02d8a24fb1f172733ede CVE-2019-10197: smbd: make sure that change_to_user_internal() always resets current_user.done_chdir
+ 8d0ec6a2c2fe52eeb6255a0a2173c5d92a31d597 CVE-2019-10197: smbd: make sure we reset current_user.{need,done}_chdir in become_root()
+ 17f249b83911b26c341020f755dfcb919f300578 CVE-2019-10197: selftest: make fsrvp_share its own independent subdirectory
+ 6f908e6a96a3ff0a323d5406bd8b42b8a5561a1a CVE-2019-10197: test_smbclient_s3.sh: add regression test for the no permission on share root problem
+ 6d5ced9bb8b412b1474133a2deb177db8da60e00 CVE-2019-10197: smbd: split change_to_user_impersonate() out of change_to_user_internal()
+ 2e75ddb958323242b1d2e747e596c1941545c760 Add patches for CVE-2019-10197
+ cc11659f797c58937e9c3c2a0851444c55921555 Prepare changelog for release
</code>

Lister tous les commits ajoutés depuis le dernier paquet EOLE à l'aide des tags dans l'ordre anti-chronologique:
<pre>
git log ${TAG_PACKAGING_EOLE}..${TAG_PACKAGING_DEBIAN}
</pre>

h3. Fusionner les modifications

Se positionner sur la branche de packaging EOLE et fusionner le tag souhaité (le dernier en général) :
<pre>
git checkout dist/eole/2.7.0/master
git merge ${TAG_PACKAGING_DEBIAN}
</pre>

Donne 
<code>
Fusion automatique de debian/patches/series
CONFLIT (contenu) : Conflit de fusion dans debian/patches/series
Fusion automatique de debian/control
Fusion automatique de debian/changelog
CONFLIT (contenu) : Conflit de fusion dans debian/changelog
La fusion automatique a échoué ; réglez les conflits et validez le résultat
</code>
Cela entraîne généralement quelques conflits mais pas trop complexes :
* @debian/changelog@: move EOLE entries at the proper place in history
* @debian/patches/series@: keep EOLE/MTES patches

Exemple pour "debian/patches/series" :

cat debian/patches/series
<code>
07_private_lib
bug_221618_precise-64bit-prototype.patch
README_nosmbldap-tools.patch
smbclient-pager.patch
usershare.patch
VERSION.patch
add-so-version-to-private-libraries
heimdal-rfc3454.txt
nsswitch-Add-try_authtok-option-to-pam_winbind.patch
smbd.service-Run-update-apparmor-samba-profile-befor.patch
CVE-2019-3880-v4-9-02.patch
CVE-2019-3870-v4-9-04.patch
<<<<<<< HEAD
0035-workaround-bug-when-demoting-RODC.patch
0036-dlz-bind-zone-transfer-restriction.patch
=======
CVE-2018-16860-v4-9-06.patch
CVE-2019-12435-4.9-03.patch
CVE-2019-10197-v4-9-03.patch
>>>>>>> debian/2%4.9.5+dfsg-5+deb10u1
</code>

cat debian/patches/series <EOF
07_private_lib
bug_221618_precise-64bit-prototype.patch
README_nosmbldap-tools.patch
smbclient-pager.patch
usershare.patch
VERSION.patch
add-so-version-to-private-libraries
heimdal-rfc3454.txt
nsswitch-Add-try_authtok-option-to-pam_winbind.patch
smbd.service-Run-update-apparmor-samba-profile-befor.patch
CVE-2019-3880-v4-9-02.patch
CVE-2019-3870-v4-9-04.patch
CVE-2018-16860-v4-9-06.patch
CVE-2019-12435-4.9-03.patch
CVE-2019-10197-v4-9-03.patch
0035-workaround-bug-when-demoting-RODC.patch
0036-dlz-bind-zone-transfer-restriction.patch
EOF

Exemple pour "debian/changelog" :

NO_LIGNE_FIN_MERGE_CONFLICT=$(grep -n ">>>>>>>" debian/changelog | cut -f1 -d:)
head -n $NO_LIGNE_FIN_MERGE_CONFLICT

Donne la liste des CVE & fonctionnalité mise à jour depuis notre dernier paquet EOLE :
exemple :
<code>
samba (2:4.9.5+dfsg-3~bpoeole270+1) samba-4.9; urgency=medium

  * Merge debian package for EOLE backport 2.7

 -- Daniel Dehennin <daniel.dehennin@baby-gnu.org>  Tue, 09 Apr 2019 11:26:19 +0200
=======
samba (2:4.9.5+dfsg-5+deb10u1) buster-security; urgency=high

  * Non-maintainer upload by the Security Team.
  * gbp.conf: change debian-branch to buster-security, and merge-mode to merge
  * CVE-2019-10197: smbd: separate out impersonation debug info into a new
    function.

....

samba (2:4.9.5+dfsg-4) unstable; urgency=high

  * This is a security release in order to address the following defect:
    - CVE-2018-16860 Heimdal KDC: Reject PA-S4U2Self with unkeyed checksum

 -- Mathieu Parent <sathieu@debian.org>  Wed, 08 May 2019 21:53:16 +0200
>>>>>>> debian/2%4.9.5+dfsg-5+deb10u1
</code>

A faire : 
- enlever les "commits" EOLE
- enlever les marques de merge
- La lecture du changelog Debian a montré que les patches de sécurité (CVE) samba-4.9.6 étaient déjà appliqués sur la version 4.9.5 packagée par Debian.%


h3. Vérifier/Corriger les dépendances

Pour vérifier les dépendances de compilation, il est possible d'utiliser la commande indiquée dans le fichier README.sources :
<pre>
if [ "$VERSION_LDB_EOLE" != "$VERSION_LDB_DEBIAN" ]
then
    echo "rebuild LDB" 
    git clone https://salsa.debian.org/samba-team/ldb.git
    cd ldb
    git remote add dev-eole https://dev-eole.ac-dijon.fr/git/ldb.git
    gbp export-orig
else
    echo "pas besoin de rebuild LDB"
fi
</pre>

%{color:darkblue}NB : Les versions actuellement disponibles dans le dépôt EOLE sont visibles dans le fichier "Packages":http://test-eole.ac-dijon.fr/samba/dists/samba-4.9/main/binary-amd64/Packages%

Mais il faut également analyser en détail les versions (et les noms) des paquets mentionnés dans la section @Build-Depends@ du fichier @debian/control@.
Les pièges sont nombreux comme des noms de paquets différents entre Debian et Ubuntu (ex : libglusterfs-dev), des paquest re-numérotés avec le mot clé "really" (ex : ldb), ...

%{color:purple}Si à cette étape, on s'aperçoit qu'une des librairies est à recompiler, aller voir [[Samba#Compilation-dune-librairie-exemple-ldb|Compiler et diffuser une librairie]] et revenez plus tard !%

Ceci dit, si on en rate, on s'en apercevra très vite dans les étapes qui suivent ;)

%{color:darkblue}NB : La bionic est en retard sur la @Standards-Version@ requise mais ce n'est pas bloquant.%

%{color:darkblue}NB : La bionic est en retard également sur les debhelper.%

%{color:darkblue}NB : La bionic est en retard également sur la version de python (impact sur les noms fichiers dans les .install notamment).%

h3. Valider les modifications

Une fois qu'on a réglé les conflits et que le fichier @debian/control@ nous semble correct, il est possible de réaliser un commit pour finaliser le merge.

Il est conseillé de vérifier toutes les modifications à l'aide de la commande suivante :
<pre>
git diff HEAD~..HEAD
</pre>

Si l'on est satisfait, on ajoute une nouvelle entrée dans le changelog avec le numéro de version souhaité et on commite.

Puis exporter le "upstream tarball" (nécessite le paquet @git-buildpackage@) :

<pre>
gbp export-orig
</pre>

Cela crée une archive au format @tar.xz@ (exemple : @samba_4.9.5+dfsg.orig.tar.xz@)

%{color:red}NB : comme par hasard, ça plante sous bionic (@XD3_INVALID_INPUT@) mais fonctionne sous Debian !%

h2. Compiler et diffuser le paquet samba

h3. Compiler le paquet

Pour compiler, le plus simple est d'installer un Eolebase, lui ajouter les dépôts samba-4.9 et les dépôts sources Ubuntu ainsi que le paquet build-essential :
<pre>
echo -e "deb [ arch=amd64 ] http://test-eole.ac-dijon.fr/samba samba-4.9 main\ndeb-src [ arch=amd64 ] http://test-eole.ac-dijon.fr/samba samba-4.9 main" > /etc/apt/sources.list.d/samba.list
sed -e 's/^deb/deb-src/' /etc/apt/sources.list >> /etc/apt/sources.list.d/samba.list
apt update
apt install build-essential
</pre>

Copier l'archive et sources (branche dist/eole/2.7.0/master du dépôt) :
<pre>
scp samba_4.9.5+dfsg.orig.tar.xz root@eolebase.ac-test.fr:
rsync -avz samba -e ssh root@eolebase.ac-test.fr:
</pre>

%{color:purple}NB : La copie des sources (dépôt) samba via ssh entraîne une erreur de liens symboliques par la suite !%

Vérifier/installer les dépendances de compilation :
<pre>
apt build-dep ./samba
</pre>

%{color:purple}Si à cette étape, on s'aperçoit qu'une des librairies est à recompiler, aller voir [[Samba#Compilation-dune-librairie-exemple-ldb|Compiler et diffuser une librairie]] et revenez plus tard !%

Compiler le paquet (%{color:purple}prévoir 40 minutes% une fois lancé)
<pre>
cd samba
dpkg-buildpackage -sa --no-sign
</pre>

* l'option @-sa@ permet d'inclure les sources. Il ne faut pas la mettre si les sources ont déjà été inclues.
* l'option @--no-sign@ évite d'avoir une erreur lors de la tentative de signature des paquets ;)

Une fois le paquet compilé on obtient les fichiers deb, changes et dsc dans le répertoire supérieur.
Il est possible de vérifier la liste de ce qui a été compilé en consultant le fichier *.changes.

h3. Signer le paquet

Sur la machine @bionic-builder@, créer un répertoire dédié (exemple @~/samba@) puis copier les fichiers générés dedans :
<pre>
scp *.*deb *.tar.xz *.dsc *.changes *.buildinfo buildd@bionic-builder.eole.lan:samba
</pre>

Sur la machine @bionic-builder@, signer les paquets à l'aide de la commande :
<pre>
cd samba
debsign -k eole *.changes
</pre>

h3. Publier le paquet

Sur la machine @castor@, créer un répertoire dédié (exemple @/srv/repository/samba/tmp/samba@) puis copier les paquets signés dedans :
<pre>
scp * repository@castor:/srv/repository/samba/tmp/samba
</pre>

Puis importer les paquets dans le dépôt :
<pre>
cd /srv/repository/samba
reprepro -v include samba-4.9 tmp/samba/*.changes
</pre>

Il est possible de vérifier les paquets disponible à l'aide de la commande :
<pre>
reprepro listfilter samba-4.9 '$Source (= samba)'
</pre>

h3. Finaliser le travail

Mettre à jour et pousser toutes les branches ...
FIXME

h2. Compiler et diffuser une librairie (exemple :ldb)

Les étapes pour compiler une des librairies sont similaires à celles nécessaires à la compilation de samba.

Pour le cas de @ldb@, il faut commencer par avoir clôné les dépôts :
<pre>
git clone https://salsa.debian.org/samba-team/ldb.git
cd ldb
git remote add dev-eole https://dev-eole.ac-dijon.fr/git/ldb.git
git remote add samba https://git.samba.org/ldb.git
</pre>

On retrouve les branches distantes suivantes :
* @master@ : branche de packaging Debian
* @upstream@ : sources importées par Debian (NB : dans cette branche les patches sont déjà appliqués)
* @pristine-tar@ : upstream tarball au format "pristine"
* @dist/eole/2.7.0/master@ : branche de packaging EOLE (NB : dans cette branche les patches sont déjà appliqués)

Il faut ensuite préparer le paquet comme expliqué dans [[Samba#Pr%C3%A9parer-le-paquet]] et terminer par la commande :
<pre>
gbp export-orig
</pre>

Cela crée une archive au format @tar.gz@ (exemple : @ldb_1.5.1+really1.4.6.orig.tar.gz@)

Il faut ensuite préparer la machine de compilation (cf. [[Samba#Compiler-et-diffuser-le-paquet-samba]] et envoyer l'archive et le dépôt (branche @dist/eole/2.7.0/master@) dessus.

Puis, vérifier/installer les dépendances de compilation et compiler :
<pre>
apt build-dep ./ldb
cd ldb
dpkg-buildpackage -sa --no-sign
</pre>


%{color:purple}NB : ça peut également être assez long surtout si le paquet contient beaucoup de tests unitaires !%

h3. Liste des dépôts pour les bibliothèques

* https://salsa.debian.org/debian/cmocka.git
* https://salsa.debian.org/samba-team/ldb.git
* https://salsa.debian.org/samba-team/talloc.git
* https://salsa.debian.org/samba-team/tdb.git
* https://salsa.debian.org/samba-team/tevent.git

h3. Ordre de compilation

Le jeu de dépendance impose un certain ordre de compilation :

<pre>
talloc <---- tevent <---- ldb <----- samba
tdb <-------------------’
cmocka <---------------’
</pre>