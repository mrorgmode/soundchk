# -*- mode: cperl ; mode: font-lock -*-   for emacs
package CrawlDB;
use strict;
use Storable qw(nstore retrieve);



sub new {
  my $proto       = shift;
  my %args        = @_;
  my $class       = ref($proto) || $proto;
  my $self        = { filebase => $args{filebase} };

  map { defined($args{$_}) || die("must define $_") }  qw/filebase/;
  bless ($self, $class);

  $self->{name_todolist} = $self->{filebase}.".todolist";
  $self->{name_record}   = $self->{filebase}.".record";

  unless (-f $self->{name_todolist}) {
    my @todolist = ();
    my %record = ();
    nstore(\@todolist, $self->{filebase}.".todolist") or die "Can't store %a\n";
    nstore(\%record, $self->{filebase}.".record") or die "Can't store %a\n";
  }

  eval {
    $self->{todolist} = retrieve($self->{name_todolist}) || die("give up");
    $self->{record}   = retrieve($self->{name_record}) || die("give up");
  };
  if($@) { die "BADASDASD"; }

  return $self;
}



sub end {
  my $self = shift;

  $self->storeDB();
}



sub storeDB {
  my $self = shift;

  eval {
    nstore($self->{todolist}, $self->{name_todolist}) || die("give up");
    nstore($self->{record},   $self->{name_record})   || die("give up");
  };
  if($@) { die "BADASDASD"; }
}



sub isDone {
  my $self = shift;
  my %args = @_;

  return $self->{record}->{$args{code}}
    && $self->{record}->{$args{code}}->{status} eq 'done';
}



sub setStatus {
  my $self = shift;
  my %args = @_;
  $self->{record}->{$args{code}} = { %args };
  $self->storeDB();
}


sub isAdded {
  my $self = shift;
  my %args = @_;

  return $self->{record}->{$args{code}};
}



sub add {
  my $self = shift;
  my %args = @_;

  $self->{record}->{$args{code}} = { %args };
  push(@{$self->{todolist}}, { %args });
  $self->storeDB();
}



sub nextLink {
  my $self = shift;

  my $link = shift(@{$self->{todolist}});
  $self->{record}->{$link->{code}}->{status} = 'start';
  $self->storeDB();
  return $link;
}



sub todolist_size {
  my $self = shift;

  return scalar(@{$self->{todolist}});
}



1;
