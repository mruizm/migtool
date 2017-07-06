# v1.0.4
#!/usr/bin/perl
# Switches:
#            --assign_ng|-a                       #<---- completed - to make nodegroup assignment based on --dwn_ng_assign
#            --distrib_pols|-b                    #<---- completed - to distribute policies
#            --dwn_ng_assign|-c                   #<---- completed - to download nodegroup assignment
#            --hosts_entry|-d                     #<---- completed - to add hpom entries into node's hosts file
#            --local_test|-e 'http|https|icmp|oastatus'    #<---- completed - to test 'http|https|icmp' from HPOM to managed node
#            --pol_own|-f '<target_pri_hpom>'     #<---- in progress - to update managed node policy ownership
#            --remote_test|-f                     #not yet implemented
#            --update_certs|-h                    #<---- completed - to update trusted certificates
#            --update_hpom_mgr|-i                 #<---- completed - to update agent hpom variables
#            #complementary switches
#            --gen_node_list|-g                   #<---- completed - complementary switch to generate on the fly list of managed nodes
#            --mgmt_server|-m                     #<---- completed - complementary switch for input file with hpom host entries (hosts file like)
#            --node_input_list|-l                 #<---- completed - complementary switch to use input file with list of managed nodes
#            --filter '<string_pattern_a>|<string_pattern_b>|...'            #<---- completed - complementary switch to use with --gen_node_list to filter out nodes based
#                                                                                   in certain node caracteristic (nodename, ip address, machine type)
# Changelog:
# v1.03 -added filter for ip within --gen_node_list parm
# v1.04 -changed file generated with --gen_node_list (ip;nodename;machine_type)
# v1.04 -added switch to create DSF file based on an input node list file
#
use strict;
use warnings;
use Getopt::Long;
use Switch;
use Net::Ping;

#Init of script options
my $hosts_entry = '';
my $gen_node_list = '';
my $distrib_pols = '';
my $update_certs = '';
my $update_hpom_mgr = '';
my $assign_ng = '';
my $dwn_ng_assign = '';
my $mgmt_server = '';
my $node_input_list = '';
my $test_comp_local = '';
my $test_comp_remote = '';
my $filter_string = '';
#########################
#Init of vars while reading node list for options
my $node_is_controlled = "0";
my $already_tested_383 = "0";
my $in_nodeline = '';
my $init_csv_line = '';
my $in_nodename = '';
my $in_nodename_ip = '';
my $in_nodename_mach_type = '';
my @r_check_node_in_HPOM = ();
my $datetime_stamp_log = '';
my $r_testOvdeploy_HpomToNode_383_SSL = '';
my $final_node_list_input = '';
##################################################
#Init of vars for $hosts_entry options
my $r_append_om_entries_to_hosts_file = '';
######################################
#Init of vars for $distrib_pols options
my $r_distribute_pols = '';
#######################################
#Init of vars for $update_certs options
my $r_update_cert = '';
#######################################
#Init of vars to validate script options for $test_comp_local
my @splitted_check_comps = ();
my @unique_check_comps = ();
my $boolean_parm_found = '';
my @valid_option_parms = ();
my @a_check_comp = qw/http https icmp oastatus/;
my %hash_check_value = ();
my $k_to_node_http_test = 'a_http';
my $k_to_node_https_test = 'b_https';
my $k_to_node_icmp_test = 'c_icmp';
my $k_to_node_oa_status = 'd_oastatus';
my @test_header_values = ();
my @test_return_values = ();
my $counter_iterations = 0;
my $r_testOvdeploy_HpomToNode_383_SSL_local;
my $r_testOvdeploy_HpomToNode_383_local;
my $r_test_icmp_to_node;
my $r_oastatus;
my $scalar_test_header_values;
my $scalar_test_return_values;
#############################################################
#Init of vars to validate $mgmt_server input file
my $pri_vip_hpom_found = 0;
#################################################
#Init of vars for $dwn_ng_assign options
my $pri_hpom_fqdn = '';
my $sec_hpom_fqdn = '';
my $vip_hpom_fqdn = '';
########################################
#Init of vars for $assign_ng options
my $ng_node_line = '';
my $nodename_assign = '';
my $node_group_name = '';
########################################
#Init of vars for $pol_own options
my $pol_own = '';
my $r_update_pol_own = '';
########################################
#Init of vars for $final_node_list_input options
my @splitted_filter_string = ();
my @unique_filter_string = ();
########################################
#Init of script working paths
my $migtool_dir = '/var/opt/OpC_local/MIGTOOL';
my $migtool_node_list_dir = $migtool_dir.'/node_list';
my $migtool_log_dir = $migtool_dir.'/log';
my $migtool_tmp_dir = $migtool_dir.'/tmp';
my $migtool_csv_dir = $migtool_dir.'/csv';
my $migtool_sql_dir = $migtool_dir.'/sql';
chomp(my $datetime_stamp = `date "+%m%d%Y_%H%M%S"`);
my $gen_node_list_file = $migtool_node_list_dir.'/managed_node_list.'.$datetime_stamp.'.lst';
my $csv_file = $migtool_csv_dir.'/node_tests.'.$datetime_stamp.'.csv';
my $migtool_log = $migtool_log_dir.'/migtool.'.$datetime_stamp.'.log';
##############################

#Create needed directories
system("mkdir -p $migtool_dir") if (!-d $migtool_dir);
system("mkdir -p $migtool_node_list_dir") if (!-d $migtool_node_list_dir);
system("mkdir -p $migtool_log_dir") if (!-d $migtool_log_dir);
system("mkdir -p $migtool_tmp_dir") if (!-d $migtool_tmp_dir);
system("mkdir -p $migtool_csv_dir") if (!-d $migtool_csv_dir);
system("mkdir -p $migtool_sql_dir") if (!-d $migtool_sql_dir);

#Definition of all available options within script
GetOptions( 'assign_ng|a=s' => \$assign_ng,                 #<---- completed - to make nodegroup assignment based on --dwn_ng_assign
            'distrib_pols|b' => \$distrib_pols,             #<---- completed - to distribute policies
            'dwn_ng_assign|c' => \$dwn_ng_assign,           #<---- completed - to download nodegroup assignment
            'hosts_entry|d' => \$hosts_entry,               #<---- completed - to add hpom entries into node's hosts file
            'local_test|e=s' => \$test_comp_local,          #<---- completed - to test 'http|https|icmp' from HPOM to managed node
            'pol_own|f=s' => \$pol_own,                     #<---- in progress - to update managed node policy ownership
            'remote_test|h' => \$test_comp_remote,          #not yet implemented
            'update_certs|i' => \$update_certs,             #<---- completed - to update trusted certificates
            'update_hpom_mgr|j' => \$update_hpom_mgr,       #<---- completed - to update agent hpom variables
            #complementary switches
            'gen_node_list|g' => \$gen_node_list,           #<---- completed - complementary switch to generate on the fly list of managed nodes
            'mgmt_server|m=s' => \$mgmt_server,             #<---- completed - complementary switch for input file with hpom host entries (hosts file like)
            'node_input_list|l=s' => \$node_input_list,     #<---- completed - complementary switch to use input file with list of managed nodes
            'filter|o=s' => \$filter_string);               #<---- in process - complementary switch to use with --gen_node_list to filter out nodes based
            #                                                      in certain node caracteristic (ip/domain/net_type/match_type/comm_type)

