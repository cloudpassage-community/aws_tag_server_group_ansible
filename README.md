Add a Linux Server to a Halo Server Group Using an AWS Tag and Ansible
-

Notes
-

1) This is sample code and is not supported by CloudPassage. The purpose is to get a user up and running using an AWS tag 
value to assign workloads to Halo server groups.  
2) This has only been tested on Amazon Linux
3) This example only shows how to do this using the AWS console

Description
-

The file aws_tag_server_group_ansible.sh will grab the value of the AWS tag "Name" key (e.g. Name:value). This value 
will be used to move the server to a Halo server group whose name has the same value.

For example, if the AWS tags are "TAGS Name Pre-Production instance cpd3mo-cicd-pre-prod.com" the server will be moved into the Pre-Production server group (if it exists).

This will be used alongside the Halo Ansible playbook located at (https://github.com/cloudpassage/ansible_halo).

Usage - Base Example Using One Host
-

This requires a role an IAM user can use with instance launches that has a describe tags policy attached to it.
A DescribeTags policy looks like:

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:DescribeTags",
            "Resource": "*"
        }
    ]
}

0) Configure variables in aws_tag_server_group_ansible.sh:  

key_path=<path_to_ssh_key>  
user=<ssh_user>  

1) The HALO_AGENT_KEY environment variable needs to be set with your Halo agent key.  Place the
the following in a file (e.g. /etc/cloudpassage) export HALO_AGENT_KEY=<key_value> and then type
source /etc/cloudpassage in the same shell you will run this program.
2) Launch an instance of Amazon Linux with the AWS console. 
3) In 'Step 3: Configure Instance Details' for 'IAM Role', choose the DescribeTags role
4) In 'Step 5: Add Tags' tag the instance with a key value pair where the key is Name (e.g. Key=Name, 
Value=Pre-Production) NOTE: Ensure you have a server group that matches or the workload
will go into the root group
5) Copy the IP address into the file ip_list
6) In the root of this repo type: sh aws_tag_server_group_ansible.sh

Usage - Multiple Hosts
-

1) Ensure each host has the DescribeTags IAM role assigned
2) Ensure each host has a Name tag with a value that matches a Halo server group
3) Add each IP to the ip_list file (one per line)
4) In the root of this repo type: sh aws_tag_server_group_ansible.sh

Have fun!
