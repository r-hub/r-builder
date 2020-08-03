#! /bin/bash

sourced=0
if [ -n "$ZSH_EVAL_CONTEXT" ]; then
    case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
    [ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
    (return 0 2>/dev/null) && sourced=1
else
    # All other shells: examine $0 for known shell binary filenames
    # Detects `sh` and `dash`; add additional shell filenames as needed.
    case ${0##*/} in sh|dash) sourced=1;; esac
fi

function install_xquartz() {
    echo "== INSTALLING XQUARTZ ============================="
    (
        set -e
        if (pkgutil --pkgs | grep -q org.macosforge.xquartz.pkg); then
            return;
        fi
        local version=2.7.11
        curl -C - -L -O -f \
            https://dl.bintray.com/xquartz/downloads/XQuartz-${version}.dmg
        sudo hdiutil attach XQuartz-${version}.dmg
        sudo installer -package /Volumes/XQuartz-${version}/XQuartz.pkg \
            -target /
        sudo hdiutil detach /Volumes/XQuartz-${version}
    )
}

function install_basictex() {
    echo "== INSTALLING BasicTex ============================="
    (
        set -e
        curl -L -O \
            http://mirror.ox.ac.uk/sites/ctan.org/systems/mac/mactex/BasicTeX.pkg
        sudo installer -package BasicTeX.pkg -target /
	export PATH=/usr/local/texlive/2020basic/bin/x86_64-darwin/:$PATH
        sudo tlmgr update --self
        sudo tlmgr install cm-super helvetic inconsolata texinfo
     )
}

function main() {
    install_xquartz
    install_basictex
}

if [ "$sourced" = "0" ]; then
    set -e
    main
fi

