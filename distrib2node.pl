#!/usr/bin/perl
################################################################################
#Script to check the policy/bins distritution to a managed node
#Author: Marco Ruiz (mruizm@hpe.com)
#Usage: perl distrib2node.pl
#Changelog:
#   v1.0: Initial release
################################################################################
#
#Future usage: perl distrib2node.pl --nodename <all|node_fqdn>
#
use warnings;
use strict;
use Socket;
my $i = 1;
my $count_distrib_file;

while (1)
{
  system("clear");
  #Get *.n files within dir /var/opt/OV/share/tmp/OpC/distrib
  my @distrib_imp_file = qx{ls -rt /var/opt/OV/share/tmp/OpC/distrib | grep -E \"\.n\$\"};
  print "\n";
  print "\rDistribution progress for a managed node:\n";
  print "\rHPOM: ".`hostname`;
  print "\rDir: /var/opt/OV/share/tmp/OpC/distrib\n\n";
  #Foreach *.n file
  foreach my $r_distrib_imp_file (@distrib_imp_file)
  {
    chomp($r_distrib_imp_file);
    my $n_r_distrib_imp_file = $r_distrib_imp_file;
    #Removes chars after file's . char
    $n_r_distrib_imp_file =~ m/(.*)\./;
    $n_r_distrib_imp_file = $1;
    #print "$n_r_distrib_imp_file\n";
    #For each *.n file look for OPC_IP_ADDRESS string
    my @nodename_from_file = qx{grep OPC_IP_ADDRESS /var/opt/OV/share/tmp/OpC/distrib/$r_distrib_imp_file | awk \'\{print \$2\}\'};
    foreach my $r_distrib_imp_file_nodename (@nodename_from_file)
    {
      #$r_distrib_imp_file_nodename contains IP address from *.n file of managed node
      chomp($r_distrib_imp_file_nodename);
      #translate IP to decimal value
      my $ip_address = ip_to_int($r_distrib_imp_file_nodename);
      #Use opc_ip_addr to translate decimal ip address to managed node fqdn
      my @resolved_ip_nodename = qx{/opt/OV/bin/OpC/install/opc_ip_addr $ip_address | uniq | awk -F\= \'\{print \$1\}\'};
      #Filter out distribution files with same id
      my @other_distrib_files = qx{ls -rt /var/opt/OV/share/tmp/OpC/distrib | grep -E \"\^$n_r_distrib_imp_file\" 2>\&1};
      #Count the number of files with same id
      foreach my $r_other_distrib_files(@other_distrib_files)
      {
        $count_distrib_file++;
      }
      #Foreach resolved ip print results
      foreach my $r_resolved_ip_nodename (@resolved_ip_nodename)
      {
        chomp($r_resolved_ip_nodename);
        ##print "\n\n$r_distrib_imp_file_nodename --> $ip_address --> $r_resolved_ip_nodename";
        print "$r_resolved_ip_nodename\tPending files: $count_distrib_file\n";
        ##print "\n\tPending files: $count_distrib_file";
      }
    }
    $count_distrib_file = 0;
  }
  $i++;
  sleep 1;
}

sub ip_to_int {
 unpack('N',inet_aton(shift));
}
