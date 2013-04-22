
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "read mail and send to wiki",
  "AUTHOR" => "ChinaXing(\351\231\210\344\272\221\346\230\237) <chen.yack\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Mail2Wiki",
  "EXE_FILES" => [
    "bin/mail2wiki.pl"
  ],
  "LICENSE" => "bsd",
  "NAME" => "Mail2Wiki",
  "PREREQ_PM" => {
    "Digest::MD5" => 0,
    "Email::MIME" => 0,
    "Encode" => 0,
    "Exporter" => 0,
    "File::Slurp" => 0,
    "FindBin" => 0,
    "Module::Runtime" => 0,
    "Mojo::DOM" => 0,
    "Mojo::UserAgent" => 0,
    "Mojo::Util" => 0,
    "Moose" => 0,
    "Net::IMAP::Client" => 0,
    "Time::Piece" => 0,
    "YAML::XS" => 0,
    "base" => 0,
    "utf8" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.006",
  "test" => {
    "TESTS" => ""
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



