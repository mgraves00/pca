# pca
## Personal Certificate Authority

## Description
pca is a shell script the allows for the easy creation and maintenance of a small Certificate
Authority.  This script will not replace more professional application.  However its learning
curve is almost 0.

The script makes extensive use of openssl(1).  There are many things to not like about the
openssl cli.  This script tries to hide the rough edges and create a pleasent and uniform expierence.

## Syntax
```
pca 1.8.8 - Personal Certificate Authroity
pca <ca> <command> [options]
Commands:
  <ca> init
  <ca> config list <attr[s] | mac[ros] | pol[icy] | ext[ension] | prog[ram]>
  <ca> config get macro <-key key> <-value>
  <ca> config set macro [-a|-d] <-key key> <-value val>
  <ca> config get attr|pol|ext|prog <-name name> <-key key> <-value>
  <ca> config set attr|pol|ext|prog [-a|-d] <-name name> <-key key> <-value val>
  <ca> config sign <-name name>
  <ca> create root [-name name] [-days #] [-bits #] [-cn name] [-ct x] [-sp x] [-co x] [-or x] [-ou x] [-em x] [ -san val ... ]
  <ca> create crl
  <ca> create key <-name name> [-bits #]
  <ca> create chain
  <ca> create req[uest] <-name name> <-key file | -newkey [#bits]> [-days #] [-cn name] [-co x] [-sp x] [-ct x] [-or x] [-ou x] [-em x] [ -san val ... ]
  <ca> show crl [-issuer] [-hash] [-fingerprint] [-num] [-last] [-next]
  <ca> show req [-name name]
  <ca> show root [-serial] [-expire] [-subject] [-subjecthash] [-issuer] [-issuerhash] [-fingerprint]
  <ca> show cert [-name name] [-serial] [-expire] [-subject] [-subjecthash] [-issuer] [-issuerhash] [-fingerprint] [-client] [-ca]
  <ca> sign <-name name> [-sign] [-days] [-san val ...] [-ext alt_extension]
  <ca> resign <-name name> [-sign] [-days]
  <ca> revoke <-name name | -serial #> [-crl]
  <ca> delete req|key|cert <-name name>
  <ca> export pkcs12 <-name name> <-file name> <-pass -|file:filename|password> [-chain] [-overwrite]
  <ca> export html <-file name> [-overwrite]
  <ca> export cert <-name name> <-file name> [-overwrite] [-chain]
  <ca> import pkcs12 <-name name> <-file name> <-pass -|file:filename|password> [-overwrite]
  <ca> import request <-name name> <-file name> [-overwrite]
```

## Setup
### Simple setup
- Copy the `pca` script into a directory in your path.
- run `pca` to get the above syntax

## Notes
`pca` was designed to be really simple. Yet powerful.  It can manage multiple CA repositories.  After `pca` is installed
just run `pca <ca_name>` to get the above syntax.

### Initialize a CA
This is the first thing you will do.  It only needsd to be done once.
```
pca myca init
```
A new CA will be created.  If the environment variable PCA_ROOT is not set the app defaults to creating the CA in '~/.pca/<ca_name>'.

### Macros, extensions, policies, programs, attributes
Have a look at the pre-built macros, extensions, policies, programs and attributes that have already been created.  They should be
complete enought to get a new CA setup and working without needing to tweak.  But take a look at the settings.  Everything in
there is an `openssl` configuration command. If there is any question about what is valid or not, review the openssl man page.

### Create a root CA
The first certificate you will create is the root CA.
```
pca myca create root -name root-myca -days 3650 -bits 4096 -or 'My Personal CA' -em 'me@example.com'
```

### Create a CRL
Certificate Revocation Lists should be create on a regular cadence.  It can be cron'd.  To create a CRL run:
```
pca myca crl
```
You may also want to setup a web server to distribute the CRL with it's created and updated.  Setting up a web server is outside
the scope of this doc, but be sure to update the PUBLICURL macro.

### Create a Certificate Chain
The create a certificate chain (a file with all the CA certificates in it) run
```
pca myca chain
```

### Create a CA website
This is not really required, but if this CA grows beyond one system, you will want a place to distribute the CRL, the root chain
etc.  `pca` can help with that task by creating a tarball of a static web site that includes a generic index.hml, the root chain,
and the current crl. To create the tarball
```
pca myca export html -file myca-site.tgz -overwrite
```
Once exported you can use the tar command to extract the file(s) you want into your web site path.

### Create a Certificate
To create a new Certificate Signing Request use the folling command.
```
pca myca create request -name firstcert.example.com -newkey -cn firstcert.example.com -san DNS=firstcert.example.com
```
This will create a new CSR with the name you specified.

### View pending CSRs
To see CSRs that have not been signed
```
pca myca show req
```
To see the details of a specific CSR use the `-name <req_name>` flag.

### Sign a request
To sign a request
```
pca myca sign -name firstcert.example.com
```
This will cause the certificate that is listed as the signing certificate (by default it is your root CA) to sign the specificed CSR.
The request will be hidden and a new certificate file will be created with the same name

### View certificates
To view certificates
```
pca myca show cert
```
This will show all certificates that pca knows about and have not been deleted.  To view more details specific the `-name <cert_name>`
command.

### Create PKCS12 (p12/pfx) file
The actually use the certificates you create, you will need the signed certificate, the key (if it was created by `pca`) and a few
other things.  To securely transfer these file the PCKS12 was created.  The extensions of .p12 or .pfx are common but not required.
To create the container
```
pca myca export pkcs12 -name firstcert.example.com -file firstcert.p12 -pass letmein
```
You can either add the password on the command line (understand that the password will be visible by anyone on the system) or you can
specifiy a file to use that contains the password.  This will be the password used to extract the cert and key (and possibly the chain)
from the PKCS12 file.  If you want to include the certificate chain (often a good idea) add the `-chain` flag.  `pca` will not
overwrite and existing file unless you give the `-overwrite` flag.

### Revoking a certificate
You will undoubtly need to revoke many certs for many reasons. Use the `revoke` command
```
pca myca revoke -name firstcert.example.com
```
This will update the CA's database and set the certifice to revoked.  A new CRL should be generated and distributed.  A revoked
certificate is not automatically deleted.  It can still be viewed and even `resigned`.

### Deleting certificate, key, request
To delete a certificate, a key, a request or all of them, use the `delete` command.  This will perminatly delete any related files.
```
pca myca delete all -name firstcert.example.com
```

## Caution / Danger
The `pca` database that contains all the certs, keys, etc is located at PCA_ROOT (by default ~/.pca)  This directory needs to be
protected.  It contains all keys, key passwords, and cert material.  While each key has a unique password the password for that key
is stored next to the key, so it is trival to retreave an unencrypted cert and key.  This is a deliberate design choice because
1) I trust myself... and you should trust yourself... mostly
2) I want this to be simple.  I didn't want to mess with typing a **secure** password just to do **every** activity.

## Companion Applications
There is a companior application called (ACME.cgi)[https://github.com/mgraves00/ACME.cgi] that will allow you to create an RFC8555
compliant ACME server that can issue certificates to standard ACME clients.  This kinda streches the `personal` CA into a `homelab` CA.

## History
This script started life as a Makefile.  Eventually the Makefile limitations were irritating
enough to drive a rewrite.


## Copyright and License
Copyright Michael Graves
Licensed under a 2 clause BSD license.  See [LICENSE.md](LICENSE.md) for details
