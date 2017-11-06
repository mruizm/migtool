################################################################################
#SQL script that gets all nodegroups assigned to a managed node
#Author: Marco Ruiz (mruizm@hpe.com)
#Date: 06/11/2017
#v1.0   Initial release
################################################################################
column node_name       format A60
column node_group_name format A50
set heading off
set echo off
set linesize 300
set pagesize 0
set feedback off
set newpage 0
Set Verify off
ttitle off

select nn.node_name, node_group_name
from opc_node_groups ng, opc_node_names nn, opc_nodes_in_group nig
where ng.node_group_id = nig.node_group_id and nn.node_id = nig.node_id and nn.node_name = '&1'
group by node_group_name, nn.node_name;
