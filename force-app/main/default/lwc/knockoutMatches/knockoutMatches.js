import { LightningElement, wire } from 'lwc';
import getKnockoutMatches from '@salesforce/apex/KnockoutMatchesController.getKnockoutMatches';

export default class KnockoutMatches extends LightningElement {
    knockoutMatches = [];
    rounds = [];

    @wire(getKnockoutMatches)
    wiredMatches({ error, data }) {
        if (data) {
            this.knockoutMatches = data;
            // Group matches by round
            const roundsMap = {};
            data.forEach(match => {
                const round = match.Round__c;
                if (!roundsMap[round]) {
                    roundsMap[round] = { round: round, matches: [] };
                }
                roundsMap[round].matches.push(match);
            });
            // Convert the rounds object into an array
            this.rounds = Object.values(roundsMap);
            console.log(JSON.stringify(this.rounds));
            // Sort rounds in desired order
            const order = {
                'Round of 16': 1,
                'Quarter Finals': 2,
                'Semi Finals': 3,
                'Finals': 4
            };
            this.rounds.sort((a, b) => order[a.round] - order[b.round]);
        } else if (error) {
            console.error('Error fetching knockout matches:', error);
        }
    }
}
