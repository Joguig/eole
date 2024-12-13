#!/bin/bash

#
# Echange la clef SSH root vers HOST_NAME
#
function echange_ssh_key()
{
    local HOST_NAME
    
    HOST_NAME="$1"

    if [ ! -d /root/.ssh ]
    then
        mkdir -p /root/.ssh
    fi
    if [ ! -f /root/.ssh/id_rsa ]
    then
        echo "* Generation de la clef SSH pour les echanges entre DC"
        if ! ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
        then
            return 1
        fi
    fi

    echo "* Envoi de la clef SSH vers ${HOST_NAME}"
    if ! ciMonitor ssh-copy-id -i /root/.ssh/id_rsa.pub "root@${HOST_NAME}"
    then
        return 2
    fi
    
    echo "* Envoi de la clef SSH root de ${HOST_NAME}"
    if ! scp "root@${HOST_NAME}:/root/.ssh/id_rsa.pub" /tmp/id_rsa.pub
    then
        return 3
    fi
    if [ ! -f /tmp/id_rsa.pub ]
    then
        return 4
    fi

    cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys
}


echo "Début $0"

# Vegeta https://github.com/tsenart/vegeta
#if [ ! -f /root/vegeta ]
#then
#    wget https://github.com/tsenart/vegeta/releases/download/v12.8.4/vegeta_12.8.4_linux_amd64.tar.gz -O /root/vegeta.tar.gz
#    tar xzvf /root/vegeta.tar.gz -C /root
#    chmod +x /root/vegeta
#    #/root/vegeta --help
#   echo "GET http://192.168.0.26/" | /root/vegeta attack -duration=5s | tee results.bin | /root/vegeta report
#fi

# Bombardier https://github.com/codesenberg/bombardier
#if [ ! -f /root/bombardier ]
#then
#    wget https://github.com/codesenberg/bombardier/releases/download/v1.2.5/bombardier-linux-amd64 -O /root/bombardier
#    chmod +x /root/bombardier
#    #/root/bombardier --help
#fi

# ApacheBenc https://httpd.apache.org/docs/2.4/programs/ab.html
#if ! command -v ab
#then
#    apt install -y apache2-utils
#fi

echange_ssh_key proxy.ac-test.fr

