use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Facebook;

$ENV{FAKE_FACEBOOK_URL} = '/dummy';

my $t = Test::Mojo->new;
my $fb = Mojo::Facebook->new(access_token => 's3cret');
my($req, @res);

post '/dummy/me/feed' => sub {
    my $c = shift;
    $req = $c->req;
    $c->render_json({ id => 1234 });
};

my($message, $tags) = $fb->_message_to_tags('@[289459768534:Some person] did some cool stuff with @[1234567891:Some other person] yey!');

is($message, 'Some person did some cool stuff with Some other person yey!', '@[...] was removed from message');
is_deeply($tags, [
    {
        id => 289459768534,
        name => 'Some person',
        offset => 0,
        length => 11,
    },
    {
        id => 1234567891,
        name => 'Some other person',
        offset => 37,
        length => 17,
    },
], 'tags was created');

$fb->post(
    {
        to => 'me',
        message => 'some @[289459768534:cool] message',
        link => 'http://perl.org',
        name => 'Perl',
        caption => 'is ice cool',
        description => 'and what cooler than beeing cool? ice cool',
        picture => 'http://st.pimg.net/perlweb/images/camel_head.v25e738a.png',
    },
    sub { @res = @_; Mojo::IOLoop->stop },
);

Mojo::IOLoop->start;
like($req->url, qr{/me/feed$}, 'correct url');
like($req->body, qr{access_token=s3cret}, 'got access_token in body');
like($req->body, qr{message=some\+cool\+message}, 'got message in body');
like($req->body, qr{link=http.*?perl\.org}, 'got link in body');
like($req->body, qr{name=Perl}, 'got name in body');
like($req->body, qr{caption=is\+ice\+cool}, 'got caption in body');
like($req->body, qr{description=and\+}, 'got description in body');
like($req->body, qr{picture=http.*?images}, 'got picture in body');

TODO: {
    local $TODO = 'I cannot figure out tagging. The doc is cryptic:/';
    like($req->body, qr{tags=\%5B.*length\%22}, 'tags were added');
}

delete $res[1]{__tx};
is_deeply($res[1], { id => 1234 }, 'got id in response');

done_testing;
