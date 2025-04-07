public with sharing class TournamentController {
    @AuraEnabled(cacheable=true)
    public static List<Tournament__c> getTournaments() {
        return [SELECT Id, Name FROM Tournament__c ORDER BY Start_Date__c DESC];
    }
}