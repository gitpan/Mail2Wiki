package Mail2Wiki::MailClient;
use Moose;
use Net::IMAP::Client;
use Email::MIME;
use File::Slurp;
use Mail2Wiki::Mail;
use Log::Any '$log';
use utf8;

has server          => ( is => 'ro', isa => 'Str',  default => '127.0.0.1' );
has port            => ( is => 'ro', isa => 'Int',  default => '993' );
has user            => ( is => 'ro', isa => 'Str',  default => 'anonymouse' );
has pass            => ( is => 'ro', isa => 'Str',  default => 'None' );
has data_dir        => ( is => 'ro', isa => 'Str',  default => 'data/' );
has ssl             => ( is => 'ro', isa => 'Int',  default => 1 );
has ssl_verify_peer => ( is => 'rw', isa => 'Bool', default => 1 );
has ssl_ca_path => ( is => 'rw', isa => 'Str', default => '/etc/ssl/certs/' );
has ssl_ca_file => ( is => 'rw', isa => 'Str', default => '' );

has imap => (
    is      => 'ro',
    isa     => 'Net::IMAP::Client',
    lazy    => 1,
    default => sub {
        my $self               = shift;
        my $imap_client_config = {
            server => $self->server,
            port   => $self->port,
            ssl    => $self->ssl,
        };
        if ( $self->ssl ) {
            $imap_client_config->{ssl_verify_peer} = $self->ssl_verify_peer;
            if ( $self->ssl_verify_peer ) {
                if ( $self->ssl_ca_file ) {
                    $imap_client_config->{ssl_ca_file} = $self->ssl_ca_file;
                }
                elsif ( $self->ssl_ca_path ) {
                    $imap_client_config->{ssl_ca_path} = $self->ssl_ca_path;
                }
                else {
                    $log->error(
"You must supply ssl_ca_path or ssl_ca_file for verify server"
                    ) and exit(1);
                }
            }
        }
        my $imap = Net::IMAP::Client->new(%$imap_client_config)
          or $log->error(" create IMAP client failed : connect failed")
          and exit(1);
        $imap->login( $self->user, $self->pass )
          or $log->error( "Login-to MailServer failed: " . $imap->errstr )
          and exit(1);
        return $imap;
    }
);

has mail => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[Mail2Wiki::Mail]',
    default => sub { [] },
    handles => { add_mail => 'push', get_mail => 'shift' }
);

sub dump {
    my $self = shift;
    $self->imap->select( $ENV{MAIL2WIKI_DEBUG} ? 'test' : 'INBOX' );
    my $all_msg = $self->imap->search( 'UNSEEN', '', 'US-ASCII' );
    foreach (@$all_msg) {
        my $msg  = $self->imap->get_rfc822_body($_);
        my $mail = Email::MIME->new($msg)
          or $log->error(
            "Analysist Mail failed , maybe invalid mail content format.")
          and next;
        my ( $subject, $files, $content, $poster ) =
          _dump_mail( $self->data_dir, $mail );
        $self->add_mail(
            Mail2Wiki::Mail->new(
                subject => $subject,
                file    => $files,
                content => $$content,
                poster  => $poster,
              )    #->dump
        );
    }
    return 1;
}

sub _dump_mail {
    my ( $dir, $mail ) = @_;
    my $subject = $mail->header('Subject');
    my ($poster) = $mail->header('From') =~ m/<([^@]+)@/;
    my ( @file, $content, $content_plain );
    $mail->walk_parts(
        sub {
            my ($part) = @_;
            return $part if $part->subparts;

            if ( $part->content_type =~ m[text/html]i ) {
                $content = $part->body_str;
            }
            elsif ( $part->content_type =~ m[text/plain]i ) {
                $content_plain = $part->body_str;
            }
            elsif ( my $filename = $part->filename =~ s/^\s+|\s+$//r ) {
                $log->debug("store file : $filename");
                write_file( "$dir$filename", { binmode => ':raw' },
                    $part->body );
                if ( my $file_id = $part->header("Content-ID") ) {
                    $file_id = substr( $file_id, 1, -1 );
                    $log->debug( "file id: " . $file_id );
                    push @file, [ $file_id => "$dir$filename" ];
                }
                else {
                    push @file, ["$dir$filename"];
                }
            }
        }
    );
    $content = $content_plain unless $content;
    return $subject, \@file, \$content, $poster;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

