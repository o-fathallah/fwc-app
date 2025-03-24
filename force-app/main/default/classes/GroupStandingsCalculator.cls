public with sharing class GroupStandingsCalculator {
    
    // Inner class to accumulate stats per team.
    public class TeamStats implements Comparable {
        public Id teamId;
        public Id ttId; // Corresponding Tournament_Team__c record Id
        public Integer matchesPlayed = 0;
        public Integer wins = 0;
        public Integer draws = 0;
        public Integer losses = 0;
        public Decimal goalsFor = 0;       // Using Decimal for score values.
        public Decimal goalsAgainst = 0;   
        public Integer points = 0;
        
        // Implement Comparable to sort the list.
        public Integer compareTo(Object obj) {
            TeamStats other = (TeamStats)obj;
            // Compare points descending.
            if(this.points != other.points) {
                return other.points - this.points;
            }
            // Compare goal difference descending.
            Decimal gd1 = this.goalsFor - this.goalsAgainst;
            Decimal gd2 = other.goalsFor - other.goalsAgainst;
            if(gd1 != gd2) {
                if(gd1 > gd2) return -1;
                else return 1;
            }
            // Compare goals for descending.
            if(this.goalsFor != other.goalsFor) {
                if(this.goalsFor > other.goalsFor) return -1;
                else return 1;
            }
            return 0;
        }
    }
    
    // Recalculate standings for the provided Tournament_Group__c Id.
    public static void recalcStandings(Id groupId) {
        // Ensure Tournament_Team__c records exist for all teams in the group.
        ensureTeamRecordsExist(groupId);
        
        // Query all completed group-stage matches for this group.
        List<Match__c> matches = [
            SELECT Home_Team__c, Away_Team__c, Score_Home_Team__c, Score_Away_Team__c
            FROM Match__c
            WHERE Tournament_Group__c = :groupId
              AND Round__c IN ('1','2','3')
              AND Score_Home_Team__c != NULL
              AND Score_Away_Team__c != NULL
        ];
        
        // Query Tournament_Team__c records for this group.
        List<Tournament_Team__c> teamRecords = [
            SELECT Id, Team__c, Matches_Played__c, Wins__c, Draws__c, Losses__c,
                   Goals_For__c, Goals_Against__c, Points__c, Qualified_Knockout__c,
                   Knockout_Disqualified__c
            FROM Tournament_Team__c
            WHERE Tournament_Group__c = :groupId
        ];
        
        // Initialize stats for each team.
        Map<Id, TeamStats> statsMap = new Map<Id, TeamStats>();
        for (Tournament_Team__c tt : teamRecords) {
            TeamStats ts = new TeamStats();
            ts.teamId = tt.Team__c;
            ts.ttId = tt.Id;
            statsMap.put(tt.Team__c, ts);
        }
        
        // Process each match to update team stats.
        for (Match__c m : matches) {
            if (statsMap.containsKey(m.Home_Team__c) && statsMap.containsKey(m.Away_Team__c)) {
                TeamStats homeStats = statsMap.get(m.Home_Team__c);
                TeamStats awayStats = statsMap.get(m.Away_Team__c);
                
                // Increment matches played.
                homeStats.matchesPlayed++;
                awayStats.matchesPlayed++;
                
                // Update goals using the score fields.
                homeStats.goalsFor += m.Score_Home_Team__c;
                homeStats.goalsAgainst += m.Score_Away_Team__c;
                awayStats.goalsFor += m.Score_Away_Team__c;
                awayStats.goalsAgainst += m.Score_Home_Team__c;
                
                // Determine outcome and assign points.
                if (m.Score_Home_Team__c > m.Score_Away_Team__c) {
                    homeStats.wins++;
                    awayStats.losses++;
                    homeStats.points += 3;
                } else if (m.Score_Home_Team__c < m.Score_Away_Team__c) {
                    awayStats.wins++;
                    homeStats.losses++;
                    awayStats.points += 3;
                } else {
                    homeStats.draws++;
                    awayStats.draws++;
                    homeStats.points += 1;
                    awayStats.points += 1;
                }
            }
        }
        
        // Convert statsMap values to a list for sorting.
        List<TeamStats> statsList = new List<TeamStats>();
        for (TeamStats ts : statsMap.values()) {
            statsList.add(ts);
        }
        
        // Sort teams using the Comparable implementation.
        statsList.sort();
        
        // Prepare a map for Tournament_Team__c updates keyed by Team__c.
        Map<Id, Tournament_Team__c> ttToUpdate = new Map<Id, Tournament_Team__c>();
        for (Tournament_Team__c tt : teamRecords) {
            ttToUpdate.put(tt.Team__c, tt);
        }
        
        // Update standings fields.
        for (TeamStats ts : statsList) {
            Tournament_Team__c ttRec = ttToUpdate.get(ts.teamId);
            ttRec.Matches_Played__c = ts.matchesPlayed;
            ttRec.Wins__c = ts.wins;
            ttRec.Draws__c = ts.draws;
            ttRec.Losses__c = ts.losses;
            ttRec.Goals_For__c = ts.goalsFor;
            ttRec.Goals_Against__c = ts.goalsAgainst;
            ttRec.Points__c = ts.points;
            // Goal_Difference__c is a formula field (Goals_For__c - Goals_Against__c), so no update is needed.
            // Default Qualified_Knockout__c to false.
            ttRec.Qualified_Knockout__c = false;
            // Knockout_Disqualified__c remains unchanged during group stage.
        }
        
        // Mark the top two teams as qualified for knockout.
        for (Integer i = 0; i < statsList.size(); i++) {
            if (i < 2) {
                Tournament_Team__c ttRec = ttToUpdate.get(statsList[i].teamId);
                ttRec.Qualified_Knockout__c = true;
            }
        }
        
        // Update the Tournament_Team__c records.
        update ttToUpdate.values();
    }
    
    // Helper method to ensure Tournament_Team__c records exist for all teams in the group.
    private static void ensureTeamRecordsExist(Id groupId) {
        // Query existing Tournament_Team__c records for this group.
        List<Tournament_Team__c> existingRecords = [
            SELECT Id, Team__c
            FROM Tournament_Team__c
            WHERE Tournament_Group__c = :groupId
        ];
        
        // Build a set of team Ids already having records.
        Set<Id> existingTeamIds = new Set<Id>();
        for (Tournament_Team__c tt : existingRecords) {
            existingTeamIds.add(tt.Team__c);
        }
        
        // Query the Tournament_Group__c record to get all team fields and required Tournament__c.
        Tournament_Group__c groupRec = [
            SELECT Id, Tournament__c, Team_1__c, Team_2__c, Team_3__c, Team_4__c
            FROM Tournament_Group__c
            WHERE Id = :groupId
            LIMIT 1
        ];
        
        // Prepare list for new Tournament_Team__c records.
        List<Tournament_Team__c> newTeamRecords = new List<Tournament_Team__c>();
        
        if (groupRec.Team_1__c != null && !existingTeamIds.contains(groupRec.Team_1__c)) {
            newTeamRecords.add(new Tournament_Team__c(
                Tournament_Group__c = groupRec.Id,
                Tournament__c = groupRec.Tournament__c,
                Team__c = groupRec.Team_1__c,
                Matches_Played__c = 0,
                Points__c = 0,
                Goals_For__c = 0,
                Goals_Against__c = 0,
                Qualified_Knockout__c = false,
                Knockout_Disqualified__c = false
            ));
        }
        if (groupRec.Team_2__c != null && !existingTeamIds.contains(groupRec.Team_2__c)) {
            newTeamRecords.add(new Tournament_Team__c(
                Tournament_Group__c = groupRec.Id,
                Tournament__c = groupRec.Tournament__c,
                Team__c = groupRec.Team_2__c,
                Matches_Played__c = 0,
                Points__c = 0,
                Goals_For__c = 0,
                Goals_Against__c = 0,
                Qualified_Knockout__c = false,
                Knockout_Disqualified__c = false
            ));
        }
        if (groupRec.Team_3__c != null && !existingTeamIds.contains(groupRec.Team_3__c)) {
            newTeamRecords.add(new Tournament_Team__c(
                Tournament_Group__c = groupRec.Id,
                Tournament__c = groupRec.Tournament__c,
                Team__c = groupRec.Team_3__c,
                Matches_Played__c = 0,
                Points__c = 0,
                Goals_For__c = 0,
                Goals_Against__c = 0,
                Qualified_Knockout__c = false,
                Knockout_Disqualified__c = false
            ));
        }
        if (groupRec.Team_4__c != null && !existingTeamIds.contains(groupRec.Team_4__c)) {
            newTeamRecords.add(new Tournament_Team__c(
                Tournament_Group__c = groupRec.Id,
                Tournament__c = groupRec.Tournament__c,
                Team__c = groupRec.Team_4__c,
                Matches_Played__c = 0,
                Points__c = 0,
                Goals_For__c = 0,
                Goals_Against__c = 0,
                Qualified_Knockout__c = false,
                Knockout_Disqualified__c = false
            ));
        }
        
        if (!newTeamRecords.isEmpty()) {
            insert newTeamRecords;
        }
    }
}
