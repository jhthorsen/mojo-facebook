use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Facebook;

$ENV{FAKE_FACEBOOK_URL} = '/dummy';

my $t = Test::Mojo->new;
my $fb = Mojo::Facebook->new(access_token => 's3cret');
my($req, @res);

del '/dummy/289459768534' => sub {
    my $c = shift;
    $req = $c->req;
    $c->render(json => {});
};

$fb->delete_object(
    289459768534,
    sub { @res = @_; Mojo::IOLoop->stop },
);

Mojo::IOLoop->start;

is $req->url, '/dummy/289459768534?access_token=s3cret', 'correct request url';
isa_ok $res[0], 'Mojo::Facebook';
delete $res[1]{__tx};
is_deeply $res[1], {}, 'correct response';

done_testing;
