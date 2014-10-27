package Mail2Wiki::Mail;
# ABSTRACT: Mail object contains file, content, subject poster
use Moose;
use File::Slurp;
use Log::Any '$log';
use utf8;


has file    => ( is => 'ro', isa => 'ArrayRef[ArrayRef[Str]]' );
has content => ( is => 'ro', isa => 'Str' );                       # utf8
has subject => ( is => 'ro', isa => 'Str' );
has poster  => ( is => 'ro', isa => 'Str' );

sub dump {
    my $self = shift;
    write_file( "data/test", { bindmode => ':utf8' }, $self->content )
      if $ENV{MAIL2WIKI_DEBUG};
    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail2Wiki::Mail - Mail object contains file, content, subject poster

=head1 VERSION

version 0.016

=head1 AUTHOR

ChinaXing(陈云星) <chen.yack@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by ChinaXing(陈云星).

This is free software, licensed under:

  The (three-clause) BSD License

=cut
