public with sharing class GroupStageService {
    @InvocableMethod(label='Generate Group Stage Matches' description='Generates group stage matches for a given group')
    public static void createGroupStageMatches(List<String> groupIdList) {
        if (groupIdList == null || groupIdList.isEmpty()) {
            return;
        }
        Id groupId = groupIdList[0];
        
        // Query as a list and check if it's empty
        List<Tournament_Group__c> groupList = [
            SELECT Id, Team_1__c, Team_2__c, Team_3__c, Team_4__c
            FROM Tournament_Group__c
            WHERE Id = :groupId
            LIMIT 1
        ];
        
        if (groupList.isEmpty()) {
            // Optionally, you can throw a custom exception or log an error.
            return;
        }
        
        Tournament_Group__c groupRec = groupList[0];
        List<Match__c> matches = GroupStageScheduler.generateGroupStageMatches(groupRec);
        insert matches;
    }
}
