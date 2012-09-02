package Mojolicious::Plugin::Facebook;

=head1 NAME

Mojolicious::Plugin::Facebook - Interact with Mojo::Facebook

=head1 DESCRIPTION

This module helps creating a L<Mojo::Facebook> object.

=head1 SYNOPSIS

In C<startup()>:

    sub startup {
        my $self = shift;
        $self->plugin('Mojolicious::Plugin::Facebook', {
            app_namespace => '...',
        });
    }

In a controller:

    sub do_stuff {
        my $self = shift;
        my $token = '123456sdfgh98765';

        Mojo::IOLoop->delay(
            sub {
                my($delay) = @_;
                $self->facebook($token)->fetch({}, $delay->begin);
            },
            sub {
                my($delay, $res) = @_;
                $self->render_json($res);
            },
        );
    }

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Facebook;

=head1 METHODS

=head2 register

Will register the helper C<facebook()>.

=cut

sub register {
    my($self, $app, $config) = @_;

    $app->helper(facebook => sub {
        my $c = shift;
        my %args = (@_ == 1 and ref $_[0] eq '') ? (access_token => shift) : @_;
        $args{app_namespace} = $config->{app_namespace} if $config->{app_namespace};
        Mojo::Facebook->new(%args);
    });
}

=head1 COPYRIGHT & LICENSE

See L<Mojo::Facebook>.

=head1 AUTHOR

See L<Mojo::Facebook>.

=cut

1;
