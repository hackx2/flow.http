package flow.http;

import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

final class StatusCode {
	static function fix(str:String):String {
		final buf = new StringBuf();

		for (i in 0...str.length) {
			final char = str.charAt(i);
			final prev_char = i > 0 ? str.charAt(i - 1) : "";
			final starts_word = (i > 0) && (char == char.toUpperCase()) && (prev_char != prev_char.toUpperCase());

			if (starts_word) buf.add(" ");
			buf.add(char);
		}

		return buf.toString().replace("_", "-");
	}

	public static function build():Array<Field> {
		final fields = Context.getBuildFields();
		final cases:Array<Case> = [];

		#if flow.http.dev
		trace(fix('NotFound'));
		trace(fix('UnavailableForLegalReasons'));
		trace(fix('Imateapot'));// hmmmm
		#end

		for (f in fields) switch f.kind {
			case FVar(_, {expr: EConst(CInt(code))}):
				cases.push({
					values: [macro $v{Std.parseInt(code)}],
					expr: macro $v{fix(f.name)},
				});
			case _:
		}

		final sw:Expr = {
			expr: ESwitch(macro this, cases, macro "Unknown"),
			pos: Context.currentPos(),
		};

		final pos = Context.currentPos();

		fields.push({
			name: "text",
			access: [APublic],
			pos: Context.currentPos(),
			kind: FFun({
				args: [],
				ret: macro :String,
				expr: macro return $sw,
			}), /*meta: [
				{
					name: ":to",
					pos: pos
				}
			]*/
		});

		return fields;
	}
}