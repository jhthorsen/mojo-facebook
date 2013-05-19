use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Facebook;

$ENV{FAKE_FACEBOOK_URL} = '/dummy';

my $t = Test::Mojo->new;
my $fb = Mojo::Facebook->new(access_token => 's3cret');
my($req, @res);

post '/dummy/me/coolestapp:cook' => sub {
    my $c = shift;
    $req = $c->req;
    $c->render(json => { id => 1234 });
};

$fb->app_namespace('coolestapp');
$fb->publish(
    {
        to => 'me',
        action => 'cook',
        food => 'http://food.com/dinner/hamburger/story',
        message => 'some @[289459768534:cool] description',
        custom_attr => 123,
    },
    sub { @res = @_; Mojo::IOLoop->stop },
);

Mojo::IOLoop->start;
like($req->url, qr{/me/coolestapp:cook$}, 'correct url');
like($req->body, qr{access_token=s3cret}, 'got access_token in body');
like($req->body, qr{food=http.*?hamburger/story}, 'got food in body');
like($req->body, qr{message=some\+cool\+description}, 'got message in body');
like($req->body, qr{custom_attr=123}, 'got custom_attr in body');
like($req->body, qr{tags=289459768534}, 'got tags in body');

done_testing;
