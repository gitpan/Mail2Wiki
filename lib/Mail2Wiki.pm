# ABSTRACT: read mail and send to wiki
package Mail2Wiki;
use Mail2Wiki::MailClient;
use Moose;
use Module::Runtime 'use_module';
use Config::Tiny;
use File::Slurp;
use Log::Any '$log';
use Encode ();
use utf8;



has 'config_file' => ( is => 'ro', isa => 'Str', default => 'config' );


has 'config' => (
    is      => 'ro',
    isa     => 'Config::Tiny',
    lazy    => 1,
    builder => '_build_config',
);


has 'mail_client' => (
    is      => 'ro',
    isa     => 'Mail2Wiki::MailClient',
    lazy    => 1,
    builder => '_build_mail_client',
);


has 'wiki' => (
    is      => 'ro',
    isa     => 'Mail2Wiki::Wiki',
    lazy    => 1,
    builder => '_build_wiki',
);

sub _build_config {
    my $self = shift;
    -f $self->config_file
      or $log->error( "Config file <", $self->config_file, ">unexist : $!" )
      and exit(1);
    my $config = Config::Tiny->read( $self->config_file )
      or $log->error( "read configure file failed: " . Config::Tiny->errstr )
      and exit(1);
    return $config;
}

sub _build_mail_client {
    my $self = shift;
    return Mail2Wiki::MailClient->new( %{ $self->config->{mail} } );
}

sub _build_wiki {
    my $self      = shift;
    my $wiki_type = delete $self->config->{wiki}->{type};
    return use_module(
        $wiki_type ? "Mail2Wiki::Wiki::$wiki_type" : "Mail2Wiki::Wiki" )
      ->new( %{ $self->config->{wiki} } );
}


sub publish {
    my $self = shift;

    $log->info('dump new mails from server ...');

    # Dump Mail from Account
    unless ( $self->mail_client->dump ) {
        $log->error("Dump Mail failed");
        return;
    }
    $log->info('dump Done ...');

    # Post Wiki
    $log->info('post each mail to wiki ...');
    while ( my $m = $self->mail_client->get_mail ) {
        $log->info( " posting : " . Encode::encode( 'utf8', $m->subject ) );
        eval {
            $self->wiki->post(
                subject => $m->subject,
                file    => $m->file,
                content => $m->content,
                poster  => $m->poster,
            );
        }
          or $log->warn( "> post failed of : "
              . Encode::encode( 'utf8', $m->subject )
              . ": $@" );
        $log->info("> Done.");
    }
    $log->info('post Done ...');
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Mail2Wiki - read mail and send to wiki

=head1 VERSION

version 0.014

=head1 SYNOPSIS

=head2 Configure

  # config.ini in current dir
  [mail]
  server = mail.alibaba-inc.com
  port   = 993
  user   = mycount
  pass   = hello1234

  # Wiki settings
  [wiki]
  type   = MindTouch
  domain = x.wf.taobao.org
  user   = wikicount
  pass   = hello1234
  prefix = PE/mail
  ;prefix = User

  # create data directory mail2wiki used
  mkdir data

=head2 Run

  mail2wiki.pl

=encoding utf8

=head1 Attributes

=head2 config_file

configure file, default C<./config>

=head2 config

configure, parsed, an L<Config::Tiny> object, readonly

=head2 mail_client

mail client to dump new mail, a Mail2Wiki::MailClient object, readonly

=head2 wiki

the wiki object to post content to wiki, an abstract object,
must suplly an instant class use configure : C<wiki_type=foo>, readonly

=head1 method

=head2 publish

B<publish>, which means dump the mail and post to wiki, accomplish all work

=head1 AUTHOR

ChinaXing(陈云星) <chen.yack@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by ChinaXing(陈云星).

This is free software, licensed under:

  The (three-clause) BSD License

=cut
