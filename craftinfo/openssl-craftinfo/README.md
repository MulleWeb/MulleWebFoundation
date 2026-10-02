# openssl-craftinfo

#### craftinfo to build the openssl library as a mulle-sde dependency

This craftinfo should be fetched automatically, if the name of the dependency is openssl.

This is how you would setup your openssl dependency:

```
mulle-sde dependency add --c --tag 1_1_1j --address openssl 'https://github.com/openssl/openssl/archive/OpenSSL_${MULLE_TAG}.tar.gz' 
mulle-sde dependency set openssl include openssl/ssl.h
mulle-sde dependency set openssl aliases ssl
```

If you don't need it for linux:

```
mulle-sde dependency unmark openssl platform-linux
```
