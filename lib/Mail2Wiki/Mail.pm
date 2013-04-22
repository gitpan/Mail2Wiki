package Mail2Wiki::Mail;
use Moose;
use File::Slurp;
use utf8;

has file    => (is => 'ro', isa => 'ArrayRef[ArrayRef[Str]]');
has content => (is => 'ro', isa => 'Str'); # utf8
has subject => (is => 'ro', isa => 'Str');
has poster  => (is => 'ro', isa => 'Str');

sub dump {
  my $self = shift;
  write_file("data/test", {bindmode => ':utf8'}, $self->content);
  return $self;
}

1;


