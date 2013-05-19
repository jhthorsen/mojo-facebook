use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Facebook;

$ENV{FAKE_FACEBOOK_URL} = '/dummy';

my $t = Test::Mojo->new;
my $fb = Mojo::Facebook->new(access_token => 's3cret');
my($req, @res);

get '/dummy/:id' => sub {
    my $c = shift;
    $req = $c->req;
    $c->render(json => { id => $c->stash('id'), name => 'John Doe' });
};

$fb->fetch(
    {
        from => 42,
        fields => ['id,name'],
        limit => 10,
        offset => 1,
    },
    sub { @res = @_; Mojo::IOLoop->stop },
);

Mojo::IOLoop->start;

is $req->url, '/dummy/42?access_token=s3cret&fields=id,name&limit=10&offset=1', 'correct request url';
isa_ok $res[0], 'Mojo::Facebook';
delete $res[1]{__tx};
is_deeply $res[1], { id => 42, name => 'John Doe' }, 'correct response';

done_testing;
