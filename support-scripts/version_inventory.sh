#!/bin/bash


WEBSERVERS_sagesure_production="aphroditeweb01.opd.com aphroditeweb02.opd.com aphroditeweb03.opd.com aphroditeweb04.opd.com"
WEBSERVERS_sagesure_staging="aaronweb01.opd.com aaronweb02.opd.com"
WEBSERVERS_fnic_production="apolloweb01.opd.com apolloweb02.opd.com apolloweb03.opd.com apolloweb04.opd.com"
WEBSERVERS_fnic_staging="alexanderweb01.opd.com alexanderweb02.opd.com"


#------------------------------------------
usage() {
   local msg="$1"

   if [ -n "$msg" ]; then
      echo $msg
   fi

   echo "Usage: $0 [sagesure|fnic] [production|staging]"
   exit 1
}

#------------------------------------------
program="$1"
environment="$2"
userid_master="$3"
password_master="$4"

test -z "$program"     && usage
test -z "$environment" && usage
test -z "$userid_master" && usage
test -z "$password_master" && usage

test "$program" != "sagesure"       -a "$program" != "fnic"         && usage "Invalid program $program"
test "$environment" != "production" -a "$environment" != "staging"  && usage "Invalid environment $environment"

#------------------------------------------
check_versions() {
   local program="$1"
   local environment="$2"
   local app="$3"
   local userid="$4"
   local password="$5"
   local webserver_url_suffix="$6"
   local grep_string="$7"
   local sed_command="$8"

   # Check version (load balancer)
   local balanced_url_varname="${app}_balanced_url_${program}_${environment}"
   local balanced_url="${!balanced_url_varname}"

   if [ -n "$balanced_url" ]; then
      local balanced_version="`curl --silent $balanced_url | grep $grep_string | sed "$sed_command"`"
      echo "$program $environment ${app}: $balanced_version"
   fi

   if [ -n "$userid" -a -n "$password" ]; then
      local basic_auth="$userid:$password@"
   fi

   # Check version (individual web servers)
   local webservers_varname="WEBSERVERS_${program}_${environment}"
   local webservers="${!webservers_varname}"

   for webserver in $webservers; do
      local webserver_url="http://${basic_auth}${webserver}${webserver_url_suffix}"
      local webserver_host_header_varname="${app}_host_header[$webserver]"
      local webserver_host_header="${!webserver_host_header_varname}"

      if [ -z "$webserver_host_header" ]; then
         local webserver_version="`curl --silent $webserver_url | grep $grep_string | sed "$sed_command"`"
      else
         local webserver_version="`curl --silent --header "Host: $webserver_host_header" $webserver_url | grep $grep_string | sed "$sed_command"`"
      fi

      if [ "$webserver_version" != "$balanced_version" ]; then
         echo "$program $environment ${app} $webserver: $webserver_version"
      fi
   done
}

#------------------------------------------
# Agent Portal
agent_portal_balanced_url_sagesure_production="https://agents.sagesure.com"
agent_portal_balanced_url_sagesure_staging="https://stage-sagesure-agents.icg360.org/"
agent_portal_balanced_url_fnic_production="https://fnic-agents.icg360.com/"
agent_portal_balanced_url_fnic_staging="https://stage-fnic-agents.icg360.org/"

declare -A agent_portal_host_header  # bash 4 associative array
agent_portal_host_header["aphroditeweb01.opd.com"]="agentportal1.sagesure"
agent_portal_host_header["aphroditeweb02.opd.com"]="agentportal2.sagesure"
agent_portal_host_header["aphroditeweb03.opd.com"]="agentportal3.sagesure"
agent_portal_host_header["aphroditeweb04.opd.com"]="agentportal4.sagesure"
agent_portal_host_header["aaronweb01.opd.com"]="stage-agentportal1.sagesure"
agent_portal_host_header["aaronweb02.opd.com"]="stage-agentportal2.sagesure"
agent_portal_host_header["apolloweb01.opd.com"]="agentportal1.fnic"
agent_portal_host_header["apolloweb02.opd.com"]="agentportal2.fnic"
agent_portal_host_header["apolloweb03.opd.com"]="agentportal3.fnic"
agent_portal_host_header["apolloweb04.opd.com"]="agentportal4.fnic"
agent_portal_host_header["alexanderweb01.opd.com"]="stage-agentportal1.fnic-1"
agent_portal_host_header["alexanderweb02.opd.com"]="stage-agentportal2.fnic-1"

