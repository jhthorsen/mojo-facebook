use Test::More;
use Test::Mojo;
use Mojo::Facebook;

plan skip_all => 'LIVE is not set' unless $ENV{LIVE};

my $fb = Mojo::Facebook->new;

$fb->fetch({ from => 'billclinton' }, sub { $tx = $_[1]->{__tx}; Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is(eval { $tx->res->json->{id} }, '65646572251', 'got response from facebook') or diag Data::Dumper::Dumper($tx->res);

done_testing;
