#!/bin/bash
echo '******Starting Encrypt Script******'

function encrypt_creds() {
    adminPwdTmp='/mnt/creds/.adminPwd'
    adminPwd='/config/cloud/openstack/.adminPwd'

    if f5-rest-node /config/cloud/openstack/node_modules/@f5devcentral/f5-cloud-libs/scripts/encryptDataToFile.js \
        --signal 'ENCR_DONE' \
        --data-file "$adminPwdTmp" \
        --out-file "$adminPwd" ; then

        echo 'Successfully encrypted admin password.'
        shred -u -z "$adminPwdTmp"
    else
        echo 'Unable to encrypt admin pwd.'
    fi

    # encrypt additional creds here as needed
}

function main() {
    encrypt_creds
}

main
