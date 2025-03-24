trigger MatchResultTrigger on Match__c (after insert, after update) {
    Set<Id> groupIds = new Set<Id>();
    for (Match__c m : Trigger.new) {
        // Only process group-stage matches with scores entered.
        if (m.Round__c != null && (m.Round__c == '1' || m.Round__c == '2' || m.Round__c == '3')
           && m.Score_Home_Team__c != null && m.Score_Away_Team__c != null) {
            groupIds.add(m.Tournament_Group__c);
        }
    }
    for (Id groupId : groupIds) {
        GroupStandingsCalculator.recalcStandings(groupId);
    }
}
