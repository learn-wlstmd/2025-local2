#!/bin/bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

mkdir -p /home/ec2-user/ec2-automation

cat << 'EOF' > /home/ec2-user/ec2-automation/delete_old_instance.sh
#!/bin/bash
aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filters Name=tag:Project,Values=skills2022 --query Reservations[].Instances[].InstanceId --output text)
EOF

cat << 'EOF' > /home/ec2-user/ec2-automation/delete_all_instance.sh
#!/bin/bash
INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running,stopped" --query 'Reservations[*].Instances[?not_null(Tags[?Key==`Name` && Value!=`automation-bastion`])].[InstanceId]' --output text)
[ -n "$INSTANCE_IDS" ] && for ID in $INSTANCE_IDS; do aws ec2 modify-instance-attribute --instance-id $ID --no-disable-api-termination; done
[ -n "$INSTANCE_IDS" ] && echo "$INSTANCE_IDS" | xargs -n 1 aws ec2 terminate-instances --instance-ids && echo "$INSTANCE_IDS" | xargs -n 1 aws ec2 wait instance-terminated --instance-ids
EOF

sudo chown -R ec2-user:ec2-user /home/ec2-user/ec2-automation
sudo chmod +x /home/ec2-user/ec2-automation/delete_old_instance.sh
sudo chmod +x /home/ec2-user/ec2-automation/delete_all_instance.sh
