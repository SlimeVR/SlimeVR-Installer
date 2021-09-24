# NScurl ([NSIS](https://github.com/negrutiu/nsis) plugin)
NScurl is a NSIS (Nullsoft Scriptable Install System) plugin with advanced HTTP/HTTPS capabilities.<br>
It's implemented on top of [libcurl](https://curl.haxx.se/libcurl/) with [OpenSSL](https://www.openssl.org/) as SSL backend.<br>
This plugin is included in my unofficial [NSIS builds](https://github.com/negrutiu/nsis).<br>

[![License: BSD3](https://img.shields.io/badge/License-BSD3-blue.svg)](LICENSE.md)
[![Latest Release](https://img.shields.io/badge/dynamic/json.svg?label=Latest%20Release&url=https%3A%2F%2Fapi.github.com%2Frepos%2Fnegrutiu%2Fnsis-nscurl%2Freleases%2Flatest&query=%24.name&colorB=orange)](../../releases/latest)
[![Downloads](https://img.shields.io/github/downloads/negrutiu/nsis-nscurl/total.svg?label=Downloads&colorB=orange)](../../releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/negrutiu/nsis-nscurl.svg?label=Issues)](../../issues)

### Features:
- **Modern**: supports modern SSL protocols and cyphers including HTTPS/2, TLS1.3, etc.
- **Compatible**: works well on Windows NT4, Windows 10 and everything in between
- **Multi-threaded**: download/upload multiple files in parallel
- **Asynchronous**: start multiple background transfers, check on them later
- **Insistent**: multiple attempts to connect and resume interrupted transfers
- **NSIS aware**: download files at any installation stage (from `.onInit`, from `Sections`, from custom pages, silent installers, etc)
- **Verbose**: plenty of useful information is available for querying (transfer size, speed, HTTP status, HTTP headers, etc)
- Supports HTTP and TLS authentication
- Supports all relevant HTTP methods (GET, POST, HEAD, etc)
- Supports DNS-over-HTTPS name resolution
- Supports custom HTTP headers and data
- Supports proxy servers (both authenticated and open)
- Supports files larger than 4GB
- Can download remote content to RAM instead of a file
- Works well in **64-bit** [NSIS builds](https://github.com/negrutiu/nsis)
- A lot more... Check out the included [documentation](NScurl.Readme.htm)

### Basic usage:
- Check out the [Getting Started](https://github.com/negrutiu/nsis-nscurl/wiki/Getting-Started/) wiki page
- Quick transfer:
```nsis
NScurl::http GET "http://live.sysinternals.com/Files/SysinternalsSuite.zip" "$TEMP\SysinternalsSuite.zip" /CANCEL /RESUME /END
Pop $0 ; Status text ("OK" for success)
```
- Quick transfer (custom GET parameters + custom request headers):
```nsis
NScurl::http GET "https://httpbin.org/get?param1=value1&param2=value2" "$TEMP\httpbin_get.json" /HEADER "Header1: Value1" /HEADER "Header2: Value2" /END
Pop $0
```
- POST a .json file
```nsis
NScurl::http POST "https://httpbin.org/post" MEMORY /HEADER "Content-Type: application/json" /DATA '{ "number_of_the_beast" : 666 }' /END
Pop $0
```
- POST a .json file (as MIME multi-part form)
```nsis
NScurl::http POST "https://httpbin.org/post" Memory /POST "User" "My user name" /POST "Password" "My password" /POST FILENAME=maiden.json TYPE=application/json "Details" '{ "number_of_the_beast" : 666 }' /END
Pop $0
```
- More complex examples in the [documentation](NScurl.Readme.htm)

### Licenses:
Project|License
:---|:---
This project itself|[BSD3](LICENSE.md)
libcurl|[MIT/X inspired](https://curl.haxx.se/docs/copyright.html)
OpenSSL|[Dual License](https://www.openssl.org/source/license.html)
nghttp2|[MIT](https://github.com/nghttp2/nghttp2/blob/master/COPYING)
zlib|[zlib](https://www.zlib.net/zlib_license.html)
