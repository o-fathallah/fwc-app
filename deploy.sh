#!/bin/bash

# Ensure the script stops on error
set -e

# Your org alias (replace with your actual org alias)
#ORG_ALIAS="fwc"

# Deploy Trigger
echo "Deploying Trigger: /Users/ofathallah/Documents/projects/fwc/force-app/main/default/classes/MatchTriggerHelper.cls"
sfdx force:source:deploy -p /Users/ofathallah/Documents/projects/fwc/force-app/main/default/classes/MatchTriggerHelper.cls -u fwc

# Deploy MatchTriggerHelper Class
echo "Deploying Class: /Users/ofathallah/Documents/projects/fwc/force-app/main/default/classes/MatchTriggerHelper.cls"
sfdx force:source:deploy -p /Users/ofathallah/Documents/projects/fwc/force-app/main/default/classes/MatchTriggerHelper.cls -u fwc

# Deploy MatchTriggerHelperTest Class
echo "Deploying Test Class: /Users/ofathallah/Documents/projects/fwc/force-app/main/default/classes/MatchTriggerHelperTest.cls"
sfdx force:source:deploy -p /Users/ofathallah/Documents/projects/fwc/force-app/main/default/classes/MatchTriggerHelperTest.cls -u fwc

echo "Deployment completed successfully!"
