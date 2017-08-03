#!/bin/bash

key_path=<path_to_ssh_key>
user=<ssh_user>
SPACE=" "
key="Name"
# so you don't have to type yes all the time, switch if you don't like
host_key_checking="no"
cwd=$(pwd)
ansible_repo="/ansible_halo/"
all="group_vars/all"
all_orig="group_vars/all.orig"
hosts="hosts"
hosts_orig="hosts.orig"
playbook="halo.yml"
inventory_file="hosts"
repo_url="https://github.com/cloudpassage/ansible_halo.git"
task_path="roles/install/tasks/yum_install.yml"

# $cwd/ansible_halo/
if [ ! -d "$cwd$ansible_repo" ]; then
    # clone the CloudPassage Ansible repo
    git clone $repo_url

    # add the server tag to the playbook
    # $cwd/ansible_halo/roles/install/tasks/yum_install.yml
    sed -i -e "s/}}/}} --tag={{ tag }}/" $cwd$ansible_repo$task_path

    # add the agent key to the group_vars
    # $cwd/ansible_halo/group_vars/all
    sed -i -e "s/agent_key:/agent_key: $HALO_AGENT_KEY/" $cwd$ansible_repo$all
fi

# keep a clean copy
# $cwd/ansible_halo/group_vars/all.orig
if [ ! -f $cwd$ansible_repo$all_orig ]
then
    # $cwd/ansible_halo/group_vars/all $cwd/ansible_halo/group_vars/all.orig
    cp $cwd$ansible_repo$all $cwd$ansible_repo$all_orig
fi

# $cwd/ansible_halo/hosts
if [ ! -f $cwd$ansible_repo$hosts_orig ]
then
    # $cwd/ansible_halo/hosts # $cwd/ansible_halo/hosts.orig
    cp $cwd$ansible_repo$hosts $cwd$ansible_repo$hosts_orig
fi

for line in $(cat ip_list)
do
    ip_address=$line

    fields=2

    #get the instance ID
    instance_id=$(ssh -i $key_path -o StrictHostKeyChecking=$host_key_checking $user@$ip_address \
    "/opt/aws/bin/ec2-metadata --instance-id | cut --fields=$fields -d \"$SPACE\"")

    metadata_url="http://169.254.169.254/latest/dynamic/instance-identity/document"
    delimeter="\""

    #get the region
    region=$(ssh -i $key_path -o StrictHostKeyChecking=$host_key_checking $user@$ip_address \
    "curl -s $metadata_url | grep region")

    region=$(echo $region | awk -F\" '{print $4}')

    fields=5

    # get the tag with the Name key and parse out the value
    tag_value=$(ssh -i $key_path -o StrictHostKeyChecking=$host_key_checking $user@$ip_address "/usr/bin/aws --region \
     $region ec2 describe-tags --filters \"Name=resource-id,Values=$instance_id\" \"Name=key,Values=$key\" \
     --output=text | cut --fields=$fields")

    # grab a clean copy
    # /ansible_halo/group_vars/all.orig /ansible_halo/group_vars/all
    cp $cwd$ansible_repo$all_orig $cwd$ansible_repo$all

    # /ansible_halo/group_vars/hosts.orig /ansible_halo/group_vars/hosts
    cp $cwd$ansible_repo$hosts_orig $cwd$ansible_repo$hosts

    # copy the tag value for the run
    # /ansible_halo/group_vars/all
    echo "tag: $tag_value" >> $cwd$ansible_repo$all

    # copy the inventory information
    echo "$ip_address ansible_user=$user" >> $cwd$ansible_repo$hosts

    # /ansible_halo/hosts /ansible_halo/halo.yml
    ansible-playbook -i $cwd$ansible_repo$inventory_file $cwd$ansible_repo$playbook --private-key=$key_path --sudo -t \
    install
done