package Mojo::Facebook;

=head1 NAME

Mojo::Facebook - Talk with Facebook

=head1 VERSION

0.0201

=head1 DESCRIPTION

This module implements basic actions to the Facebook graph protocol.

=head1 SYNOPSIS

    use Mojo::Facebook;
    my $fb = Mojo::Facebook->new(access_token => $some_secret);

    # fetch facebook name
    Mojo::IOLoop->delay(
        sub {
            my($delay) = @_;
            $fb->fetch({
                from => '1234567890',
                fields => 'name',
            }, $delay->begin);
        },
        sub {
            my($delay, $res) = @_;
            warn $res->{error} || $res->{name};
        },
    )

    # fetch cover photo url
    $fb->fetch({
        from => '1234567890',
        fields => ['cover']
    }, sub {
        my($fb, $res) = @_;
        return $res->{errors} if $res->{error};
        warn $res->{cover}{source}; # URL
    });

=head1 ERROR HANDLING

Facebook JSON errors will be set in the C<$res> hash returned to the callback:

=head2 Error messages

=over 4

=item * Could not decode JSON from Facebook

=item * $fb_json->{error}{message}

=item * HTTP status message

=item * Unknown error from JSON structure

=back

=cut

use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::Util qw/ url_unescape /;
use constant TEST => $INC{'Test/Mojo.pm'};

our $VERSION = eval '0.0201';

=head1 ATTRIBUTES

=head2 access_token

This attribute need to be set when doing L</fetch> on private objects
or when issuing L</post>.

=head2 app_namespace

This attribute is used by L</publish> as prefix to the publish URL:

    https://graph.facebook.com/$id/$app_namespace:$action

=cut

has access_token => '';
has app_namespace => '';
has _ua => sub { Mojo::UserAgent->new };
has _url => sub { $ENV{FAKE_FACEBOOK_URL} || 'https://graph.facebook.com' };

=head1 METHODS

=head2 fetch

    $self->fetch({
        from => $id,
        fields => [...]
        ids => [...],
        limit => $Int,
        offset => $Int,
    }, $callback);

Will fetch information from Facebook about a user.

C<$id> can be ommitted and will then default to "me".
C<$callback> will be called like this:

    $callback->($self, $res);

C<$res> will be a hash-ref containing the result. Look for the "error" key to
check for errors.

=cut

sub fetch {
    my($self, $args, $cb) = @_;
    my $tx = $self->_ua->build_tx(GET => $self->_url);
    my $url = $tx->req->url;

    if($self->access_token) {
        $url->query([ access_token => url_unescape $self->access_token ]);
    }

    for my $key (qw/ fields ids /) {
        my $value = $args->{$key} or next;
        $url->query([ $key => ref $value eq 'ARRAY' ? join ',', @$value : $value ]);
    }
    for my $key (qw/ date_format limit metadata offset since until /) {
        defined $args->{$key} or next;
        $url->query([ $key => $args->{$key} ]);
    }

    $url->path($args->{from} || 'me');
    $self->_ua->start($tx, sub { $cb->(__check_response(@_)) });
}

=head2 post

    $self->post({
        to => $id,
        message => $str,
        link => $url,
        name => $str,
        caption => $str,
        description => $str,
        picture => $url,
    }, $callback);

Creates a post at C<$who>'s wall, looking like this:

    .------------------------------------.
    | $message ...                       |
    |                                    |
    | .----------.                       |
    | | $picture |  [$link]($name)       |
    | |          |  $caption ...         |
    | |          |  $description ...     |
    | '----------'                       |
    '------------------------------------'

C<$callback> will be called like this:

    $callback->($self, $res);

C<$res> will be a hash-ref containing the result. Look for the "error" key to
check for errors.

TODO: Tags are not supported yet. Getting

    {
        "error":{
            "message":"(#100) Array does not resolve to a valid user ID",
            "type":"OAuthException",
            "code":100
        }
    }

=cut

sub post {
    my($self, $args, $cb) = @_;
    my($message, $tags) = $self->_message_to_tags($args->{message});
    my $tx = $self->_ua->build_tx(POST => $self->_url);
    my $p = Mojo::Parameters->new;

    $p->append(access_token => $self->access_token);
    $p->append(message => $message);

    for my $key (qw/ picture link name caption description source place /) {
        $args->{$key} or next;
        $p->append($key => $args->{$key});
    }

    #if(@$tags) {
    #    $p->append(tags => Mojo::JSON->new->encode($tags));
    #}

    if($args->{action} and $args->{object}) {
        $tx->req->url->path($args->{to} .'/' .join ':', @$args{qw/ object action /});
    }
    else {
        $tx->req->url->path($args->{to} .'/feed');
    }

    $tx->req->body($p->to_string);
    $self->_ua->start($tx, sub { $cb->(__check_response(@_)) });
}

