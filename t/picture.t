use Test::More;
use Mojo::Facebook;

my $fb = Mojo::Facebook->new;

is $fb->picture, 'https://graph.facebook.com/me/picture?type=square', 'got picture url (default: me)';
is $fb->picture('me', 'foo'), 'https://graph.facebook.com/me/picture?type=foo', 'got foo picture url';
is $fb->picture(42), 'https://graph.facebook.com/42/picture?type=square', 'got picture url for 42';

$fb->scheme('http');

is $fb->picture(42), 'http://graph.facebook.com/42/picture?type=square', 'got picture url for http';

done_testing;
