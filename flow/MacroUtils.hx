package flow;

import haxe.macro.Context;
import haxe.macro.Expr;

final class MacroUtils {
	public static macro function unreachable(msg:ExprOf<String>):Expr { // i like rust
		final pos = Context.currentPos();
		return macro @:pos(pos) {
			throw $msg;
		}
	}
}