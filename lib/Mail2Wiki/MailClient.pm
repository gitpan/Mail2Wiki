package Mail2Wiki::MailClient;
use Moose;
use Net::IMAP::Client;
use Email::MIME;
use File::Slurp;
use Mail2Wiki::Mail;
use Mail2Wiki::Utils;
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
      port   => $self->port,
      ssl    => 1,
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
  $self->imap->select($ENV{MAIL2WIKI_DEBUG} ? 'test' : 'INBOX');
  my $all_msg = $self->imap->search('UNSEEN', '', 'US-ASCII');
  foreach (@$all_msg) {
    my $msg = $self->imap->get_rfc822_body($_);
    my $mail = Email::MIME->new($msg) or die "Create mail failed !!\n";
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
  my (@file, $content, $content_plain);
  $mail->walk_parts(
    sub {
      my ($part) = @_;
      return $part if $part->subparts;

      if ($part->content_type =~ m[text/html]i) {
        $content = $part->body_str;
      }
      elsif ($part->content_type =~ m[text/plain]i) {
        $content_plain = $part->body_str;
      }
      elsif (my $filename = $part->filename =~ s/^\s+|\s+$//r) {
        debug "store file : $filename";
        write_file("$dir$filename", {binmode => ':raw'}, $part->body);
        if (my $file_id = $part->header("Content-ID")) {
          $file_id = substr($file_id, 1, -1);
          debug "file id: " . $file_id;
          push @file, [$file_id => "$dir$filename"];
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

1;

