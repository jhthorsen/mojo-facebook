use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Facebook;

$ENV{FAKE_FACEBOOK_URL} = '/dummy';

my $t = Test::Mojo->new;
my $fb = Mojo::Facebook->new(access_token => 's3cret');
my($req, @res);

post '/dummy/42/comments' => sub {
    my $c = shift;
    $req = $c->req;
    $c->render_json({ id => 1234 });
};

$fb->comment(
    { on => 42, message => 'too cool!' },
    sub { @res = @_; Mojo::IOLoop->stop },
);

Mojo::IOLoop->start;

is $req->body, 'access_token=s3cret&message=too+cool!', 'correct request body';
isa_ok $res[0], 'Mojo::Facebook';
delete $res[1]{__tx};
is_deeply $res[1], { id => 1234 }, 'correct response';

done_testing;
