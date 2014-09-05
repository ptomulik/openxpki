# OpenXPKI::Client::UI::Home
# Written 2013 by Oliver Welter
# (C) Copyright 2013 by The OpenXPKI Project

package OpenXPKI::Client::UI::Home;

use Moose;
use Data::Dumper;
use OpenXPKI::i18n qw( i18nGettext );

extends 'OpenXPKI::Client::UI::Result';

sub BUILD {

    my $self = shift;
    $self->_page ({'label' => 'Welcome to your OpenXPKI Trustcenter'});
}

sub init_welcome {


    my $self = shift;
    my $args = shift;

    my $status = $self->send_command("get_ui_system_status");

    my @fields;

    my $critical = 0;
    if ($status->{secret_offline}) {
        push @fields, {
            label => 'Secret groups',
            format=>'link',
            value => {
                label => sprintf ('%01d secret groups are NOT available',  $status->{secret_offline}),
                page => 'secret!index',
                target => '_top'
            }
        };
        $critical = 1;
    }

    my $now = time();
    if ($status->{crl_expiry} < $now + 5*86400) {
        push @fields, {
            label  => 'CRL update required',
            format => 'timestamp',
            value  => $status->{crl_expiry}
        };
        $critical = 1 if ($status->{crl_expiry} < $now);
    }

    if ($status->{dv_expiry} < $now + 30*86400) {
        push @fields, {
            label  => 'Encryption token expires',
            format => 'timestamp',
            value  => $status->{dv_expiry}
        };
        $critical = 1 if ($status->{dv_expiry} < $now);
    }

    if ($status->{watchdog} < 1) {
        push @fields, {
            label  => 'Watchdog',
            value  => 'Not running!'
        };
        $critical = 1;
    }

    if (@fields) {
        if ($critical) {
            $self->set_status('Your system status is critical!','error');
        } else {
            $self->set_status('Your system status requires your attention!','warn');
        }
        $self->add_section({
            type => 'keyvalue',
            content => {
                label => 'OpenXPKI system status',
                data => \@fields
            }
        });
    } else {
        $self->set_status('System status is good','success');
        $self->init_index( $args );
    }

    return $self;
}

sub init_index {

    my $self = shift;
    my $args = shift;

    $self->add_section({
        type => 'text',
        content => {
            label => '',
            description => 'This page was left blank.'
        }
    });

    return $self;
}

sub init_certificate {

    my $self = shift;
    my $args = shift;

    my $search_result = $self->send_command( 'list_my_certificates' );
    return $self unless(defined $search_result);

    $self->_page({
        label => 'My Certificates',
    });

    my $i = 1;
    my @result;
    foreach my $item (@{$search_result}) {
        push @result, [
            $self->_escape($item->{'SUBJECT'}),
            $item->{'NOTBEFORE'},
            $item->{'NOTAFTER'},
            { value => $item->{'STATUS'}, label => i18nGettext('I18N_OPENXPKI_UI_CERT_STATUS_'.$item->{'STATUS'}) },
            $item->{'CERTIFICATE_SERIAL'},
            $item->{'IDENTIFIER'},
            $item->{'STATUS'},
        ]
    }

    $self->logger()->trace( "dumper result: " . Dumper @result);

    $self->add_section({
        type => 'grid',
        className => 'certificate',
        processing_type => 'all',
        content => {
            actions => [{
                path => 'certificate!detail!identifier!{identifier}',
                target => 'tab',
            }],
            columns => [
                { sTitle => "subject" },
                { sTitle => "not before", format => 'timestamp'},
                { sTitle => "not after", format => 'timestamp'},
                { sTitle => "status", format => 'certstatus'},
                { sTitle => "serial"},
                { sTitle => "identifier"},
                { sTitle => "_className"},
            ],
            data => \@result
        }
    });
    return $self;

}

