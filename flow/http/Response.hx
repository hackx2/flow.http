package flow.http;

import haxe.Json;
import haxe.io.Path;
import haxe.io.Bytes;

import sys.io.File;
import sys.FileSystem;

import flow.http.header.Headers;
import flow.http.Cookies.Cookie;
import flow.http.header.MimeType;
import flow.http.header.Headers.HeaderName;

using StringTools;
using Std;

final class Response {
	public var cookies:Array<Cookie>;

	public var status:StatusCode;
	public var body:Bytes;
	public var headers:Headers;

	public function new(?status:StatusCode, ?body:Bytes, ?headers:Headers, ?cookies:Array<Cookie>) {
		this.status = status ?? OK;
		this.body = body ?? Bytes.alloc(0);
		this.headers = headers ?? new Headers();
		this.cookies = cookies ?? new Array<Cookie>();
	}

	public function cookie(cookie:Cookie):Response {
		this.cookies.push(cookie);
		return this;
	}

	public function header(name:HeaderName, value:String):Response { // idk how i feel about this :c
		headers.add(name, value);
		return this;
	}

	public static function txt(status:Null<StatusCode>, text:String) {
		return new Response(status ?? OK, Bytes.ofString(text), Headers.from([
			ContentType => [MimeType.Text]
		]));
	}

	public static function json(status:Null<StatusCode>, data:Dynamic) {
		final json_str:String = haxe.Json.stringify(data);
		return new Response(status ?? OK, Bytes.ofString(json_str), Headers.from([
			ContentType => [MimeType.Json.charset(Utf8)]
		]));
	}

	public static function file(status:Null<StatusCode>, path:String, ?headers:Headers) {
		if (!FileSystem.exists(path) || FileSystem.isDirectory(path)) return txt(NotFound, "Resource not found");

		final type = MimeType.ext(Path.extension(path)) ?? MimeType.OctetStream;
		final body = File.getBytes(path);
		return new Response(status ?? OK, body, Headers.from([
			ContentType => [(type : String).startsWith("text/") ? type.charset(Utf8) : type]
		]));
	}

	public static function html(status:Null<StatusCode>, text:String) {
		return new Response(status ?? OK, Bytes.ofString(text), Headers.from([
			ContentType => [MimeType.Html.charset(Utf8)]
		]));
	}
}