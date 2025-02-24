public class MatchTriggerHelper {

    public static void updateTournamentTeam(List<Match__c> newMatches, List<Match__c> oldMatches) {
        Set<Id> teamIds = new Set<Id>();

        // Collect the Team IDs from the new matches
        for (Match__c match : newMatches) {
            teamIds.add(match.Home_Team__c);
            teamIds.add(match.Away_Team__c);
        }

        // Collect the Team IDs from the old matches (for delete or update)
        for (Match__c match : oldMatches) {
            teamIds.add(match.Home_Team__c);
            teamIds.add(match.Away_Team__c);
        }

        // Query for Tournament_Team__c records for those teams
        List<Tournament_Team__c> tournamentTeams = [SELECT Id, Goals_Against__c, Goals_For__c, Matches_played__c, Points__c, 
                                                    Knockout_Disqualified__c, Qualified_Knockout__c, Team__c, Tournament__c
                                                    FROM Tournament_Team__c
                                                    WHERE Team__c IN :teamIds];

        // Logic for Insert and Update
        for (Match__c match : newMatches) {
            Tournament_Team__c homeTeam = getTournamentTeam(tournamentTeams, match.Home_Team__c, match.Tournament__c);
            Tournament_Team__c awayTeam = getTournamentTeam(tournamentTeams, match.Away_Team__c, match.Tournament__c);
            
            // Update home team stats
            updateTeamStats(homeTeam, match.Score_Home_Team__c, match.Score_Away_Team__c, true);
            
            // Update away team stats
            updateTeamStats(awayTeam, match.Score_Away_Team__c, match.Score_Home_Team__c, false);
        }

        // Perform DML update
        update tournamentTeams;
    }

    private static Tournament_Team__c getTournamentTeam(List<Tournament_Team__c> tournamentTeams, Id teamId, Id tournamentId) {
        for (Tournament_Team__c tt : tournamentTeams) {
            if (tt.Team__c == teamId && tt.Tournament__c == tournamentId) {
                return tt;
            }
        }
        return null;
    }

    private static void updateTeamStats(Tournament_Team__c team, Decimal teamGoals, Decimal opponentGoals, Boolean isHome) {
    if (team == null) return;

    // Update Goals
    if (teamGoals != null) {
        team.Goals_For__c = (team.Goals_For__c == null ? 0 : team.Goals_For__c) + teamGoals;
    }
    if (opponentGoals != null) {
        team.Goals_Against__c = (team.Goals_Against__c == null ? 0 : team.Goals_Against__c) + opponentGoals;
    }

    // Update Matches Played
    team.Matches_played__c = (team.Matches_played__c == null ? 0 : team.Matches_played__c) + 1;

    // Update Points: Calculate based on score
    if (teamGoals > opponentGoals) {
        team.Points__c = (team.Points__c == null ? 0 : team.Points__c) + 3; // Win
    } else if (teamGoals == opponentGoals) {
        team.Points__c = (team.Points__c == null ? 0 : team.Points__c) + 1; // Draw
    }
}

}
