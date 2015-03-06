#!/bin/bash

LOGGLY_SUBDOMAIN="icg360"
LOGGLY_USERID="devops"
REGISTRY="54.148.110.251"


#--------------------------------------------
deploy_container() {
   local name="$1"
   local version_pattern="$2"
   local port1="$3"
   local port2="$4"
   local port3="$5"
   local port4="$6"
   local secretkey="$7"
   local loggly_password="$8"
   local dryrun="$9"

   local registry_tags_url="https://$REGISTRY/v1/repositories/$name/tags"
   local cookbooks_dir="/usr/local/lib"
   local repo_cookbooks="https://github.com/icg360/chef_cookbooks.git"
   local path_cookbooks="$cookbooks_dir/chef_cookbooks"
   local logdir="/var/log/icg"
   local logpath="$logdir/$name.log"
   local loggly_configure_file_monitoring_url="https://www.loggly.com/install/configure-file-monitoring.sh"

   # Check if arguments OK
   if [ -z "$name" -o -z "$loggly_password" ]; then
      echo "ERROR: Missing arguments"
      return
   fi

   # Envtag now taken from the environment
   if [ -z "$ICG_ENVIRONMENT" ]; then
      echo "ERROR: No value for ICG_ENVIRONMENT"
      return
   fi
   local envtag="$ICG_ENVIRONMENT"

   # Tag now determined by querying the registry for a given version
   local tag=`curl --silent $registry_tags_url | sed 's|{||g; s|}||g; s|"||g' | tr ',' '\n' | awk -F: '{print $1}' | grep "${version_pattern}" | sort --version-sort | tail -1 | sed 's|[[:space:]]||g'`

   if [ -z "$tag" ]; then
      echo "ERROR: Could not find a container image tag for $name $version_pattern"
      curl --silent $registry_tags_url | sed 's|{||g; s|}||g; s|"||g' | tr ',' '\n' | awk -F: '{print $1}'
      return
   fi

   local image="$REGISTRY/$name:$tag"

   # Construct a docker run command
   if [ -n "$port1" ]; then
      local port_mapping1="--publish=$port1:$port1"
   fi

   if [ -n "$port2" ]; then
      local port_mapping2="--publish=$port2:$port2"
   fi

   if [ -n "$port3" ]; then
      local port_mapping3="--publish=$port3:$port3"
   fi

   if [ -n "$port4" ]; then
      local port_mapping4="--publish=$port4:$port4"
   fi

   local docker_host_ip="`/sbin/ip route | awk '/eth0.*src/ { print $9 }'`"

   local docker_run="sudo docker run --detach=true --name=$name --volume=$logdir:/var/log/$name --volume=$path_cookbooks:/cookbooks:ro --env secret=$secretkey --env environment=$envtag --env DOCKER_HOST_IP=$docker_host_ip $port_mapping1 $port_mapping2 $port_mapping3 $port_mapping4"

   # Ensure the configs are current (for redundancy, duplicates docker host regular pulls)
   if [ -d "$path_cookbooks" ]; then
      cd $path_cookbooks; sudo git pull origin master
   else
      sudo git clone $repo_cookbooks $path_cookbooks
   fi

   # Pull the image from the registry
   if [ -z "$dryrun" ]; then
      sudo docker pull $image
      if [ "$?" != "0" ]; then
         echo "ERROR pulling image $image"
         return
      fi
   fi

   # Run the container
   if [ -z "$dryrun" ]; then

      if [ ! -e "$logpath" ]; then
         sudo mkdir -p `dirname $logpath`
         sudo touch $logpath
      fi

      echo | sudo tee --append $logpath
      echo "`date`: Deploying $envtag $name container $tag" | sudo tee --append $logpath

      #echo "EXECUTING COMMAND: $docker_run $image /sbin/my_init"
      #echo
      local cid=`$docker_run $image /sbin/my_init`
      if [ -z "$cid" ]; then
         echo "ERROR running container"
         return
      fi

      echo "Deployed container ID $cid"

   else
      echo
      echo "$docker_run $image /sbin/my_init"
   fi

   # Enable Loggly file monitoring of the application log
   # https://www.loggly.com/docs/file-monitoring/
   if [ -z "$dryrun" ]; then
      cd /tmp

      # Download install script
      curl -O $loggly_configure_file_monitoring_url
      if [ "$?" != "0" ]; then
         echo "ERROR downloading Loggly $loggly_configure_file_monitoring_url"
         return
      fi

      # Idempotentcy
      sudo bash configure-file-monitoring.sh --account $LOGGLY_SUBDOMAIN --filealias $name --rollback

      # Enable file monitoring
      yes "no" | sudo bash configure-file-monitoring.sh --account $LOGGLY_SUBDOMAIN --filealias $name --filename $logpath --username $LOGGLY_USERID --password "$loggly_password"
      local rc="$?"

      sudo rm -rf configure-file-monitoring.sh configure-linux.sh
      cd - > /dev/null

      if [ "$rc" != "0" ]; then
         echo "WARNING: Review Loggly file monitoring for $logpath"
      fi

   fi

   if [ -z "$dryrun" ]; then
      echo
      echo "Deployed $ICG_ENVIRONMENT $name container tagged $tag"
   fi
}

