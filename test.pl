use Mojolicious::Lite;
plugin AutoRefresh => {};
get '/' => 'index';
app->start;
__DATA__
@@ layouts/default.html.ep
%= auto_refresh;
%= content;
@@ index.html.ep
% layout 'default';
Hello world!