sub init_workflow {

    my $self = shift;
    my $args = shift;

    my $query = {
        ATTRIBUTE => [{ KEY => 'creator', VALUE => $self->_client()->session()->param('user')->{name} }],
        LIMIT => 100
    };

    $self->logger()->debug("query : " . Dumper $query);

    my $search_result = $self->send_command( 'search_workflow_instances', $query );
    return $self unless(defined $search_result);

    $self->logger()->debug( "search result: " . Dumper $search_result);

    $self->_page({
        label => 'My Workflows',
    });

    my $i = 1;
    my @result;
    foreach my $item (@{$search_result}) {
        push @result, [
            $item->{'WORKFLOW.WORKFLOW_SERIAL'},
            $item->{'WORKFLOW.WORKFLOW_LAST_UPDATE'},
            i18nGettext($item->{'WORKFLOW.WORKFLOW_TYPE'}),
            i18nGettext($item->{'WORKFLOW.WORKFLOW_STATE'}),
            i18nGettext($item->{'WORKFLOW.WORKFLOW_PROC_STATE'}),
            $item->{'WORKFLOW.WORKFLOW_WAKEUP_AT'},
        ]
    }

    $self->logger()->trace( "dumper result: " . Dumper @result);

    $self->add_section({
        type => 'grid',
        className => 'workflow',
        processing_type => 'all',
        content => {
            actions => [{
                path => 'workflow!load!wf_id!{serial}',
                target => 'tab',
            }],
            columns => [
                { sTitle => "serial" },
                { sTitle => "updated" },
                { sTitle => "type"},
                { sTitle => "state"},
                { sTitle => "procstate"},
                { sTitle => "wake up", format => 'timestamp'},
            ],
            data => \@result
        }
    });
    return $self;

}

=head2 init_task

Outstanding tasks, for now pending approvals on CRR and CSR

=cut

sub init_task {

    my $self = shift;
    my $args = shift;

    $self->_page({
        label => 'Outstanding tasks'
    });

    # TODO - need to make enable filter for own workflows by configuration
    # CSR
    my $search_result = $self->send_command( 'search_workflow_instances', {
        LIMIT => 100,  # Safety barrier
        #ATTRIBUTE => [{ KEY => 'creator', VALUE => $self->_client()->session()->param('user')->{name}, OPERATOR => 'NOT_EQUAL' }],
        TYPE => 'I18N_OPENXPKI_WF_TYPE_CERTIFICATE_SIGNING_REQUEST_V2',
        STATE => [ 'PENDING', 'APPROVAL' ],
    });

    my @csr;
    foreach my $item (@{$search_result}) {
        push @csr, [
            $item->{'WORKFLOW.WORKFLOW_SERIAL'},
            $item->{'WORKFLOW.WORKFLOW_LAST_UPDATE'},
            i18nGettext($item->{'WORKFLOW.WORKFLOW_TYPE'}),
            i18nGettext($item->{'WORKFLOW.WORKFLOW_STATE'}),
            i18nGettext($item->{'WORKFLOW.WORKFLOW_PROC_STATE'}),
        ]
    }

    $self->logger()->trace( "dumper result: " . Dumper @csr);

    $self->add_section({
        type => 'grid',
        className => 'workflow',
        processing_type => 'all',
        content => {
            label => 'Certificate requests',
            actions => [{
                path => 'redirect!workflow!load!wf_id!{serial}',
                icon => 'view',
            }],
            columns => [
                { sTitle => "serial" },
                { sTitle => "updated" },
                { sTitle => "type"},
                { sTitle => "state"},
                { sTitle => "procstate"},
            ],
            data => \@csr
        }
    });


    $search_result = $self->send_command( 'search_workflow_instances', {
        LIMIT => 100,  # Safety barrier
        #ATTRIBUTE => [{ KEY => 'creator', VALUE => $self->_client()->session()->param('user')->{name}, OPERATOR => 'NOT_EQUAL' }],
        TYPE => 'I18N_OPENXPKI_WF_TYPE_CERTIFICATE_REVOCATION_REQUEST_V2',
        STATE => [ 'PENDING', 'ONHOLD' ],
    });

    my @crr = ();
    foreach my $item (@{$search_result}) {
        push @crr, [
            $item->{'WORKFLOW.WORKFLOW_SERIAL'},
            $item->{'WORKFLOW.WORKFLOW_LAST_UPDATE'},
            i18nGettext($item->{'WORKFLOW.WORKFLOW_TYPE'}),
            i18nGettext($item->{'WORKFLOW.WORKFLOW_STATE'}),
            i18nGettext($item->{'WORKFLOW.WORKFLOW_PROC_STATE'}),
        ]
    }

    $self->logger()->trace( "dumper result: " . Dumper @crr);

    $self->add_section({
        type => 'grid',
        className => 'workflow',
        processing_type => 'all',
        content => {
            label => 'Revocation requests',
            actions => [{
                path => 'redirect!workflow!load!wf_id!{serial}',
                icon => 'view',
            }],
            columns => [
                { sTitle => "serial" },
                { sTitle => "updated" },
                { sTitle => "type"},
                { sTitle => "state"},
                { sTitle => "procstate"},
            ],
            data => \@crr
        }
    });


}

1;
