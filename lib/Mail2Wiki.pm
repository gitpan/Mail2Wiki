# ABSTRACT: read mail and send to wiki
package Mail2Wiki;
use Moose;
use YAML::XS 'LoadFile';
use Module::Runtime 'use_module';
use File::Slurp;
use Mail2Wiki::MailClient;
use Mail2Wiki::Wiki;
use Log::Any '$log';
use Encode ();
use utf8;

has 'config_file' => ( is => 'ro', isa => 'Str', default => 'config' );

has 'config' => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    lazy    => 1,
    builder => '_build_config',
    handles => { get_config => 'get' },
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
      or die "Config file <", $self->config_file, ">unexist : $!\n";
    my $conf = LoadFile( $self->config_file );
    return $conf;
}

sub _build_mail_client {
    my $self = shift;
    return Mail2Wiki::MailClient->new(
        server => $self->get_config('mail_server') // "",
        port   => $self->get_config('mail_port')   // 993,
        user   => $self->get_config('mail_user')   // "",
        pass   => $self->get_config('mail_pass')   // "",
    );
}

sub _build_wiki {
    my $self = shift;
    my $type = $self->get_config('wiki_type');
    my $wiki = $type ? "Mail2Wiki::Wiki::$type" : "Mail2Wiki::Wiki";
    return use_module($wiki)->new(
        domain => $self->get_config('wiki_domain') // "",
        user   => $self->get_config('wiki_user')   // "",
        pass   => $self->get_config('wiki_pass')   // "",
        prefix => $self->get_config('wiki_prefix') // "",
    );
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
        eval {
            $self->wiki->post(
                subject => $m->subject,
                file    => $m->file,
                content => $m->content,
                poster  => $m->poster,
            );
        }
          or $log->warn( " post failed of : "
              . Encode::encode( 'utf8', $m->subject )
              . ": $@" );
    }
    $log->info('post Done ...');
}

1;
