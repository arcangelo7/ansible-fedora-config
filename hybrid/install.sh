#!/bin/bash

if [ -d ~/.config/conky/hybrid/ ]
then
    rm -R ~/.config/conky/hybrid/
    echo 'hybrid uninstalled'
fi

rsync -IrW --stats --exclude={'.git','deploy.sh','install.sh','readme.md','fonts','screenshots','bad-experiment','classic'} $(pwd) ~/.config/conky/
echo 'hybrid installed'