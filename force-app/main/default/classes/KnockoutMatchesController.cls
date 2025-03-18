public with sharing class KnockoutMatchesController {
    @AuraEnabled(cacheable=true)
    public static List<Match__c> getKnockoutMatches() {
        return [
            SELECT Id, Name, Round__c, Match_Datetime__c, 
                   Score_Home_Team__c, Score_Away_Team__c, 
                   Penalty_Shootout__c, Home_Penalty_Score__c, Away_Penalty_Score__c,
                   Home_Team__r.Name, Away_Team__r.Name, Stadium_Name__c
            FROM Match__c
            WHERE Round__c IN ('Round of 16','Quarter Finals','Semi Finals','Finals')
            ORDER BY Match_Datetime__c
        ];
    }
}