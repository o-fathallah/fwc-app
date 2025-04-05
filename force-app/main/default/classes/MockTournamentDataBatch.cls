public class MockTournamentDataBatch implements Database.Batchable<Integer> {
    public Iterable<Integer> start(Database.BatchableContext bc) {
        return new List<Integer>{1}; // Single-run batch
    }
    
    public void execute(Database.BatchableContext bc, List<Integer> scope) {
        createTournamentWithUniqueName();
    }
    
    public void finish(Database.BatchableContext bc) {}
    
    private void createTournamentWithUniqueName() {
        // Step 1: Calculate candidate tournament year based on current year.
        Integer currentYear = Date.today().year();
        Integer remainder = Math.mod(currentYear, 4);
        Integer candidateYear;
        if (remainder == 0) {
            candidateYear = currentYear + 4;
        } else {
            candidateYear = currentYear + (4 - remainder);
        }
        
        // Step 2: Query existing tournaments for their used years.
        Set<Integer> usedYears = new Set<Integer>();
        for (Tournament__c t : [
            SELECT Tournament_Year__c 
            FROM Tournament__c 
            WHERE Tournament_Year__c != null
        ]) {
            usedYears.add((Integer)t.Tournament_Year__c);
        }
        // If candidateYear is already used, move to the next cycle until available.
        while (usedYears.contains(candidateYear)) {
            candidateYear += 4;
        }
        
        // Step 3: Define a list of possible host countries.
        List<String> countries = new List<String>{
            'Brazil', 'Germany', 'France', 'Italy', 'USA',
            'Argentina', 'Spain', 'Netherlands', 'Japan', 'Morocco',
            'South Korea', 'England', 'Canada', 'Australia'
        };
        
        // Step 4: Query existing tournaments for their Host_Country__c values.
        Set<String> usedHosts = new Set<String>();
        for (Tournament__c t : [
            SELECT Host_Country__c 
            FROM Tournament__c 
            WHERE Host_Country__c != null
        ]) {
            usedHosts.add(t.Host_Country__c);
        }
        
        // Build a list of available countries that haven't been used yet.
        List<String> availableCountries = new List<String>();
        for (String c : countries) {
            if (!usedHosts.contains(c)) {
                availableCountries.add(c);
            }
        }
        
        // Step 5: Select a host country ensuring uniqueness.
        String host;
        if (availableCountries.size() > 0) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), availableCountries.size());
            host = availableCountries[randomIndex];
        } else {
            // All predefined countries are used; pick one and append a numeric suffix to make it unique.
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), countries.size());
            String baseHost = countries[randomIndex];
            host = baseHost;
            Integer hSuffix = 1;
            while ([SELECT COUNT() FROM Tournament__c WHERE Host_Country__c = :host] > 0) {
                host = baseHost + ' (' + hSuffix + ')';
                hSuffix++;
            }
        }
        
        // Step 6: Build the base tournament name.
        String baseName = 'FIFA World Cup ' + host + ' ' + candidateYear;
        String tournamentName = baseName;
        
        // Check for duplicate tournament names and add a suffix if needed.
        Integer suffix = 1;
        while ([SELECT COUNT() FROM Tournament__c WHERE Name = :tournamentName] > 0) {
            tournamentName = baseName + ' (' + suffix + ')';
            suffix++;
        }
        
        // Step 7: Create and insert the tournament record.
        Tournament__c tournament = new Tournament__c(
            Name = tournamentName,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(30),
            Host_Country__c = host,
            Status__c = 'Upcoming',  // Must match an allowed picklist value
            Tournament_Year__c = candidateYear
        );
        insert tournament;
        System.debug('✅ Created tournament: ' + tournamentName);
    }
}
