#!/bin/env perl
# ABSTRACT: binary file to bootstrap and entry the Mail2Wiki Module
# PODNAME: mail2wiki.pl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Log::Any::App '$log',
  -level  => 'info',
  -file   => 0,
  -screen => { pattern_style => 'script_long' };
require Mail2Wiki;
$log->info('Start Mail2Wiki ..');
Mail2Wiki->new->publish;
$log->info('Shutdown Mail2Wiki ..');

__END__

=pod

=encoding UTF-8

=head1 NAME

mail2wiki.pl - binary file to bootstrap and entry the Mail2Wiki Module

=head1 VERSION

version 0.016

=head1 AUTHOR

ChinaXing(陈云星) <chen.yack@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by ChinaXing(陈云星).

This is free software, licensed under:

  The (three-clause) BSD License

=cut
