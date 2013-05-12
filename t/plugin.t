use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

my $t = Test::Mojo->new;
my $fb;

plugin 'Facebook';

get '/whatever' => sub {
    my $c = shift;
    $fb = $c->facebook('s3cret');
    $c->render_text('yay!');
};

$t->get_ok('/whatever')->status_is(200);

is $fb->access_token, 's3cret', 'access_token was set';
is $fb->scheme, 'http', 'scheme was set';

my $tx = $fb->_tx('POST');

is $tx->req->url, 'http://graph.facebook.com', 'correct transaction url';

done_testing;
