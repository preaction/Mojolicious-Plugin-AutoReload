
use Mojo::Base '-strict';
use Test::Mojo;
use Test::More;

my $VALUE = 'Foobar';

my $t = Test::Mojo->new( 'Mojolicious' );
$t->app->mode( 'development' );
$t->app->routes->get( '/' => sub {
    my ( $c ) = @_;
    $c->render(
        inline => '<%= auto_refresh %>' . $VALUE,
    );
} );
$t->app->plugin( 'AutoRefresh' );

$t->get_ok( '/' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_like( qr{location\.refresh\(\)}, 'development mode contains script with refresh' )
    ;

$t->app->mode( 'production' );
$t->get_ok( '/' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_unlike( qr{location\.refresh\(\)}, 'non-development mode lacks refresh' )
    ;

done_testing;
