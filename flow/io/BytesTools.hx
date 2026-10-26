package flow.io;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;

final class BytesTools {
	public static function append(a:Bytes, b:Bytes):Bytes {
		if (a.length == 0) return b;
		if (b.length == 0) return a;

		final buf = new BytesBuffer();
		buf.add(a);
		buf.add(b);
		return buf.getBytes();
	}

	public static function concat(a:Bytes, b:Bytes):Bytes {
		final out = Bytes.alloc(a.length + b.length);
		out.blit(0, a, 0, a.length);
		out.blit(a.length, b, 0, b.length);
		return out;
	}
}
