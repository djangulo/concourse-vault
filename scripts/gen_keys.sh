#!/usr/bin/env bash

##
## Create directory scaffolding and generate certificates.
##


set -o errexit
set -o pipefail
set -o nounset

mkdir -p $(pwd)/traefik-concourse-vault
working_dir=$(pwd)/traefik-concourse-vault

cd $working_dir

# generate necessary directories so the docker volumes don't assign them to root
mkdir -p \
    $working_dir/concourse/keys \
    $working_dir/letsencrypt \
    $working_dir/vault/certs \
    $working_dir/vault/file \
    $working_dir/vault/config \
    $working_dir/postgres-data

#touch $working_dir/letsencrypt/acme.json
#chmod 600 $working_dir/letsencrypt/acme.json

userid=$(id -u)
#--user $userid`
docker run -it --user=$(id -u) -v $working_dir/concourse/keys:/concourse-keys concourse/concourse generate-key -t rsa -f /concourse-keys/session_signing_key
docker run -it --user=$(id -u) -v $working_dir/concourse/keys:/concourse-keys concourse/concourse generate-key -t ssh -f /concourse-keys/tsa_host_key
docker run -it --user=$(id -u) -v $working_dir/concourse/keys:/concourse-keys concourse/concourse generate-key -t ssh -f /concourse-keys/worker_key
sudo chown -R $USER:root $working_dir/concourse

cp $working_dir/concourse/keys/worker_key.pub $working_dir/concourse/keys/authorized_worker_keys

