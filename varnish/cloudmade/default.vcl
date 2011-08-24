# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# 
# Default backend definition.  Set this to point to your content
# server.
# 
 backend default {
     .host = "a.tile.cloudmade.com";
     .port = "80";
 }
# 
# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.
# 
 sub vcl_recv {
     # Hardcode Host header to point to cloudmade tile server.
     set req.http.host = "a.tile.cloudmade.com";

     if (req.http.x-forwarded-for) {
 	set req.http.X-Forwarded-For =
 	    req.http.X-Forwarded-For ", " client.ip;
     } else {
 	set req.http.X-Forwarded-For = client.ip;
     }
     if (req.request != "GET" &&
       req.request != "HEAD" &&
       req.request != "PUT" &&
       req.request != "POST" &&
       req.request != "TRACE" &&
       req.request != "OPTIONS" &&
       req.request != "DELETE") {
         /* Non-RFC2616 or CONNECT which is weird. */
         return (pipe);
     }
     if (req.request != "GET" && req.request != "HEAD") {
         /* We only deal with GET and HEAD by default */
         return (pass);
     }
     return (lookup);
 }
# 
# sub vcl_pipe {
#     # Note that only the first request to the backend will have
#     # X-Forwarded-For set.  If you use X-Forwarded-For and want to
#     # have it set for all requests, make sure to have:
#     # set req.http.connection = "close";
#     # here.  It is not set by default as it might break some broken web
#     # applications, like IIS with NTLM authentication.
#     return (pipe);
# }
# 
# sub vcl_pass {
#     return (pass);
# }
# 
# sub vcl_hash {
#     set req.hash += req.url;
#     if (req.http.host) {
#         set req.hash += req.http.host;
#     } else {
#         set req.hash += server.ip;
#     }
#     return (hash);
# }
# 
# sub vcl_hit {
#     if (!obj.cacheable) {
#         return (pass);
#     }
#     return (deliver);
# }
# 
# sub vcl_miss {
#     return (fetch);
# }
# 

 sub vcl_fetch {
     if (!beresp.cacheable) {
         return (pass);
     }

     /* Remove Expires from backend, it's not long enough */
     unset beresp.http.expires;

     /* Set the clients TTL on this object */
     set beresp.http.cache-control = "max-age=900";

     /* Set how long Varnish will keep it */
     set beresp.ttl = 20w;

     /* marker for vcl_deliver to reset Age: */
     set beresp.http.magicmarker = "1";

     return (deliver);
 }
 
sub vcl_deliver {
    if (resp.http.magicmarker) {
        /* Remove the magic marker */
        unset resp.http.magicmarker;

        /* By definition we have a fresh object */
        set resp.http.age = "0";
    }
    return (deliver);
}
 
# sub vcl_error {
#     set obj.http.Content-Type = "text/html; charset=utf-8";
#     synthetic {"
# <?xml version="1.0" encoding="utf-8"?>
# <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
#  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
# <html>
#   <head>
#     <title>"} obj.status " " obj.response {"</title>
#   </head>
#   <body>
#     <h1>Error "} obj.status " " obj.response {"</h1>
#     <p>"} obj.response {"</p>
#     <h3>Guru Meditation:</h3>
#     <p>XID: "} req.xid {"</p>
#     <hr>
#     <address>
#        <a href="http://www.varnish-cache.org/">Varnish cache server</a>
#     </address>
#   </body>
# </html>
# "};
#     return (deliver);
# }
