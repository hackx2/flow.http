package flow.http;

import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.http.HttpMethod;

import sys.net.Host;

import hl.uv.Tcp;
import hl.uv.Loop;
import hl.uv.Stream;

import flow.ds.Result;
import flow.http.StatusCode;
import flow.http.header.Headers;
import flow.http.Request.Version;
import flow.http.Error.HeaderError;
import flow.http.Request.RequestLine;
import flow.http.Request.ConnectionDirective;

import flow.MacroUtils.unreachable;

using StringTools;
using flow.io.BytesTools;

@:nullSafety(Strict)
class Server {
	public var host(default, null):Host;
	public var port(default, null):Int;

	public function new(?host:Host, ?port:Int) {
		this.host = host ?? new Host("127.0.0.1");
		this.port = port ?? 3000;
	}

	var tcp:Null<Tcp>;

	public function listen(?backlog:Int, ?callback:Void->Void) {
		stopping = false; // init <3

		final loop = Loop.getDefault();

		final t = new Tcp(loop);
		tcp = t;
		t.bind(host, port);
		t.listen(backlog ?? 512, () -> process(t.accept()));

		if(callback != null) callback() else trace('Server started @ ${host.host}:${port}');

		loop.run(Default);
	}

	var stopping:Bool = false;
	public function stop(force:Bool = false, ?callback:() -> Void) {
		stopping = true;
		tcp?.close(callback);
	}

	private function process(client:Stream) {
		var buf = Bytes.alloc(0);
		
		client.readStart(data -> {
			if (data == null) return client.close();

			buf = buf.append(data);

			var close = true;
			try {
				while (true) {
					#if flow.http.enable_experimental_http_0_9
					final EoL = buf.toString().indexOf("\r\n");
					if (EoL >= 0) {
						final first = buf.sub(0, EoL).toString().split(" ");
						if (first.length == 2) {
							if (first[0] == HttpMethod.Get && first[1] != "") {
								final req = new Request(new RequestLine(first[0], first[1], Http09), new Headers(), Bytes.alloc(0));
								respond(client, Http09, try handle(req) catch (e) on_error(InternalServerError, e), req);
							} else {
								reject(client, Http11, BadRequest, "http/0.9 only supports GET");
							}
							break;
						}
					}
					#end

					final end = buf.toString().indexOf("\r\n\r\n");
					if (end < 0 ? buf.length > max_header_bytes : end > max_header_bytes) {
						reject(client, Http11, RequestHeaderFieldsTooLarge, "header fields too large");
						break;
					}
					if (end < 0) return;

					final input = new BytesInput(buf);
					
					final line:RequestLine = switch read_request_line(input) {
						case Ok(v): v;
						case Err(status): 
							reject(client, Http11, status, 'bad request line');
							break;
					};

					final version:Version = line.version;

					final headers:Headers = switch read_headers(input) {
						case Ok(h): h;
						case Err(err):
							switch err {
								case MalformedHeader(l): reject(client, version, BadRequest, 'malformed header: $l');
								case IoError(e): reject(client, version, InternalServerError, e);
							}
							break;
					};

					// HTTP/1.1 requires a host
					if (version == Http11 && !headers.exists(Host)) {
						reject(client, version, BadRequest, "The 'host' header is missing. HTTP/1.1 requests require a valid 'host' header.");
						break;
					}

					final body = switch read_body(headers, input, version) {
						case Ok(o): o;
						case Err(status):
							reject(client, version, status, "bad body");
							break;
					}

					buf = buf.sub(input.position, buf.length - input.position);

					final req = new Request(line, headers, body);
					final res = try handle(req) catch(e) on_error(InternalServerError, e);

					respond(client, version, res, req);

					if (!req.keep_alive || stopping) break;
				}
			} catch (_:Eof) {
				close = false;
			} catch (e) {
				trace('connection err $e');
			}

			try if (close) client.close() catch (_) {}
		});
	}

