package Mail2Wiki::Utils;
use base 'Exporter';
our $VERSION = 0.001;
use utf8;

my $DEBUG ||= $ENV{MAIL2WIKI_DEBUG};

our @EXPORT = qw/log debug/;

sub logger {
  my $level = "info";
  $level = shift if lc $_[0] ~~ [qw/debug info error warn notice/];
  print "[" . $level . "]", shift,"\n";
}

sub debug {
  logger("debug", shift) if $DEBUG;
}

1;


