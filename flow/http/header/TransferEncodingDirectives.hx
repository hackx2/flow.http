package flow.http.header;

enum abstract TransferEncodingDirectives(String) to String from String {
	var Chunked = 'chunked'; // we're only doing this one
	// var Compress ='compress';
	// var Deflate = 'deflate'
	// var GZip = 'gzip';
}