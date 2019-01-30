# nginx + HTTP/2 + wsgi のサンプル

## 環境

```
$ sw_vers
ProductName:	Mac OS X
ProductVersion:	10.13.3
BuildVersion:	17D47
```

# nginx をインストール + 自前証明書で ssl を使えるように

https://qiita.com/ww24/items/423108ac3659e0f06bc7

```bash
brew install nginx
```

で入れたものとする。

### `/etc/hosts` の設定

* オレオレ証明書の `Common Name` に指定するFQDN
* nginx の [server_name](foreground.nginx.conf#L28) に指定する値

と同じ値。
適当に読み替えてください。

```
127.0.0.1 kuryu.local
::1       kuryu.local
```

※ `::1` の IPv6のループバックも追加しないと名前解決が遅いので注意

## nginx + HTTP/2 の設定

https://qiita.com/ekzemplaro/items/817e653a4a16aea06c56

# run server

## nginx reverse proxy

* port [4443](foreground.nginx.conf#L23) で HTTP/1.1
* port [4444](foreground.nginx.conf#L26) で HTTP/2

```bash
nginx -p . -c foreground.nginx.conf
```

## backend wsgi server 

`app.sock` 経由でnginxと疎通する。

```bash
uwsgi uwsgi.ini
```

# 疎通確認

### HTTP/1.1

```bash
$ curl -v -k https://kuryu.local:4443/app/
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to kuryu.local (127.0.0.1) port 4443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Client hello (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: CN=kuryu.local
*  start date: Jan 30 09:42:11 2019 GMT
*  expire date: Jan 30 09:42:11 2020 GMT
*  issuer: CN=kuryu.local
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
> GET /app/ HTTP/1.1
> Host: kuryu.local:4443
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.15.8
< Date: Wed, 30 Jan 2019 09:52:51 GMT
< Content-Type: text/plain
< Content-Length: 120
< Connection: keep-alive
<
* Connection #0 to host kuryu.local left intact
Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!
```

### HTTP/2

```bash
$ curl -v -k https://kuryu.local:4444/app/
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to kuryu.local (127.0.0.1) port 4444 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Client hello (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=kuryu.local
*  start date: Jan 30 09:42:11 2019 GMT
*  expire date: Jan 30 09:42:11 2020 GMT
*  issuer: CN=kuryu.local
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fc2ae000000)
> GET /app/ HTTP/2
> Host: kuryu.local:4444
> User-Agent: curl/7.54.0
> Accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 200
< server: nginx/1.15.8
< date: Wed, 30 Jan 2019 09:52:56 GMT
< content-type: text/plain
< content-length: 120
<
* Connection #0 to host kuryu.local left intact
Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!Hello World!
```


# ベンチマーク

[ab](https://httpd.apache.org/docs/2.4/programs/ab.html) は HTTP/2 のリクエストに対応してないので、
[h2load](https://nghttp2.org/documentation/h2load-howto.html) を使えるようにする。

## install

https://github.com/nghttp2/nghttp2

macでビルドすると `./configure`途中で `PKG_PROG_PKG_CONFIG` あたりでエラーになったので、

```bash
brew install nghttp2
```

するのが良いと思う。

## 実行例

### HTTP/1.1

```bash
h2load -n 10000 -c 100 -m 1 https://kuryu.local:4443/app/
```

```txt
starting benchmark...
spawning thread #0: 100 total client(s). 10000 total requests
TLS Protocol: TLSv1.2
Cipher: ECDHE-RSA-AES256-GCM-SHA384
Server Temp Key: ECDH P-256 256 bits
Application protocol: http/1.1
progress: 10% done
progress: 20% done
progress: 30% done
progress: 40% done
progress: 50% done
progress: 60% done
progress: 70% done
progress: 80% done
progress: 90% done
progress: 100% done

finished in 15.66s, 638.47 req/s, 166.04KB/s
requests: 10000 total, 10000 started, 10000 done, 10000 succeeded, 0 failed, 0 errored, 0 timeout
status codes: 10000 2xx, 0 3xx, 0 4xx, 0 5xx
traffic: 2.54MB (2663100) total, 1.05MB (1099500) headers (space savings 0.00%), 1.14MB (1200000) data
                     min         max         mean         sd        +/- sd
time for request:     3.12ms    498.72ms    128.90ms     60.07ms    74.42%
time for connect:    38.99ms    637.33ms    479.19ms    158.64ms    78.00%
time to 1st byte:    53.32ms       1.12s    682.27ms    249.30ms    78.00%
req/s           :       6.38      103.87        9.56       13.64    98.00%
```

### HTTP/2

```bash
h2load -n 10000 -c 100 -m 1 https://kuryu.local:4444/app/
```

```txt
starting benchmark...
spawning thread #0: 100 total client(s). 10000 total requests
TLS Protocol: TLSv1.2
Cipher: ECDHE-RSA-AES256-GCM-SHA384
Server Temp Key: ECDH P-256 256 bits
Application protocol: h2
progress: 10% done
progress: 20% done
progress: 30% done
progress: 40% done
progress: 50% done
progress: 60% done
progress: 70% done
progress: 80% done
progress: 90% done
progress: 100% done

finished in 16.48s, 606.71 req/s, 111.68KB/s
requests: 10000 total, 10000 started, 10000 done, 10000 succeeded, 0 failed, 0 errored, 0 timeout
status codes: 10000 2xx, 0 3xx, 0 4xx, 0 5xx
traffic: 1.80MB (1884900) total, 488.28KB (500000) headers (space savings 50.00%), 1.14MB (1200000) data
                     min         max         mean         sd        +/- sd
time for request:     4.79ms    569.48ms    139.27ms     62.27ms    71.73%
time for connect:    86.42ms    639.21ms    505.70ms    171.70ms    86.00%
time to 1st byte:   107.31ms       1.21s    745.61ms    254.88ms    87.00%
req/s           :       6.07       35.78        9.15        7.97    88.00%
```

速度はあまり変わらないが、
> traffic: 1.80MB (1884900) total, 488.28KB (500000) headers (space savings 50.00%), 1.14MB (1200000) data

トラフィックは減っているようだ。
