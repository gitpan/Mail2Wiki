package Mail2Wiki::MailClient;
use Moose;
use Net::IMAP::Client;
use Email::MIME;
use File::Slurp;
use Mail2Wiki::Mail;
use Encode qw/encode decode/;
use utf8;

has server   => (is => 'ro', isa => 'Str', default => '127.0.0.1');
has port     => (is => 'ro', isa => 'Int', default => '993');
has user     => (is => 'ro', isa => 'Str', default => 'anonymouse');
has pass     => (is => 'ro', isa => 'Str', default => 'None');
has data_dir => (is => 'ro', isa => 'Str', default => 'data/');

has imap => (
  is      => 'ro',
  isa     => 'Net::IMAP::Client',
  lazy    => 1,
  default => sub {
    my $self = shift;
    my $imap = Net::IMAP::Client->new(
      server => $self->server,
      port    => $self->port,
      ssl     => 1,
    ) or die $Net::IMAP::Simple::errstr, "\n";
    $imap->login($self->user, $self->pass)
      or die "Login-to MailServer failed: ", $imap->errstr, "\n";
    return $imap;
  }
);

has mail => (
  is      => 'ro',
  traits  => ['Array'],
  isa     => 'ArrayRef[Mail2Wiki::Mail]',
  default => sub { [] },
  handles => {add_mail => 'push', get_mail => 'shift'}
);

sub dump {
  my $self = shift;
  $self->imap->select('INBOX');
  my $all_msg = $self->imap->search('UNSEEN','','US-ASCII');
  foreach (@$all_msg) {
    my $msg = $self->imap->get_rfc822_body($_);
    my $mail = Email::MIME->new($msg)
      or die "Create mail failed !!\n";
    my ($subject, $files, $content, $poster)
      = _dump_mail($self->data_dir, $mail);
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
  my ($dir, $mail) = @_;
  my $subject = $mail->header('Subject');
  my ($poster) = $mail->header('From') =~ m/<([^@]+)@/;
  my (@file, $content);
  $mail->walk_parts(
    sub {
      my ($part) = @_;
      if (my @subpart = $part->subparts) {
        warn "multipart\n";
        foreach my $p (@subpart) {
          warn "content-type is :", $p->content_type, ", \n";
          if ($p->content_type =~ m[image/]i) {
            my ($file) = $p->content_type =~ m[name="(.*)"];
            my $file_id = substr($p->header("Content-ID"), 1, -1);
            warn "file is: $file", ",id : ", $file_id, "\n";
            write_file("$dir$file", {binmode => ':raw'}, $p->body);
            push @file, [$file_id => "$dir$file"];
          }
        }
      }
      elsif ($part->content_type =~ m[text/html]i) {
        my $charset = $1
          if $part->content_type =~ m/charset="([^"]+)"/ ? $1 : 'utf-8';
        write_file "${dir}testtest", $part->body;
        $content
          = $charset eq 'utf-8'
          ? $part->body
          : encode('utf-8', decode($charset, $part->body, Encode::FB_CROAK),
          Encode::FB_CROAK);
      }
    }
  );
  return $subject, \@file, \$content, $poster;
}

1;

