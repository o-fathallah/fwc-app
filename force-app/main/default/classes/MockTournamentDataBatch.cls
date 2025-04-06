public class MockTournamentDataBatch implements Database.Batchable<Integer> {

    public Iterable<Integer> start(Database.BatchableContext bc) {
        return new List<Integer>{1};
    }
    
    public void execute(Database.BatchableContext bc, List<Integer> scope) {
        // 1) Create the tournament
        Tournament__c tournament = createTournamentWithUniqueName();
        if (tournament == null) {
            return;
        }
        
        // 2) Create 8 group-stage groups + 1 "Knockout Stage" group
        Tournament_Group__c knockoutGroup = createGroupsForTournament(tournament);
        
        // 3) Create group stage matches
        createGroupStageMatches(tournament);
        
        // 4) Create knockout matches referencing the "Knockout Stage" group
        createKnockoutMatches(tournament, knockoutGroup);
    }
    
    public void finish(Database.BatchableContext bc) {}
    
    //──────────────────────────────────────────────────────────────
    // Creates a tournament record and returns it.
    private Tournament__c createTournamentWithUniqueName() {
        Integer currentYear = Date.today().year();
        Integer remainder = Math.mod(currentYear, 4);
        Integer candidateYear = (remainder == 0) ? currentYear + 4 : currentYear + (4 - remainder);
        
        // Ensure candidateYear not used
        Set<Integer> usedYears = new Set<Integer>();
        for (Tournament__c t : [SELECT Tournament_Year__c FROM Tournament__c WHERE Tournament_Year__c != null]) {
            usedYears.add((Integer)t.Tournament_Year__c);
        }
        while (usedYears.contains(candidateYear)) {
            candidateYear += 4;
        }
        
        // Host logic
        List<String> countries = new List<String>{
            'Brazil','Germany','France','Italy','USA',
            'Argentina','Spain','Netherlands','Japan','Morocco',
            'South Korea','England','Canada','Australia'
        };
        Set<String> usedHosts = new Set<String>();
        for (Tournament__c t : [SELECT Host_Country__c FROM Tournament__c WHERE Host_Country__c != null]) {
            usedHosts.add(t.Host_Country__c);
        }
        List<String> availableCountries = new List<String>();
        for (String c : countries) {
            if (!usedHosts.contains(c)) {
                availableCountries.add(c);
            }
        }
        String host;
        if (!availableCountries.isEmpty()) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), availableCountries.size());
            host = availableCountries[idx];
        } else {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), countries.size());
            String baseHost = countries[idx];
            host = baseHost;
            Integer hSuffix = 1;
            while ([SELECT COUNT() FROM Tournament__c WHERE Host_Country__c = :host] > 0) {
                host = baseHost + ' (' + hSuffix + ')';
                hSuffix++;
            }
        }
        
        // Unique name
        String baseName = 'FIFA World Cup ' + host + ' ' + candidateYear;
        String tournamentName = baseName;
        Integer suffix = 1;
        while ([SELECT COUNT() FROM Tournament__c WHERE Name = :tournamentName] > 0) {
            tournamentName = baseName + ' (' + suffix + ')';
            suffix++;
        }
        
        Tournament__c tournament = new Tournament__c(
            Name = tournamentName,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(30),
            Host_Country__c = host,
            Status__c = 'Upcoming',
            Tournament_Year__c = candidateYear
        );
        insert tournament;
        
        System.debug('✅ Created tournament: ' + tournamentName);
        return tournament;
    }
    
    //──────────────────────────────────────────────────────────────
    // Creates 8 groups (A–H) for group stage + 1 "Knockout Stage" group with no teams.
    // Returns the newly created knockoutGroup record.
    private Tournament_Group__c createGroupsForTournament(Tournament__c tournament) {
        // Shuffle all teams
        List<Team__c> allTeams = [SELECT Id FROM Team__c];
        for (Integer i = 0; i < allTeams.size(); i++) {
            Integer r = i + Math.mod(Math.abs(Crypto.getRandomInteger()), allTeams.size() - i);
            Team__c temp = allTeams[i];
            allTeams[i] = allTeams[r];
            allTeams[r] = temp;
        }
        
        // Take first 32 teams for group stage
        Integer teamCount = Math.min(32, allTeams.size());
        List<Team__c> selectedTeams = new List<Team__c>();
        for (Integer i = 0; i < teamCount; i++) {
            selectedTeams.add(allTeams[i]);
        }
        
        // Build 8 group stage records
        List<Tournament_Group__c> groups = new List<Tournament_Group__c>();
        List<String> letters = new List<String>{'A','B','C','D','E','F','G','H'};
        Integer idx = 0;
        for (String letter : letters) {
            DateTime round3Dt = DateTime.newInstance(tournament.Start_Date__c.addDays(20), Time.newInstance(18,0,0,0));
            groups.add(new Tournament_Group__c(
                Name = 'Group ' + letter,
                Tournament__c = tournament.Id,
                Team_1__c = selectedTeams[idx].Id,
                Team_2__c = selectedTeams[idx+1].Id,
                Team_3__c = selectedTeams[idx+2].Id,
                Team_4__c = selectedTeams[idx+3].Id,
                Match_Round_3_DateTime__c = round3Dt
            ));
            idx += 4;
        }
        insert groups;
        System.debug('✅ Created 8 group-stage records for ' + tournament.Name);
        
        // Create a "Knockout Stage" group with no teams
        Tournament_Group__c knockoutGroup = new Tournament_Group__c(
            Name = 'Knockout Stage',
            Tournament__c = tournament.Id
        );
        insert knockoutGroup;
        System.debug('✅ Created 1 knockout group for ' + tournament.Name);
        
        return knockoutGroup;
    }
    
    //──────────────────────────────────────────────────────────────
    // Creates 6 group stage matches per group (rounds 1, 2, 3).
    // No penalty fields set, to avoid validation errors for group stage.
    private void createGroupStageMatches(Tournament__c tournament) {
        List<Tournament_Group__c> groups = [
            SELECT Id, Match_Round_3_DateTime__c,
                   Team_1__c, Team_2__c, Team_3__c, Team_4__c
            FROM Tournament_Group__c
            WHERE Tournament__c = :tournament.Id
            AND Name LIKE 'Group%'
        ];
        
        List<Match__c> matches = new List<Match__c>();
        List<String> stadiums = new List<String>{'Stadium A','Stadium B','Stadium C','Stadium D'};
        
        // Round-robin pairings for 4 teams
        List<List<Integer>> pairings = new List<List<Integer>>{
            new List<Integer>{0,1},
            new List<Integer>{0,2},
            new List<Integer>{0,3},
            new List<Integer>{1,2},
            new List<Integer>{1,3},
            new List<Integer>{2,3}
        };
        
        for (Tournament_Group__c grp : groups) {
            List<Id> teamIds = new List<Id>{grp.Team_1__c, grp.Team_2__c, grp.Team_3__c, grp.Team_4__c};
            Integer matchCount = 0;
            for (List<Integer> pairing : pairings) {
                String roundVal;
                DateTime matchDt;
                if (matchCount < 2) {
                    roundVal = '1';
                    matchDt = DateTime.newInstance(
                        tournament.Start_Date__c.addDays(Math.mod(Math.abs(Crypto.getRandomInteger()), 10)),
                        Time.newInstance(16,0,0,0)
                    );
                } else if (matchCount < 4) {
                    roundVal = '2';
                    matchDt = DateTime.newInstance(
                        tournament.Start_Date__c.addDays(Math.mod(Math.abs(Crypto.getRandomInteger()), 10) + 10),
                        Time.newInstance(18,0,0,0)
                    );
                } else {
                    roundVal = '3';
                    matchDt = grp.Match_Round_3_DateTime__c;
                }
                
                Integer stIdx = Math.mod(Math.abs(Crypto.getRandomInteger()), stadiums.size());
                String stadium = stadiums[stIdx];
                Integer scoreHome = Math.mod(Math.abs(Crypto.getRandomInteger()), 6);
                Integer scoreAway = Math.mod(Math.abs(Crypto.getRandomInteger()), 6);
                
                // No penalty fields for group stage
                matches.add(new Match__c(
                    Tournament__c = tournament.Id,
                    Tournament_Group__c = grp.Id,
                    Home_Team__c = teamIds[pairing[0]],
                    Away_Team__c = teamIds[pairing[1]],
                    Score_Home_Team__c = scoreHome,
                    Score_Away_Team__c = scoreAway,
                    Round__c = roundVal,
                    Match_Datetime__c = matchDt,
                    Stadium_Name__c = stadium
                ));
                matchCount++;
            }
        }
        insert matches;
        System.debug('✅ Created ' + matches.size() + ' group-stage matches for ' + tournament.Name);
    }
    
    //──────────────────────────────────────────────────────────────
    // Creates knockout matches using the "Knockout Stage" group to satisfy required master-detail field.
    private void createKnockoutMatches(Tournament__c tournament, Tournament_Group__c knockoutGroup) {
        // 1) Gather qualified teams (Team_1__c, Team_2__c from each group).
        List<Tournament_Group__c> groupStage = [
            SELECT Team_1__c, Team_2__c
            FROM Tournament_Group__c
            WHERE Tournament__c = :tournament.Id
            AND Name LIKE 'Group%'
        ];
        List<Id> qualified = new List<Id>();
        for (Tournament_Group__c g : groupStage) {
            qualified.add(g.Team_1__c);
            qualified.add(g.Team_2__c);
        }
        
        // Shuffle
        for (Integer i = 0; i < qualified.size(); i++) {
            Integer r = i + Math.mod(Math.abs(Crypto.getRandomInteger()), qualified.size() - i);
            Id temp = qualified[i];
            qualified[i] = qualified[r];
            qualified[r] = temp;
        }
        
        // Stadium list
        List<String> stadiums = new List<String>{'Knockout Stadium 1','Knockout Stadium 2','Knockout Stadium 3'};
        
        // Sample scheduling
        DateTime dtRound16 = DateTime.newInstance(tournament.Start_Date__c.addDays(25), Time.newInstance(18,0,0,0));
        DateTime dtQuarter = DateTime.newInstance(tournament.Start_Date__c.addDays(27), Time.newInstance(20,0,0,0));
        DateTime dtSemi = DateTime.newInstance(tournament.Start_Date__c.addDays(29), Time.newInstance(20,0,0,0));
        DateTime dtFinal = DateTime.newInstance(tournament.End_Date__c, Time.newInstance(20,0,0,0));
        DateTime dtThirdPlace = DateTime.newInstance(tournament.Start_Date__c.addDays(29), Time.newInstance(18,0,0,0));
        
        // Round of 16 => 8 matches => 8 winners
        List<Id> r16Winners = new List<Id>();
        for (Integer i = 0; i < qualified.size(); i += 2) {
            Integer stIdx = Math.mod(Math.abs(Crypto.getRandomInteger()), stadiums.size());
            Id winner = simulateKnockoutMatch(qualified[i], qualified[i+1], 'Round of 16', dtRound16, stadiums[stIdx], tournament, knockoutGroup.Id);
            r16Winners.add(winner);
        }
        
        // Quarter => 4 matches => 4 winners
        List<Id> qWinners = new List<Id>();
        for (Integer i = 0; i < r16Winners.size(); i += 2) {
            Integer stIdx = Math.mod(Math.abs(Crypto.getRandomInteger()), stadiums.size());
            Id winner = simulateKnockoutMatch(r16Winners[i], r16Winners[i+1], 'Quarter Finals', dtQuarter, stadiums[stIdx], tournament, knockoutGroup.Id);
            qWinners.add(winner);
        }
        
        // Semi => 2 matches => 2 winners, 2 losers
        List<Id> semiWinners = new List<Id>();
        List<Id> semiLosers = new List<Id>();
        for (Integer i = 0; i < qWinners.size(); i += 2) {
            Integer stIdx = Math.mod(Math.abs(Crypto.getRandomInteger()), stadiums.size());
            Id teamA = qWinners[i];
            Id teamB = qWinners[i+1];
            
            // Simulate
            Id winner = simulateKnockoutMatch(teamA, teamB, 'Semi Finals', dtSemi, stadiums[stIdx], tournament, knockoutGroup.Id);
            Id loser = (winner == teamA) ? teamB : teamA;
            semiWinners.add(winner);
            semiLosers.add(loser);
        }
        
        // Finals
        Integer stF = Math.mod(Math.abs(Crypto.getRandomInteger()), stadiums.size());
        Id finalWinner = simulateKnockoutMatch(semiWinners[0], semiWinners[1], 'Finals', dtFinal, stadiums[stF], tournament, knockoutGroup.Id);
        
        // Third Place
        Integer stT = Math.mod(Math.abs(Crypto.getRandomInteger()), stadiums.size());
        simulateKnockoutMatch(semiLosers[0], semiLosers[1], 'Third Place Playoff', dtThirdPlace, stadiums[stT], tournament, knockoutGroup.Id);
        
        System.debug('✅ Knockout matches created.');
    }
    
    //──────────────────────────────────────────────────────────────
    // Simulates a knockout match with possible penalties, references the "Knockout Stage" group.
    private Id simulateKnockoutMatch(
        Id teamA, 
        Id teamB, 
        String roundVal, 
        DateTime matchDt, 
        String stadium, 
        Tournament__c tournament,
        Id knockoutGroupId
    ) {
        Integer scoreA = Math.mod(Math.abs(Crypto.getRandomInteger()), 6);
        Integer scoreB = Math.mod(Math.abs(Crypto.getRandomInteger()), 6);
        Boolean penShootout = false;
        Integer penA = 0;
        Integer penB = 0;
        if (scoreA == scoreB) {
            penShootout = true;
            penA = Math.mod(Math.abs(Crypto.getRandomInteger()), 6);
            penB = Math.mod(Math.abs(Crypto.getRandomInteger()), 6);
            while (penA == penB) {
                penB = Math.mod(Math.abs(Crypto.getRandomInteger()), 6);
            }
        }
        
        Match__c m = new Match__c(
            Tournament__c = tournament.Id,
            Tournament_Group__c = knockoutGroupId, // REQUIRED master-detail
            Home_Team__c = teamA,
            Away_Team__c = teamB,
            Score_Home_Team__c = scoreA,
            Score_Away_Team__c = scoreB,
            Home_Penalty_Score__c = penA,
            Away_Penalty_Score__c = penB,
            Penalty_Shootout__c = penShootout,
            Round__c = roundVal,
            Match_Datetime__c = matchDt,
            Stadium_Name__c = stadium
        );
        insert m;
        
        // Return the winner
        if (scoreA > scoreB || (scoreA == scoreB && penA > penB)) {
            return teamA;
        } else {
            return teamB;
        }
    }
}
