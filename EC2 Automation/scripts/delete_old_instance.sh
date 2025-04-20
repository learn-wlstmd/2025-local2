#!/bin/bash
aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filters Name=tag:Project,Values=skills2022 --query Reservations[].Instances[].InstanceId --output text)