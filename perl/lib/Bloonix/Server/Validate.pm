package Bloonix::Server::Validate;

use strict;
use warnings;
use Params::Validate qw();
use Sys::Hostname;
use Bloonix::Config;

sub config {
    my ($class, $config_file) = @_;
    my $config = Bloonix::Config->parse($config_file);
    return $class->main($config);
}

sub main {
    my $class = shift;

    my %opts = Params::Validate::validate(@_, {
        proc_manager => {
            type => Params::Validate::HASHREF,
        },
        timezone => {
            type => Params::Validate::SCALAR,
            default => "Europe/Berlin",
        },
        user => {
            type => Params::Validate::SCALAR,
            default => "bloonix",
        },
        group => {
            type => Params::Validate::SCALAR,
            default => "bloonix",
        },
        hostname => {
            type => Params::Validate::SCALAR,
            default => Sys::Hostname::hostname(),
        },
        elasticsearch => {
            type => Params::Validate::HASHREF,
            default => { },
        },
        database => {
            type => Params::Validate::HASHREF,
        },
        logger => {
            type => Params::Validate::HASHREF,
            optional => 1,
        },
        elasticsearch_roll_forward => {
            type => Params::Validate::SCALAR,
            default => "/var/log/bloonix/elasticsearch-roll-forward.json"
        },
        smsgateway => {
            type => Params::Validate::HASHREF,
            optional => 1,
        },
        redirect_remote_agent_timeouts => {
            type => Params::Validate::HASHREF,
            default => { },
        },
        email => {
            type => Params::Validate::HASHREF,
        },
        allow_from => {
            type => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
            default => [ '^127\.0\.0\.1\z' ],
        },
    });

    if ($opts{allow_from} && ref($opts{allow_from}) ne "ARRAY") {
        $opts{allow_from} =~ s/\s//g;
        $opts{allow_from} = [ split /,/, $opts{allow_from} ];
    }

    $opts{email} = $class->email($opts{email});

    if ($opts{smsgateway}) {
        $opts{smsgateway} = $class->smsgateway($opts{smsgateway});
    }

    $opts{redirect_remote_agent_timeouts} = $class->redirect_remote_agent_timeouts($opts{redirect_remote_agent_timeouts});

    $opts{elasticsearch_roll_forward} = {
        filename => $opts{elasticsearch_roll_forward},
        filelock => 0,
        reopen => 1,
        autoflush => 1,
        mode => "append"
    };

    return \%opts;
}

sub email {
    my $class = shift;

    my %opts = Params::Validate::validate(@_, {
        sendmail => {
            type => Params::Validate::SCALAR,
            default => "/usr/sbin/sendmail -t -oi -oem",
        },
        from => {
            type => Params::Validate::SCALAR,
            default => 'bloonix@localhost',
        },
        bcc => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        subject => {
            type => Params::Validate::SCALAR,
            default => "*** STATUS %s FOR %h (%a) ***",
        },
    });

    return \%opts;
}

sub smsgateway {
    my $class = shift;

    my %opts = Params::Validate::validate(@_, {
        command => {
            type => Params::Validate::SCALAR,
        },
        response => {
            type => Params::Validate::SCALAR,
            default => "",
        }
    });

    return \%opts;
}

sub redirect_remote_agent_timeouts {
    my $class = shift;

    my %opts = Params::Validate::validate(@_, {
        sms_to => {
            type => Params::Validate::SCALAR,
            default => "",
        },
        mail_to => {
            type => Params::Validate::SCALAR,
            default => "",
        }
    });

    if ($opts{resp}) {
        $opts{response} = $opts{resp};
    }

    return \%opts;
}

sub request {
    my $self = shift;

    my %opts = Params::Validate::validate(@_, {
        whoami => {
            type => Params::Validate::SCALAR,
            regex => qr/^[\w\-]+\z/,
            default => "agent"
        },
        version => {
            type => Params::Validate::SCALAR,
            regex => qr/^\d+\.\d+\z/
        },
        host_id => {
            type => Params::Validate::SCALAR,
            regex => qr/^[a-z0-9\-\.]+\z/,
            optional => 1
        },
        hostid => {
            type => Params::Validate::SCALAR,
            regex => qr/^[a-z0-9\-\.]+\z/,
            optional => 1
        },
        agent_id => {
            type => Params::Validate::SCALAR,
            default => "localhost"
        },
        agentid => {
            type => Params::Validate::SCALAR,
            optional => 1
        },
        password => {
            type => Params::Validate::SCALAR,
            optional => 1
        },
        data => {
            type => Params::Validate::HASHREF,
            optional => 1
        },
        facts => {
            type => Params::Validate::HASHREF,
            default => { }
        }
    });

    if (defined $opts{hostid}) {
        $opts{host_id} = $opts{hostid};
    }
    if ($opts{host_id} =~ /^(\d+)(\.(all|remote|localhost|intranet)){0,3}\z/) {
        $opts{host_id} = $1;
    }
    if ($opts{agentid}) {
        $opts{agent_id} = $opts{agentid};
    }
    if ($opts{agent_id} eq "0" || $opts{agent_id} eq "local") {
        $opts{agent_id} = "localhost";
    }
    if ($opts{agent_id} eq "9000") {
        $opts{agent_id} = "remote";
    }

    if (!defined $opts{host_id}) {
        die "missing host id in agent request";
    }

    return \%opts;
}

sub argv {
    my $class = shift;

    my %opts = Params::Validate::validate(@_, {
        config_file => {
            type => Params::Validate::SCALAR,
            default => "/etc/bloonix/server/main.conf",
        },
        pid_file => {
            type => Params::Validate::SCALAR,
            default => "/var/run/bloonix/bloonix-server.pid",
        },
    });

    return \%opts;
}

1;
