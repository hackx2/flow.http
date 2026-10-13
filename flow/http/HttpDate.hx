package flow.http;

using StringTools;

final class HttpDate {
	static final days = "Sun Mon Tue Wed Thu Fri Sat".split(" ");
	static final months = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split(" ");
	
	static inline function better_lpad(n:Int):String return Std.string(n).lpad("0", 2);

	public static function format(d:Date):String {
		// Mon, 3 Apr 2020 (lol)
		final date = '${days[d.getUTCDay()]}, ${better_lpad(d.getUTCDate())} ${months[d.getUTCMonth()]} ${d.getUTCFullYear()}';
		// 12:30:10
		final time = [d.getUTCHours(), d.getUTCMinutes(), d.getUTCSeconds()].map(better_lpad).join(":");
		// MOn, 3 Apr 2020 12:30:10 GMT
		return '$date $time GMT';
	}

	public static inline function now():String return format(Date.now());
}