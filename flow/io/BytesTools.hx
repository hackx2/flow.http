package flow.io;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;

final class BytesTools {
	public static function append(buf:Bytes, data:Bytes):Bytes {
		if (buf.length == 0) return data;
		if (data.length == 0) return buf;

		final b = new BytesBuffer();
		b.add(buf);
		b.add(data);
		return b.getBytes();
	}
}
