package Mojolicious::Plugin::AutoRefresh;
our $VERSION = '0.001';
# ABSTRACT: Automatically refresh open browser windows when your application changes

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This plugin automatically refreshes the page when the Mojolicious webapp
restarts.  This is especially useful when using L<the Morbo development
server|http://mojolicious.org/perldoc/Mojolicious/Guides/Tutorial#Reloading>,
which automatically restarts the webapp when it detects changes.
Combined, C<morbo> and C<Mojolicious::Plugin::AutoRefresh> will
automatically display your new content whenever you change your webapp
in your editor!

This works by opening a WebSocket connection to a specific Mojolicious
route. When the server restarts, the WebSocket is disconnected, which
triggers a refresh of the page.

=head1 HELPERS

=head2 auto_refresh

The C<auto_refresh> template helper inserts the JavaScript to
automatically refresh the page. This helper only works when the
application mode is C<development>, so you can leave this in all the
time and have it only appear during local development.

=head1 ROUTES

=head2 /auto_refresh

This plugin adds a C</auto_refresh> WebSocket route to your application.

=head1 SEE ALSO

L<Mojolicious>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::IOLoop;
use Mojo::Util qw( unindent trim );

sub register {
    my ( $self, $app, $config ) = @_;

    $app->routes->websocket( '/auto_refresh' => sub {
        my ( $c ) = @_;
        my $timer_id = Mojo::IOLoop->timer( 30, sub { $c->send( 'ping' ) } );
        $c->on( finish => sub {
            Mojo::IOLoop->remove( $timer_id );
        } );
    } )->name( 'auto_refresh' );

    $app->helper( auto_refresh => sub {
        my ( $c ) = @_;
        if ( $app->mode eq 'development' ) {
            return $c->render_to_string( inline => unindent trim( <<'ENDHTML' ) );
                <script>
                    // If we lose our websocket connection, the web server must
                    // be restarting, and we should refresh the page
                    var autoRefreshWs = new WebSocket( "ws://" + location.host + "<%== url_for( 'auto_refresh' ) %>" );
                    autoRefreshWs.addEventListener( "close", function (event) {
                        location.reload(true); // force a refresh from the server
                    } );
                    // Send pings to ensure that the connection stays up, or we learn
                    // of the connection's death
                    setInterval( function () { autoRefreshWs.send( "ping" ) }, 5000 );
                </script>
ENDHTML
        }
        return '';
    } );
}

1;

