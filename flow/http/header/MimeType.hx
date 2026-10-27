package flow.http.header;

@:build(flow.http.header.MimeType.build())
enum abstract MimeType(String) from String to String {
	@:ext("txt") var Text = "text/plain";
	@:ext("html") var Html = "text/html";
	@:ext("css") var Css = "text/css";
	@:ext("js") var JavaScript = "text/javascript";
	@:ext("json") var Json = "application/json";
	@:ext("xml") var Xml = "application/xml";
	@:ext("png") var Png = "image/png";
	@:ext("jpg", "jpeg") var Jpeg = "image/jpeg";
	@:ext("gif") var Gif = "image/gif";
	@:ext("svg") var Svg = "image/svg+xml";
	@:ext("webp") var Webp = "image/webp";
	@:ext("mp4") var Mp4 = "video/mp4";

	// todo: i think im forgetting something :c

	// if the MIME type isn't included here, it falls back to this <3
	var OctetStream = "application/octet-stream";

	public inline function charset(opt:Charset):String {
		return this + '; charset=${opt}';
	}
}

// todo: https://www.iana.org/assignments/character-sets
enum abstract Charset(String) from String to String {
	var Utf7 = 'utf-7';
	var Utf8 = "utf-8";

	var Utf16 = "utf-16";
	var Utf16LE = "utf-16le";
	var Utf16BE = "utf-16be";

	var Utf32 = "utf-32";
	var Utf32LE = "utf-32le";
	var Utf32BE = "utf-32be";
}