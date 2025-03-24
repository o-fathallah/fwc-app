trigger GroupMatchTrigger on Match__c (before insert, before update) {
    Set<Id> groupIds = new Set<Id>();
    for (Match__c m : Trigger.new) {
        if ((m.Round__c == '1' || m.Round__c == '2' || m.Round__c == '3')
             && m.Tournament_Group__c != null) {
            groupIds.add(m.Tournament_Group__c);
        }
    }
    if (groupIds.isEmpty()) return;

    // Count existing group-stage matches for these groups.
    Map<Id, Integer> existingCountMap = new Map<Id, Integer>();
    for (AggregateResult ar : [
        SELECT Tournament_Group__c grp, COUNT(Id) cnt
        FROM Match__c
        WHERE Tournament_Group__c IN :groupIds 
              AND Round__c IN ('1','2','3')
        GROUP BY Tournament_Group__c
    ]) {
        existingCountMap.put((Id)ar.get('grp'), (Integer)ar.get('cnt'));
    }

    // Count new matches being processed in this transaction.
    Map<Id, Integer> newCountMap = new Map<Id, Integer>();
    for (Match__c m : Trigger.new) {
        if ((m.Round__c == '1' || m.Round__c == '2' || m.Round__c == '3')
             && m.Tournament_Group__c != null) {
            Id grpId = m.Tournament_Group__c;
            Integer countSoFar = newCountMap.containsKey(grpId) ? newCountMap.get(grpId) : 0;
            newCountMap.put(grpId, countSoFar + 1);
        }
    }

    // Validate that total (existing + new) does not exceed 6 per group.
    for (Match__c m : Trigger.new) {
        if ((m.Round__c == '1' || m.Round__c == '2' || m.Round__c == '3')
             && m.Tournament_Group__c != null) {
            Id grpId = m.Tournament_Group__c;
            Integer existingCount = existingCountMap.containsKey(grpId) ? existingCountMap.get(grpId) : 0;
            Integer newCount = newCountMap.get(grpId);
            if ((existingCount + newCount) > 6) {
                m.addError('Only 6 group-stage matches (Rounds 1, 2, 3) are allowed per group.');
            }
        }
    }
}
