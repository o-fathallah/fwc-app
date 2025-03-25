import { LightningElement, wire } from 'lwc';
import getKnockoutMatches from '@salesforce/apex/KnockoutMatchesController.getKnockoutMatches';

export default class KnockoutMatches extends LightningElement {
    bracketData = []; // Final array for template
    error;

    // Use round names exactly as in your data
    roundOrder = [
        'Round of 16',
        'Quarter Finals',
        'Semi Finals',
        'Third Place Playoff',
        'Finals'
    ];

    @wire(getKnockoutMatches)
    wiredMatches({ data, error }) {
        if (data) {
            // 1) Group matches by round
            const roundsMap = {};
            this.roundOrder.forEach(r => { roundsMap[r] = []; });
            data.forEach(m => {
                // Ensure the key matches exactly (e.g., "Finals" not "Final")
                if (!roundsMap[m.Round__c]) {
                    roundsMap[m.Round__c] = [];
                }
                roundsMap[m.Round__c].push({
                    Id: m.Id,
                    Round__c: m.Round__c,
                    HomeTeam: m.Home_Team__r ? m.Home_Team__r.Name : '',
                    AwayTeam: m.Away_Team__r ? m.Away_Team__r.Name : '',
                    HomeScore: m.Score_Home_Team__c,
                    AwayScore: m.Score_Away_Team__c,
                    x: 0,
                    y: 0,
                    inlineStyle: ''
                });
            });

            // 2) Sort matches in each round (assuming order by Id works; adjust if needed)
            for (let r of this.roundOrder) {
                roundsMap[r].sort((a, b) => (a.Id > b.Id ? 1 : -1));
            }

            // 3) Define horizontal positions for each round
            const xPos = {
                'Round of 16': 50,
                'Quarter Finals': 250,
                'Semi Finals': 450,
                'Third Place Playoff': 650,
                'Finals': 850
            };

            // A) Position Round of 16
            const r16 = roundsMap['Round of 16'];
            let startY = 50;
            let spacing = 100;
            r16.forEach((matchObj, i) => {
                matchObj.x = xPos['Round of 16'];
                matchObj.y = startY + i * spacing;
            });

            // B) Position Quarter Finals
            const quarter = roundsMap['Quarter Finals'];
            quarter.forEach((matchObj, i) => {
                const parent1 = r16[2*i];
                const parent2 = r16[2*i + 1];
                matchObj.x = xPos['Quarter Finals'];
                matchObj.y = (parent1.y + parent2.y) / 2;
            });

            // C) Position Semi Finals
            const semis = roundsMap['Semi Finals'];
            semis.forEach((matchObj, i) => {
                const parent1 = quarter[2*i];
                const parent2 = quarter[2*i + 1];
                matchObj.x = xPos['Semi Finals'];
                matchObj.y = (parent1.y + parent2.y) / 2;
            });

            // D) Position Third Place Playoff (if exists)
            const thirdPlace = roundsMap['Third Place Playoff'];
            if (thirdPlace.length > 0) {
                let tp = thirdPlace[0];
                tp.x = xPos['Third Place Playoff'];
                // For example, position it a bit below the semifinals
                tp.y = (semis[0].y + semis[1].y) / 2 + 50;
            }

            // E) Position Finals
            const finals = roundsMap['Finals'];
            if (finals.length > 0) {
                const finalObj = finals[0];
                finalObj.x = xPos['Finals'];
                if (semis.length >= 2) {
                    finalObj.y = (semis[0].y + semis[1].y) / 2;
                } else if (semis.length === 1) {
                    finalObj.y = semis[0].y;
                } else {
                    finalObj.y = 0;
                }
            }

            // 4) Build inline styles and combine all matches into one array
            let allMatches = [];
            for (let r of this.roundOrder) {
                roundsMap[r].forEach(mObj => {
                    mObj.inlineStyle = `left:${mObj.x}px; top:${mObj.y}px;`;
                    allMatches.push(mObj);
                });
            }

            this.bracketData = allMatches;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.bracketData = [];
        }
    }
}
