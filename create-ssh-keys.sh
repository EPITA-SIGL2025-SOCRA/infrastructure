#!/bin/bash

SSH_KEYS_DIR="ssh_keys"
mkdir -p "$SSH_KEYS_DIR"

if [ -d "$SSH_KEYS_DIR" ]; then
   if [ "$(ls -A $SSH_KEYS_DIR)" ]; then
      echo "Removing keys already in $SSH_KEYS_DIR..."
      rm $SSH_KEYS_DIR/*
   fi
fi
echo "Generate SSH keys from $1..."
while read line; do
   ssh-keygen -C "$line@socra-sigl.fr" -t ed25519 -f ssh_keys/id_$line -N "" -q
   chmod 600 ssh_keys/id_$line.pub
   chmod 700 ssh_keys/id_$line
done < <(tail -n +2 $1)
echo "Done!"
