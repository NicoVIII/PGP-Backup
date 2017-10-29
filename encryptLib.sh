#!/bin/bash

#TODO: Documentation

function checkFiles {
    local email=$1
    local path=$2

    find $path -maxdepth 1 -type f | while read i
    do
        if [[ $i != *decrypt.sh ]] && [[ $i != *decryptLib.sh ]]; then
            gpg --output "../backup/$i.gpg" --encrypt --recipient $email "$i"
        else
            cp "$i" "../backup/$i"
        fi
    done
}

function handleDir {
    local depth=$1
    local email=$2
    local path=$3

    echo "Handle dir: $path"

    # Create necessary folders
    if [ $path == "." ]; then
        mkdir "../backup"
        mkdir "../tmp"
    else
        mkdir "../backup/$path"
        mkdir "../tmp/$path"
    fi

    # Handle files in directory
    checkFiles $email $path

    # Handle directories in directory
    find $path -maxdepth 1 ! -path $path -type d | while read i
    do
        if [ $depth -gt 0 ]; then
            handleDir $[$depth-1] $email $i
        else
            local oldPath=$PWD
            cd "$path"
            echo "Now in: $path"
            echo "Try to zip: $i"
            folder=$(basename "$i")
            zip -r "$oldPath/../tmp/$i.zip" "./$folder"
            cd "$oldPath"
            echo "Now in: $oldPath"
            gpg --output "../backup/$i.zip.gpg" --encrypt --recipient $email "../tmp/$i.zip"
        fi
    done
}

#Check flags
depth=0
while getopts ":d:h" opt; do
    case $opt in
        d)
            #TODO: check for int
            depth=$OPTARG;;
        h)
            echo "Usage: encryptLib.sh [-d depth]... email"
            exit 0;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1;;
    esac
done
shift $(($OPTIND - 1))

#Parameters
if [ $# -ne 1 ]; then
    echo "Please provide an email to encrypt for as argument."
    exit 1
fi
email=$1

handleDir $depth $email .
echo "Finished encrypting!"
exit 0
