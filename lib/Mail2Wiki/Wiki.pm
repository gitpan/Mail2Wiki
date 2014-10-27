package Mail2Wiki::Wiki;
# ABSTRACT: Wiki object an abstract class need to be subclassed
use Moose;
use Log::Any::App '$log';
use utf8;


has domain => ( is => 'ro', isa => 'Str', default => '127.0.0.1' );
has user   => ( is => 'ro', isa => 'Str', default => 'anonymous' );
has pass   => ( is => 'ro', isa => 'Str', default => 'None' );
has prefix => ( is => 'ro', isa => 'Str' );
has poster => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $log->debug(" initial poster "); shift->user }
);

sub post {
    $log->error("subclass unimpletment the post method !");
    return;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail2Wiki::Wiki - Wiki object an abstract class need to be subclassed

=head1 VERSION

version 0.016

=head1 AUTHOR

ChinaXing(陈云星) <chen.yack@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by ChinaXing(陈云星).

This is free software, licensed under:

  The (three-clause) BSD License

=cut