#If none of the mandatory options is defined
if ((!$gen_node_list && !$node_input_list) && ($distrib_pols || $hosts_entry || $test_comp_local || $update_hpom_mgr || $pol_own))
#if ((!$gen_node_list && !$node_input_list) && (!$assign_ng))
{
  print "\nAny of the options requires either one of the following parameters:\n";
  print " --gen_node_list|-g\n";
  print " --node_input_list|-l <input_file>\n";
  print "\n";
  exit 0;
}
#if none of the mandatory options is defined
if ($gen_node_list && $node_input_list)
{
  print "\nChoose just ONE the following parameters:\n";
  print " --gen_node_list|-g\n";
  print " --node_input_list|-l <input_file>\n";
  print "\n";
  exit 0;
}
#Option to download assignments groups for all managed nodes
if ($dwn_ng_assign)
{
  if (!$mgmt_server)
  {
    print "Option needs parameter --mgmt_server|m <input_file>\n\n";
    exit 0;
  }
  print "\nChecking syntax of $mgmt_server file...";
  open(MGR_FILE_IN, "< $mgmt_server")
    or die "\nCan\'t open file $mgmt_server\n";
  while(<MGR_FILE_IN>)
  {
    chomp(my $mgr_line = $_);
    if ($mgr_line =~ m/(.*)\s+?(.*)\s+?(.*)\s+?\#Primary_HPOM_MIGTOOL$/)
    {
      $mgr_line =~ m/(.*)\s+?(.*)\s+?(.*)\s+?\#Primary_HPOM_MIGTOOL$/;
      chomp($pri_hpom_fqdn = $2);
      $pri_vip_hpom_found++;
    }
    if ($mgr_line =~ m/(.*)\s+?(.*)\s+?(.*)\s+?\#Secondary_HPOM_MIGTOOL$/)
    {
      $mgr_line =~ m/(.*)\s+?(.*)\s+?(.*)\s+?\#Secondary_HPOM_MIGTOOL$/;
      chomp($sec_hpom_fqdn = $2);
      $pri_vip_hpom_found++;
    }
    if ($mgr_line =~ m/(.*)\s+?(.*)\s+?(.*)\s+?\#VIP_HPOM_MIGTOOL$/)
    {
      $mgr_line =~ m/(.*)\s+?(.*)\s+?(.*)\s+?\#VIP_HPOM_MIGTOOL$/;
      chomp($vip_hpom_fqdn = $2);
      $pri_vip_hpom_found++;
    }
    #if ($mgr_line =~ m/OVR_MIGTOOL$/)
    #{
    #  $pri_vip_hpom_found++;
    #}
  }
  close(MGR_FILE_IN);
  if ($pri_vip_hpom_found !~ 3)
  {
    print "\nFile $mgmt_server does not contains correct syntax for hpom manager entries! Won\'t execute routine!\n\n";
    exit 0;
  }
  print "\rChecking syntax of $mgmt_server file...PASSED!";
  if (!-f "/etc/opt/OV/share/conf/OpC/mgmt_sv/reports/en_US.utf8/Nodegroup-Overview.sql")
  {
    print "\nSQL script /etc/opt/OV/share/conf/OpC/mgmt_sv/reports/en_US.utf8/Nodegroup-Overview.sql NOT FOUND!";
    exit 0;
  }
  print "\nDownloading assignment of nodegroups for managed nodes...";
  print "\nFilename: $migtool_sql_dir/node_2_nodegroup.$datetime_stamp.log\n\n";
  system("/opt/OV/bin/OpC/call_sqlplus.sh Nodegroup-Overview | grep -ve \"$pri_hpom_fqdn\" -ve \"$sec_hpom_fqdn\" -ve \"$vip_hpom_fqdn\" | tee -a $migtool_sql_dir/node_2_nodegroup.$datetime_stamp.log > /dev/null");
  exit 0;
}
#Option to assign nodegroups to nodes based on file generated by --dwn_ng_assign option
if ($assign_ng)
{
  print "\nStarting migtool.pl...\n";
  print "Error logfile: $migtool_log\n\n" if (!$test_comp_local);
  open(NG_FILE_IN, "< $assign_ng")
    or die "\nCan\'t open file $assign_ng\n";
  while(<NG_FILE_IN>)
  {
    chomp($ng_node_line = $_);
    if ($ng_node_line =~ m/([(\w\d\-\.?)]+)\s+(.*)/)
    {
      chomp($nodename_assign = $1);
      chomp($node_group_name = $2);
      @r_check_node_in_HPOM = check_node_in_HPOM($nodename_assign);
      if($r_check_node_in_HPOM[0] eq "0")
      {
        #Node NOT FOUND
        print "\nNode $nodename_assign NOT FOUND...SKIPPING!";
        chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
        script_logger($datetime_stamp_log, $migtool_log, "$nodename_assign:node_pre_check_assign_ng:check_node_in_HPOM():NODE_NOT_FOUND");
        next;
      }
      else
      {
        #print "Nodegroup => $node_group_name\n";
        system("opcnode -list_groups | grep ^Name | cut -d'=' -f2 | grep -e \'^ $node_group_name\' > /dev/null");
        if ($? eq "0")
        {
          print "\n$nodename_assign => \"$node_group_name\"";
          chomp($in_nodename_mach_type = $r_check_node_in_HPOM[2]);
          system("opcnode -assign_node group_name=\"$node_group_name\" node_name=$nodename_assign net_type=$in_nodename_mach_type > /dev/null");
          if ($? ne "0")
          {
            print "\r$nodename_assign => \"$node_group_name\"...\nINFO: Nodegroup already assigned!";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$nodename_assign:assign_ng:$node_group_name:NODEGROUP_ALREADY_ASSIGNED");
          }
        }
        else
        {
          print "\r$nodename_assign => \"$node_group_name\"...WARNING: Nodegroup NOT FOUND!\n";
          chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
          script_logger($datetime_stamp_log, $migtool_log, "$nodename_assign:assign_ng:$node_group_name:NODEGROUP_NOT_FOUND");
          print "Want to create node group $node_group_name? (Y/N)";
          chomp(my $input_create_ng = <STDIN>);
          if($input_create_ng =~ m/YES|Y|y/)
          {
            system("opcnode -add_group group_name=\"$node_group_name\" group_label=\"$node_group_name\" > /dev/null");
            if ($? eq "0")
            {
              print "Node group $node_group_name create successfully!\n";
              #Assign node afterwards nodegroup was created
              print "$nodename_assign => \"$node_group_name\"";
              system("opcnode -assign_node group_name=\"$node_group_name\" node_name=$nodename_assign net_type=$in_nodename_mach_type > /dev/null");
              if ($? ne "0")
              {
                print "\r$nodename_assign => \"$node_group_name\"...WARNING!\nNodegroup already assigned!";
                chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
                script_logger($datetime_stamp_log, $migtool_log, "$nodename_assign:assign_ng:$node_group_name:NODEGROUP_ALREADY_ASSIGNED");
              }
            }
            else
            {
              chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
              script_logger($datetime_stamp_log, $migtool_log, "$nodename_assign:assign_ng:$node_group_name:CANT_CREATE_NODEGROUP");
            }
          }
          if($input_create_ng =~ m/NO|N|n/)
          {
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$nodename_assign:assign_ng:$node_group_name:NODEGROUP_NOT_CREATED");
          }
        }
      }
    }
  }
  print "Error logfile: $migtool_log\n" if (!$test_comp_local);
}

#Switch to generate list of managed nodes
if ($gen_node_list && (!$hosts_entry || !$distrib_pols || !$update_certs || !$update_hpom_mgr || !$assign_ng || !$test_comp_local || !$node_input_list || !$pol_own))
{
  if ($filter_string)
  {
    #Validates that the options entered in --local_test are unique and are contained in the the available ones
    print "\nFilters to evaluate: ".join(' ', split(/\|/, $filter_string));
    @splitted_filter_string = split(/\|/, $filter_string);
    print "\nRemoving duplicate parameters if found...";
    @unique_filter_string = do { my %seen; grep { !$seen{$_}++ } @splitted_filter_string };
  }
  print "\nGenerating node list...";
  gen_node_list($gen_node_list_file, \@unique_filter_string);
  if (!-f $gen_node_list_file)
  {
    print "\rGenerating list of nodes...FAILED!";
    print "Can't continue with script!\n";
    exit 0;
  }
  else
  {
    print "\rGenerating list of nodes...COMPLETED!\n";
    print "File generated: $gen_node_list_file\n";
    $final_node_list_input = $gen_node_list_file;
  }
}
#Switch to test 'https|http|ping' from hpom to managed node
if ($test_comp_local)
{
  #if (!$mgmt_server)
  #{
  #  print "Option --local_test needs --mgmt_server|-m option!\n\n";
  #  exit 0;
  #}
  #Switches that can't be used with --local_test|-t
  if ($hosts_entry || $distrib_pols || $update_certs || $update_hpom_mgr || $pol_own)
  {
    print "Option \'--local_test|-e\' can\'t be used with any other option!\n\n";
    exit 0;
  }
  #Validates that the options entered in --local_test are unique and are contained in the the available ones
  print "\nAudit parms to evaluate: ".join(' ', split(/\|/, $test_comp_local));
  @splitted_check_comps = split(/\|/, $test_comp_local);
  print "\nRemoving duplicate parameters if found...";
  @unique_check_comps = do { my %seen; grep { !$seen{$_}++ } @splitted_check_comps };
  print "\nVerifying \'--local_test|-e\' parameters...";
  @splitted_check_comps = split(/\|/, $test_comp_local);
  #Loop that validates that entered parameters are within available ones in @a_check_comp
  foreach my $current_splitted_check_comps (@unique_check_comps)
  {
    $boolean_parm_found = 0;
    foreach my $current_a_check_comp (@a_check_comp)
    {
      #print "Comparing $current_splitted_check_comps (parm from script) = $current_a_check_comp (static)\n";
      #Pushes elements as a valid one
      if($current_splitted_check_comps =~ m/^$current_a_check_comp$/)
      {
        $boolean_parm_found = 1;
        push(@valid_option_parms, $current_splitted_check_comps);
        #print "Processing the following '--check' parameter: $current_splitted_check_comps!\n";
        last;
      }
    }
    #print "boolean: $boolean_parm_found\n";
    #Conditional that states that an entered parameter is not a valid one
    if ($boolean_parm_found == 0)
    {
      print "\rVerifying \'--local_test|-e\' parameters...NOT PASSED!";
      print "\nParameter \'$current_splitted_check_comps\' is not available for \'--local_test|-e\' option!\n";
      exit 0;
    }
  }
  print "\rVerifying \'--local_test|-e\' parameters...PASSED!";
}

if($hosts_entry || $distrib_pols || $update_certs || $update_hpom_mgr || $test_comp_local || $dwn_ng_assign || $pol_own)
{
  #Validation of $mgmt_server input file
  if (($hosts_entry || $update_hpom_mgr) && $mgmt_server)
  {
    print "\nChecking syntax of $mgmt_server file...";
    open(MGR_FILE_IN, "< $mgmt_server")
      or die "\nCan\'t open file $mgmt_server\n";
    while(<MGR_FILE_IN>)
    {
      chomp(my $mgr_line = $_);
      if ($mgr_line =~ m/(.*)\s+?(.*)\s+?(.*)\s+?\#Primary_HPOM_MIGTOOL$/)
      {
        $pri_vip_hpom_found++;
      }
      if ($mgr_line =~ m/(.*)\s+?(.*)\s+?(.*)\s+?\#Secondary_HPOM_MIGTOOL$/)
      {
        $pri_vip_hpom_found++;
      }
      if ($mgr_line =~ m/(.*)\s+?(.*)\s+?(.*)\s+?\#VIP_HPOM_MIGTOOL$/)
      {
        $pri_vip_hpom_found++;
      }
      #if ($mgr_line =~ m/OVR_MIGTOOL$/)
      #{
      #  $pri_vip_hpom_found++;
      #}
    }
    close(MGR_FILE_IN);
    if ($pri_vip_hpom_found != 3)
    {
      print "\nFile $mgmt_server does not contains correct syntax for hpom manager entries! Won\'t execute routine!\n\n";
      exit 0;
    }
    print "\rChecking syntax of $mgmt_server file...PASSED!";
  }
  #If '--hosts_entry|-a,' defined but no --mgmt_server|-m <input_file>' defined
  if (($hosts_entry || $update_hpom_mgr) && !$mgmt_server)
  {
    if (!$mgmt_server)
    {
      print "Option needs parameter --mgmt_server|m <input_file>\n\n";
      exit 0;
    }
  }
 #Start of script after all options validations passed
  print "\nStarting migtool.pl...\n";
  print "Error logfile: $migtool_log\n" if (!$test_comp_local);

  #When '--node_input_list|-l <input_file>' defined
  if ($node_input_list)
  {
    $final_node_list_input = $node_input_list;
  }
  #When '--gen_node_list|-g' defined
  if ($gen_node_list)
  {
    print "\nGenerating controlled node list...";
    gen_controlled_node_list($gen_node_list_file);
    if (!-f $gen_node_list_file)
    {
      print "\rGenerating list of controlled nodes...FAILED!";
      print "Can't continue with script!\n";
      exit 0;
    }
    else
    {
      print "\rGenerating list of controlled nodes...COMPLETED!";
      $final_node_list_input = $gen_node_list_file;
    }
  }
  #open files either using input list or the list generated on the fly of managed nodes
  open(INPUT_NODELIST_USER, "< $final_node_list_input")
    or die "\nCan't open file $final_node_list_input\n";

  #Reads nodes input file
  while (<INPUT_NODELIST_USER>)
  {
    #print "\n$in_nodeline\n";
    $node_is_controlled = "0";
    $already_tested_383 = "0";
    chomp($in_nodeline = $_);
    $in_nodeline =~ m/(.*);(.*);(.*)/;
    chomp($in_nodename = $1);
    chomp($in_nodename_ip = $2);
    chomp($in_nodename_mach_type = $3);
    if ($gen_node_list)
    {
      $init_csv_line = $in_nodeline;
      #chomp($in_nodename = $1);
      #chomp($in_nodename_ip = $2);
      #chomp($in_nodename_mach_type = $3);
    }
    #If '--node_input_list|-l <input_file>' defined scripts makes and initial check of the managed node to whether if found or not
    if ($node_input_list)
    {
      #chomp($in_nodename = $1);
      #chomp($in_nodename_ip = $2);
      #chomp($in_nodename_mach_type = $3);
      $in_nodeline = $in_nodename;
      @r_check_node_in_HPOM = check_node_in_HPOM($in_nodeline);
      if ($test_comp_local)
      {
        if($r_check_node_in_HPOM[0] eq "0")
        {
          #
          chomp($in_nodename_ip = "NOT_FOUND");
          chomp($in_nodename_mach_type = "NOT_FOUND");
          #$init_csv_line = "$in_nodename;NOT_FOUND";
          #print "$init_csv_line\n";
        }
        #else
        #{
          #chomp($in_nodename = $in_nodeline);
          #chomp($in_nodename_ip = $r_check_node_in_HPOM[1]);
          #chomp($in_nodename_mach_type = $r_check_node_in_HPOM[3]);
        #}
      }
      if (!$test_comp_local)
      {
        #print "\nCheck HPOM: $r_check_node_in_HPOM[1]\n";
        #print "\nCSV: $in_nodename;$in_nodename_ip;$in_nodename_mach_type\n";
        print "\n\nManaged node: $in_nodeline\n";
        #chomp($in_nodename = $in_nodeline);
        if($r_check_node_in_HPOM[0] eq "0")
        {
          print "\nChecking https...Skipping! NODE NOT FOUND!";
          chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
          script_logger($datetime_stamp_log, $migtool_log, "$in_nodeline:node_pre_check:check_node_in_HPOM():NODE_NOT_FOUND");
          next;
        }
        if(($r_check_node_in_HPOM[0] eq "1") && ($in_nodename_mach_type =~ m/MACH_BBC_OTHER/))
        {
            print "\nChecking https...Skipping! NOT CONTROLLED NODE";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodeline:node_pre_check:check_node_in_HPOM():NOT_CONTROLLED");
            next;
        }
        if(($r_check_node_in_HPOM[0] eq "1") && ($in_nodename_mach_type !~ m/MACH_BBC_OTHER/))
        {
          $node_is_controlled = "1";
          #chomp($in_nodename_ip = $r_check_node_in_HPOM[1]);
          #chomp($in_nodename_mach_type = $r_check_node_in_HPOM[3]);
        }
      }
    }
    #Sets $node_is_controlled = 1 as generate list routine takes just controlled nodes
    if($gen_node_list)
    {
      $node_is_controlled = "1";
    }

    if ($node_is_controlled eq "1" || $test_comp_local)
    {
      #Option to add entries within a managed node hosts file
      if ($hosts_entry)
      {
        #print "\nCSV: $in_nodename;$in_nodename_ip;$in_nodename_mach_type\n";
        print "\n-->Adding host entries into managed node hosts file...";
        print "\nChecking https...";
        if ($already_tested_383 eq "0")
        {
          print "\rChecking https...TESTING";
          if (($r_testOvdeploy_HpomToNode_383_SSL = testOvdeploy_HpomToNode_383_SSL($in_nodename, "3000")) eq "1")
          {
            $already_tested_383 = "1";
          }
          else
          {
            $already_tested_383 = "2";
          }
        }
        if ($already_tested_383 eq "2")
        {
          print "\rChecking https...FAILED!";
          chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
          script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:hosts_entry_opt:append_om_entries_to_hosts_file():FAILED_383_HTTPS_TO_NODE");
        }
        if ($already_tested_383 eq "1")
        {
          print "\rChecking https...PASSED!";
          #if ($node_input_list)
          #{
          #  $in_nodename_mach_type = $r_check_node_in_HPOM[3];
          #}
          #print "\nMachtype: $in_nodename_mach_type\n";
          #print "\nRoutine append_om_entries_to_hosts_file() called...\n";
          $r_append_om_entries_to_hosts_file = append_om_entries_to_hosts_file($in_nodename, $in_nodename_mach_type, $migtool_tmp_dir, $mgmt_server, "3000", $datetime_stamp);
          if ($r_append_om_entries_to_hosts_file eq "2")
          {
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:hosts_entry_opt:append_om_entries_to_hosts_file():AUTOMATED_HOSTS_KEY_ENTRY_FOUND_IN_NODE");
          }
          if ($r_append_om_entries_to_hosts_file eq "3")
          {
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:hosts_entry_opt:append_om_entries_to_hosts_file():CANT_UPLOAD_HOSTS_FILE_TO_NODE");
          }
          if ($r_append_om_entries_to_hosts_file eq "1")
          {
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:hosts_entry_opt:append_om_entries_to_hosts_file():CANT_DOWNLOAD_HOSTS_FILE_FROM_NODE");
          }
        }
      }
      #Option to distribute policies to a managed node
      if ($distrib_pols)
      {
        print "\n-->Distributing policies to a managed node....";
        print "\nChecking https...";
        if ($already_tested_383 eq "0")
        {
          print "\rChecking https...TESTING";
          if (($r_testOvdeploy_HpomToNode_383_SSL = testOvdeploy_HpomToNode_383_SSL($in_nodename, "3000")) eq "1")
          {
            $already_tested_383 = "1";
          }
          else
          {
            $already_tested_383 = "2";
          }
        }
        if ($already_tested_383 eq "2")
        {
          print "\rChecking https...FAILED!";
          chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
          script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:distrib_pols_opt:distrib_pols_opt():FAILED_383_HTTPS_TO_NODE");
        }
        if ($already_tested_383 eq "1")
        {
          print "\rChecking https...PASSED!";
          print "\nDistributing policies...";
          $r_distribute_pols = distrib_pols($in_nodename);
          if ($r_distribute_pols eq "0")
          {
            print "\rDistributing policies...COMPLETED!";
            sleep 10;
          }
          if ($r_distribute_pols eq "1")
          {
            print "\rDistributing policies...FAILED!";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:distrib_pols_opt:distrib_pols():FAILED_POLICY_DISTRIBUTION");
          }
        }
      }
      #Option to update trusted certificates to a managed node
      if ($update_certs)
      {
        print "\n-->Updating trusted certificates to a managed node...";
        print "\nChecking https...";
        if ($already_tested_383 eq "0")
        {
          print "\rChecking https...TESTING";
          if (($r_testOvdeploy_HpomToNode_383_SSL = testOvdeploy_HpomToNode_383_SSL($in_nodename, "3000")) eq "1")
          {
            $already_tested_383 = "1";
          }
          else
          {
            $already_tested_383 = "2";
          }
        }
        if ($already_tested_383 eq "2")
        {
          print "\rChecking https...FAILED!";
          chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
          script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:update_certs_opt:update_certs_opt():FAILED_383_HTTPS_TO_NODE");
        }
        if ($already_tested_383 eq "1")
        {
          print "\rChecking https...PASSED!";
          print "\nUpdating certificates...";
          $r_update_cert = update_certs($in_nodename, "3000");
          #print "val: $r_update_cert\n";
          if($r_update_cert eq "0")
          {
            print "\rUpdating certificates...COMPLETED!";
          }
          if($r_update_cert eq "1")
          {
            print "\rUpdating certificates...FAILED!";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:update_certs_opt:update_certs():FAILED_CERTIFICATE_UPDATE");
          }
        }
      }
      #Option to update ovconfget within a managed node
      if ($update_hpom_mgr)
      {
        print "\n-->Updating manager within a managed node...";
        print "\nChecking https...";
        if ($already_tested_383 eq "0")
        {
          print "\rChecking https...TESTING";
          if (($r_testOvdeploy_HpomToNode_383_SSL = testOvdeploy_HpomToNode_383_SSL($in_nodename, "3000")) eq "1")
          {
            $already_tested_383 = "1";
          }
          else
          {
            $already_tested_383 = "2";
          }
        }
        if ($already_tested_383 eq "2")
        {
          print "\rChecking https...FAILED!";
          chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
          script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:update_hpom_mgr_opt:update_hpom_mgr_opt():FAILED_383_HTTPS_TO_NODE");
        }
        if ($already_tested_383 eq "1")
        {
          print "\rChecking https...PASSED!";
          $pri_vip_hpom_found = 0;
          my @r_update_hpom_mgr = update_hpom_mgr($mgmt_server, $in_nodename);
          #Update OPC_PRIMARY_MGR
          if($r_update_hpom_mgr[0] eq "0")
          {
            print "\nUpdating OPC_PRIMARY_MGR within managed node...COMPLETED!\n";
          }
          if($r_update_hpom_mgr[0] eq "1")
          {
            print "\nUpdating OPC_PRIMARY_MGR within managed node...FAILED!\n";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:update_hpom_mgr_opt:update_hpom_mgr():FAILED_UPDATE_OPC_PRIMARY_MGR");
          }
          #Update general_licmgr
          if($r_update_hpom_mgr[1] eq "0")
          {
            print "Updating general_licmgr...COMPLETED!\n";
          }
          if($r_update_hpom_mgr[1] eq "1")
          {
            print "Updating general_licmgr...FAILED!\n";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:update_hpom_mgr_opt:update_hpom_mgr():FAILED_UPDATE_general_licmgr");
          }
          #Update CERTIFICATE_SERVER
          if($r_update_hpom_mgr[2] eq "0")
          {
            print "Updating CERTIFICATE_SERVER...COMPLETED!\n";
          }
          if($r_update_hpom_mgr[2] eq "1")
          {
            print "Updating CERTIFICATE_SERVER...FAILED!\n";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:update_hpom_mgr_opt:update_hpom_mgr():FAILED_UPDATE_CERTIFICATE_SERVER");
          }
          #Update MANAGER
          if($r_update_hpom_mgr[3] eq "0")
          {
            print "Updating MANAGER...COMPLETED!\n";
          }
          if($r_update_hpom_mgr[3] eq "1")
          {
            print "Updating MANAGER...FAILED!\n";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:update_hpom_mgr_opt:update_hpom_mgr():FAILED_UPDATE_MANAGER");
          }
          #Update MANAGER
          if($r_update_hpom_mgr[4] eq "0")
          {
            print "Updating MANAGER_ID...COMPLETED!\n";
          }
          if($r_update_hpom_mgr[4] eq "1")
          {
            print "Updating MANAGER_ID...FAILED!\n";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:update_hpom_mgr_opt:update_hpom_mgr():FAILED_MANAGER_ID");
          }
        }
      }
      #Option to target HPOM take policy ownership
      if ($pol_own)
      {
        print "\n-->Updating policy ownership for all managed node policies...";
        print "\nChecking https...";
        if ($already_tested_383 eq "0")
        {
          print "\rChecking https...TESTING";
          if (($r_testOvdeploy_HpomToNode_383_SSL = testOvdeploy_HpomToNode_383_SSL($in_nodename, "3000")) eq "1")
          {
            $already_tested_383 = "1";
          }
          else
          {
            $already_tested_383 = "2";
          }
        }
        if ($already_tested_383 eq "2")
        {
          print "\rChecking https...FAILED!";
          chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
          script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:pol_own_opt:pol_own():FAILED_383_HTTPS_TO_NODE");
        }
        if ($already_tested_383 eq "1")
        {
          print "\rChecking https...PASSED!";
          print "\nUpdating policy ownership...";
          $r_update_pol_own = update_pol_own($in_nodename, $pol_own, "3000");
          #print "val: $r_update_cert\n";
          if($r_update_pol_own eq "0")
          {
            print "\rUpdating policy ownership...COMPLETED!";
          }
          if($r_update_pol_own eq "1")
          {
            print "\rUpdating policy ownership...FAILED!";
            chomp($datetime_stamp_log = `date "+%m%d%Y_%H%M%S"`);
            script_logger($datetime_stamp_log, $migtool_log, "$in_nodename:pol_own_opt:pol_own():FAILED_POL_OWNERSHIP");
          }
        }
      }

      if ($test_comp_local)
      {
        #$init_csv_line =~ m/(.*);(.*);(.*)/;
        #chomp(my $nodename = $1);
        #chomp(my $nodename_ip = $2);
        #chomp(my $nodename_mt = $3);
        #@test_return_values = ();
        #$scalar_test_return_values = "";
        my @sorted_valid_option_parms = sort @valid_option_parms;
        foreach my $current_valid_option_parms (@sorted_valid_option_parms)
        {
          switch ($current_valid_option_parms)
          {
            case "http"
            {
              if ($gen_node_list)
              {
                #$hash_check_value{$k_to_node_https_test} = "";
                $r_testOvdeploy_HpomToNode_383_local = testOvdeploy_HpomToNode_383($in_nodename_ip, "3000");
                if ($r_testOvdeploy_HpomToNode_383_local eq "1")
                {
                  $hash_check_value{$k_to_node_http_test} = "OK";
                }
                else
                {
                  $hash_check_value{$k_to_node_http_test} = "NOK";
                }
              }
              if ($node_input_list)
              {
                if ($in_nodename_ip eq "NOT_FOUND")
                {
                  $hash_check_value{$k_to_node_http_test} = "NOT_FOUND";
                }
                if ($in_nodename_mach_type =~ m/MACH_BBC_OTHER/)
                {
                  $hash_check_value{$k_to_node_http_test} = "NOT_CONTROLLED";
                }
                if ($in_nodename_ip ne "NOT_FOUND" && $in_nodename_mach_type !~ m/MACH_BBC_OTHER/)
                {
                  $r_testOvdeploy_HpomToNode_383_local = testOvdeploy_HpomToNode_383($in_nodename_ip, "3000");
                  if ($r_testOvdeploy_HpomToNode_383_local eq "1")
                  {
                    $hash_check_value{$k_to_node_http_test} = "OK";
                  }
                  else
                  {
                    $hash_check_value{$k_to_node_http_test} = "NOK";
                  }
                }
              }
            }
            case "https"
            {
              if ($gen_node_list)
              {
                #$hash_check_value{$k_to_node_https_test} = "";
                $r_testOvdeploy_HpomToNode_383_SSL_local = testOvdeploy_HpomToNode_383_SSL($in_nodename_ip, "3000");
                if ($r_testOvdeploy_HpomToNode_383_SSL_local eq "1")
                {
                  $hash_check_value{$k_to_node_https_test} = "OK";
                }
                else
                {
                  $hash_check_value{$k_to_node_https_test} = "NOK";
                }
              }
              if ($node_input_list)
              {
                if ($in_nodename_ip eq "NOT_FOUND")
                {
                  $hash_check_value{$k_to_node_https_test} = "NOT_FOUND";
                }
                if ($in_nodename_mach_type =~ m/MACH_BBC_OTHER/)
                {
                  $hash_check_value{$k_to_node_https_test} = "NOT_CONTROLLED";
                }
                if ($in_nodename_ip ne "NOT_FOUND" && $in_nodename_mach_type !~ m/MACH_BBC_OTHER/)
                {
                  $r_testOvdeploy_HpomToNode_383_SSL_local = testOvdeploy_HpomToNode_383_SSL($in_nodename_ip, "3000");
                  if ($r_testOvdeploy_HpomToNode_383_SSL_local eq "1")
                  {
                    $hash_check_value{$k_to_node_https_test} = "OK";
                  }
                  else
                  {
                    $hash_check_value{$k_to_node_https_test} = "NOK";
                  }
                }
              }
            }
            case "icmp"
            {
              #$r_test_icmp_to_node = "";
              #$hash_check_value{$k_to_node_icmp_test} = "";
              if ($gen_node_list)
              {
                #print "\nPinging $in_nodename_ip...";
                $r_test_icmp_to_node = test_icmp_to_node($in_nodename_ip);
                if ($r_test_icmp_to_node eq "0")
                {
                  #print "Ping OK!";
                  $hash_check_value{$k_to_node_icmp_test} = "OK";
                }
                if ($r_test_icmp_to_node eq "1")
                {
                  #print "Ping NOK!";
                  $hash_check_value{$k_to_node_icmp_test} = "NOK";
                }
              }
              if ($node_input_list)
              {
                if ($in_nodename_ip eq "NOT_FOUND")
                {
                  $hash_check_value{$k_to_node_icmp_test} = "NOT_FOUND";
                }
                #If node has an IP and is found within HPOM
                if ($in_nodename_ip ne "0.0.0.0" && $in_nodename_ip ne "NOT_FOUND")
                {
                  $r_test_icmp_to_node = test_icmp_to_node($in_nodename_ip);
                  if ($r_test_icmp_to_node eq "0")
                  {
                    #print "Ping OK!";
                    $hash_check_value{$k_to_node_icmp_test} = "OK";
                  }
                  if ($r_test_icmp_to_node eq "1")
                  {
                    #print "Ping NOK!";
                    $hash_check_value{$k_to_node_icmp_test} = "NOK";
                  }
                }
                if ($in_nodename_ip eq "0.0.0.0")
                {
                  $hash_check_value{$k_to_node_icmp_test} = "NA"
                }
              }
            }
            case "oastatus"
            {
              if ($gen_node_list)
              {
              }
              if ($node_input_list)
              {
                if ($in_nodename_ip eq "NOT_FOUND")
                {
                  $hash_check_value{$k_to_node_oa_status} = "NOT_FOUND";
                }
                if ($in_nodename_mach_type =~ m/MACH_BBC_OTHER/)
                {
                  $hash_check_value{$k_to_node_oa_status} = "NOT_CONTROLLED";
                }
                if ($in_nodename_ip ne "NOT_FOUND" && $in_nodename_mach_type !~ m/MACH_BBC_OTHER/)
                {
                  if ($already_tested_383 eq "0")
                  {
                    if (($r_testOvdeploy_HpomToNode_383_SSL = testOvdeploy_HpomToNode_383_SSL($in_nodename_ip, "3000")) eq "1")
                    {
                      $already_tested_383 = "1";
                    }
                    else
                    {
                      $already_tested_383 = "2";
                    }
                  }
                  if ($already_tested_383 eq "2")
                  {
                    #Failed 383 SSL Comm to managed node
                    $hash_check_value{$k_to_node_oa_status} = "NA";
                  }
                  if ($already_tested_383 eq "1")
                  {
                    #If comm 383 SSL is OK exec oastatus routine
                    $r_oastatus = oastatus($in_nodename, "3000");
                    #print "val: $r_update_cert\n";
                    if($r_oastatus eq "0")
                    {
                      $hash_check_value{$k_to_node_oa_status} = "OK";
                    }
                    if($r_oastatus eq "1")
                    {
                      $hash_check_value{$k_to_node_oa_status} = "NOK";
                    }
                  }
                }
              }
            }
          }
        }
        @test_header_values = ("node_name,node_ip,node_mach_type");
        for my $key_test_name (sort keys %hash_check_value)
        {
          push(@test_header_values, $key_test_name);
          push(@test_return_values, $hash_check_value{$key_test_name});
        }
        $scalar_test_header_values = join ',', @test_header_values;
        $scalar_test_return_values = join ',', @test_return_values;
        #print "\rRunning test(s) ... COMPLETED!\n";

        if ($counter_iterations == 0)
        {
          print "Test(s) save in csv file: $csv_file\n";
          print "\n$scalar_test_header_values";
          csv_logger($csv_file, $scalar_test_header_values);
        }
        $in_nodename =~ s/\s+//;
        csv_logger($csv_file, "$in_nodename,$in_nodename_ip,$in_nodename_mach_type,$scalar_test_return_values");
        print "\n$in_nodename,$in_nodename_ip,$in_nodename_mach_type,$scalar_test_return_values";
        $counter_iterations++;
        #print "$init_csv_line\n";
        #print join(' ', split(/\|/, $check));
        #print Dumper \@valid_option_parms;
      }
    }
    @test_return_values = ();
    %hash_check_value = ();
  }
  close(INPUT_NODELIST_USER);
  print "\n\nTest(s) save in csv file: $csv_file\n" if ($test_comp_local);
  print "\n\nError logfile: $migtool_log\n" if (!$test_comp_local);
}
print "\n";
#########################################################
#
#                   SCRIPT SUBROUTINES
#
#########################################################

#########################################################
# Sub that generates file with list of controlled nodes
# @Parms:
#   $out_managed_node_file        : File with path to which add node entries
# Return:
#   None
#########################################################
sub gen_controlled_node_list
{
  my ($out_managed_node_file) = @_;
  my @opcnode_cmd_mach_type = ();
  my $node_name = "";
  my $node_ip = "";
  my $node_mach_type = "";

  open (MYFILE, ">> $out_managed_node_file")
   or die("File not found: $out_managed_node_file");

  my @managed_node_mach_type = qw/MACH_BBC_LX26RPM_X64 MACH_BBC_LX26RPM_IPF64 MACH_BBC_LX26RPM_X86 MACH_BBC_LX26DEB_X64 MACH_BBC_LX26RPM_PPC MACH_BBC_SOL10_X86 MACH_BBC_SOL_SPARC MACH_BBC_WINXP_IPF64 MACH_BBC_WIN2K3_X64 MACH_BBC_WINNT_X86 MACH_BBC_HPUX_IPF32 MACH_BBC_HPUX_PA_RISC MACH_BBC_AIX_K64_PPC MACH_BBC_AIX_PPC/;
  foreach my $managed_node_mach_type_ele (@managed_node_mach_type)
  {
    @opcnode_cmd_mach_type = qx{opcnode -list_nodes mach_type=$managed_node_mach_type_ele};
    foreach my $opcnode_cmd_mach_type_line (@opcnode_cmd_mach_type)
    {
      if ($opcnode_cmd_mach_type_line =~ m/^Name\s+=\s+(.*)/)
      {
        chomp($node_name = $1);
      }
      if ($opcnode_cmd_mach_type_line =~ m/^IP-Address\s+=\s+(.*)/)
      {
        chomp($node_ip = $1);
      }
      if ($opcnode_cmd_mach_type_line =~ m/^Machine Type\s+=\s+(.*)/)
      {
        chomp($node_mach_type = $1);
      }
      if ($node_name && $node_ip && $node_mach_type)
      {
        #print "$node_name;$node_ip;$node_mach_type\n";
        print MYFILE "$node_name;$node_ip;$node_mach_type\n";
        $node_name = '';
        $node_ip = '';
        $node_mach_type = '';
      }
    }
  }
  close (MYFILE);
}

#########################################################
# Sub that generates file with list of controlled nodes
# @Parms:
#   $out_managed_node_file        : File with path to which add node entries
# Return:
#   None
#########################################################
sub gen_node_list
{
  my ($out_managed_node_file, $filter_string) = @_;
  my @filter_arr = @{$filter_string};
  my @opcnode_cmd_mach_type = ();
  my $node_name = "";
  my $node_ip = "";
  my $node_mach_type = "";
  my $node_skipped = "0";
  my $end_ok_node_details = "0";

  #If passed filter arary is null
  if(!@filter_arr)
  {
    @filter_arr = qw/\"\"/;
  }

  open (MYFILE, ">> $out_managed_node_file")
   or die("File not found: $out_managed_node_file");

  my @managed_node_mach_type = qw/MACH_BBC_OTHER_IP MACH_BBC_OTHER_NON_IP MACH_BBC_LX26RPM_X64 MACH_BBC_LX26RPM_IPF64 MACH_BBC_LX26RPM_X86 MACH_BBC_LX26DEB_X64 MACH_BBC_LX26RPM_PPC MACH_BBC_SOL10_X86 MACH_BBC_SOL_SPARC MACH_BBC_WINXP_IPF64 MACH_BBC_WIN2K3_X64 MACH_BBC_WINNT_X86 MACH_BBC_HPUX_IPF32 MACH_BBC_HPUX_PA_RISC MACH_BBC_AIX_K64_PPC MACH_BBC_AIX_PPC/;
  foreach my $managed_node_mach_type_ele (@managed_node_mach_type)
  {
    @opcnode_cmd_mach_type = qx{opcnode -list_nodes mach_type=$managed_node_mach_type_ele};
    foreach my $opcnode_cmd_mach_type_line (@opcnode_cmd_mach_type)
    {
      #Loops through all the filters passed by parameter
      foreach my $filter_val (@filter_arr)
      {
        chomp($filter_val);
        if ($opcnode_cmd_mach_type_line =~ m/^Name\s+=\s+(.*)/)
        {
          #print "Filter value: $filter_val\n";
          chomp($node_name = $1);
          #print "$filter_val = $node_name\n";
          #added condition to match nodes host-like valid character
          if (($node_name =~ m/$filter_val/) || ($node_name !~ m/^[\w\d\-_\.]+$/))
          {
            $node_skipped = "1";
            #print "\nSkipped $node_name";
            #print "Node skipped due filterer match!\n";
          }
        }
        if ($opcnode_cmd_mach_type_line =~ m/^IP-Address\s+=\s+(.*)/)
        {
          #print "Filter value: $filter_val\n";
          chomp($node_ip = $1);
          #print "$filter_val = $node_ip\n";
          if ($node_ip =~ m/$filter_val/)
          {
            $node_skipped = "1";
            #print "Node skipped due filterer match!\n";
          }
        }
        if ($opcnode_cmd_mach_type_line =~ m/^Machine Type\s+=\s+(.*)/)
        {
          $end_ok_node_details = "1";
          #print "Filter value: $filter_val\n";
          chomp($node_mach_type = $1);
          #print "$filter_val = $node_mach_type\n";
          if ($node_mach_type =~ m/$filter_val/)
          {
            $node_skipped = "1";
            #print "Node skipped due filterer match!\n";
          }
        }
      }
      if ($node_name && $node_ip && $node_mach_type)
      {
        #print "$node_name;$node_ip;$node_mach_type\n";
        #print MYFILE "$node_name;$node_ip;$node_mach_type\n";
        #print "node_skipped=$node_skipped\n";
        if ($node_skipped eq "0" && $end_ok_node_details eq "1")
        {
          #print "$node_name\n";
          print MYFILE "$node_name;$node_ip;$node_mach_type\n";
        }
        $node_name = '';
        $node_ip = '';
        $node_mach_type = '';
        $node_skipped = "0";
      }
    }
    $end_ok_node_details = "0";
  }
  close (MYFILE);
}

sub distrib_pols
{
  my ($nodename) = @_;
  my @distrib_pols_cmd = qx{/opt/OV/bin/OpC/opcragt -distrib -policies -force $nodename};
  foreach my $distrib_pols_cmd_line (@distrib_pols_cmd)
  {
    chomp($distrib_pols_cmd_line);
    if ($distrib_pols_cmd_line =~ m/Done/)
    {
      return 0;
    }
  }
  return 1;
}

sub update_certs
{
  my ($nodename, $cmdtimeout) = @_;
  #print "ovdeploy -cmd \"ovcert -updatetrusted\" -node $nodename -cmd_timeout $cmdtimeout\n";
  system("ovdeploy -cmd \"ovcert -updatetrusted\" -node $nodename -cmd_timeout $cmdtimeout > /dev/null");
  if ($? eq "0")
  {
    return 0;
  }
  else
  {
    return 1;
  }
  #foreach my $update_certs_line (@update_certs)
  #{
  #  chomp($update_certs_line);
  #  if ($update_certs_line =~ m/update was successful/)
  #  {
  #    return 0;
  #  }
  #}
  #return 1;
}

#########################################################
# Sub that checks node's port 383 from HPOM
# @Parms:
#   $nodename:              Nodename
#   $HPOM:                  HPOM FQDN
# Return:
#   1:                      OK
#   0:                      Timed out/Unavailable
###########################################################
sub testOvdeploy_HpomToNode_383_SSL
{
  my ($nodename, $cmdtimeout) = @_;
  my $eServiceOK_found = 1;
  my @remote_bbcutil_ping_node = qx{ovdeploy -cmd bbcutil -par \"-ping https://$nodename\" -ovrg server -cmd_timeout $cmdtimeout};
  foreach my $bbcutil_line_out (@remote_bbcutil_ping_node)
  {
    chomp($bbcutil_line_out);
    if ($bbcutil_line_out =~ m/eServiceOK/)
    {
      last;
    }
    if ($bbcutil_line_out =~ m/^ERROR:/)
    {
      $eServiceOK_found = 0;                                  # change to 1 if error while making test
      last;
    }
  }
  return $eServiceOK_found;
}

##########################################################
# Sub that checks node's port 383 from HPOM
#	@Parms:
#			$nodename:		Nodename
#     $HPOM:        HPOM FQDN
#	Return:
#			1:	OK
#			0:	Timed out/Unavailable
###########################################################
sub testOvdeploy_NodeToHpom_383
{
	my ($hpom_server_ip, $nodename, $cmdtimeout) = @_;
	chomp($nodename);
  chomp($cmdtimeout);
	my $eServiceOK_found = 1;
	my @remote_bbcutil_ping_node = qx{ovdeploy -cmd bbcutil -par \"-ping http://$hpom_server_ip\" -node $nodename -cmd_timeout $cmdtimeout};
	foreach my $bbcutil_line_out (@remote_bbcutil_ping_node)
	{
		chomp($bbcutil_line_out);
		if ($bbcutil_line_out =~ m/eServiceOK/)
		{
			last;
		}
		if ($bbcutil_line_out =~ m/^ERROR:/)
		{
			$eServiceOK_found = 0;					# change to 0 if error while making test
      last;
		}
	}
  return $eServiceOK_found;
}

##########################################################
# Sub that checks node's port 383 from HPOM
#	@Parms:
#			$nodename:		Nodename
#     $HPOM:        HPOM FQDN
#	Return:
#			1:	OK
#			0:	Timed out/Unavailable
###########################################################
sub testOvdeploy_HpomToNode_383
{
	my ($nodename, $cmdtimeout) = @_;
	chomp($nodename);
  chomp($cmdtimeout);
	my $eServiceOK_found = 1;
	my @remote_bbcutil_ping_node = qx{ovdeploy -cmd bbcutil -par \"-ping http://$nodename\" -ovrg server -cmd_timeout $cmdtimeout};
	foreach my $bbcutil_line_out (@remote_bbcutil_ping_node)
	{
		chomp($bbcutil_line_out);
		if ($bbcutil_line_out =~ m/eServiceOK/)
		{
			last;
		}
		if ($bbcutil_line_out =~ m/^ERROR:/)
		{
			$eServiceOK_found = 0;					# change to 0 if error while making test
      last;
		}
	}
  return $eServiceOK_found;
}


sub script_logger
{
  my ($date_and_time, $logfilename_with_path, $entry_to_log) = @_;
  open (MYFILE, ">> $logfilename_with_path")
   or die("File not found: $logfilename_with_path");
  print MYFILE "$date_and_time\:\:$entry_to_log\n";
  close (MYFILE);
}

sub csv_logger
{
  my ($logfilename_with_path, $entry_to_log) = @_;
  open (MYFILE, ">> $logfilename_with_path")
   or die("File not found: $logfilename_with_path");
  print MYFILE "$entry_to_log\n";
  close (MYFILE);
}

######################################################################
# Sub that checks if a managed node is within a HPOM and if found determine its ip_address, node_net_type, mach_type
#	@Parms:
#		$nodename : Nodename to check
#	Return:
#		@node_mach_type_ip_addr = (node_exists, node_ip_address, node_net_type, node_mach_type, comm_type)	:
#															[0|1],
#															[<ip_addr>],
#															[NETWORK_NO_NODE|NETWORK_IP|NETWORK_OTHER|NETWORK_UNKNOWN|PATTERN_IP_ADDR|PATTERN_IP_NAME|PATTERN_OTHER],
#															[MACH_BBC_LX26|MACH_BBC_SOL|MACH_BBC_HPUX|MACH_BBC_AIX|MACH_BBC_WIN|MACH_BBC_OTHER],
#                             [COMM_UNSPEC_COMM|COMM_BBC]
#		$node_mach_type_ip_addr[0] = 0: If nodename is not found within HPOM
#   $node_mach_type_ip_addr[0] = 1: If nodename is found within HPOM
######################################################################
sub check_node_in_HPOM
{
  my $nodename = shift;
	my $nodename_exists = 0;
	my @node_mach_type_ip_addr = ();
	my ($node_ip_address, $node_mach_type, $node_net_type, $node_comm_type) = ("", "", "", "");
	my @opcnode_out = qx{opcnode -list_nodes node_list=$nodename};
	foreach my $opnode_line_out (@opcnode_out)
	{
		chomp($opnode_line_out);
		if ($opnode_line_out =~ /^Name/)
		{
			$nodename_exists = 1;					# change to 0 if node is found
      push (@node_mach_type_ip_addr, $nodename_exists);
		}
		if ($opnode_line_out =~ m/IP-Address/)
		{
			$opnode_line_out =~ m/.*=\s(.*)/;
			$node_ip_address = $1;
			chomp($node_ip_address);
			push (@node_mach_type_ip_addr, $node_ip_address);
		}
		if ($opnode_line_out =~ m/Network\s+Type/)
		{
			$opnode_line_out =~ m/.*=\s(.*)/;
			$node_net_type = $1;
			chomp($node_net_type);
			push (@node_mach_type_ip_addr, $node_net_type);
		}
		if ($opnode_line_out =~ m/MACH_BBC_LX26|MACH_BBC_SOL|MACH_BBC_HPUX|MACH_BBC_AIX|MACH_BBC_WIN|MACH_BBC_OTHER/)
		{
			$opnode_line_out =~ m/.*=\s(.*)/;
			$node_mach_type = $1;
			chomp($node_mach_type);
			push (@node_mach_type_ip_addr, $node_mach_type);
		}
    if ($opnode_line_out =~ m/Comm\s+Type/)
    {
      $opnode_line_out =~ m/.*=\s(.*)/;
			$node_comm_type = $1;
			chomp($node_comm_type);
			push (@node_mach_type_ip_addr, $node_comm_type);
    }
	}
	# Nodename not found
	if ($nodename_exists eq 0)
	{
		$node_mach_type_ip_addr[0] = 0;
	}
  return @node_mach_type_ip_addr;
}

######################################################################
#Sub that renames a file within a managed node
# @Parms:
#   $date_time              : Timestamp
#   $file_path_one          : Files path within managed node
#   $file_path_two          : Files path within managed node
#   $filename               : Name of file to rename
#   $nodename               : Target managed node
#   $node_os                : Node's machine type
#   $cmdtimeout             : Timeout to exec ovdeploy cmd
# Return:
#   0                       : Upload finished successful
#   1                       : Error while uploading file
######################################################################
sub rename_file_routine
{
  my ($date_time, $file_path_one, $file_path_two, $filename, $nodename, $node_os, $cmdtimeout) = @_;
  my @rename_cmd = ();
  #print "$node_os\n";
  if ($node_os =~ m/MACH_BBC_WIN/)
  {
      $file_path_two =~ m/(.*\\)([\w\.]+)/;
      $file_path_two = $1;
  }
  #print "--> ovdeploy -cmd \'rename \"$file_path_one\\$filename\" \"$filename.$date_time.mcfgc\"\' -node $nodename\n" if ($verbose_flag eq "1");
  if ($node_os =~ m/MACH_BBC_WIN/)
  {
    system("ovdeploy -cmd \'rename \"$file_path_one\\$filename\" \"$filename.$date_time.bck\"\' -node $nodename -cmd_timeout $cmdtimeout > /dev/null");
  }
  if ($node_os =~ m/MACH_BBC_LX26|MACH_BBC_SOL|MACH_BBC_HPUX|MACH_BBC_AIX/)
  {
    system("ovdeploy -cmd \'mv \"$file_path_one\/$filename\" \"$file_path_two\/$filename.$date_time.bck\"\' -node $nodename -cmd_timeout $cmdtimeout > /dev/null");
  }
	if ($? ne "0")
	{
    return 1;
  }
	else
	{
    return 0;
	}
}

######################################################################
#Sub that upload a file to a managed node
# @Parms:
#   $nodename               : Target managed node
#   $mon_filename           : Filename to upload
#   $mon_file_sd            : File's source dir
#   $mon_file_td            : Target dir to upload file within managed node
#   $timeout                : Timeout to exec ovdeploy cmd
# Return:
#   0                       : Upload finished successful
#   1                       : Error while uploading file
######################################################################
sub upload_mon_file
{
  my ($nodename, $mon_filename, $mon_file_sd, $mon_file_td, $timeout) = @_;
	my @upload_cmd = qx{ovdeploy -cmd \"ovdeploy -upload -file $mon_filename -sd $mon_file_sd -td \'$mon_file_td\' -node $nodename\" -ovrg server -cmd_timeout $timeout};
  foreach my $upload_cmd_line (@upload_cmd)
  {
    chomp($upload_cmd_line);
  }
	if ($? eq "0")
	{
    return 0;
	}
	else
	{
		return 1;
	}
}

######################################################################
# Sub that add hosts entries using an input file into a managed node hosts files
#	@Parms:
#   $nodename               : Target nodename of managed node
#   $node_os                : OS of managed node
#   $target_dir_download    : Target dir to download managed node hosts file
#   $input_hpom_file        : Input file with hosts entries
#   $timeout                : Timeout to download file
#   $date_and_time          : Timestamp
#	Return:
#   0                       : OK upload of hosts file to managed node
#   1                       : Failed download of hosts file from managed node
#   2                       : Script already processed node's hosts file
#   3                       : Failed upload of hosts file to managed node
######################################################################
sub append_om_entries_to_hosts_file
{
  my ($nodename, $node_os, $target_dir_download, $input_hpom_file, $timeout, $date_and_time, $update_hpom_mgr_flag) = @_;
  my $source_file_dir = "";
  my $splitted_hpom_entry;
  my $input_line_file;
  my $input_line_file_mn;
  my @hpom_update = ();
  my @r_update_hpom_mgr = ();

  system("rm -f $target_dir_download'/hosts'");
  system("rm -f $target_dir_download'/hosts.tmp'");
  if ($node_os =~ m/MACH_BBC_WIN/)
  {
    $source_file_dir = "c:\\windows\\system32\\drivers\\etc";
  }
  if ($node_os =~ m/MACH_BBC_LX26|MACH_BBC_SOL|MACH_BBC_HPUX|MACH_BBC_AIX/)
  {
    $source_file_dir = "/etc";
  }
  #print "Downloading hosts file from managed node...";
  #my $cmd_line = "ovdeploy -cmd \"ovdeploy -download -file hosts -sd \'$source_file_dir\' -td $target_dir_download -node $nodename\" -ovrg server -cmd_timeout $timeout";
  #print "$cmd_line\n";
  system("ovdeploy -cmd \"ovdeploy -download -file hosts -sd \'$source_file_dir\' -td $target_dir_download -node $nodename\" -ovrg server -cmd_timeout $timeout > /dev/null");
  if ($? eq "0")
  {
    print "\rDownloading hosts file from managed node...COMPLETED!";
    #opens downloaded hosts file from managed node
    open(MANAGED_NODE_HOSTS_FILE, "< $target_dir_download/hosts")
      or die "Can't open file $target_dir_download/hosts\n";
    #opens input file with hosts entries
    open(INPUT_HPOM_FILE, "< $input_hpom_file")
      or die "Can't open file $input_hpom_file\n";
    #opens file to write hosts entries from input file and managed node current entries
    open(PUT_ENTRY_FILE, ">> $target_dir_download/hosts.tmp")
      or die "Can't open file $target_dir_download/hosts.tmp\n";
    print "\nAdding hosts entries into tmp hosts file...";
    #print "\n#### ENTRIES ADDED BY MIGTOOL.PL ####\n";
    #print PUT_ENTRY_FILE "#### ENTRIES ADDED BY MIGTOOL.PL ####\n";
    print PUT_ENTRY_FILE "#### START ENTRIES ADDED BY MIGTOOL.PL ####\n";
    while(<INPUT_HPOM_FILE>)
    {
      chomp($input_line_file = $_);
      #print "$input_line_file\n";
      print PUT_ENTRY_FILE "$input_line_file\n";
    }
    close(INPUT_HPOM_FILE);
    #print "####################################\n";
    #print PUT_ENTRY_FILE "####################################\n";
    print PUT_ENTRY_FILE "#### END ENTRIES ADDED BY MIGTOOL.PL ####\n";
    print "\rAdding hosts entries into tmp hosts file...COMPLETED!";
    print "\nAdding hosts entries into tmp hosts file from managed node...";
    ##print "\nChecking if previous MIGTOOL.PL line is found...";
    while(<MANAGED_NODE_HOSTS_FILE>)
    {
      chomp($input_line_file_mn = $_);
      if (/START ENTRIES ADDED BY MIGTOOL.PL/ .. /END ENTRIES ADDED BY MIGTOOL.PL/)
      {
        next;
      }
      if (/ENTRIES ADDED BY MIGTOOL.PL/ .. /\#{36}/)
      {
        next;
      }
      ##if ($input_line_file_mn =~ m/MIGTOOL/)
      ##{
      ##  print "\rChecking if previous MIGTOOL.PL line is found...FOUND, SKIPPING NODE!";
      ##  system("rm -f $target_dir_download'/hosts'");
      ##  system("rm -f $target_dir_download'/hosts.tmp'");
      ##  return 2;
      ##}
      else
      {
        #print "$input_line_file_mn\n";
        print PUT_ENTRY_FILE "$input_line_file_mn\n";
      }
    }
    ##print "\rChecking if previous MIGTOOL.PL line is found...NOT FOUND!";
    print "\nAdding hosts entries into tmp hosts file from managed node...COMPLETED!\n";
    close(MANAGED_NODE_HOSTS_FILE);
    close(PUT_ENTRY_FILE);
    print "Doing backup of managed node hosts file...";
    #my ($date_time, $file_path_one, $filename, $nodename, $node_os, $verbose_flag, $cmdtimeout) = @_;
    my $r_rename_file_routine = rename_file_routine($date_and_time, $source_file_dir, $source_file_dir, "hosts", $nodename, $node_os, $timeout);
    if ($r_rename_file_routine eq "0")
    {
      print "\rDoing backup of managed node hosts file...COMPLETED!";
    }
    else
    {
      print "\rDoing backup of managed node hosts file...FILE DOES NOT EXISTS IN PATH!";
    }
    #my ($nodename, $mon_filename, $mon_file_sd, $mon_file_td, $verbose_flag, $timeout) = @_;
    print "\nUploading hosts file to managed node...";
    system("mv $target_dir_download'/hosts.tmp' $target_dir_download'/hosts'");
    my $r_upload_mon_file = upload_mon_file($nodename, "hosts", $target_dir_download, $source_file_dir, "3000");
    if ($r_upload_mon_file eq "0")
    {
      print "\rUploading hosts file to managed node...COMPLETED!";
      system("rm -f $target_dir_download'/hosts'");
      system("rm -f $target_dir_download'/hosts.tmp'");
      return 0;
    }
    else
    {
      print "\rUploading hosts file to managed node...FAILED!";
      system("rm -f $target_dir_download'/hosts'");
      system("rm -f $target_dir_download'/hosts.tmp'");
      return 3;
    }
  }
  else
  {
    print "\rDownloading hosts file from managed node...FAILED!";
    system("rm -f $target_dir_download'/hosts'");
    system("rm -f $target_dir_download'/hosts.tmp'");
    return 1;
  }
}


sub update_hpom_mgr
{
  my ($hpom_input_file, $nodename) = @_;
  my @r_commands = ();
  my $n_hpom_fqdn;
  my @arr_hpoms = ();
  open(INPUT_HPOM_FILE, "< $hpom_input_file")
    or die "Can't open file $hpom_input_file\n";
  while(<INPUT_HPOM_FILE>)
  {
    chomp(my $input_line_mgr = $_);
    if ($input_line_mgr =~ m/Primary_HPOM_MIGTOOL$/)
    {
      $input_line_mgr =~ m/(.*)\s+?(.*)\s+?(.*)\s+?(.*)/;
      chomp($n_hpom_fqdn = $2);
      #print "$n_hpom_fqdn\n";
      push(@arr_hpoms, $n_hpom_fqdn);
    }
    if($input_line_mgr =~ m/VIP_HPOM_MIGTOOL$/)
    {
      $input_line_mgr =~ m/(.*)\s+?(.*)\s+?(.*)\s+?(.*)/;
      chomp($n_hpom_fqdn = $2);
      #print "$n_hpom_fqdn\n";
      push(@arr_hpoms, $n_hpom_fqdn);
    }
  }
  close(INPUT_HPOM_FILE);
  my $size = @arr_hpoms;
  if ($size < 1)
  {
    print "Please check input file for argument --mgmt_server\n";
    exit 0;
  }
  print "\nUpdating OPC_PRIMARY_MGR...\n";
  system("/opt/OV/bin/ovconfpar -change -host $nodename -ns eaagt -set OPC_PRIMARY_MGR $arr_hpoms[1] > /dev/null");
  #print "/opt/OV/bin/ovconfpar -change -host $nodename -ns eaagt -set OPC_PRIMARY_MGR $arr_hpoms[1] > /dev/null\n";
  if ($? eq "0")
  {
    #print "\nUpdating OPC_PRIMARY_MGR within managed node...COMPLETED!\n";
    $r_commands[0] = "0";
  }
  else
  {
    #print "\nUpdating OPC_PRIMARY_MGR within managed node...FAILED!\n";
    $r_commands[0] = "1";
  }
  print "Updating general_licmgr...\n";
  system("/opt/OV/bin/ovconfpar -change -host $nodename -ns eaagt.lic.mgrs -set general_licmgr $arr_hpoms[0] > /dev/null");
  #print "/opt/OV/bin/ovconfpar -change -host $nodename -ns eaagt.lic.mgrs -set general_licmgr $arr_hpoms[0]\n";
  if ($? eq "0")
  {
    #print "Updating general_licmgr...COMPLETED!\n";
    $r_commands[1] = "0";
  }
  else
  {
    #print "Updating general_licmgr...FAILED!\n";
    $r_commands[1] = "1";
  }
  print "Updating CERTIFICATE_SERVER...\n";
  system("/opt/OV/bin/ovconfpar -change -host $nodename -ns sec.cm.client -set CERTIFICATE_SERVER $arr_hpoms[0] > /dev/null");
  #print "/opt/OV/bin/ovconfpar -change -host $nodename -ns sec.cm.client -set CERTIFICATE_SERVER $arr_hpoms[0]\n";
  if ($? eq "0")
  {
    #print "Updating CERTIFICATE_SERVER...COMPLETED!\n";
    $r_commands[2] = "0";
  }
  else
  {
    #print "Updating CERTIFICATE_SERVER...FAILED!\n";
    $r_commands[2] = "1";
  }
  print "Updating MANAGER...\n";
  system("/opt/OV/bin/ovconfpar -change -host $nodename -ns sec.core.auth -set MANAGER $arr_hpoms[0] > /dev/null");
  #print "/opt/OV/bin/ovconfpar -change -host $nodename -ns sec.core.auth -set MANAGER $arr_hpoms[0]\n";
  if ($? eq "0")
  {
    #print "Updating MANAGER...COMPLETED!\n";
    $r_commands[3] = "0";
  }
  else
  {
    #print "Updating MANAGER...FAILED!\n";
    $r_commands[3] = "1";
  }
  print "Updating MANAGER_ID...\n";
  system("/opt/OV/bin/ovconfpar -change -host $nodename -ns sec.core.auth -set MANAGER_ID \`ovcoreid -ovrg server\` > /dev/null");
  #print "/opt/OV/bin/ovconfpar -change -host $nodename -ns sec.core.auth -set MANAGER_ID \`ovcoreid -ovrg server\`\n";
  if ($? eq "0")
  {
    #print "Updating MANAGER_ID...COMPLETED!\n";
    $r_commands[4] = "0";
  }
  else
  {
    #print "Updating MANAGER_ID...FAILED!\n";
    $r_commands[4] = "1";
  }

  #Target HPOM takes ownership of policies for a managed node if all agent updates were ok.
  return @r_commands;
}

##########################################################
# Sub that check ICMP to managed node
#	@Parms:
#			$nodename:		nodename
#	Return:
#			0:	OK
#			1:	Error
###########################################################
sub test_icmp_to_node
{
  my $nodename = shift;
  my $return_icmp_test;
  my $p = Net::Ping->new("icmp");
  #$p->bind("204.104.116.27");

  if ($p->ping($nodename))
  {
    #print "$nodename-->Ping OK!";
    $return_icmp_test = "0";
    #print ";$nodename is alive;$return_icmp_test";
  }
  else
  {
    #print "$nodename-->Ping NOK!";
    $return_icmp_test = "1";
    #print ";$nodename is NOT alive;$return_icmp_test";
  }
  sleep(1);
  $p->close();
  return $return_icmp_test;
}

##########################################################
# Sub that test ICMP to a target ip by ovdeploy
#	@Parms:
#			$nodename:		nodename
#	Return:
#			0:	OK
#			1:	Error
###########################################################
sub icmp_to_host_test
{
	my ($nodename, $targethost, $node_mach_type, $icmp_packet_count, $icmp_packet_size, $cmdtimeout) = @_;
	my @icmp_result = ();
	my $icmp_result_porcentaje = "";

	#print "$nodename $targethost $node_mach_type $icmp_packet_count $icmp_packet_size $cmdtimeout\n";
	if ($node_mach_type =~ m/MACH_BBC_LX26|MACH_BBC_AIX/)
	{
		#print "Linux\n";
		@icmp_result = qx{/opt/OV/bin/ovdeploy -cmd ping -par \"-c $icmp_packet_count -s  $icmp_packet_size $targethost\" -host $nodename -cmd_timeout $cmdtimeout};
	}
	if ($node_mach_type =~ m/MACH_BBC_WIN/)
	{
		#print "Windows\n";
		@icmp_result = qx{/opt/OV/bin/ovdeploy -cmd ping -par \"-n $icmp_packet_count -l  $icmp_packet_size $targethost\" -host $nodename -cmd_timeout $cmdtimeout};
	}
	if ($node_mach_type =~ m/MACH_BBC_HPUX/)
	{
		#print "HPUX\n";
		@icmp_result = qx{/opt/OV/bin/ovdeploy -cmd ping -par \"$targethost $icmp_packet_size -n $icmp_packet_count\" -host $nodename -cmd_timeout $cmdtimeout};
	}
	if ($node_mach_type =~ m/MACH_BBC_SOL/)
	{
		#print "SOL\n";
		@icmp_result = qx{/opt/OV/bin/ovdeploy -cmd ping -par \"-s $targethost $icmp_packet_size $icmp_packet_count\" -host $nodename -cmd_timeout $cmdtimeout};
	}

	foreach my $icmp_line (@icmp_result)
	{
		chomp($icmp_line);
		if ($icmp_line =~ m/(\d\d?%)/)
		{
			$icmp_line = $1;
			chomp($icmp_line);
			$icmp_line =~ s/%//g;
			$icmp_result_porcentaje = $icmp_line;

		#	push(@icmp_result, $icmp_line);
		}
		if ($icmp_line =~ m/Timeout occured/)
		{
			$icmp_result_porcentaje = "N/A";
		}
	}
	return $icmp_result_porcentaje;
}

##########################################################
# Sub that performs by ovdeploy an 'opcragt -status' to managed node
#	@Parms:
#			$nodename:		nodename
#     $cmd_timeout: cmd timeout
#	Return:
#			0:	OK
#			1:	Error
###########################################################
sub oastatus
{
  my ($nodename, $cmd_timeout) = @_;
  my @oastatus_cmd = qx{/opt/OV/bin/ovdeploy -cmd \"opcragt -status $nodename\" -ovrg server -cmd_timeout $cmd_timeout};
  my $procs_ok = 0;
  foreach my $oastatus_cmd_line (@oastatus_cmd)
  {
    chomp($oastatus_cmd_line);
    if ($oastatus_cmd_line =~ m/(coda|ovbbccb|ovcd|ovconfd)\s+\(\d+\)\sis\s+running$/)
    {
      $procs_ok++;
    }
  }
  if ($procs_ok == 4)
  {
    return 0;
  }
  return 1;
}

##########################################################
# Sub that performs the policy ownership
#	@Parms:
#			$nodename:		nodename
#     $target_pri_hpom: hpom that will take policy ownership
#	Return:
#			0:	OK
#			1:	Error
###########################################################
sub update_pol_own
{
  my ($nodename, $target_pri_hpom, $cmd_timeout) = @_;
  system("/opt/OV/bin/ovdeploy -cmd \"ovpolicy -setowner OVO\:$target_pri_hpom -all\" -node $nodename -cmd_timeout $cmd_timeout > /dev/null");
  #print "/opt/OV/bin/ovdeploy -cmd \"/opt/OV/bin/ovpolicy -setowner OVO\:$target_pri_hpom -all\" -ovrg server -cmd_timeout $cmd_timeout > /dev/null\n";
  if ($? eq "0")
  {
    return 0;
  }
  return 1;
}

##########################################################
# Sub that generates dsf file to make managed node download
#	@Parms:
#			$nodename:		nodename
#     $nodeip:      nodeip
#     $dsf_filename: file used to add entities for downloading
#	Return:
#			0:	OK
#			1:	Error
###########################################################
sub generate_dsf_file
{
  my ($nodename, $nodeip, $dsf_filename) = @_;
  open(INPUT_HPOM_FILE, "< $dsf_filename")
#print "/opt/OV/bin/ovdeploy -cmd \"/opt/OV/bin/ovpolicy -setowner OVO\:$target_pri_hpom -all\" -ovrg server -cmd_timeout $cmd_timeout > /dev/null\n";
  if ($? eq "0")
  {
    return 0;
  }
  return 1;
}