	private function read_body(headers:Headers, input:Input, version:Version):Result<Bytes, StatusCode> {
		final te = headers.get(TransferEncoding);
		final cl = headers.get(ContentLength);

		if (te != null) {
			// reject transfer encoding requests on http/1.0
			if (cl != null || version == Http10) return Err(BadRequest);
			return Err(NotImplemented); // todo transfer encoding bs here <3
		}

		if (cl != null) {
			final len = Std.parseInt(cl) ?? -1;
			if (len < 0) return Err(BadRequest);
			if (len > max_body_bytes) return Err(ContentTooLarge);
			return Ok(len > 0 ? input.read(len) : Bytes.alloc(0));
		}

		return Ok(Bytes.alloc(0));
	}

	// todo: move all request-related parsing into it's own class

	public var max_request_line:Int = (8 * 1024); // 8KB
	public var max_header_bytes = (16 * 1024); // 16KB
	public var max_body_bytes:Int = (1024 * 1024);// 1MB

	private function read_request_line(input:Input):Result<RequestLine, StatusCode> {
		var line = input.readLine();
		while (line == "") line = input.readLine();//keep consuming the input until we've skipped all the blank lines

		if (line.length > max_request_line) return Err(URITooLong);

		final parts = line.split(" ");

		if (parts.length != 3 || parts[0] == "" || parts[1] == "") return Err(BadRequest);

		final ver = Version.parse(parts[2]);
		if (ver == null) {
			return Err(parts[2].startsWith("HTTP/") ? HTTPVersionNotSupported : BadRequest);
		}

		#if flow.http.enable_experimental_http_0_9
		// http/0.9 request lines look like this: `GET /`
		// NOT like this: `GET / HTTP/0.9`
		if (ver == Http09) return Err(BadRequest);
		#end
		
		return Ok(new RequestLine(parts[0], parts[1], ver));
	}

	private function read_headers(input:Input):Result<Headers, HeaderError> {
		final headers = new Headers();

		try while (true) {
			final line = input.readLine();
			if (line == "") break;
			
			final i = line.indexOf(":");
			if (i <= 0) return Err(MalformedHeader(line));
			headers.add(line.substr(0, i), line.substr(i + 1).trim());
		} catch(err) return Err(IoError(err));

		return Ok(headers);
	}

	private function respond(client:Stream, version:Version, res:Response, req:Request) {
		trace('${version} ${res.status} ~ Got ${res.body.length} bytes at ${req.path}');
		this.response(client, version, res, req.keep_alive, req.method == HttpMethod.Head);
	}

	private function response(client:Stream, version:Version, res:Response, keep_alive:Bool, head_only:Bool = false):Void {
		switch version {
			#if flow.http.enable_experimental_http_0_9
			// Http/0.9 only requires the body
			case Http09: client.write(res.body);
			#end
			case Http10 | Http11:
				res.headers.set(ContentLength, Std.string(res.body.length));
				res.headers.set(Connection, keep_alive ? ConnectionDirective.KeepAlive : ConnectionDirective.Close);
				res.headers.set(Date, HttpDate.now());

				final head = new StringBuf();
				head.add('$version ${res.status} ${res.status.text()}\r\n');
				// one line per val ensures `Set-Cookie` works correctly
				for(i => v in res.headers) head.add('$i: $v\r\n');
				for(c in res.cookies) head.add('Set-Cookie: ${c.toString()}\r\n');
				head.add('\r\n');

				client.write(Bytes.ofString(head.toString()));
				if(!head_only) client.write(res.body);
			case _: unreachable('um...');
		}
	}

	private function reject(client:Stream, version:Null<Version>, status:StatusCode, ?err:Dynamic):Void {
		final v:Version = version ?? Http11;
		response(client, v, on_error(status, err), false);
	}

	////////////////////////////////////////////////////////////////////////////////////////////////

	dynamic public function handle(req:Request):Response {
		return Response.txt(OK, 'mrraow!');
	}

	dynamic public function on_error(status:StatusCode, ?err:Dynamic):Response {
		if (err != null) trace('error $status ${status.text()} : $err');
		return Response.txt(status, '$status ${status.text()}');
	}
}
