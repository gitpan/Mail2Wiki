package Mail2Wiki::Wiki;
use Moose;
use utf8;

has domain => (is => 'ro', isa => 'Str', default => '127.0.0.1');
has user   => (is => 'ro', isa => 'Str', default => 'anonymous');
has pass   => (is => 'ro', isa => 'Str', default => 'None');
has prefix => (is => 'ro', isa => 'Str');
has poster => (is => 'rw', isa => 'Str', default => sub { shift->user });

sub post {
  warn "Unimpletmented !\n";
}

1;


