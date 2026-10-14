package;


import haxe.Json;

import sys.io.File;
import sys.net.Host;

import flow.http.Server;
import flow.http.Request;
import flow.http.Response;
import flow.http.StatusCode;
import flow.http.Cookies.Cookie;
import flow.http.header.ContentTypeOptions;

function main(){
    final server = new Server(new Host("127.0.0.1"), 3000);
    
    var idek = 'mrrraow!';

    server.handle = req -> {
		final parts = req.path.split("/");

        if (parts.length == 3 && parts[1] == "users") {
            final user_id = parts[2];

            return switch req.method {
                case Get | Head:
                    final raw = try File.getContent('public/users/${user_id}.json') catch (_) {
                        return Response.txt(NotFound, 'Cannot find specified user...');
                    };
                    final data = try Json.parse(raw) catch (e) {
                        return Response.txt(InternalServerError, 'Unable to parse user.json...\nError: $e');
                    };
                    Response.json(OK, data);
                case Delete: Response.txt(OK, 'deleted user $user_id');
                case _: Response.txt(MethodNotAllowed, 'nope').header(Allow, 'GET, DELETE');
            };
        }

        switch [req.method, req.path] {
            case [Options, "/meow"]: new Response(OK).header(Allow, "GET, POST, PUT, PATCH, DELETE, OPTIONS");
            case [Get, '/meow']: return Response.txt(OK, idek);
            case [Post, '/meow']: Response.txt(Created, 'got ${req.body.length} bytes: ${req.body.toString()}');
            case [Put, '/meow']: idek = req.body.toString(); Response.txt(OK, 'replaced with: $idek');
            case [Patch, '/meow']: Response.txt(OK, 'patched with: ${req.body.toString()}'); // todo
            case [Delete, '/meow']: return Response.txt(OK, 'deleted mrraow! :<');

            case [Get | Head, '/json']: return Response.json(OK, Json.parse(File.getContent('public/mrraow.json'))).header(CacheControl, 'no-store'); // todo: make CacheDirective
            
            case [Get, '/video']: 
                final res = Response.file(OK, 'public/vid.mp4');
                res.header(XContentTypeOptions, ContentTypeOptions.NoSniff);
                return res;
            case [Get, '/video.html']:
                final html_content = File.getContent('public/video.html');
                return Response.html(OK, html_content);
            
            case [Get, '/query']: return Response.json(OK, [for (k => v in req.query) k => v]);
            
            case [Get, '/cookie']:
                if(req.cookies.exists('meow')) return Response.txt(OK, 'grr');

                final cookie:Cookie = {
                    name: 'meow',
                    value: 'true...',
                    path: '/cookie',
                    max_age: 72783187,
                    http_only: true,
                    same_site: Lax
                }
				return Response.json(OK, { ok: true }).cookie(cookie);
            
            case [_, '/json' | '/cookie' | '/video' | '/video-html']: return Response.txt(MethodNotAllowed, 'heh').header(Allow, 'GET');
            case _: return Response.txt(NotFound, 'not found\n\nidior');
        };
    };

    server.listen(512, () -> {
        trace('Server is listening on ${server.host.toString()}:${server.port} <3');
    });
}