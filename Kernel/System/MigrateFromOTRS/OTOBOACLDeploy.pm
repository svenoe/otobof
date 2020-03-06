# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2020 Rother OSS GmbH, https://otobo.de/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::System::MigrateFromOTRS::OTOBOACLDeploy;    ## no critic

use strict;
use warnings;

use parent qw(Kernel::System::MigrateFromOTRS::Base);

our @ObjectDependencies = (
    'Kernel::Language',
    'Kernel::Config',
    'Kernel::System::ACL::DB::ACL',
    'Kernel::System::Cache',
    'Kernel::System::DateTime',
);

=head2 CheckPreviousRequirement()

check for initial conditions for running this migration step.

Returns 1 on success

    my $Result = $DBUpdateTo6Object->CheckPreviousRequirement();

=cut

sub CheckPreviousRequirement {
    my ( $Self, %Param ) = @_;

        return 1;
    }

=head1 NAME

Kernel::System::MigrateFromOTRS::OTOBOACLDeploy - Deploy the acl configuration.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # Set cache object with taskinfo and starttime to show current state in frontend
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $DateTimeObject = $Kernel::OM->Create( 'Kernel::System::DateTime');
    my $Epoch = $DateTimeObject->ToEpoch();

    $CacheObject->Set(
        Type  => 'OTRSMigration',
        Key   => 'MigrationState',
        Value => {
            Task        => 'OTOBOACLDeploy',
            SubTask     => "Deploy new ACL settings.",
            StartTime   => $Epoch,
        },
    );

    my  %Result;
    my $Location = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/Kernel/Config/Files/ZZZACL.pm';

    my $ACLDump = $Kernel::OM->Get('Kernel::System::ACL::DB::ACL')->ACLDump(
        ResultType => 'FILE',
        Location   => $Location,
        UserID     => 1,
    );

    if ( !$ACLDump ) {
        $Result{Message}    = $Self->{LanguageObject}->Translate( "Deploy the ACL configuration." );
        $Result{Comment}    = $Self->{LanguageObject}->Translate( "There was an error synchronizing the ACLs." );
        $Result{Successful} = 0;

        return \%Result;
    }

    my $Success = $Kernel::OM->Get('Kernel::System::ACL::DB::ACL')->ACLsNeedSyncReset();
    if ( !$Success ) {
        $Result{Message}    = $Self->{LanguageObject}->Translate( "Deploy the ACL configuration." );
        $Result{Comment}    = $Self->{LanguageObject}->Translate( "There was an error setting the entity sync status." );
        $Result{Successful} = 0;

        return \%Result;
    }

    $Result{Message}    = $Self->{LanguageObject}->Translate( "Deploy the ACL configuration." );
    $Result{Comment}    = $Self->{LanguageObject}->Translate( "Deployment completed, perfect!" );
    $Result{Successful} = 1;

    return \%Result;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTOBO project (L<https://otobo.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