agent_portal_check_versions() {
   local program="$1"
   local environment="$2"

   check_versions $program $environment "agent_portal" "" "" "" "id.*version-number" "s|^.*Version: ||; s|</li>.*$||"
}


#------------------------------------------
# pxCentral
# https://icg360.atlassian.net/browse/ICS-3040
# confirmed that version is showing up at https://stage-sagesure-svc.icg360.org/cru-4/pxcentral/api/rest/v1/version

#------------------------------------------
# GIQ (skip for now since it's only SageSure)


#------------------------------------------
# ixLogic
ixlogic_balanced_url_sagesure_production="https://services.sagesure.com/cru-4/ixlogic"
ixlogic_balanced_url_sagesure_staging=""  # TODO
ixlogic_balanced_url_fnic_production="https://fnic-services.icg360.com/fnic-1/ixlogic"
ixlogic_balanced_url_fnic_staging=""  # TODO

declare -A ixlogic_host_header  # bash 4 associative array
ixlogic_host_header["aphroditeweb01.opd.com"]="ixlogic1.cru-4"
ixlogic_host_header["aphroditeweb02.opd.com"]="ixlogic2.cru-4"
ixlogic_host_header["aphroditeweb03.opd.com"]="ixlogic3.cru-4"
ixlogic_host_header["aphroditeweb04.opd.com"]="ixlogic4.cru-4"
ixlogic_host_header["aaronweb01.opd.com"]="stage-ixlogic1.cru-4"
ixlogic_host_header["aaronweb02.opd.com"]="stage-ixlogic2.cru-4"
ixlogic_host_header["apolloweb01.opd.com"]="ixlogic1.fnic-1"
ixlogic_host_header["apolloweb02.opd.com"]="ixlogic2.fnic-1"
ixlogic_host_header["apolloweb03.opd.com"]="ixlogic3.fnic-1"
ixlogic_host_header["apolloweb04.opd.com"]="ixlogic4.fnic-1"
ixlogic_host_header["alexanderweb01.opd.com"]="stage-ixlogic1.fnic-1"
ixlogic_host_header["alexanderweb02.opd.com"]="stage-ixlogic2.fnic-1"

ixlogic_check_versions() {
   local program="$1"
   local environment="$2"

   check_versions $program $environment "ixlogic" "" "" "" "part.of.cxSeries" "s|^.*ixLogic ||; s|, part of cxSeries.*$||"
}

#------------------------------------------
# mxServer
mxserver_balanced_url_sagesure_production="https://$userid_master:$password_master@services.sagesure.com/cru-4/mxserver/api/rest/v1/version"
mxserver_balanced_url_sagesure_staging="https://$userid_master:$password_master@stage-sagesure-svc.icg360.org/cru-4/mxserver/api/rest/v1/version"
mxserver_balanced_url_fnic_production=""
mxserver_balanced_url_fnic_staging=""

declare -A mxserver_host_header  # bash 4 associative array

mxserver_check_versions() {
   local program="$1"
   local environment="$2"

   check_versions $program $environment "mxserver" "$userid_master" "$password_master" ":8804/api/rest/v1/version" "MxServerVersion" 's|^.*:"||; s|" }$||'
}

#------------------------------------------
# Policy Central (skip for now since it's Universal


#==========================================
agent_portal_check_versions $program $environment
ixlogic_check_versions $program $environment
mxserver_check_versions     $program $environment

exit


