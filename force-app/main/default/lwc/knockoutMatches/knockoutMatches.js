import { LightningElement, wire } from 'lwc';
import getKnockoutMatches from '@salesforce/apex/KnockoutMatchesController.getKnockoutMatches';

export default class KnockoutMatches extends LightningElement {
    bracketData = [];   // All matches (with x, y, inlineStyle)
    bracketLines = [];  // Array of { x1, y1, x2, y2, lineKey } for SVG lines
    error;

    // Round order in bracket
    roundOrder = ['Round of 16','Quarter Finals','Semi Finals','Finals'];

    // Match box dimensions used in line calculations
    matchBoxWidth = 140;
    matchBoxHeight = 60;

    @wire(getKnockoutMatches)
    wiredMatches({ data, error }) {
        if (data) {
            // 1) Group matches by round
            const roundsMap = {
                'Round of 16': [],
                'Quarter Finals': [],
                'Semi Finals': [],
                'Finals': []
            };
            data.forEach(m => {
                roundsMap[m.Round__c].push({
                    Id: m.Id,
                    Round__c: m.Round__c,
                    HomeTeam: m.Home_Team__r?.Name,
                    AwayTeam: m.Away_Team__r?.Name,
                    HomeScore: m.Score_Home_Team__c,
                    AwayScore: m.Score_Away_Team__c,
                    x: 0,
                    y: 0,
                    inlineStyle: ''
                });
            });

            // 2) Sort each round if needed (by Id or your custom logic)
            for (let r in roundsMap) {
                roundsMap[r].sort((a, b) => (a.Id > b.Id ? 1 : -1));
            }

            // 3) Position Round of 16
            const r16 = roundsMap['Round of 16'];
            let startY = 50;
            let spacing = 100;
            let xR16 = 50;
            r16.forEach((m, i) => {
                m.x = xR16;
                m.y = startY + i * spacing;
            });

            // 4) Position Quarter Finals
            const qf = roundsMap['Quarter Finals'];
            let xQF = 250;
            qf.forEach((m, i) => {
                const parent1 = r16[2*i];
                const parent2 = r16[2*i + 1];
                if (parent1 && parent2) {
                    m.x = xQF;
                    m.y = (parent1.y + parent2.y) / 2;
                }
            });

            // 5) Position Semi Finals
            const sf = roundsMap['Semi Finals'];
            let xSF = 450;
            sf.forEach((m, i) => {
                const parent1 = qf[2*i];
                const parent2 = qf[2*i + 1];
                if (parent1 && parent2) {
                    m.x = xSF;
                    m.y = (parent1.y + parent2.y) / 2;
                }
            });

            // 6) Position Finals
            const finals = roundsMap['Finals'];
            let xFinal = 650;
            if (finals.length > 0 && sf.length >= 2) {
                finals[0].x = xFinal;
                finals[0].y = (sf[0].y + sf[1].y) / 2;
            }

            // 7) Build bracketData (with inline styles)
            const allMatches = [...r16, ...qf, ...sf, ...finals];
            allMatches.forEach(m => {
                m.inlineStyle = `left:${m.x}px; top:${m.y}px;`;
            });

            // 8) Build bracketLines
            const lines = [];

            // Helper to connect 2 matches
            const connectMatches = (parent, child) => {
                if (!parent || !child) return;
                // parent's center-right
                const px = parent.x + this.matchBoxWidth;
                const py = parent.y + this.matchBoxHeight / 2;
                // child's center-left
                const cx = child.x;
                const cy = child.y + this.matchBoxHeight / 2;
                lines.push({
                    x1: px,
                    y1: py,
                    x2: cx,
                    y2: cy,
                    lineKey: `${px}-${py}-${cx}-${cy}` // Unique key for LWC
                });
            };

            // A) R16 -> QF
            qf.forEach((child, i) => {
                connectMatches(r16[2*i], child);
                connectMatches(r16[2*i + 1], child);
            });

            // B) QF -> SF
            sf.forEach((child, i) => {
                connectMatches(qf[2*i], child);
                connectMatches(qf[2*i + 1], child);
            });

            // C) SF -> Final
            if (finals.length > 0 && sf.length >= 2) {
                connectMatches(sf[0], finals[0]);
                connectMatches(sf[1], finals[0]);
            }

            this.bracketData = allMatches;
            this.bracketLines = lines;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.bracketData = [];
            this.bracketLines = [];
        }
    }
}
