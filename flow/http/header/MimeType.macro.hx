package flow.http.header;

import haxe.macro.Context;
import haxe.macro.Expr;

final class MimeType {
	public static function build():Array<Field> {
		final fields = Context.getBuildFields();

		final cases = new Array<Case>();
		for (f in fields) {
			for (m in (f.meta ?? [])) {
				if (m.name != ":ext") continue;

				final exts = [for (p in m.params ?? []) switch p.expr {
					case EConst(CString(s, _)): macro $v{s.toLowerCase()};
					case _: Context.error('@:ext expects string literal(s)', p.pos);
				}];

				cases.push({values: exts, expr: macro $i{f.name}});
			}
		}

		final pos = Context.currentPos();

		final switch_expr:Expr = {
			expr: ESwitch(
				macro ext.toLowerCase(), 
				cases,
				macro null
			),
			pos: pos
		};

		fields.push({
			name: "ext",
			access: [APublic, AStatic, AInline],
			pos: pos,
			kind: FFun({
				args: [{name:"ext", type: macro:String}],
				ret: macro : Null<flow.http.header.MimeType>,
				expr: macro return $switch_expr
			})
		});

		return fields; // totally didn't forget to include this...
	}
}