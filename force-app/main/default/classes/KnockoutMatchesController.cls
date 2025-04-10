public with sharing class KnockoutMatchesController {
    @AuraEnabled(cacheable=true)
    public static List<Match__c> getKnockoutMatchesByTournament(Id tournamentId) {
        return [
            SELECT Id, 
                   Round__c, 
                   Home_Team__r.Name, 
                   Away_Team__r.Name,
                   Score_Home_Team__c,
                   Score_Away_Team__c,
                   Penalty_Shootout__c,
                   Home_Penalty_Score__c,
                   Away_Penalty_Score__c,
                   Winner__c,
                   Match_Datetime__c
            FROM Match__c
            WHERE Tournament__c = :tournamentId 
              AND Round__c IN ('Round of 16','Quarter Finals','Semi Finals','Finals')
            ORDER BY Round__c, Match_Datetime__c
        ];
    }
}
