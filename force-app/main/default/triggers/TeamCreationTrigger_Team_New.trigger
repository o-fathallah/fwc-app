trigger TeamCreationTrigger_Team_New on Team__c (after insert) {
    List<Team__c> newTeams = Trigger.new;
    TeamNotificationHelper.sendTeamCreationEmail(newTeams);
}
