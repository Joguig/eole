DEST=/opt/eclipse/
mkdir "$DEST" 
for depot in   https://git.eclipse.org/r/platform/eclipse.platform.common.git \
               https://git.eclipse.org/r/platform/eclipse.platform.debug.git \
               https://git.eclipse.org/r/platform/eclipse.platform.git \
               https://git.eclipse.org/r/platform/eclipse.platform.releng.aggregator.git \
               https://git.eclipse.org/r/platform/eclipse.platform.releng.buildtools.git \
               https://git.eclipse.org/r/platform/eclipse.platform.releng.git \
               https://git.eclipse.org/r/platform/eclipse.platform.resources.git \
               https://git.eclipse.org/r/platform/eclipse.platform.runtime.git \
               https://git.eclipse.org/r/platform/eclipse.platform.swt.git \
               https://git.eclipse.org/r/platform/eclipse.platform.swt.binaries.git \
               https://git.eclipse.org/r/platform/eclipse.platform.team.git \
               https://git.eclipse.org/r/platform/eclipse.platform.text.git \
               https://git.eclipse.org/r/platform/eclipse.platform.ua.git \
               https://git.eclipse.org/r/platform/eclipse.platform.ui.git \
               https://git.eclipse.org/r/platform/eclipse.platform.ui.tools.git
do
	echo "$depot"
	cd "$DEST" || exit 1
	PROJET="${depot/.git/}"
	PROJET="${PROJET##*/}"
        if [ -d "$DEST/$PROJET" ]
	then
            cd "$DEST/$PROJET"
	    git pull
	else
            git clone "$depot"
	fi
done
