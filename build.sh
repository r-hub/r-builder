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

function install_software() {
    ./software/software.sh
}

function create_build_scripts() {
    (
        mkdir -p _build
        cp -r simon/* _build/
        cd _build/
        patch -p0 < ../simon.diff
        cd R4
        if [[ ! -e R-devel ]]; then cp -a ../../r-source R-devel; fi
        if [[ ! -e R-4-2-branch ]]; then cp -a ../../r-patched R-4-2-branch; fi
        if [[ ! -e Mac-GUI ]]; then cp -a ../../mac-gui Mac-GUI; fi
        mkdir -p R-devel/.svn/tmp
        mkdir -p Mac-GUI/.svn/tmp
        cp ../../software/tcltk.pkg packaging/
        cp ../../software/texinfo.pkg packaging/
    )
}

function build() {
    (
        cd _build/R4
        export BASE=`pwd`
        export RDIRS="R-4-2-branch"
#        export RDIRS="R-4-2-branch R-devel"
        make
        sudo -E ./nightly
    )
}

function deploy() {
    true
}

function main() {
    install_software
    create_build_scripts
    build
    deploy
}

if [ "$sourced" = "0" ]; then
    set -e
    main
fi

