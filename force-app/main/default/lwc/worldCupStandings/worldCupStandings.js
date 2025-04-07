import { LightningElement, track, wire } from 'lwc';
import getTournaments from '@salesforce/apex/TournamentController.getTournaments';
import getGroupStandingsByTournament from '@salesforce/apex/TournamentTeamStandingsController.getGroupStandingsByTournament';

export default class WorldCupStandings extends LightningElement {
    @track selectedTournamentId = '';
    @track tournamentOptions = [];
    standings = [];
    groupedStandings = [];
    error;

    // Wire tournaments for dropdown options.
    @wire(getTournaments)
    wiredTournaments({ data, error }) {
        if (data) {
            this.tournamentOptions = data.map(t => ({
                label: t.Name,
                value: t.Id
            }));
            // Set default tournament if not selected.
            if (!this.selectedTournamentId && data.length > 0) {
                this.selectedTournamentId = data[0].Id;
            }
        } else if (error) {
            this.error = error;
            console.error('Error fetching tournaments:', error);
        }
    }

    // Wire group standings based on selected tournament.
    @wire(getGroupStandingsByTournament, { tournamentId: '$selectedTournamentId' })
    wiredStandings({ data, error }) {
        if (data) {
            this.standings = data;
            // Group standings by Tournament_Group__r.Name and compute rank.
            const groups = {};
            data.forEach(team => {
                const groupName = team.Tournament_Group__r.Name;
                if (!groups[groupName]) {
                    groups[groupName] = { name: groupName, teams: [] };
                }
                groups[groupName].teams.push({ ...team, rank: groups[groupName].teams.length + 1 });
            });
            this.groupedStandings = Object.values(groups);
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching group standings:', error);
            this.error = error;
            this.standings = [];
            this.groupedStandings = [];
        }
    }

    // Handle dropdown change.
    handleTournamentChange(event) {
        this.selectedTournamentId = event.detail.value;
    }
}
