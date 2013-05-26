#!/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Log::Any::App '$log', -level => 'info';
require Mail2Wiki;
$log->info('Start Mail2Wiki ..');
Mail2Wiki->new->publish;
$log->info('Shutdown Mail2Wiki ..');

