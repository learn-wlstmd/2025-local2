#!/bin/bash
INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running,stopped" --query 'Reservations[*].Instances[?not_null(Tags[?Key==`Name` && Value!=`automation-bastion`])].[InstanceId]' --output text)
[ -n "$INSTANCE_IDS" ] && for ID in $INSTANCE_IDS; do aws ec2 modify-instance-attribute --instance-id $ID --no-disable-api-termination; done
[ -n "$INSTANCE_IDS" ] && echo "$INSTANCE_IDS" | xargs -n 1 aws ec2 terminate-instances --instance-ids && echo "$INSTANCE_IDS" | xargs -n 1 aws ec2 wait instance-terminated --instance-ids