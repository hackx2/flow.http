package flow.http;

import haxe.ds.StringMap;

using StringTools;

enum abstract SameSite(String) to String {
	var Strict = "Strict";
	var Lax = "Lax";
	var None = "None";
}

@:structInit
final class Cookie {
	public final name:String;
	public final value:String;

	public var secure:Bool;
	public var httpOnly:Bool;
	public var path:Null<String>;
	public var domain:Null<String>;
	public var maxAge:Null<Int>;
	public var expires:Null<Date>;
	public var sameSite:Null<SameSite>;

	public function new(
		name:String, 
		value:String, 
		?path:String = "/", 
		?domain:String, 
		?maxAge:Int, 
		?expires:Date, 
		secure:Bool = false, 
		httpOnly:Bool = false, 
		?sameSite:SameSite
	) {
		this.name = name;
		this.value = value;
		this.path = path;
		this.domain = domain;
		this.maxAge = maxAge;
		this.expires = expires;
		this.secure = secure;
		this.httpOnly = httpOnly;
		this.sameSite = sameSite;
	}

	public function toString():String {
		final b = new StringBuf();
		b.add('$name=${value.urlEncode()}');

		if (path != null) b.add('; Path=$path');
		if (domain != null) b.add('; Domain=$domain');
		if (maxAge != null) b.add('; Max-Age=$maxAge');
		if (expires != null) b.add('; Expires=${HttpDate.format(expires)}');
		// If SameSite=None is set then the Secure attri must also be set.
		// https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Cookies
		if (secure || sameSite == None) b.add('; Secure');
		if (httpOnly) b.add('; HttpOnly');
		if (sameSite != null) b.add('; SameSite=${(sameSite : String)}');

		return b.toString();
	}
}

@:forward(keyValueIterator, keys, exists, remove, toString)
abstract Cookies(StringMap<String>) {
	public inline function new() this = new StringMap();

	@:arrayAccess public inline function get(name:String):Null<String> return this.get(name);
	@:arrayAccess public inline function set(name:String, value:String):String {
		this.set(name, value);
		return value;
	}

	@:from // u can do `var blah:Cookies = cast str;` btw
	public static function parse(header:String):Cookies {
		final c = new Cookies();

		for (part in header.split(";")) {
			final i = part.indexOf("=");
			if (i <= 0) continue;

			final name = part.substr(0, i).trim();
			if (!c.exists(name)) c.set(name, part.substr(i + 1).trim());
		}

		return c;
	}

	public function toString():String {
		return '{ ' + [for (k => v in this) '$k=$v'].join(', ') + ' }';
	}
}