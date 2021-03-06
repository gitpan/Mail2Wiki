package Mail2Wiki::Wiki::MindTouch;

# ABSTRACT: MindTouch wiki object, subclass of Wiki, post content to mindtouch wiki
use base 'Mail2Wiki::Wiki';
use Moose;
use Time::Piece;
use Mojo::UserAgent;
use Mojo::DOM;
use Mojo::Util 'url_escape';
use Log::Any '$log';
use File::Slurp;
use Digest::MD5 'md5_hex';

use Encode;
use utf8;



has ua => (
    is      => 'ro',
    isa     => 'Mojo::UserAgent',
    default => sub { Mojo::UserAgent->new->connect_timeout(3) }
);


has create_file_api => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        "http://"
          . $self->user . ":"
          . $self->pass . "@"
          . $self->domain
          . '/@api/deki/pages/=foo/files/=bar';
    }
);


has create_page_api => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        "http://"
          . $self->user . ":"
          . $self->pass . "@"
          . $self->domain
          . '/@api/deki/pages/=foo/contents';
    }
);


has dom => (
    is      => 'ro',
    isa     => 'Mojo::DOM',
    default => sub { Mojo::DOM->new->xml(0) }
);


sub post {
    my ( $self, %args ) = @_;
    my $subject = $args{subject}
      or $log->error("page subject empty !!")
      and return;
    my $file = ref $args{file} eq 'ARRAY' ? $args{file} : [ $args{file} ];
    my $content = $args{content}
      or $log->error("page content empty !!")
      and return;
    my $poster = $args{poster} or $log->warn("poster is None !!");
    $self->poster($poster) if $poster;

    # post file
    my $t;
    my $pid = $self->_post_page( $subject, \$t );
    $log->debug( "the page id is : " . $pid );
    my %file_link;
    foreach my $f (@$file) {

        my $file_path = pop @$f;

        $log->debug( "post file : " . $file_path );
        my $flink = $self->_post_file( $file_path, $pid );

        $content =~ s/(<img .*? src=")cid:\Q$f->[0]\E"/$1$flink"/sg if $f->[0];
    }

    # post content
    $pid = $self->_post_page( $subject, \$content, $pid );
    return 1;
}

sub _post_file {
    my ( $self, $file, $page_id ) = @_;
    my ($file_name) = $file =~ m[/([^/]+)$];
    my $url = $self->create_file_api =~ s/=foo/$page_id/r;
    my $filename_encoded = _double_url_escape( encode( 'utf8', $file_name ) );
    $url =~ s/=bar/=$filename_encoded/;
    my $file_content = read_file( $file, { binmode => ':raw' } );
    my $tx = $self->ua->put( $url, $file_content );
    if ( my $res = $tx->success ) {
        my $fid = $res->dom->file->{id};
        $log->debug( "post file ok : " . $file . ",file id : " . $fid );
        return $res->dom->file->contents->{href};    # file_link
    }
    $log->error( "post file failed : " . $file );
}

sub _post_page {
    my ( $self, $subject, $content, $page_id, $url ) = @_;
    if ($page_id) {
        $url = $self->create_page_api =~ s/=foo/$page_id/r;
        $url .= "?edittime=" . localtime->strftime("%Y%m%d%H%M%S");
    }
    else {
        my $title = $self->_build_title($subject);
        $url = $self->create_page_api =~ s/=foo/=$title/r;
    }

# drop html and body tag
# content strip "<meta content="MSHTML 9.00.8112.16470" name="GENERATOR"/> <style></style> <style></style> <style></style>"
    if ($$content) {
        my $bd = $self->dom->parse($$content)->find("html > body")->first;
        if ($bd) {
            $bd->children->each(
                sub {
                    my $el = shift;
                    $el->find('meta')->each( sub  { shift->remove } );
                    $el->find('style')->each( sub { shift->remove } );
                }
            );

            $$content = encode( 'utf8', $bd->children );
        }
    }
    my $tx = $self->ua->post(
        $url,
        { 'Content-Type' => "application/x-www-form-urlencoded" },
        $$content // "",
    );
    if ( my $res = $tx->success ) {
        my $pid = $res->dom->edit->page->{id};
        $log->debug( "post page ok : "
              . encode( 'utf8', $subject )
              . ",page id : "
              . $pid );
        return $pid;
    }
    $log->error( "post page failed :"
          . encode( 'utf8', $subject ) . ", tx:"
          . $tx->error );
}

sub _double_url_escape {
    url_escape( url_escape(shift) );
}

sub _build_title {
    my ( $self, $subject ) = @_;
    $subject =~ s/^.*Re: *//ui;
    $subject =~ s/^.*答复: *//ui;
    $subject =~ s/（.*$//ui;
    my $prefix =
      $self->prefix eq "User"
      ? "User:" . $self->poster . '/'
      : $self->prefix . '/';
    _double_url_escape( $prefix . encode( 'utf8', $subject ) );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail2Wiki::Wiki::MindTouch - MindTouch wiki object, subclass of Wiki, post content to mindtouch wiki

=head1 VERSION

version 0.016

=head1 ATTRIBUTES

=head2 ua

The UserAgent used to do post, a Mojo::UserAgent object

=head2 create_file_api

api used to post a file to a page.

See L<https://help.mindtouch.us/01MindTouch_TCS/Developer_Guide/API_Reference/PUT%3Apages%2F%2F%7Bpageid%7D%2F%2Ffiles%2F%2F%7Bfilename%7D>

=head2 create_page_api

api used to post a page.

See L<https://help.mindtouch.us/index.php?title=01MindTouch_TCS/Developer_Guide/API_Reference/POST:pages%2F%2F%7Bpageid%7D%2F%2Fcontents>

=head2 dom

Dom object to parse HTML mail content, a Mojo::DOM object.

=head1 METHODS

=head2 post(%args)

post an Wiki page, if has attachement, will be also posted.

=over

=item %args

B<file>: an array of filename belongs to the page

B<content>: the content of page

=back

=head1 AUTHOR

ChinaXing(陈云星) <chen.yack@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by ChinaXing(陈云星).

This is free software, licensed under:

  The (three-clause) BSD License

=cut
