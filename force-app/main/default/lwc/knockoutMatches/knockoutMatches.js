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
            const roundMap = {};
            data.forEach(match => {
                const round = match.Round__c;
                if (!roundMap[round]) {
                    roundMap[round] = { round: round, matches: [] };
                }
                roundMap[round].matches.push(match);
            });
            // Convert roundMap to an array and sort by the desired knockout order
            const roundOrder = {
                'Round of 16': 1,
                'Quarter Finals': 2,
                'Semi Finals': 3,
                'Finals': 4
            };
            this.rounds = Object.values(roundMap).sort((a, b) => {
                return roundOrder[a.round] - roundOrder[b.round];
            });
        } else if (error) {
            console.error('Error fetching knockout matches:', error);
        }
    }
}
