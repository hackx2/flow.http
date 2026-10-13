package flow.http;

enum HeaderError {
	MalformedHeader(l:String);
	IoError(e:Dynamic);
}