#!/usr/local/bin/perl

# This is an answer to a Frequently Asked Question about Procmail, but it is 
# not a good answer. The good answer is "Don't use Procmail for this at all".
# Read the FAQ. <http://www.iki.fi/era/procmail/mini-faq.html#advanced>

# Still here? Read it again; look for "virtual domain".

# You'd add your local users in the left column, and the address they map to
# in the right column. Run this perl script and place the results in
# kevorkian.rc, then do INCLUDERC=kevorkian.rc from your main
# /etc/procmailrc or .procmailrc.

%mapping = qw(
    bart@simpson.net    bfsimpso@school.edu
    homer@simpson.net   simpson@duh.com
    lisa@simpson.net    lisa@slashdot.org
);

# No user editable parts below this line

print <<'HERE';
SHELL=/bin/sh
LOG="kevorkian.rc: Don't do this. You should be eligible for a Darwin Award.
kevorkian.rc: See the FAQ for why.
kevorkian.rc: <http://www.iki.fi/era/procmail/mini-faq.html#kevorkian>
"
LOGFILE=${LOGFILE:-kevorkian.log}

KEVORKIAN_RCPTS                     # Unset KEVORKIAN_RCPTS completely

HERE

for (keys %mapping)
{
    my ($addr) = quotemeta ($_);    # Needlessly backslashes @:s, ugh

    print <<HERE;
:0
* ^TO_$addr\\>
{ KEVORKIAN_RCPTS="\$KEVORKIAN_RCPTS $mapping{$_}" }
HERE
}

print <<'HERE';
:0
* KEVORKIAN_RCPTS ?? [^ ]
! $KEVORKIAN_RCPTS
HERE
