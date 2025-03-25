public with sharing class KnockoutMatchesController {
    @AuraEnabled(cacheable=true)
    public static List<Match__c> getKnockoutMatches() {
        return [
            SELECT Id,
                   Name,
                   Round__c,
                   Home_Team__r.Name,
                   Away_Team__r.Name,
                   Score_Home_Team__c,
                   Score_Away_Team__c
            FROM Match__c
            WHERE Round__c IN ('Round of 16','Quarter Finals','Semi Finals','Final','Third Place Playoff')
            ORDER BY Round__c
        ];
    }
}
