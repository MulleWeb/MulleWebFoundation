//
//  MulleCurl+Private.m
//  MulleCurl
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
//  Copyright (c) 2019 Codeon GmbH.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "MulleCurl.h"
#import "MulleCurl+Private.h"

#import "import-private.h"


#ifdef CINIT
# undef CINIT
#endif
#ifdef CURLOPT_LASTENTRY
# undef CURLOPT_LASTENTRY
#endif


#define _STRINGIFY( x)  #x
#define CINIT( na, t, nu) { _STRINGIFY( CURLOPT_ ## na), CURLOPT_ ## na, t }
#define CURLOPT_LASTENTRY  { 0, 0 }



//
// The values are copied from the curl header, we use it to map strings
// to values via a NSMapTable. The curl header is MIT licensed and copyrighted
//
// This table deliberately lists (and maps) deprecated curl options as well,
// so deprecation warnings are suppressed for it.
//
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

static struct mulle_curl_options
{
   char    *name;
   short   value;
   short   type;
} curl_options[] =
{
  /* This is the FILE * or void * the regular output should be written to. */
  CINIT(WRITEDATA, MULLE_CURL_OBJECTPOINT, 1),

  /* The full URL to get/put */
  CINIT(URL, MULLE_CURL_STRINGPOINT, 2),

  /* Port number to connect to, if other than default. */
  CINIT(PORT, MULLE_CURL_LONG, 3),

  /* Name of proxy to use. */
  CINIT(PROXY, MULLE_CURL_STRINGPOINT, 4),

  /* "user:password;options" to use when fetching. */
  CINIT(USERPWD, MULLE_CURL_STRINGPOINT, 5),

  /* "user:password" to use with proxy. */
  CINIT(PROXYUSERPWD, MULLE_CURL_STRINGPOINT, 6),

  /* Range to get, specified as an ASCII string. */
  CINIT(RANGE, MULLE_CURL_STRINGPOINT, 7),

  /* not used */

  /* Specified file stream to upload from (use as input): */
  CINIT(READDATA, MULLE_CURL_OBJECTPOINT, 9),

  /* Buffer to receive error messages in, must be at least CURL_ERROR_SIZE
   * bytes big. */
  CINIT(ERRORBUFFER, MULLE_CURL_OBJECTPOINT, 10),

  /* Function that will be called to store the output (instead of fwrite). The
   * parameters will use fwrite() syntax, make sure to follow them. */
  CINIT(WRITEFUNCTION, MULLE_CURL_FUNCTIONPOINT, 11),

  /* Function that will be called to read the input (instead of fread). The
   * parameters will use fread() syntax, make sure to follow them. */
  CINIT(READFUNCTION, MULLE_CURL_FUNCTIONPOINT, 12),

  /* Time-out the read operation after this amount of seconds */
  CINIT(TIMEOUT, MULLE_CURL_LONG, 13),

  /* If the CURLOPT_INFILE is used, this can be used to inform libcurl about
   * how large the file being sent really is. That allows better error
   * checking and better verifies that the upload was successful. -1 means
   * unknown size.
   *
   * For large file support, there is also a _LARGE version of the key
   * which takes an off_t type, allowing platforms with larger off_t
   * sizes to handle larger files.  See below for INFILESIZE_LARGE.
   */
  CINIT(INFILESIZE, MULLE_CURL_LONG, 14),

  /* POST static input fields. */
  CINIT(POSTFIELDS, MULLE_CURL_OBJECTPOINT, 15),

  /* Set the referrer page (needed by some CGIs) */
  CINIT(REFERER, MULLE_CURL_STRINGPOINT, 16),

  /* Set the FTP PORT string (interface name, named or numerical IP address)
     Use i.e '-' to use default address. */
  CINIT(FTPPORT, MULLE_CURL_STRINGPOINT, 17),

  /* Set the User-Agent string (examined by some CGIs) */
  CINIT(USERAGENT, MULLE_CURL_STRINGPOINT, 18),

  /* If the download receives less than "low speed limit" bytes/second
   * during "low speed time" seconds, the operations is aborted.
   * You could i.e if you have a pretty high speed connection, abort if
   * it is less than 2000 bytes/sec during 20 seconds.
   */

  /* Set the "low speed limit" */
  CINIT(LOW_SPEED_LIMIT, MULLE_CURL_LONG, 19),

  /* Set the "low speed time" */
  CINIT(LOW_SPEED_TIME, MULLE_CURL_LONG, 20),

  /* Set the continuation offset.
   *
   * Note there is also a _LARGE version of this key which uses
   * off_t types, allowing for large file offsets on platforms which
   * use larger-than-32-bit off_t's.  Look below for RESUME_FROM_LARGE.
   */
  CINIT(RESUME_FROM, MULLE_CURL_LONG, 21),

  /* Set cookie in request: */
  CINIT(COOKIE, MULLE_CURL_STRINGPOINT, 22),

  /* This points to a linked list of headers, struct curl_slist kind. This
     list is also used for RTSP (in spite of its name) */
  CINIT(HTTPHEADER, MULLE_CURL_SLISTPOINT, 23),

  /* This points to a linked list of post entries, struct curl_httppost */
#if !CURL_AT_LEAST_VERSION(7,56,0)
  CINIT(HTTPPOST, MULLE_CURL_OBJECTPOINT, 24),
#else
  CINIT(MIMEPOST, MULLE_CURL_OBJECTPOINT, 269),  /* use this instead of HTTPPOST */
#endif

  /* name of the file keeping your private SSL-certificate */
  CINIT(SSLCERT, MULLE_CURL_STRINGPOINT, 25),

  /* password for the SSL or SSH private key */
  CINIT(KEYPASSWD, MULLE_CURL_STRINGPOINT, 26),

  /* send TYPE parameter? */
  CINIT(CRLF, MULLE_CURL_LONG, 27),

  /* send linked-list of QUOTE commands */
  CINIT(QUOTE, MULLE_CURL_SLISTPOINT, 28),

  /* send FILE * or void * to store headers to, if you use a callback it
     is simply passed to the callback unmodified */
  CINIT(HEADERDATA, MULLE_CURL_OBJECTPOINT, 29),

  /* point to a file to read the initial cookies from, also enables
     "cookie awareness" */
  CINIT(COOKIEFILE, MULLE_CURL_STRINGPOINT, 31),

  /* What version to specifically try to use.
     See CURL_SSLVERSION defines below. */
  CINIT(SSLVERSION, MULLE_CURL_LONG, 32),

  /* What kind of HTTP time condition to use, see defines */
  CINIT(TIMECONDITION, MULLE_CURL_LONG, 33),

  /* Time to use with the above condition. Specified in number of seconds
     since 1 Jan 1970 */
  CINIT(TIMEVALUE, MULLE_CURL_LONG, 34),

  /* 35 = OBSOLETE */

  /* Custom request, for customizing the get command like
     HTTP: DELETE, TRACE and others
     FTP: to use a different list command
     */
  CINIT(CUSTOMREQUEST, MULLE_CURL_STRINGPOINT, 36),

  /* FILE handle to use instead of stderr */
  CINIT(STDERR, MULLE_CURL_OBJECTPOINT, 37),

  /* 38 is not used */

  /* send linked-list of post-transfer QUOTE commands */
  CINIT(POSTQUOTE, MULLE_CURL_SLISTPOINT, 39),

  CINIT(OBSOLETE40, MULLE_CURL_OBJECTPOINT, 40), /* OBSOLETE, do not use! */

  CINIT(VERBOSE, MULLE_CURL_LONG, 41),      /* talk a lot */
  CINIT(HEADER, MULLE_CURL_LONG, 42),       /* throw the header out too */
  CINIT(NOPROGRESS, MULLE_CURL_LONG, 43),   /* shut off the progress meter */
  CINIT(NOBODY, MULLE_CURL_LONG, 44),       /* use HEAD to get http document */
  CINIT(FAILONERROR, MULLE_CURL_LONG, 45),  /* no output on http error codes >= 400 */
  CINIT(POST, MULLE_CURL_LONG, 47),         /* HTTP POST method */
  CINIT(DIRLISTONLY, MULLE_CURL_LONG, 48),  /* bare names when listing directories */

  CINIT(APPEND, MULLE_CURL_LONG, 50),       /* Append instead of overwrite on upload! */

  /* Specify whether to read the user+password from the .netrc or the URL.
   * This must be one of the CURL_NETRC_* enums below. */
  CINIT(NETRC, MULLE_CURL_LONG, 51),

  CINIT(FOLLOWLOCATION, MULLE_CURL_LONG, 52),  /* use Location: Luke! */

  CINIT(TRANSFERTEXT, MULLE_CURL_LONG, 53), /* transfer data in text/ASCII format */
#if !CURL_AT_LEAST_VERSION(7,12,1)
  CINIT(PUT, MULLE_CURL_LONG, 54),          /* HTTP PUT */
#else
  CINIT(UPLOAD, MULLE_CURL_LONG, 46),       /* use this instead of PUT */
#endif

  /* 55 = OBSOLETE */

  /* DEPRECATED
   * Function that will be called instead of the internal progress display
   * function. This function should be defined as the curl_progress_callback
   * prototype defines. */
#if !CURL_AT_LEAST_VERSION(7,32,0)
  CINIT(PROGRESSFUNCTION, MULLE_CURL_FUNCTIONPOINT, 56),
#else
  CINIT(XFERINFOFUNCTION, MULLE_CURL_FUNCTIONPOINT, 219),  /* use this instead of PROGRESSFUNCTION */
#endif

  /* Data passed to the CURLOPT_PROGRESSFUNCTION and CURLOPT_XFERINFOFUNCTION
     callbacks */
  CINIT(PROGRESSDATA, MULLE_CURL_OBJECTPOINT, 57),
#define CURLOPT_XFERINFODATA CURLOPT_PROGRESSDATA

  /* We want the referrer field set automatically when following locations */
  CINIT(AUTOREFERER, MULLE_CURL_LONG, 58),

  /* Port of the proxy, can be set in the proxy string as well with:
     "[host]:[port]" */
  CINIT(PROXYPORT, MULLE_CURL_LONG, 59),

  /* size of the POST input data, if strlen() is not good to use */
  CINIT(POSTFIELDSIZE, MULLE_CURL_LONG, 60),

  /* tunnel non-http operations through a HTTP proxy */
  CINIT(HTTPPROXYTUNNEL, MULLE_CURL_LONG, 61),

  /* Set the interface string to use as outgoing network interface */
  CINIT(INTERFACE, MULLE_CURL_STRINGPOINT, 62),

  /* Set the krb4/5 security level, this also enables krb4/5 awareness.  This
   * is a string, 'clear', 'safe', 'confidential' or 'private'.  If the string
   * is set but doesn't match one of these, 'private' will be used.  */
#if !CURL_AT_LEAST_VERSION(8,17,0)
  CINIT(KRBLEVEL, MULLE_CURL_STRINGPOINT, 63),  /* removed in 8.17.0 */
#endif

  /* Set if we should verify the peer in ssl handshake, set 1 to verify. */
  CINIT(SSL_VERIFYPEER, MULLE_CURL_LONG, 64),

  /* The CApath or CAfile used to validate the peer certificate
     this option is used only if SSL_VERIFYPEER is true */
  CINIT(CAINFO, MULLE_CURL_STRINGPOINT, 65),

  /* 66 = OBSOLETE */
  /* 67 = OBSOLETE */

  /* Maximum number of http redirects to follow */
  CINIT(MAXREDIRS, MULLE_CURL_LONG, 68),

  /* Pass a long set to 1 to get the date of the requested document (if
     possible)! Pass a zero to shut it off. */
  CINIT(FILETIME, MULLE_CURL_LONG, 69),

  /* This points to a linked list of telnet options */
  CINIT(TELNETOPTIONS, MULLE_CURL_SLISTPOINT, 70),

  /* Max amount of cached alive connections */
  CINIT(MAXCONNECTS, MULLE_CURL_LONG, 71),

  CINIT(OBSOLETE72, MULLE_CURL_LONG, 72), /* OBSOLETE, do not use! */

  /* 73 = OBSOLETE */

  /* Set to explicitly use a new connection for the upcoming transfer.
     Do not use this unless you're absolutely sure of this, as it makes the
     operation slower and is less friendly for the network. */
  CINIT(FRESH_CONNECT, MULLE_CURL_LONG, 74),

  /* Set to explicitly forbid the upcoming transfer's connection to be re-used
     when done. Do not use this unless you're absolutely sure of this, as it
     makes the operation slower and is less friendly for the network. */
  CINIT(FORBID_REUSE, MULLE_CURL_LONG, 75),

  /* Set to a file name that contains random data for libcurl to use to
     seed the random engine when doing SSL connects. */
#if !CURL_AT_LEAST_VERSION(7,84,0)
  CINIT(RANDOM_FILE, MULLE_CURL_STRINGPOINT, 76),  /* serves no purpose since 7.84.0 */
#endif

  /* Set to the Entropy Gathering Daemon socket pathname */
#if !CURL_AT_LEAST_VERSION(7,84,0)
  CINIT(EGDSOCKET, MULLE_CURL_STRINGPOINT, 77),    /* serves no purpose since 7.84.0 */
#endif

  /* Time-out connect operations after this amount of seconds, if connects are
     OK within this time, then fine... This only aborts the connect phase. */
  CINIT(CONNECTTIMEOUT, MULLE_CURL_LONG, 78),

  /* Function that will be called to store headers (instead of fwrite). The
   * parameters will use fwrite() syntax, make sure to follow them. */
  CINIT(HEADERFUNCTION, MULLE_CURL_FUNCTIONPOINT, 79),

  /* Set this to force the HTTP request to get back to GET. Only really usable
     if POST, PUT or a custom request have been used first.
   */
  CINIT(HTTPGET, MULLE_CURL_LONG, 80),

  /* Set if we should verify the Common name from the peer certificate in ssl
   * handshake, set 1 to check existence, 2 to ensure that it matches the
   * provided hostname. */
  CINIT(SSL_VERIFYHOST, MULLE_CURL_LONG, 81),

  /* Specify which file name to write all known cookies in after completed
     operation. Set file name to "-" (dash) to make it go to stdout. */
  CINIT(COOKIEJAR, MULLE_CURL_STRINGPOINT, 82),

  /* Specify which SSL ciphers to use */
  CINIT(SSL_CIPHER_LIST, MULLE_CURL_STRINGPOINT, 83),

  /* Specify which HTTP version to use! This must be set to one of the
     CURL_HTTP_VERSION* enums set below. */
  CINIT(HTTP_VERSION, MULLE_CURL_LONG, 84),

  /* Specifically switch on or off the FTP engine's use of the EPSV command. By
     default, that one will always be attempted before the more traditional
     PASV command. */
  CINIT(FTP_USE_EPSV, MULLE_CURL_LONG, 85),

  /* type of the file keeping your SSL-certificate ("DER", "PEM", "ENG") */
  CINIT(SSLCERTTYPE, MULLE_CURL_STRINGPOINT, 86),

  /* name of the file keeping your private SSL-key */
  CINIT(SSLKEY, MULLE_CURL_STRINGPOINT, 87),

  /* type of the file keeping your private SSL-key ("DER", "PEM", "ENG") */
  CINIT(SSLKEYTYPE, MULLE_CURL_STRINGPOINT, 88),

  /* crypto engine for the SSL-sub system */
  CINIT(SSLENGINE, MULLE_CURL_STRINGPOINT, 89),

  /* set the crypto engine for the SSL-sub system as default
     the param has no meaning...
   */
  CINIT(SSLENGINE_DEFAULT, MULLE_CURL_LONG, 90),

  /* Non-zero value means to use the global dns cache */
#if !CURL_AT_LEAST_VERSION(7,11,1)
  CINIT(DNS_USE_GLOBAL_CACHE, MULLE_CURL_LONG, 91), /* DEPRECATED, do not use! */
#else
  CINIT(SHARE, MULLE_CURL_OBJECTPOINT, 100),  /* use this instead of DNS_USE_GLOBAL_CACHE */
#endif

  /* DNS cache timeout */
  CINIT(DNS_CACHE_TIMEOUT, MULLE_CURL_LONG, 92),

  /* send linked-list of pre-transfer QUOTE commands */
  CINIT(PREQUOTE, MULLE_CURL_SLISTPOINT, 93),

  /* set the debug function */
  CINIT(DEBUGFUNCTION, MULLE_CURL_FUNCTIONPOINT, 94),

  /* set the data for the debug function */
  CINIT(DEBUGDATA, MULLE_CURL_OBJECTPOINT, 95),

  /* mark this as start of a cookie session */
  CINIT(COOKIESESSION, MULLE_CURL_LONG, 96),

  /* The CApath directory used to validate the peer certificate
     this option is used only if SSL_VERIFYPEER is true */
  CINIT(CAPATH, MULLE_CURL_STRINGPOINT, 97),

  /* Instruct libcurl to use a smaller receive buffer */
  CINIT(BUFFERSIZE, MULLE_CURL_LONG, 98),

  /* Instruct libcurl to not use any signal/alarm handlers, even when using
     timeouts. This option is useful for multi-threaded applications.
     See libcurl-the-guide for more background information. */
  CINIT(NOSIGNAL, MULLE_CURL_LONG, 99),

  /* Provide a CURLShare for mutexing non-ts data */

  /* indicates type of proxy. accepted values are CURLPROXY_HTTP (default),
     CURLPROXY_HTTPS, CURLPROXY_SOCKS4, CURLPROXY_SOCKS4A and
     CURLPROXY_SOCKS5. */
  CINIT(PROXYTYPE, MULLE_CURL_LONG, 101),

  /* Set the Accept-Encoding string. Use this to tell a server you would like
     the response to be compressed. Before 7.21.6, this was known as
     CURLOPT_ENCODING */
  CINIT(ACCEPT_ENCODING, MULLE_CURL_STRINGPOINT, 102),

  /* Set pointer to private data */
  CINIT(PRIVATE, MULLE_CURL_OBJECTPOINT, 103),

  /* Set aliases for HTTP 200 in the HTTP Response header */
  CINIT(HTTP200ALIASES, MULLE_CURL_SLISTPOINT, 104),

  /* Continue to send authentication (user+password) when following locations,
     even when hostname changed. This can potentially send off the name
     and password to whatever host the server decides. */
  CINIT(UNRESTRICTED_AUTH, MULLE_CURL_LONG, 105),

  /* Specifically switch on or off the FTP engine's use of the EPRT command (
     it also disables the LPRT attempt). By default, those ones will always be
     attempted before the good old traditional PORT command. */
  CINIT(FTP_USE_EPRT, MULLE_CURL_LONG, 106),

  /* Set this to a bitmask value to enable the particular authentications
     methods you like. Use this in combination with CURLOPT_USERPWD.
     Note that setting multiple bits may cause extra network round-trips. */
  CINIT(HTTPAUTH, MULLE_CURL_LONG, 107),

  /* Set the ssl context callback function, currently only for OpenSSL or
     WolfSSL ssl_ctx, or mbedTLS mbedtls_ssl_config in the second argument.
     The function must match the curl_ssl_ctx_callback prototype. */
  CINIT(SSL_CTX_FUNCTION, MULLE_CURL_FUNCTIONPOINT, 108),

  /* Set the userdata for the ssl context callback function's third
     argument */
  CINIT(SSL_CTX_DATA, MULLE_CURL_OBJECTPOINT, 109),

  /* FTP Option that causes missing dirs to be created on the remote server.
     In 7.19.4 we introduced the convenience enums for this option using the
     CURLFTP_CREATE_DIR prefix.
  */
  CINIT(FTP_CREATE_MISSING_DIRS, MULLE_CURL_LONG, 110),

  /* Set this to a bitmask value to enable the particular authentications
     methods you like. Use this in combination with CURLOPT_PROXYUSERPWD.
     Note that setting multiple bits may cause extra network round-trips. */
  CINIT(PROXYAUTH, MULLE_CURL_LONG, 111),

  /* FTP option that changes the timeout, in seconds, associated with
     getting a response.  This is different from transfer timeout time and
     essentially places a demand on the FTP server to acknowledge commands
     in a timely manner. */
  CINIT(FTP_RESPONSE_TIMEOUT, MULLE_CURL_LONG, 112),
#define CURLOPT_SERVER_RESPONSE_TIMEOUT CURLOPT_FTP_RESPONSE_TIMEOUT

  /* Set this option to one of the CURL_IPRESOLVE_* defines (see below) to
     tell libcurl to resolve names to those IP versions only. This only has
     affect on systems with support for more than one, i.e IPv4 _and_ IPv6. */
  CINIT(IPRESOLVE, MULLE_CURL_LONG, 113),

  /* Set this option to limit the size of a file that will be downloaded from
     an HTTP or FTP server.
     Note there is also _LARGE version which adds large file support for
     platforms which have larger off_t sizes.  See MAXFILESIZE_LARGE below. */
  CINIT(MAXFILESIZE, MULLE_CURL_LONG, 114),

  /* See the comment for INFILESIZE above, but in short, specifies
   * the size of the file being uploaded.  -1 means unknown.
   */
  CINIT(INFILESIZE_LARGE, MULLE_CURL_OFF_T, 115),

  /* Sets the continuation offset.  There is also a LONG version of this;
   * look above for RESUME_FROM.
   */
  CINIT(RESUME_FROM_LARGE, MULLE_CURL_OFF_T, 116),

  /* Sets the maximum size of data that will be downloaded from
   * an HTTP or FTP server.  See MAXFILESIZE above for the LONG version.
   */
  CINIT(MAXFILESIZE_LARGE, MULLE_CURL_OFF_T, 117),

  /* Set this option to the file name of your .netrc file you want libcurl
     to parse (using the CURLOPT_NETRC option). If not set, libcurl will do
     a poor attempt to find the user's home directory and check for a .netrc
     file in there. */
  CINIT(NETRC_FILE, MULLE_CURL_STRINGPOINT, 118),

  /* Enable SSL/TLS for FTP, pick one of:
     CURLUSESSL_TRY     - try using SSL, proceed anyway otherwise
     CURLUSESSL_CONTROL - SSL for the control connection or fail
     CURLUSESSL_ALL     - SSL for all communication or fail
  */
  CINIT(USE_SSL, MULLE_CURL_LONG, 119),

  /* The _LARGE version of the standard POSTFIELDSIZE option */
  CINIT(POSTFIELDSIZE_LARGE, MULLE_CURL_OFF_T, 120),

  /* Enable/disable the TCP Nagle algorithm */
  CINIT(TCP_NODELAY, MULLE_CURL_LONG, 121),

  /* 122 OBSOLETE, used in 7.12.3. Gone in 7.13.0 */
  /* 123 OBSOLETE. Gone in 7.16.0 */
  /* 124 OBSOLETE, used in 7.12.3. Gone in 7.13.0 */
  /* 125 OBSOLETE, used in 7.12.3. Gone in 7.13.0 */
  /* 126 OBSOLETE, used in 7.12.3. Gone in 7.13.0 */
  /* 127 OBSOLETE. Gone in 7.16.0 */
  /* 128 OBSOLETE. Gone in 7.16.0 */

  /* When FTP over SSL/TLS is selected (with CURLOPT_USE_SSL), this option
     can be used to change libcurl's default action which is to first try
     "AUTH SSL" and then "AUTH TLS" in this order, and proceed when a OK
     response has been received.
     Available parameters are:
     CURLFTPAUTH_DEFAULT - let libcurl decide
     CURLFTPAUTH_SSL     - try "AUTH SSL" first, then TLS
     CURLFTPAUTH_TLS     - try "AUTH TLS" first, then SSL
  */
  CINIT(FTPSSLAUTH, MULLE_CURL_LONG, 129),

#if !CURL_AT_LEAST_VERSION(7,18,0)
  CINIT(IOCTLFUNCTION, MULLE_CURL_FUNCTIONPOINT, 130),
  CINIT(IOCTLDATA, MULLE_CURL_OBJECTPOINT, 131),
#else
  CINIT(SEEKFUNCTION, MULLE_CURL_FUNCTIONPOINT, 167),   /* use this instead of IOCTLFUNCTION */
  CINIT(SEEKDATA, MULLE_CURL_OBJECTPOINT, 168),         /* use this instead of IOCTLDATA */
#endif

  /* 132 OBSOLETE. Gone in 7.16.0 */
  /* 133 OBSOLETE. Gone in 7.16.0 */

  /* zero terminated string for pass on to the FTP server when asked for
     "account" info */
  CINIT(FTP_ACCOUNT, MULLE_CURL_STRINGPOINT, 134),

  /* feed cookie into cookie engine */
  CINIT(COOKIELIST, MULLE_CURL_STRINGPOINT, 135),

  /* ignore Content-Length */
  CINIT(IGNORE_CONTENT_LENGTH, MULLE_CURL_LONG, 136),

  /* Set to non-zero to skip the IP address received in a 227 PASV FTP server
     response. Typically used for FTP-SSL purposes but is not restricted to
     that. libcurl will then instead use the same IP address it used for the
     control connection. */
  CINIT(FTP_SKIP_PASV_IP, MULLE_CURL_LONG, 137),

  /* Select "file method" to use when doing FTP, see the curl_ftpmethod
     above. */
  CINIT(FTP_FILEMETHOD, MULLE_CURL_LONG, 138),

  /* Local port number to bind the socket to */
  CINIT(LOCALPORT, MULLE_CURL_LONG, 139),

  /* Number of ports to try, including the first one set with LOCALPORT.
     Thus, setting it to 1 will make no additional attempts but the first.
  */
  CINIT(LOCALPORTRANGE, MULLE_CURL_LONG, 140),

  /* no transfer, set up connection and let application use the socket by
     extracting it with CURLINFO_LASTSOCKET */
  CINIT(CONNECT_ONLY, MULLE_CURL_LONG, 141),

  /* Function that will be called to convert from the
     network encoding (instead of using the iconv calls in libcurl) */
#if !CURL_AT_LEAST_VERSION(7,82,0)
  CINIT(CONV_FROM_NETWORK_FUNCTION, MULLE_CURL_FUNCTIONPOINT, 142),  /* serves no purpose since 7.82.0 */
#endif

  /* Function that will be called to convert to the
     network encoding (instead of using the iconv calls in libcurl) */
#if !CURL_AT_LEAST_VERSION(7,82,0)
  CINIT(CONV_TO_NETWORK_FUNCTION, MULLE_CURL_FUNCTIONPOINT, 143),    /* serves no purpose since 7.82.0 */
#endif

  /* Function that will be called to convert from UTF8
     (instead of using the iconv calls in libcurl)
     Note that this is used only for SSL certificate processing */
#if !CURL_AT_LEAST_VERSION(7,82,0)
  CINIT(CONV_FROM_UTF8_FUNCTION, MULLE_CURL_FUNCTIONPOINT, 144),     /* serves no purpose since 7.82.0 */
#endif

  /* if the connection proceeds too quickly then need to slow it down */
  /* limit-rate: maximum number of bytes per second to send or receive */
  CINIT(MAX_SEND_SPEED_LARGE, MULLE_CURL_OFF_T, 145),
  CINIT(MAX_RECV_SPEED_LARGE, MULLE_CURL_OFF_T, 146),

  /* Pointer to command string to send if USER/PASS fails. */
  CINIT(FTP_ALTERNATIVE_TO_USER, MULLE_CURL_STRINGPOINT, 147),

  /* callback function for setting socket options */
  CINIT(SOCKOPTFUNCTION, MULLE_CURL_FUNCTIONPOINT, 148),
  CINIT(SOCKOPTDATA, MULLE_CURL_OBJECTPOINT, 149),

  /* set to 0 to disable session ID re-use for this transfer, default is
     enabled (== 1) */
  CINIT(SSL_SESSIONID_CACHE, MULLE_CURL_LONG, 150),

  /* allowed SSH authentication methods */
  CINIT(SSH_AUTH_TYPES, MULLE_CURL_LONG, 151),

  /* Used by scp/sftp to do public/private key authentication */
  CINIT(SSH_PUBLIC_KEYFILE, MULLE_CURL_STRINGPOINT, 152),
  CINIT(SSH_PRIVATE_KEYFILE, MULLE_CURL_STRINGPOINT, 153),

  /* Send CCC (Clear Command Channel) after authentication */
  CINIT(FTP_SSL_CCC, MULLE_CURL_LONG, 154),

  /* Same as TIMEOUT and CONNECTTIMEOUT, but with ms resolution */
  CINIT(TIMEOUT_MS, MULLE_CURL_LONG, 155),
  CINIT(CONNECTTIMEOUT_MS, MULLE_CURL_LONG, 156),

  /* set to zero to disable the libcurl's decoding and thus pass the raw body
     data to the application even when it is encoded/compressed */
  CINIT(HTTP_TRANSFER_DECODING, MULLE_CURL_LONG, 157),
  CINIT(HTTP_CONTENT_DECODING, MULLE_CURL_LONG, 158),

  /* Permission used when creating new files and directories on the remote
     server for protocols that support it, SFTP/SCP/FILE */
  CINIT(NEW_FILE_PERMS, MULLE_CURL_LONG, 159),
  CINIT(NEW_DIRECTORY_PERMS, MULLE_CURL_LONG, 160),

  /* Set the behaviour of POST when redirecting. Values must be set to one
     of CURL_REDIR* defines below. This used to be called CURLOPT_POST301 */
  CINIT(POSTREDIR, MULLE_CURL_LONG, 161),

  /* used by scp/sftp to verify the host's public key */
  CINIT(SSH_HOST_PUBLIC_KEY_MD5, MULLE_CURL_STRINGPOINT, 162),

  /* Callback function for opening socket (instead of socket(2)). Optionally,
     callback is able change the address or refuse to connect returning
     CURL_SOCKET_BAD.  The callback should have type
     curl_opensocket_callback */
  CINIT(OPENSOCKETFUNCTION, MULLE_CURL_FUNCTIONPOINT, 163),
  CINIT(OPENSOCKETDATA, MULLE_CURL_OBJECTPOINT, 164),

  /* POST volatile input fields. */
  CINIT(COPYPOSTFIELDS, MULLE_CURL_OBJECTPOINT, 165),

  /* set transfer mode (;type=<a|i>) when doing FTP via an HTTP proxy */
  CINIT(PROXY_TRANSFER_MODE, MULLE_CURL_LONG, 166),

  /* Callback function for seeking in the input stream */

  /* CRL file */
  CINIT(CRLFILE, MULLE_CURL_STRINGPOINT, 169),

  /* Issuer certificate */
  CINIT(ISSUERCERT, MULLE_CURL_STRINGPOINT, 170),

  /* (IPv6) Address scope */
  CINIT(ADDRESS_SCOPE, MULLE_CURL_LONG, 171),

  /* Collect certificate chain info and allow it to get retrievable with
     CURLINFO_CERTINFO after the transfer is complete. */
  CINIT(CERTINFO, MULLE_CURL_LONG, 172),

  /* "name" and "pwd" to use when fetching. */
  CINIT(USERNAME, MULLE_CURL_STRINGPOINT, 173),
  CINIT(PASSWORD, MULLE_CURL_STRINGPOINT, 174),

    /* "name" and "pwd" to use with Proxy when fetching. */
  CINIT(PROXYUSERNAME, MULLE_CURL_STRINGPOINT, 175),
  CINIT(PROXYPASSWORD, MULLE_CURL_STRINGPOINT, 176),

  /* Comma separated list of hostnames defining no-proxy zones. These should
     match both hostnames directly, and hostnames within a domain. For
     example, local.com will match local.com and www.local.com, but NOT
     notlocal.com or www.notlocal.com. For compatibility with other
     implementations of this, .local.com will be considered to be the same as
     local.com. A single * is the only valid wildcard, and effectively
     disables the use of proxy. */
  CINIT(NOPROXY, MULLE_CURL_STRINGPOINT, 177),

  /* block size for TFTP transfers */
  CINIT(TFTP_BLKSIZE, MULLE_CURL_LONG, 178),

  /* Socks Service */
#if !CURL_AT_LEAST_VERSION(7,49,0)
  CINIT(SOCKS5_GSSAPI_SERVICE, MULLE_CURL_STRINGPOINT, 179), /* DEPRECATED, do not use! */
#else
  CINIT(PROXY_SERVICE_NAME, MULLE_CURL_STRINGPOINT, 235),    /* use this instead of SOCKS5_GSSAPI_SERVICE */
#endif

  /* Socks Service */
  CINIT(SOCKS5_GSSAPI_NEC, MULLE_CURL_LONG, 180),

  /* set the bitmask for the protocols that are allowed to be used for the
     transfer, which thus helps the app which takes URLs from users or other
     external inputs and want to restrict what protocol(s) to deal
     with. Defaults to CURLPROTO_ALL. */
#if !CURL_AT_LEAST_VERSION(7,85,0)
  CINIT(PROTOCOLS, MULLE_CURL_LONG, 181),
#else
  CINIT(PROTOCOLS_STR, MULLE_CURL_STRINGPOINT, 318),          /* use this instead of PROTOCOLS */
#endif

  /* set the bitmask for the protocols that libcurl is allowed to follow to,
     as a subset of the CURLOPT_PROTOCOLS ones. That means the protocol needs
     to be set in both bitmasks to be allowed to get redirected to. */
#if !CURL_AT_LEAST_VERSION(7,85,0)
  CINIT(REDIR_PROTOCOLS, MULLE_CURL_LONG, 182),
#else
  CINIT(REDIR_PROTOCOLS_STR, MULLE_CURL_STRINGPOINT, 319),    /* use this instead of REDIR_PROTOCOLS */
#endif

  /* set the SSH knownhost file name to use */
  CINIT(SSH_KNOWNHOSTS, MULLE_CURL_STRINGPOINT, 183),

  /* set the SSH host key callback, must point to a curl_sshkeycallback
     function */
  CINIT(SSH_KEYFUNCTION, MULLE_CURL_FUNCTIONPOINT, 184),

  /* set the SSH host key callback custom pointer */
  CINIT(SSH_KEYDATA, MULLE_CURL_OBJECTPOINT, 185),

  /* set the SMTP mail originator */
  CINIT(MAIL_FROM, MULLE_CURL_STRINGPOINT, 186),

  /* set the list of SMTP mail receiver(s) */
  CINIT(MAIL_RCPT, MULLE_CURL_SLISTPOINT, 187),

  /* FTP: send PRET before PASV */
  CINIT(FTP_USE_PRET, MULLE_CURL_LONG, 188),

  /* RTSP request method (OPTIONS, SETUP, PLAY, etc...) */
  CINIT(RTSP_REQUEST, MULLE_CURL_LONG, 189),

  /* The RTSP session identifier */
  CINIT(RTSP_SESSION_ID, MULLE_CURL_STRINGPOINT, 190),

  /* The RTSP stream URI */
  CINIT(RTSP_STREAM_URI, MULLE_CURL_STRINGPOINT, 191),

  /* The Transport: header to use in RTSP requests */
  CINIT(RTSP_TRANSPORT, MULLE_CURL_STRINGPOINT, 192),

  /* Manually initialize the client RTSP CSeq for this handle */
  CINIT(RTSP_CLIENT_CSEQ, MULLE_CURL_LONG, 193),

  /* Manually initialize the server RTSP CSeq for this handle */
  CINIT(RTSP_SERVER_CSEQ, MULLE_CURL_LONG, 194),

  /* The stream to pass to INTERLEAVEFUNCTION. */
  CINIT(INTERLEAVEDATA, MULLE_CURL_OBJECTPOINT, 195),

  /* Let the application define a custom write method for RTP data */
  CINIT(INTERLEAVEFUNCTION, MULLE_CURL_FUNCTIONPOINT, 196),

  /* Turn on wildcard matching */
  CINIT(WILDCARDMATCH, MULLE_CURL_LONG, 197),

  /* Directory matching callback called before downloading of an
     individual file (chunk) started */
  CINIT(CHUNK_BGN_FUNCTION, MULLE_CURL_FUNCTIONPOINT, 198),

  /* Directory matching callback called after the file (chunk)
     was downloaded, or skipped */
  CINIT(CHUNK_END_FUNCTION, MULLE_CURL_FUNCTIONPOINT, 199),

  /* Change match (fnmatch-like) callback for wildcard matching */
  CINIT(FNMATCH_FUNCTION, MULLE_CURL_FUNCTIONPOINT, 200),

  /* Let the application define custom chunk data pointer */
  CINIT(CHUNK_DATA, MULLE_CURL_OBJECTPOINT, 201),

  /* FNMATCH_FUNCTION user pointer */
  CINIT(FNMATCH_DATA, MULLE_CURL_OBJECTPOINT, 202),

  /* send linked-list of name:port:address sets */
  CINIT(RESOLVE, MULLE_CURL_SLISTPOINT, 203),

  /* Set a username for authenticated TLS */
  CINIT(TLSAUTH_USERNAME, MULLE_CURL_STRINGPOINT, 204),

  /* Set a password for authenticated TLS */
  CINIT(TLSAUTH_PASSWORD, MULLE_CURL_STRINGPOINT, 205),

  /* Set authentication type for authenticated TLS */
  CINIT(TLSAUTH_TYPE, MULLE_CURL_STRINGPOINT, 206),

  /* Set to 1 to enable the "TE:" header in HTTP requests to ask for
     compressed transfer-encoded responses. Set to 0 to disable the use of TE:
     in outgoing requests. The current default is 0, but it might change in a
     future libcurl release.
     libcurl will ask for the compressed methods it knows of, and if that
     isn't any, it will not ask for transfer-encoding at all even if this
     option is set to 1.
  */
  CINIT(TRANSFER_ENCODING, MULLE_CURL_LONG, 207),

  /* Callback function for closing socket (instead of close(2)). The callback
     should have type curl_closesocket_callback */
  CINIT(CLOSESOCKETFUNCTION, MULLE_CURL_FUNCTIONPOINT, 208),
  CINIT(CLOSESOCKETDATA, MULLE_CURL_OBJECTPOINT, 209),

  /* allow GSSAPI credential delegation */
  CINIT(GSSAPI_DELEGATION, MULLE_CURL_LONG, 210),

  /* Set the name servers to use for DNS resolution */
  CINIT(DNS_SERVERS, MULLE_CURL_STRINGPOINT, 211),

  /* Time-out accept operations (currently for FTP only) after this amount
     of milliseconds. */
  CINIT(ACCEPTTIMEOUT_MS, MULLE_CURL_LONG, 212),

  /* Set TCP keepalive */
  CINIT(TCP_KEEPALIVE, MULLE_CURL_LONG, 213),

  /* non-universal keepalive knobs (Linux, AIX, HP-UX, more) */
  CINIT(TCP_KEEPIDLE, MULLE_CURL_LONG, 214),
  CINIT(TCP_KEEPINTVL, MULLE_CURL_LONG, 215),

  /* Enable/disable specific SSL features with a bitmask, see CURLSSLOPT_* */
  CINIT(SSL_OPTIONS, MULLE_CURL_LONG, 216),

  /* Set the SMTP auth originator */
  CINIT(MAIL_AUTH, MULLE_CURL_STRINGPOINT, 217),

  /* Enable/disable SASL initial response */
  CINIT(SASL_IR, MULLE_CURL_LONG, 218),

  /* Function that will be called instead of the internal progress display
   * function. This function should be defined as the curl_xferinfo_callback
   * prototype defines. (Deprecates CURLOPT_PROGRESSFUNCTION) */
  CINIT(XFERINFOFUNCTION, MULLE_CURL_FUNCTIONPOINT, 219),

  /* The XOAUTH2 bearer token */
  CINIT(XOAUTH2_BEARER, MULLE_CURL_STRINGPOINT, 220),

  /* Set the interface string to use as outgoing network
   * interface for DNS requests.
   * Only supported by the c-ares DNS backend */
  CINIT(DNS_INTERFACE, MULLE_CURL_STRINGPOINT, 221),

  /* Set the local IPv4 address to use for outgoing DNS requests.
   * Only supported by the c-ares DNS backend */
  CINIT(DNS_LOCAL_IP4, MULLE_CURL_STRINGPOINT, 222),

  /* Set the local IPv6 address to use for outgoing DNS requests.
   * Only supported by the c-ares DNS backend */
  CINIT(DNS_LOCAL_IP6, MULLE_CURL_STRINGPOINT, 223),

  /* Set authentication options directly */
  CINIT(LOGIN_OPTIONS, MULLE_CURL_STRINGPOINT, 224),

  /* Enable/disable TLS NPN extension (http2 over ssl might fail without) */
#if !CURL_AT_LEAST_VERSION(7,86,0)
  CINIT(SSL_ENABLE_NPN, MULLE_CURL_LONG, 225),                /* has no function since 7.86.0 */
#endif

  /* Enable/disable TLS ALPN extension (http2 over ssl might fail without) */
  CINIT(SSL_ENABLE_ALPN, MULLE_CURL_LONG, 226),

  /* Time to wait for a response to a HTTP request containing an
   * Expect: 100-continue header before sending the data anyway. */
  CINIT(EXPECT_100_TIMEOUT_MS, MULLE_CURL_LONG, 227),

  /* This points to a linked list of headers used for proxy requests only,
     struct curl_slist kind */
  CINIT(PROXYHEADER, MULLE_CURL_SLISTPOINT, 228),

  /* Pass in a bitmask of "header options" */
  CINIT(HEADEROPT, MULLE_CURL_LONG, 229),

  /* The public key in DER form used to validate the peer public key
     this option is used only if SSL_VERIFYPEER is true */
  CINIT(PINNEDPUBLICKEY, MULLE_CURL_STRINGPOINT, 230),

  /* Path to Unix domain socket */
  CINIT(UNIX_SOCKET_PATH, MULLE_CURL_STRINGPOINT, 231),

  /* Set if we should verify the certificate status. */
  CINIT(SSL_VERIFYSTATUS, MULLE_CURL_LONG, 232),

  /* Set if we should enable TLS false start. */
#if !CURL_AT_LEAST_VERSION(8,15,0)
  CINIT(SSL_FALSESTART, MULLE_CURL_LONG, 233),                /* has no function since 8.15.0 */
#endif

  /* Do not squash dot-dot sequences */
  CINIT(PATH_AS_IS, MULLE_CURL_LONG, 234),

  /* Proxy Service Name */

  /* Service Name */
  CINIT(SERVICE_NAME, MULLE_CURL_STRINGPOINT, 236),

  /* Wait/don't wait for pipe/mutex to clarify */
  CINIT(PIPEWAIT, MULLE_CURL_LONG, 237),

  /* Set the protocol used when curl is given a URL without a protocol */
  CINIT(DEFAULT_PROTOCOL, MULLE_CURL_STRINGPOINT, 238),

  /* Set stream weight, 1 - 256 (default is 16) */
  CINIT(STREAM_WEIGHT, MULLE_CURL_LONG, 239),

  /* Set stream dependency on another CURL handle */
  CINIT(STREAM_DEPENDS, MULLE_CURL_OBJECTPOINT, 240),

  /* Set E-xclusive stream dependency on another CURL handle */
  CINIT(STREAM_DEPENDS_E, MULLE_CURL_OBJECTPOINT, 241),

  /* Do not send any tftp option requests to the server */
  CINIT(TFTP_NO_OPTIONS, MULLE_CURL_LONG, 242),

  /* Linked-list of host:port:connect-to-host:connect-to-port,
     overrides the URL's host:port (only for the network layer) */
  CINIT(CONNECT_TO, MULLE_CURL_SLISTPOINT, 243),

  /* Set TCP Fast Open */
  CINIT(TCP_FASTOPEN, MULLE_CURL_LONG, 244),

  /* Continue to send data if the server responds early with an
   * HTTP status code >= 300 */
  CINIT(KEEP_SENDING_ON_ERROR, MULLE_CURL_LONG, 245),

  /* The CApath or CAfile used to validate the proxy certificate
     this option is used only if PROXY_SSL_VERIFYPEER is true */
  CINIT(PROXY_CAINFO, MULLE_CURL_STRINGPOINT, 246),

  /* The CApath directory used to validate the proxy certificate
     this option is used only if PROXY_SSL_VERIFYPEER is true */
  CINIT(PROXY_CAPATH, MULLE_CURL_STRINGPOINT, 247),

  /* Set if we should verify the proxy in ssl handshake,
     set 1 to verify. */
  CINIT(PROXY_SSL_VERIFYPEER, MULLE_CURL_LONG, 248),

  /* Set if we should verify the Common name from the proxy certificate in ssl
   * handshake, set 1 to check existence, 2 to ensure that it matches
   * the provided hostname. */
  CINIT(PROXY_SSL_VERIFYHOST, MULLE_CURL_LONG, 249),

  /* What version to specifically try to use for proxy.
     See CURL_SSLVERSION defines below. */
  CINIT(PROXY_SSLVERSION, MULLE_CURL_LONG, 250),

  /* Set a username for authenticated TLS for proxy */
  CINIT(PROXY_TLSAUTH_USERNAME, MULLE_CURL_STRINGPOINT, 251),

  /* Set a password for authenticated TLS for proxy */
  CINIT(PROXY_TLSAUTH_PASSWORD, MULLE_CURL_STRINGPOINT, 252),

  /* Set authentication type for authenticated TLS for proxy */
  CINIT(PROXY_TLSAUTH_TYPE, MULLE_CURL_STRINGPOINT, 253),

  /* name of the file keeping your private SSL-certificate for proxy */
  CINIT(PROXY_SSLCERT, MULLE_CURL_STRINGPOINT, 254),

  /* type of the file keeping your SSL-certificate ("DER", "PEM", "ENG") for
     proxy */
  CINIT(PROXY_SSLCERTTYPE, MULLE_CURL_STRINGPOINT, 255),

  /* name of the file keeping your private SSL-key for proxy */
  CINIT(PROXY_SSLKEY, MULLE_CURL_STRINGPOINT, 256),

  /* type of the file keeping your private SSL-key ("DER", "PEM", "ENG") for
     proxy */
  CINIT(PROXY_SSLKEYTYPE, MULLE_CURL_STRINGPOINT, 257),

  /* password for the SSL private key for proxy */
  CINIT(PROXY_KEYPASSWD, MULLE_CURL_STRINGPOINT, 258),

  /* Specify which SSL ciphers to use for proxy */
  CINIT(PROXY_SSL_CIPHER_LIST, MULLE_CURL_STRINGPOINT, 259),

  /* CRL file for proxy */
  CINIT(PROXY_CRLFILE, MULLE_CURL_STRINGPOINT, 260),

  /* Enable/disable specific SSL features with a bitmask for proxy, see
     CURLSSLOPT_* */
  CINIT(PROXY_SSL_OPTIONS, MULLE_CURL_LONG, 261),

  /* Name of pre proxy to use. */
  CINIT(PRE_PROXY, MULLE_CURL_STRINGPOINT, 262),

  /* The public key in DER form used to validate the proxy public key
     this option is used only if PROXY_SSL_VERIFYPEER is true */
  CINIT(PROXY_PINNEDPUBLICKEY, MULLE_CURL_STRINGPOINT, 263),

  /* Path to an abstract Unix domain socket */
  CINIT(ABSTRACT_UNIX_SOCKET, MULLE_CURL_STRINGPOINT, 264),

  /* Suppress proxy CONNECT response headers from user callbacks */
  CINIT(SUPPRESS_CONNECT_HEADERS, MULLE_CURL_LONG, 265),

  /* The request target, instead of extracted from the URL */
  CINIT(REQUEST_TARGET, MULLE_CURL_STRINGPOINT, 266),

  /* bitmask of allowed auth methods for connections to SOCKS5 proxies */
  CINIT(SOCKS5_AUTH, MULLE_CURL_LONG, 267),

  /* Enable/disable SSH compression */
  CINIT(SSH_COMPRESSION, MULLE_CURL_LONG, 268),

  /* Post MIME data. */

  /* Time to use with the CURLOPT_TIMECONDITION. Specified in number of
     seconds since 1 Jan 1970. */
  CINIT(TIMEVALUE_LARGE, MULLE_CURL_OFF_T, 270),

  /* Head start in milliseconds to give happy eyeballs. */
  CINIT(HAPPY_EYEBALLS_TIMEOUT_MS, MULLE_CURL_LONG, 271),

  /* Function that will be called before a resolver request is made */
  CINIT(RESOLVER_START_FUNCTION, MULLE_CURL_FUNCTIONPOINT, 272),

  /* User data to pass to the resolver start callback. */
  CINIT(RESOLVER_START_DATA, MULLE_CURL_OBJECTPOINT, 273),

  /* send HAProxy PROXY protocol header? */
  CINIT(HAPROXYPROTOCOL, MULLE_CURL_LONG, 274),

  /* shuffle addresses before use when DNS returns multiple */
  CINIT(DNS_SHUFFLE_ADDRESSES, MULLE_CURL_LONG, 275),

  /* Specify which TLS 1.3 ciphers suites to use */
  CINIT(TLS13_CIPHERS, MULLE_CURL_STRINGPOINT, 276),
  CINIT(PROXY_TLS13_CIPHERS, MULLE_CURL_STRINGPOINT, 277),

  /* Disallow specifying username/login in URL. */
  CINIT(DISALLOW_USERNAME_IN_URL, MULLE_CURL_LONG, 278),

  /* DNS-over-HTTPS URL */
  CINIT(DOH_URL, MULLE_CURL_STRINGPOINT, 279),

  /* Preferred buffer size to use for uploads */
  CINIT(UPLOAD_BUFFERSIZE, MULLE_CURL_LONG, 280),

  /* Time in ms between connection upkeep calls for long-lived connections. */
  CINIT(UPKEEP_INTERVAL_MS, MULLE_CURL_LONG, 281),

  /* Specify URL using CURL URL API. */
  CINIT(CURLU, MULLE_CURL_OBJECTPOINT, 282),

  /* add trailing data just after no more data is available */
  CINIT(TRAILERFUNCTION, MULLE_CURL_FUNCTIONPOINT, 283),

  /* pointer to be passed to HTTP_TRAILER_FUNCTION */
  CINIT(TRAILERDATA, MULLE_CURL_OBJECTPOINT, 284),

  /* set this to 1L to allow HTTP/0.9 responses or 0L to disallow */
  CINIT(HTTP09_ALLOWED, MULLE_CURL_LONG, 285),

  /* alt-svc control bitmask */
  CINIT(ALTSVC_CTRL, MULLE_CURL_LONG, 286),

  /* alt-svc cache file name to possibly read from/write to */
  CINIT(ALTSVC, MULLE_CURL_STRINGPOINT, 287),

  /* maximum age of a connection to consider it for reuse (in seconds) */
  CINIT(MAXAGE_CONN, MULLE_CURL_LONG, 288),

  /* SASL authorisation identity */
  CINIT(SASL_AUTHZID, MULLE_CURL_STRINGPOINT, 289)
};

#pragma GCC diagnostic pop



//
// if +initialize is too slow or not used often, make it lazy and
// ask it from here (but then we need to lock...)
//
MULLE_C_NONNULL_RETURN
NSMapTable   *MulleCurlOptionLookupTable( void)
{
   struct mulle_curl_options  *p;
   struct mulle_curl_options  *sentinel;
   NSString                   *s;
   intptr_t                   value;
   NSMapTable                 *table;

   table = NSCreateMapTable( NSObjectMapKeyCallBacks,
                             NSIntMapValueCallBacks,
                             300);
   p        = curl_options;
   sentinel = (struct mulle_curl_options *) &((char *) p)[ sizeof( curl_options)];
   for(; p < sentinel; ++p)
   {
      s = [NSString stringWithUTF8String:p->name];
      switch( p->type)
      {
      case MULLE_CURL_LONG   :
      case MULLE_CURL_OFF_T       :
      case MULLE_CURL_STRINGPOINT :
         value = ((intptr_t) p->value << 4) | p->type;
         NSMapInsertKnownAbsent( table, s, (void *) value);
      }
   }
   return( table);
}

