trigger PreventDuplicateTeamInGroup on Tournament_Group__c (before insert, before update) {
    // Collect all team IDs from the incoming records.
    Set<Id> teamIds = new Set<Id>();
    for (Tournament_Group__c groupRec : Trigger.new) {
        if (groupRec.Team_1__c != null) teamIds.add(groupRec.Team_1__c);
        if (groupRec.Team_2__c != null) teamIds.add(groupRec.Team_2__c);
        if (groupRec.Team_3__c != null) teamIds.add(groupRec.Team_3__c);
        if (groupRec.Team_4__c != null) teamIds.add(groupRec.Team_4__c);
    }

    // Query other Tournament_Group__c records that already use these team IDs.
    List<Tournament_Group__c> existingGroups = [
        SELECT Id, Team_1__c, Team_2__c, Team_3__c, Team_4__c
        FROM Tournament_Group__c
        WHERE Id NOT IN :Trigger.newMap.keySet()
          AND (
                Team_1__c IN :teamIds OR
                Team_2__c IN :teamIds OR
                Team_3__c IN :teamIds OR
                Team_4__c IN :teamIds
          )
    ];

    // Check each incoming record against the existing records.
    for (Tournament_Group__c newGroup : Trigger.new) {
        Boolean duplicateFound = false;
        
        // Check for each team field if the team is already used in another group.
        if (newGroup.Team_1__c != null) {
            for (Tournament_Group__c grp : existingGroups) {
                if (newGroup.Team_1__c == grp.Team_1__c ||
                    newGroup.Team_1__c == grp.Team_2__c ||
                    newGroup.Team_1__c == grp.Team_3__c ||
                    newGroup.Team_1__c == grp.Team_4__c) {
                    duplicateFound = true;
                    break;
                }
            }
        }
        if (!duplicateFound && newGroup.Team_2__c != null) {
            for (Tournament_Group__c grp : existingGroups) {
                if (newGroup.Team_2__c == grp.Team_1__c ||
                    newGroup.Team_2__c == grp.Team_2__c ||
                    newGroup.Team_2__c == grp.Team_3__c ||
                    newGroup.Team_2__c == grp.Team_4__c) {
                    duplicateFound = true;
                    break;
                }
            }
        }
        if (!duplicateFound && newGroup.Team_3__c != null) {
            for (Tournament_Group__c grp : existingGroups) {
                if (newGroup.Team_3__c == grp.Team_1__c ||
                    newGroup.Team_3__c == grp.Team_2__c ||
                    newGroup.Team_3__c == grp.Team_3__c ||
                    newGroup.Team_3__c == grp.Team_4__c) {
                    duplicateFound = true;
                    break;
                }
            }
        }
        if (!duplicateFound && newGroup.Team_4__c != null) {
            for (Tournament_Group__c grp : existingGroups) {
                if (newGroup.Team_4__c == grp.Team_1__c ||
                    newGroup.Team_4__c == grp.Team_2__c ||
                    newGroup.Team_4__c == grp.Team_3__c ||
                    newGroup.Team_4__c == grp.Team_4__c) {
                    duplicateFound = true;
                    break;
                }
            }
        }
        
        if (duplicateFound) {
            newGroup.addError('One or more teams in this group are already assigned to another group.');
        }
    }
}