cat >/root/urls <<EOF
facebook.com,SITE_AUTORISE
fonts.googleapis.com,SITE_AUTORISE
twitter.com,SITE_AUTORISE
google.com,SITE_AUTORISE
youtube.com,SITE_AUTORISE
s.w.org,SITE_AUTORISE
instagram.com,SITE_AUTORISE
googletagmanager.com,SITE_AUTORISE
linkedin.com,SITE_AUTORISE
ajax.googleapis.com,SITE_AUTORISE
gmpg.org,SITE_AUTORISE
plus.google.com,SITE_AUTORISE
fonts.gstatic.com,SITE_AUTORISE
youtu.be,SITE_AUTORISE
cdnjs.cloudflare.com,SITE_AUTORISE
pinterest.com,SITE_AUTORISE
maps.google.com,SITE_AUTORISE
en.wikipedia.org,SITE_AUTORISE
wordpress.org,SITE_AUTORISE
bit.ly,SITE_AUTORISE
play.google.com,SITE_AUTORISE
goo.gl,SITE_AUTORISE
github.com,SITE_AUTORISE
itunes.apple.com,SITE_AUTORISE
docs.google.com,SITE_AUTORISE
support.google.com,SITE_AUTORISE
vimeo.com,SITE_AUTORISE
amazon.com,SITE_AUTORISE
apis.google.com,SITE_AUTORISE
developers.google.com,SITE_AUTORISE
maps.googleapis.com,SITE_AUTORISE
paypal.com,SITE_AUTORISE
google-analytics.com,SITE_AUTORISE
nytimes.com,SITE_AUTORISE
ec.europa.eu,SITE_AUTORISE
medium.com,SITE_AUTORISE
creativecommons.org,SITE_AUTORISE
reddit.com,SITE_AUTORISE
mail.google.com,SITE_AUTORISE
code.jquery.com,SITE_AUTORISE
vk.com,SITE_AUTORISE
drive.google.com,SITE_AUTORISE
secure.gravatar.com,SITE_AUTORISE
policies.google.com,SITE_AUTORISE
accounts.google.com,SITE_AUTORISE
soundcloud.com,SITE_AUTORISE
player.vimeo.com,SITE_AUTORISE
flickr.com,SITE_AUTORISE
lh3.googleusercontent.com,SITE_AUTORISE
m.facebook.com,SITE_AUTORISE
t.co,SITE_AUTORISE
blogger.com,SITE_AUTORISE
ads.google.com,SITE_AUTORISE
dropbox.com,SITE_AUTORISE
maxcdn.bootstrapcdn.com,SITE_AUTORISE
gstatic.com,SITE_AUTORISE
tinyurl.com,SITE_AUTORISE
cloud.google.com,SITE_AUTORISE
sites.google.com,SITE_AUTORISE
platform.twitter.com,SITE_AUTORISE
i.ytimg.com,SITE_AUTORISE
apps.apple.com,SITE_AUTORISE
podcasts.google.com,SITE_AUTORISE
microsoft.com,SITE_AUTORISE
w3.org,SITE_AUTORISE
bing.com,SITE_AUTORISE
tumblr.com,SITE_AUTORISE
wired.com,SITE_AUTORISE
bbc.co.uk,SITE_AUTORISE
messenger.com,SITE_AUTORISE
cloudflare.com,SITE_AUTORISE
open.spotify.com,SITE_AUTORISE
forbes.com,SITE_AUTORISE
static.wixstatic.com,SITE_AUTORISE
t.me,SITE_AUTORISE
commons.wikimedia.org,SITE_AUTORISE
support.apple.com,SITE_AUTORISE
i.imgur.com,SITE_AUTORISE
ted.com,SITE_AUTORISE
calendar.google.com,SITE_AUTORISE
apple.com,SITE_AUTORISE
google.de,SITE_AUTORISE
adobe.com,SITE_AUTORISE
slideshare.net,SITE_AUTORISE
s3.amazonaws.com,SITE_AUTORISE
archive.org,SITE_AUTORISE
translate.google.com,SITE_AUTORISE
patreon.com,SITE_AUTORISE
chrome.google.com,SITE_AUTORISE
wordpress.com,SITE_AUTORISE
podcasts.apple.com,SITE_AUTORISE
theguardian.com,SITE_AUTORISE
twitch.tv,SITE_AUTORISE
mozilla.org,SITE_AUTORISE
cdn.jsdelivr.net,SITE_AUTORISE
wp.me,SITE_AUTORISE
google.co.uk,SITE_AUTORISE
issuu.com,SITE_AUTORISE
amzn.to,SITE_AUTORISE
adatom.com,SITE_INTERDIT
ad.be.doubleclick.net,SITE_INTERDIT
ad.br.doubleclick.net,SITE_INTERDIT
ad.ca.doubleclick.net,SITE_INTERDIT
ad.ch.doubleclick.net,SITE_INTERDIT
ad.de.doubleclick.net,SITE_INTERDIT
ad.dk.doubleclick.net,SITE_INTERDIT
ad.es.doubleclick.net,SITE_INTERDIT
ad.fi.doubleclick.net,SITE_INTERDIT
ad.in.doubleclick.net,SITE_INTERDIT
ad.it.doubleclick.net,SITE_INTERDIT
ad.no.doubleclick.net,SITE_INTERDIT
ad.pt.doubleclick.net,SITE_INTERDIT
ad.se.doubleclick.net,SITE_INTERDIT
ad.doubleclick.net,SITE_INTERDIT
adbot.theonion.com,SITE_INTERDIT
ad.caos.it,SITE_INTERDIT
adcycle.com,SITE_INTERDIT
addfreestats.com,SITE_INTERDIT
addme.com,SITE_INTERDIT
ad.keenspace.com,SITE_INTERDIT
ads1.gccx.com,SITE_INTERDIT
ads2.collegclub.com,SITE_INTERDIT
ads.51.net,SITE_INTERDIT
ads.amazingmedia.com,SITE_INTERDIT
ads.amusive.com,SITE_INTERDIT
adserver.onwisconsin.com,SITE_INTERDIT
ads.eu.msn.com,SITE_INTERDIT
ads.flashtrack.net,SITE_INTERDIT
ads.home.net,SITE_INTERDIT
ads.inet1.com,SITE_INTERDIT
ads.jp.msn.com,SITE_INTERDIT
ads.jpost.com,SITE_INTERDIT
ads-links.com,SITE_INTERDIT
adsmart.ru,SITE_INTERDIT
ads.msn.com,SITE_INTERDIT
adsrotation.com,SITE_INTERDIT
ads.stileproject.com,SITE_INTERDIT
ads.terra.com.br,SITE_INTERDIT
ads.usatoday.com,SITE_INTERDIT
adtech.de,SITE_INTERDIT
ad.uk.doubleclick.net,SITE_INTERDIT
adultboerse.de,SITE_INTERDIT
adultmegamall.com,SITE_INTERDIT
adultrevenueservice.com,SITE_INTERDIT
adv.bbanner.it,SITE_INTERDIT
advertising.com,SITE_INTERDIT
adv.wp.pl,SITE_INTERDIT
adworks.cc,SITE_INTERDIT
ai.net,SITE_INTERDIT
asacp.org,SITE_INTERDIT
ashampoo.com,SITE_INTERDIT
atlas.services.ou.edu,SITE_INTERDIT
avault.com,SITE_INTERDIT
bannerads.de,SITE_INTERDIT
banner.avp2000.com,SITE_INTERDIT
bannerco-op.com,SITE_INTERDIT
banner.freeservers.com,SITE_INTERDIT
banner-mania.com,SITE_INTERDIT
bannerpoint.ru,SITE_INTERDIT
bannerpower.com,SITE_INTERDIT
banners.adultfriendfinder.com,SITE_INTERDIT
banners.babylon-x.com,SITE_INTERDIT
banners.czi.cz,SITE_INTERDIT
banners.df.ru,SITE_INTERDIT
banners.hotqueens.com,SITE_INTERDIT
bannerspace.com,SITE_INTERDIT
bannerswap.com,SITE_INTERDIT
bb.ru,SITE_INTERDIT
befree.com,SITE_INTERDIT
best-ads.com,SITE_INTERDIT
bigwebtools.com,SITE_INTERDIT
billboard.cz,SITE_INTERDIT
bizlink.ru,SITE_INTERDIT
bns1.net,SITE_INTERDIT
boxfrog.com,SITE_INTERDIT
bravenet.com,SITE_INTERDIT
brodia.com,SITE_INTERDIT
bserver.bclick.com,SITE_INTERDIT
bulkregister.com,SITE_INTERDIT
cgi.netscape.com,SITE_INTERDIT
cidyweb.free.fr,SITE_INTERDIT
cj.com,SITE_INTERDIT
clickagents.com,SITE_INTERDIT
clickhere.ru,SITE_INTERDIT
clickit.com,SITE_INTERDIT
clicksxchange.com,SITE_INTERDIT
clickxchange.com,SITE_INTERDIT
cometsystems.com,SITE_INTERDIT
cometzone.com,SITE_INTERDIT
counted.com,SITE_INTERDIT
counter.cnw.cz,SITE_INTERDIT
counter.gamespy.com,SITE_INTERDIT
counter.tripod.com,SITE_INTERDIT
countus.editeurjavascript.com,SITE_INTERDIT
criticalmass.com,SITE_INTERDIT
cybererotica.com,SITE_INTERDIT
cybersexent.com,SITE_INTERDIT
cyberthrill.com,SITE_INTERDIT
cz3.clickzs.com,SITE_INTERDIT
cz6.clickzs.com,SITE_INTERDIT
da.ru,SITE_INTERDIT
data.webhancer.com,SITE_INTERDIT
digemon.com,SITE_INTERDIT
digits.com,SITE_INTERDIT
directhit.com,SITE_INTERDIT
domainsystems.com/buy_now,SITE_INTERDIT
doubleclick.com,SITE_INTERDIT
electrongames.com,SITE_INTERDIT
elf.box.sk,SITE_INTERDIT
elitetoplist.com,SITE_INTERDIT
eqantics.freeservers.com,SITE_INTERDIT
escati.linkopp.net,SITE_INTERDIT
eurosponsor.de,SITE_INTERDIT
eval.bizrate.com,SITE_INTERDIT
exchange-it.com,SITE_INTERDIT
exitexchange.com,SITE_INTERDIT
ezgreen.com,SITE_INTERDIT
ezhe.ru,SITE_INTERDIT
f2.ru,SITE_INTERDIT
fastgraphics.com,SITE_INTERDIT
firechicken.com,SITE_INTERDIT
flowgo.com,SITE_INTERDIT
fool.com,SITE_INTERDIT
fr.adserver.yahoo.com,SITE_INTERDIT
free-banners.com,SITE_INTERDIT
freestats.com,SITE_INTERDIT
freetop.ru,SITE_INTERDIT
futuresite.register.com,SITE_INTERDIT
g.adx.cc,SITE_INTERDIT
gator.com,SITE_INTERDIT
gayweb.com,SITE_INTERDIT
getpaid4.com,SITE_INTERDIT
gohip.com,SITE_INTERDIT
gopher.com,SITE_INTERDIT
gozilla.com,SITE_INTERDIT
guid.org,SITE_INTERDIT
headlightsw.com,SITE_INTERDIT
helie.com,SITE_INTERDIT
hitboss.com,SITE_INTERDIT
hitsquad.com,SITE_INTERDIT
hits.ru,SITE_INTERDIT
html.tucows.com,SITE_INTERDIT
hyebiz.net,SITE_INTERDIT
hypercount.com,SITE_INTERDIT
ign.com,SITE_INTERDIT
img.zmedia.com,SITE_INTERDIT
inet-traffic.com,SITE_INTERDIT
internetfuel.com,SITE_INTERDIT
ireklama.cz,SITE_INTERDIT
iv.doubleclick.net,SITE_INTERDIT
j2.ru,SITE_INTERDIT
join.netbroadcaster.com,SITE_INTERDIT
js.zmedia.com,SITE_INTERDIT
krutilka.ru,SITE_INTERDIT
lbn.ru,SITE_INTERDIT
link4link.com,SITE_INTERDIT
linkexchange.ru,SITE_INTERDIT
linkshare.com,SITE_INTERDIT
linkstoyou.com,SITE_INTERDIT
linkworld.ws,SITE_INTERDIT
linux.org.ru/gallery,SITE_INTERDIT
liquidad.narrowcastmedia.com,SITE_INTERDIT
loga.hit-parade.com,SITE_INTERDIT
logp.hit-parade.com,SITE_INTERDIT
logs.sexy-parade.com,SITE_INTERDIT
mafia.ru,SITE_INTERDIT
mail.ru/cgi-bin/splash,SITE_INTERDIT
makingitpay.com,SITE_INTERDIT
m.doubleclick.net,SITE_INTERDIT
mediakit.theonion.com,SITE_INTERDIT
mediaodyssey.com,SITE_INTERDIT
mediaplex.com,SITE_INTERDIT
megacash.de,SITE_INTERDIT
mycometcursor.com,SITE_INTERDIT
n0cgi.distributed.net,SITE_INTERDIT
netdirect.nl,SITE_INTERDIT
netomia.com,SITE_INTERDIT
netzapp.nu,SITE_INTERDIT
nmia.com,SITE_INTERDIT
osp.ru/system/img,SITE_INTERDIT
pcnews.ru/out,SITE_INTERDIT
pegasoweb.com,SITE_INTERDIT
phreedom.org,SITE_INTERDIT
popme.163.com,SITE_INTERDIT
popuptraffic.com,SITE_INTERDIT
pornaddict.com,SITE_INTERDIT
premiumcash.de,SITE_INTERDIT
premiumnetwork.com,SITE_INTERDIT
rambler.ru,SITE_INTERDIT
rankyou.com,SITE_INTERDIT
realnetworks.com,SITE_INTERDIT
reclama.ru,SITE_INTERDIT
reklama.internet.cz,SITE_INTERDIT
reporting.net,SITE_INTERDIT
rg2.com,SITE_INTERDIT
rg7.com,SITE_INTERDIT
rightstats.com,SITE_INTERDIT
sabela.com,SITE_INTERDIT
seawood.org,SITE_INTERDIT
seeq.com/lander.jsp,SITE_INTERDIT
seeq.com/popupwrapper.jsp,SITE_INTERDIT
sexillustrated.com,SITE_INTERDIT
sexlist.com,SITE_INTERDIT
sextracker.com,SITE_INTERDIT
shareasale.com,SITE_INTERDIT
sher.index.hu,SITE_INTERDIT
shout-ads.com,SITE_INTERDIT
sitecentric.com/companysite,SITE_INTERDIT
siterank.hypermart.net,SITE_INTERDIT
sitetracker.com,SITE_INTERDIT
sptimes.com,SITE_INTERDIT
starsads.com,SITE_INTERDIT
static.everyone.net,SITE_INTERDIT
stats.net,SITE_INTERDIT
strategy.com,SITE_INTERDIT
targetnet.com,SITE_INTERDIT
teensexaction.com,SITE_INTERDIT
textlinks.com,SITE_INTERDIT
thecounter.com,SITE_INTERDIT
theozone.tripod.com,SITE_INTERDIT
theregister.co.uk/images,SITE_INTERDIT
theregister.co.uk/media,SITE_INTERDIT
thinknyc.eu-adcenter.net,SITE_INTERDIT
thruport.com,SITE_INTERDIT
tomshardware.com,SITE_INTERDIT
top50.co.uk,SITE_INTERDIT
topping.com.ua,SITE_INTERDIT
topping.od.ua,SITE_INTERDIT
trafficoverdrive.com,SITE_INTERDIT
tribalfusion.com,SITE_INTERDIT
tweaktown.com/images,SITE_INTERDIT
ugo.eu-adcenter.net,SITE_INTERDIT
uncovered.net,SITE_INTERDIT
ushki.ru,SITE_INTERDIT
v3.come.to,SITE_INTERDIT
valueclick.com,SITE_INTERDIT
vg.no/annonser,SITE_INTERDIT
vnu.eu-adcenter.net,SITE_INTERDIT
wamanet.virtualave.net,SITE_INTERDIT
warezlist.com,SITE_INTERDIT
web4friends.com,SITE_INTERDIT
webcamworld.com,SITE_INTERDIT
webclients.net,SITE_INTERDIT
webcounter.goweb.de,SITE_INTERDIT
webhits.de,SITE_INTERDIT
webshots.com,SITE_INTERDIT
websitesponsor.de,SITE_INTERDIT
websponsors.com,SITE_INTERDIT
web-stat.com,SITE_INTERDIT
webstat.net,SITE_INTERDIT
win.mail.ru/cgi-bin/splash,SITE_INTERDIT
worldbannerexchange.com,SITE_INTERDIT
worldbe.com,SITE_INTERDIT
worldprofit.com,SITE_INTERDIT
worldsex.com,SITE_INTERDIT
yandex.ru/gifs,SITE_INTERDIT
zmedia.com/zm,SITE_INTERDIT
EOF
#links2u.com,SITE_INTERDIT


ciImportCaCertificatSSLInLocalStore scribe.ac-test.fr
ciImportCaCertificatSSLInLocalStore proxy.ac-test.fr 3128
update-ca-certificates

exit 0
