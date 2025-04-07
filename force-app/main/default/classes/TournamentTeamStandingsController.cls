public with sharing class TournamentTeamStandingsController {
    @AuraEnabled(cacheable=true)
    public static List<Tournament_Team__c> getGroupStandingsByTournament(Id tournamentId) {
        return [
            SELECT Id, 
                   Name, 
                   Matches_played__c, 
                   Wins__c, 
                   Draws__c, 
                   Losses__c, 
                   Goals_For__c, 
                   Goals_Against__c, 
                   Goal_Difference__c, 
                   Points__c, 
                   Qualified_Knockout__c, 
                   Tournament_Group__r.Name, 
                   Team__r.Name
            FROM Tournament_Team__c
            WHERE Tournament__c = :tournamentId
            ORDER BY Tournament_Group__r.Name, Points__c DESC, Goal_Difference__c DESC, Goals_For__c DESC
        ];
    }
}
