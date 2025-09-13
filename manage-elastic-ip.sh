#!/bin/bash

# Elastic IP Management Script
INSTANCE_ID="i-06be8249f6ef53137"
ELASTIC_IP="34.236.16.67"
ALLOCATION_ID="eipalloc-0b4653c525de790c2"
ASSOCIATION_ID="eipassoc-0662346383937ab02"
REGION="us-east-1"

case "${1}" in
    "status")
        echo "🔍 Checking Elastic IP status..."
        aws ec2 describe-addresses --allocation-ids $ALLOCATION_ID --region $REGION
        ;;
    "associate")
        echo "🔗 Associating Elastic IP with instance..."
        aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $ALLOCATION_ID --region $REGION
        ;;
    "disassociate")
        echo "🔌 Disassociating Elastic IP from instance..."
        aws ec2 disassociate-address --association-id $ASSOCIATION_ID --region $REGION
        ;;
    "release")
        echo "⚠️  Releasing Elastic IP (PERMANENT - will lose the IP!)..."
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" = "yes" ]; then
            aws ec2 disassociate-address --association-id $ASSOCIATION_ID --region $REGION
            aws ec2 release-address --allocation-id $ALLOCATION_ID --region $REGION
            echo "✅ Elastic IP released"
        else
            echo "❌ Release cancelled"
        fi
        ;;
    "cost")
        echo "💰 Elastic IP Cost Information:"
        echo "  - Attached to running instance: FREE"
        echo "  - Attached to stopped instance: ~\$3.60/month"
        echo "  - Unattached: ~\$3.60/month"
        echo "  - Current IP: $ELASTIC_IP"
        ;;
    *)
        echo "Usage: $0 {status|associate|disassociate|release|cost}"
        echo ""
        echo "Commands:"
        echo "  status       - Check Elastic IP status"
        echo "  associate    - Attach IP to instance"
        echo "  disassociate - Detach IP from instance"
        echo "  release      - Permanently delete the IP (careful!)"
        echo "  cost         - Show cost information"
        ;;
esac
