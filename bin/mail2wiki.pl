#!/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
require Mail2Wiki;
Mail2Wiki->new->publish;

