################################################################################
#SQL script that gets parent layout group for a managed node
#Author: Marco Ruiz (mruizm@hpe.com)
#Date: 06/11/2017
#v1.0   Initial release
################################################################################
set heading off
set pagesize 0
set feedback off
Set Verify off
ttitle off;

select a.parent_id from opc_nodehier_layout a, opc_node_names b
where a.node_id = b.node_id and b.node_name = '&1';
