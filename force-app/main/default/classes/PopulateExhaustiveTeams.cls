public class PopulateExhaustiveTeams {
    public static void run() {
        // Define an exhaustive list of national team names (32 from your PDF plus additional teams)
        List<String> exhaustiveTeamNames = new List<String>{
            // Teams from your PDF:
            'Argentina', 'Australia', 'Belgium', 'Brazil', 'Cameroon', 'Canada', 
            'Costa Rica', 'Croatia', 'Denmark', 'Ecuador', 'England', 'France', 
            'Germany', 'Ghana', 'Iran', 'Japan', 'Mexico', 'Morocco', 'Netherlands', 
            'Poland', 'Portugal', 'Qatar', 'Saudi Arabia', 'Senegal', 'Serbia', 
            'South Korea', 'Spain', 'Switzerland', 'Tunisia', 'Uruguay', 'USA', 'Wales',
            // Additional teams:
            'Nigeria', 'Ivory Coast', 'Algeria', 'Egypt', 'Chile', 'Colombia', 'Peru', 
            'Bolivia', 'Paraguay', 'Scotland', 'Iceland', 'Russia', 'Turkey', 'Czech Republic', 
            'Austria', 'Hungary', 'Romania', 'Bulgaria', 'Slovakia', 'Slovenia', 'Finland', 
            'Sweden', 'Norway', 'United Arab Emirates', 'Iraq', 'Kuwait', 'Uzbekistan', 'India', 
            'China', 'New Zealand'
        };
        
        // Map of team names to their official abbreviations (as per FIFA conventions)
        Map<String, String> teamAbbreviations = new Map<String, String>{
            // From PDF:
            'Argentina' => 'ARG',
            'Australia' => 'AUS',
            'Belgium'   => 'BEL',
            'Brazil'    => 'BRA',
            'Cameroon'  => 'CMR',
            'Canada'    => 'CAN',
            'Costa Rica'=> 'CRC',
            'Croatia'   => 'CRO',
            'Denmark'   => 'DEN',
            'Ecuador'   => 'ECU',
            'England'   => 'ENG',
            'France'    => 'FRA',
            'Germany'   => 'GER',
            'Ghana'     => 'GHA',
            'Iran'      => 'IRN',
            'Japan'     => 'JPN',
            'Mexico'    => 'MEX',
            'Morocco'   => 'MAR',
            'Netherlands'=> 'NED',
            'Poland'    => 'POL',
            'Portugal'  => 'PRT',
            'Qatar'     => 'QA',
            'Saudi Arabia' => 'SAU',
            'Senegal'   => 'SEN',
            'Serbia'    => 'SRB',
            'South Korea' => 'KOR',
            'Spain'     => 'ESP',
            'Switzerland' => 'CHE',
            'Tunisia'   => 'TUN',
            'Uruguay'   => 'URY',
            'USA'       => 'USA',
            'Wales'     => 'WAL',
            // Additional teams:
            'Nigeria'         => 'NGA',
            'Ivory Coast'     => 'CIV',
            'Algeria'         => 'ALG',
            'Egypt'           => 'EGY',
            'Chile'           => 'CHI',
            'Colombia'        => 'COL',
            'Peru'            => 'PER',
            'Bolivia'         => 'BOL',
            'Paraguay'        => 'PAR',
            'Scotland'        => 'SCO',
            'Iceland'         => 'ISL',
            'Russia'          => 'RUS',
            'Turkey'          => 'TUR',
            'Czech Republic'  => 'CZE',
            'Austria'         => 'AUT',
            'Hungary'         => 'HUN',
            'Romania'         => 'ROU',
            'Bulgaria'        => 'BUL',
            'Slovakia'        => 'SVK',
            'Slovenia'        => 'SVN',
            'Finland'         => 'FIN',
            'Sweden'          => 'SWE',
            'Norway'          => 'NOR',
            'United Arab Emirates' => 'UAE',
            'Iraq'            => 'IRQ',
            'Kuwait'          => 'KUW',
            'Uzbekistan'      => 'UZB',
            'India'           => 'IND',
            'China'           => 'CHN',
            'New Zealand'     => 'NZL'
        };
        
        // Query existing Team__c records to get existing team names and abbreviations
        Set<String> existingNames = new Set<String>();
        Set<String> existingAbbrs = new Set<String>();
        for (Team__c t : [SELECT Name, Abbreviation_of__c FROM Team__c]) {
            existingNames.add(t.Name.toLowerCase());
            if (t.Abbreviation_of__c != null) {
                existingAbbrs.add(t.Abbreviation_of__c.toUpperCase());
            }
        }
        
        // Prepare a list for new team records that are missing.
        List<Team__c> teamsToInsert = new List<Team__c>();
        for (String name : exhaustiveTeamNames) {
            // Use case-insensitive check on name.
            if (!existingNames.contains(name.toLowerCase())) {
                String abbr;
                if (teamAbbreviations.containsKey(name)) {
                    abbr = teamAbbreviations.get(name);
                } else {
                    // Fallback: use first three letters in uppercase.
                    abbr = (name.length() >= 3) ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
                }
                // Ensure abbreviation uniqueness: if the abbreviation is already used, append a numeric suffix.
                String uniqueAbbr = abbr;
                Integer suffix = 1;
                while (existingAbbrs.contains(uniqueAbbr)) {
                    uniqueAbbr = abbr + ' (' + suffix + ')';
                    suffix++;
                }
                // Add the new abbreviation to the set so that subsequent checks consider it.
                existingAbbrs.add(uniqueAbbr);
                
                // Create new team record.
                teamsToInsert.add(new Team__c(
                    Name = name,
                    Abbreviation_of__c = uniqueAbbr
                ));
            }
        }
        
        // Insert missing teams, if any.
        if (!teamsToInsert.isEmpty()) {
            insert teamsToInsert;
            System.debug('Inserted ' + teamsToInsert.size() + ' missing teams.');
        } else {
            System.debug('No new teams to insert.');
        }
    }
}
