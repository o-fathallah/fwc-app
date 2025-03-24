trigger MatchResultDeleteTrigger on Match__c (after delete) {
    Set<Id> groupIds = new Set<Id>();
    for (Match__c m : Trigger.old) {
        if (m.Round__c != null && (m.Round__c == '1' || m.Round__c == '2' || m.Round__c == '3')) {
            groupIds.add(m.Tournament_Group__c);
        }
    }
    for (Id groupId : groupIds) {
        GroupStandingsCalculator.recalcStandings(groupId);
    }
}
