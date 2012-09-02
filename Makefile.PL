use inc::Module::Install;

name q(Mojo-Facebook);
all_from q(lib/Mojo/Facebook.pm);

requires q(Mojolicious) => 3.32;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojo-Facebook);
homepage q(https://metacpan.org/release/Mojo::Facebook);
repository q(git://github.com/jhthorsen/mojo-facebook);

auto_install;
WriteAll;
