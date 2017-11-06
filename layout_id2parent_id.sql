################################################################################
#SQL script that gets parent_id for a layout_id
#Can be used recursively to get layout tree for a managed node
#Author: Marco Ruiz (mruizm@hpe.com)
#Date: 06/11/2017
#v1.0   Initial release
################################################################################
set heading off
set echo off
set linesize 158
set pagesize 0
set feedback off
set newpage 0;
set verify off
set recsep off
ttitle off;

column parent_id format A40 WRAPPED
column name format A40 WRAPPED
select parent_id, name from opc_nodehier_layout where layout_id = '&1';
