# flow.http

A little haxe-based http library using hashlink's built-in uvlib bindings. inspired by: [fuzzy.http](https://github.com/nyan-labs/fuzzy.http/)

> [!WARNING]
> This project is still a work in progress.

## usage

```haxe
import sys.net.Host;
import flow.http.Server;
import flow.http.Response;

function main() {
  final server = new Server(new Host("127.0.0.1"), 3000);
  server.handle = req -> Response.txt(OK, "hewwo!! ^w^");
  server.listen(512, _ -> trace('listening...'));
}
```

Then build with `haxe build.hxml`, and test with `curl -i http://127.0.0.1:3000/`.

---

| version  | support | notes                                       |
| -------- | ------- | ------------------------------------------- |
| http/0.9 | full    | `-D flow.http.enable_experimental_http_0_9` |
| http/1.0 | mostly  | -                                           |
| http/1.1 | mostly  | -                                           |

<br>

# roadmap

## http/1.1
- [x] required `Host` header
- [x] connection directives `keep-alive` & `close` for persistent connections.
- [x] `HEAD` responses without a body
- [ ] `chunked` `Transfer-Encoding` request body thingy

## http/1.0
- [x] All Http methods are supported (`GET`, `HEAD`, `POST`, `PUT`, `DELETE`, `PATCH`, and `OPTIONS`)
- [x] request line + header parsing
- [x] status codes with reason phrases
- [x] `Content-Length` bodies
- [x] `Date` header
- [x] case-insensitive headers
- [x] request size limits
- [ ] strict `Content-Length`
  - [ ] Reject any requests have has duplicate `Content-Length` headers with different values
  - [ ] Ensure `Content-Length` header value only contains digits, reject if it doesn't.
- [x] reject `Transfer-Encoding` on `HTTP/1.0` requests
- [x] close the connection after any error

## http/0.9 (experimental / untested)
- [x] `GET` only
- [x] two-part request line (`GET /meow`)
- [x] body-only responses
- [x] reject any Http/0.9 requests that include the http version 
- [x] reject `GET / HTTP/0.9` (http/0.9 request line doesn't include the version)
- [x] reject non-`GET` methods

## additional features
- [x] cookies & `Set-Cookie`
- [x] `Response.hx`
  - [x] text()
  - [x] json()
  - [x] html()
  - [x] file()
- [x] MIME type detection from file extension (using macros)
- [x] charset support
- [x] full status code list
- [x] query string parsing
- [ ] timeouts
- [ ] my own libuv bindings

<br>

---