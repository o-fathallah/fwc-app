trigger UpdateTournamentTeam on Match__c (after insert, after update, after delete) {
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
        MatchTriggerHelper.updateTournamentTeam(Trigger.new, Trigger.old);
    }
}
