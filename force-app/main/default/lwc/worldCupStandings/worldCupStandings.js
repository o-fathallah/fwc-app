import { LightningElement, wire } from 'lwc';
import getGroupStandings from '@salesforce/apex/TournamentTeamController.getGroupStandings';

export default class WorldCupStandings extends LightningElement {
    standings = [];
    groupedStandings = [];

    @wire(getGroupStandings)
    wiredStandings({ error, data }) {
        if (data) {
            this.standings = data;

            // Group standings by tournament group
            const groups = {};
            data.forEach(team => {
                const groupName = team.Tournament_Group__r.Name;
                if (!groups[groupName]) {
                    groups[groupName] = { name: groupName, teams: [] };
                }
                // Compute rank for each team in the group (using current group team count + 1)
                groups[groupName].teams.push({ ...team, rank: groups[groupName].teams.length + 1 });
            });

            // Convert grouped object to array for LWC template usage
            this.groupedStandings = Object.values(groups);
        } else if (error) {
            console.error('Error fetching standings:', error);
        }
    }
}
