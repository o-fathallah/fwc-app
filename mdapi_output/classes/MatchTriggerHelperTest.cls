@isTest
public class MatchTriggerHelperTest {
    @isTest
    static void testUpdateTournamentTeam() {
        // Create mock data for teams, tournament, and matches
        Tournament__c tournament = new Tournament__c(Name = 'World Cup 2022');
        insert tournament;

        Team__c team1 = new Team__c(Name = 'Brazil');
        Team__c team2 = new Team__c(Name = 'Morocco');
        insert new List<Team__c>{ team1, team2 };

        Match__c match = new Match__c(
            Tournament__c = tournament.Id,
            Home_Team__c = team1.Id,
            Away_Team__c = team2.Id,
            Match_Datetime__c = DateTime.now(),
            Score_Home_Team__c = 2,
            Score_Away_Team__c = 1
        );
        insert match;

        // Verify that the Tournament_Team__c records were updated
        List<Tournament_Team__c> tournamentTeams = [SELECT Id, Points__c, Matches_played__c FROM Tournament_Team__c WHERE Tournament__c = :tournament.Id];
        
        // Check that the stats are updated correctly
        System.assertEquals(3, tournamentTeams[0].Points__c);  // Home team gets 3 points
        System.assertEquals(1, tournamentTeams[1].Points__c);  // Away team gets 1 point (draw)
    }
}
