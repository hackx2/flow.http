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
	public var http_only:Bool;
	public var path:Null<String>;
	public var domain:Null<String>;
	public var max_age:Null<Int>;
	public var expires:Null<Date>;
	public var same_site:Null<SameSite>;

	public function new(
		name:String, 
		value:String, 
		?path:String = "/", 
		?domain:String, 
		?max_age:Int, 
		?expires:Date, 
		secure:Bool = false, 
		http_only:Bool = false, 
		?same_site:SameSite
	) {
		this.name = name;
		this.value = value;
		this.path = path;
		this.domain = domain;
		this.max_age = max_age;
		this.expires = expires;
		this.secure = secure;
		this.http_only = http_only;
		this.same_site = same_site;
	}

	public function toString():String {
		final b = new StringBuf();
		b.add('$name=${value.urlEncode()}');

		if (path != null) b.add('; Path=$path');
		if (domain != null) b.add('; Domain=$domain');
		if (max_age != null) b.add('; Max-Age=$max_age');
		if (expires != null) b.add('; Expires=${HttpDate.format(expires)}');
		// If SameSite=None is set then the Secure attri must also be set.
		// https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Cookies
		if (secure || same_site == None) b.add('; Secure');
		if (http_only) b.add('; HttpOnly');
		if (same_site != null) b.add('; SameSite=${(same_site : String)}');

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