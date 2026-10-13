package flow.http;

import haxe.io.Bytes;
import haxe.http.HttpMethod;

import flow.http.header.Headers;

using StringTools;

enum abstract Version(String) to String {
	#if flow.http.enable_experimental_http_0_9 var Http09 = 'HTTP/0.9'; #end
	var Http10 = 'HTTP/1.0';
	var Http11 = 'HTTP/1.1';

	public static function parse(s:String):Null<Version>  return switch s {
		case #if flow.http.enable_experimental_http_0_9 Http09, #end Http10, Http11: cast s;
		case _: null;
	}
}

enum abstract ConnectionDirective(String) to String from String {
	var KeepAlive = 'keep-alive';
	var Close = 'close';
}

@:publicFields
final class RequestLine {
	var method:HttpMethod;
	var path:String;
	var version:Version;

	inline function new(method:HttpMethod, path:String, version:Version):Void {
		this.method = method;
		this.path = path;
		this.version = version;
	}
}

final class Request {
	public var method:HttpMethod;

	public var path:String;
	public var query:Map<String, String>;
	public var params:Map<String, String> = [];

	@:isVar public var cookies(get, null):Cookies;
	inline function get_cookies():Cookies {
		if(cookies == null) cookies = Cookies.parse(headers.get(Cookie) ?? "");
		return cookies;
	}

	public var version:Version;
	public var headers:Headers;
	public var body:Bytes;
	public var keep_alive:Bool;

	public function new(line:RequestLine, h:Headers, b:Bytes){
		this.method = line.method;
		this.version = line.version;
		this.headers = h;
		this.body = b;

		final raw = line.path; // lol

		// path & query
		final query = raw.indexOf("?");

		final raw_path = query < 0 ? raw : raw.substr(0, query);
		this.path = raw_path.urlDecode() ?? raw_path;
		this.query = parse_query(query < 0 ? "" : raw.substr(query + 1));

		final connection = (h.get(Connection) ?? "").toLowerCase();
		this.keep_alive = should_keep_alive(version, connection);
	}

	static function should_keep_alive(version:Version, connection:String):Bool {
		final parameters = [for (t in connection.split(",")) t.trim()];
		final wants_close = parameters.contains(ConnectionDirective.Close);
		
		return switch version {
			case Http11: !wants_close;
			case Http10: !wants_close && parameters.contains(ConnectionDirective.KeepAlive);
			case _: false;
		}
	}

	static function parse_query(q:String):Map<String, String> {
		final fixed_query = new Map<String, String>();
		if (q.trim() == "") return fixed_query;

		for (pair in q.split("&")) {
			if (pair == "") continue;

			final sep = pair.indexOf("=");

			final raw_key = (sep >= 0 ? pair.substr(0, sep) : pair).replace("+", " ");
			final raw_val = (sep >= 0 ? pair.substr(sep + 1) : "").replace("+", " ");

			fixed_query.set(raw_key.urlDecode() ?? raw_key, raw_val.urlDecode() ?? raw_val);
		}

		return fixed_query;
	}
}