sub _message_to_tags {
    my($self, $message) = @_;
    my @tags;

    while(1) {
        $message =~ s/\@\[ (\w+) : ([^\]]+) \]/$2/ox or last;

        push @tags, {
            id => int $1,
            name => $2,
            offset => $-[0],
            length => length $2,
        };
    }

    return $message, \@tags;
}

=head2 comment

    $self->comment({ on => $id, message => $str }, $callback);

Will add a comment to a graph element with the given C<$id>.

C<$callback> will be called like this:

    $callback->($self, $res);

C<$res> will be a hash-ref containing the result. Look for the "error" key to
check for errors.

=cut

sub comment {
    my($self, $args, $cb) = @_;
    my $tx = $self->_ua->build_tx(POST => $self->_url);
    my $p = Mojo::Parameters->new;

    $p->append(access_token => $self->access_token);
    $p->append(message => $args->{message});
    $tx->req->body($p->to_string);
    $tx->req->url->path($args->{on} .'/comments');
    $self->_ua->start($tx, sub { $cb->(__check_response(@_)) });
}

=head2 publish

    $self->publish({
        to => $id,
        action => $str,
        $object_name => $object_url,

        # optional
        start_time => $DateTime,
        end_time => $DateTime,
        expires_in => $int,
        message => $str,
        place => $facebook_id,
        ref => String,
        tags => "$facebook_id,...",

        # any other key/value is considered to be custom
        $custom_attribute => $any,
    });

Publish a story at C<$who>'s wall, looking like this:

    .--------------------------------------.
    | $who $action a $object_name ... $app |
    |                                      |
    | .----------.                         |
    | |  $image  |  [$url]($title)         |
    | |          |  $descripton ...        |
    | '----------'                         |
    '--------------------------------------'

Required HTML:

    <meta property="fb:app_id" content="$app_id" />
    <meta property="og:image" content="$url" />
    <meta property="og:title" content="$str" />
    <meta property="og:url" content="$url_to_self" />
    <meta property="og:description" content="$str">
    <meta property="og:type" content="$app_namespace:$action" />

C<$callback> will be called like this:

    $callback->($self, $res);

C<$res> will be a hash-ref containing the result. Look for the "error" key to
check for errors.

=cut

sub publish {
    my($self, $args, $cb) = @_;
    my $tx = $self->_ua->build_tx(POST => $self->_url);
    my $p = Mojo::Parameters->new;
    my $tags = [];

    if($args->{message}) {
        ($args->{message}, $tags) = $self->_message_to_tags($args->{message});
    }

    while(my($name, $value) = each %$args) {
        next if $name eq 'to' or $name eq 'action';
        $p->append($name => $value);
    }
    if(@$tags) {
        $p->append(tags => join ',', map { $_->{id} } @$tags);
    }

    $p->append(access_token => $self->access_token);
    $tx->req->url->path(sprintf '%s/%s:%s', $args->{to}, $self->app_namespace, $args->{action});
    $tx->req->body($p->to_string);
    $self->_ua->start($tx, sub { $cb->(__check_response(@_)) });
}

=head2 delete_object

    $self->delete_object($id, $callback);

Will try to remove an object from Facebook.

C<&callback> will be called like this:

    $callback->($self, $res);

C<$res> will be a hash-ref containing the result. Look for the "error" key to
check for errors.

=cut

sub delete_object {
    my($self, $id, $cb) = @_;
    my $tx = $self->_ua->build_tx(DELETE => $self->_url);

    $tx->req->url->query->param(access_token => $self->access_token);
    $tx->req->url->path($id);
    $self->_ua->start($tx, sub { $cb->(__check_response(@_)) });
}

=head2 picture

    $url = $self->picture;
    $url = $self->picture($who, $type);

Returns a L<Mojo::URL> object with the URL to a Facebook image.

C<$who> defaults to "me".
C<$type> can be "square", "small" or "large". Default to "square".

=cut

sub picture {
    my $self = shift;
    my $who = shift || 'me';
    my $type = shift || 'square';

    return Mojo::URL->new($self->_url)->path("$who/picture")->query(type => $type);
}

sub __check_response {
    my($ua, $tx) = @_;
    my $res = $tx->res;
    my $json = $res->json;

    if(ref $json eq 'HASH' and $json->{error}) {
        $json->{error} = $json->{error}{message} if $json->{error}{message};
        $json->{code} = $res->code;
    }
    elsif($res->error) {
        $json = { error => ($res->error)[0], code => $res->code };
    }
    elsif(!$json) {
        $json = { error => 'Could not decode JSON from Facebook', code => $res->code };
    }

    $json->{__tx} = $tx if TEST;
    return undef, $json;
}

=head1 COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen - jhthorsen@cpan.org

=cut

1;
