import { LightningElement, wire } from 'lwc';
import getKnockoutMatches from '@salesforce/apex/KnockoutMatchesController.getKnockoutMatches';

export default class KnockoutMatches extends LightningElement {
    bracketData = [];   // final array of matches in bracket order (R16->QF->SF->Final)
    bracketPaths = [];  // array of SVG lines
    roundHeadings = []; // optional headings
    error;

    // container size
    containerWidth = 0;
    containerHeight = 0;

    // match box size
    matchBoxWidth = 140;
    matchBoxHeight = 80;

    // columns for the 4 rounds
    xR16   = 50;
    xQF    = 250;
    xSF    = 450;
    xFinal = 650;

    @wire(getKnockoutMatches)
    wiredMatches({ data, error }) {
        if (data) {
            // 1) convert raw records into simpler objects
            let raw = data.map(m => {
                return {
                    Id: m.Id,
                    Round__c: m.Round__c,
                    HomeTeam: m.Home_Team__r?.Name || '',
                    AwayTeam: m.Away_Team__r?.Name || '',
                    HomeScore: m.Score_Home_Team__c,
                    AwayScore: m.Score_Away_Team__c,
                    Penalty: m.Penalty_Shootout__c,
                    HomePenalty: m.Home_Penalty_Score__c,
                    AwayPenalty: m.Away_Penalty_Score__c,
                    Winner: m.Winner__c || '',  // formula field for winner
                    MatchDatetime: m.Match_Datetime__c,
                    x: 0, y: 0,
                    boxClass: '', inlineStyle: ''
                };
            });

            // 2) group by round
            let r16 = raw.filter(r => r.Round__c === 'Round of 16');
            let qf  = raw.filter(r => r.Round__c === 'Quarter Finals');
            let sf  = raw.filter(r => r.Round__c === 'Semi Finals');
            let finals = raw.filter(r => r.Round__c === 'Finals');

            // 3) sort each round by datetime (or by your custom logic)
            r16.sort((a, b) => a.MatchDatetime.localeCompare(b.MatchDatetime));
            qf.sort((a, b) => a.MatchDatetime.localeCompare(b.MatchDatetime));
            sf.sort((a, b) => a.MatchDatetime.localeCompare(b.MatchDatetime));
            finals.sort((a, b) => a.MatchDatetime.localeCompare(b.MatchDatetime));

            // 4) reorder Semi Finals based on Final
            let finalMatch = finals.length ? finals[0] : null;
            let orderedSF = sf;
            if (finalMatch && sf.length >= 2) {
                // top SF is the one whose Winner = finalMatch.HomeTeam
                let topSF = sf.find(s => s.Winner === finalMatch.HomeTeam);
                let bottomSF = sf.find(s => s.Winner === finalMatch.AwayTeam);
                if (topSF && bottomSF && topSF !== bottomSF) {
                    orderedSF = [topSF, bottomSF];
                }
            }

            // 5) reorder Quarter Finals based on newly ordered SF
            let orderedQF = [];
            if (orderedSF.length >= 2) {
                // for top SF
                let topSemi = orderedSF[0];
                // find QF whose winners match topSemi’s home/away
                let qfForTop = qf.filter(q => q.Winner === topSemi.HomeTeam || q.Winner === topSemi.AwayTeam);
                // for bottom SF
                let bottomSemi = orderedSF[1];
                let qfForBottom = qf.filter(q => q.Winner === bottomSemi.HomeTeam || bottomSemi.AwayTeam === q.Winner);
                orderedQF = [...qfForTop, ...qfForBottom];
                // if not all found, fallback
                if (orderedQF.length < qf.length) {
                    orderedQF = qf;
                }
            } else {
                orderedQF = qf;
            }

            // 6) reorder Round of 16 based on newly ordered QF
            let orderedR16 = [];
            orderedQF.forEach(q => {
                // find the two R16 matches whose Winner = q.HomeTeam or q.AwayTeam
                let matchHome = r16.find(r => r.Winner === q.HomeTeam);
                let matchAway = r16.find(r => r.Winner === q.AwayTeam);
                if (matchHome) orderedR16.push(matchHome);
                if (matchAway && matchAway !== matchHome) orderedR16.push(matchAway);
            });
            // if we didn't find them all, fallback
            if (orderedR16.length < r16.length) {
                orderedR16 = r16;
            }

            // 7) now we have ordered R16, QF, SF, final
            // position them in columns
            let startY_R16 = 50, spacingR16 = 100;
            orderedR16.forEach((m, i) => {
                m.x = this.xR16;
                m.y = startY_R16 + i * spacingR16;
            });
            let startY_QF = 50, spacingQF = 120;
            orderedQF.forEach((m, i) => {
                m.x = this.xQF;
                m.y = startY_QF + i * spacingQF;
            });
            let startY_SF = 50, spacingSF = 180;
            orderedSF.forEach((m, i) => {
                m.x = this.xSF;
                m.y = startY_SF + i * spacingSF;
            });
            if (finalMatch) {
                finalMatch.x = this.xFinal;
                finalMatch.y = 150; // or any logic to place the final
            }

            // 8) combine them for display
            let allMatches = [...orderedR16, ...orderedQF, ...orderedSF];
            if (finalMatch) allMatches.push(finalMatch);

            // build lines by matching parent winners
            let paths = [];
            const offset = 30;
            const createPath = (parent, child) => {
                if (!parent || !child) return null;
                let px = parent.x + this.matchBoxWidth;
                let py = parent.y + this.matchBoxHeight/2;
                let cx = child.x;
                let cy = child.y + this.matchBoxHeight/2;
                return `M ${px},${py} C ${px+offset},${py} ${cx-offset},${cy} ${cx},${cy}`;
            };

            // function to link parent round -> child round
            function linkParents(parents, children) {
                children.forEach(child => {
                    // find two parents whose Winner = child.HomeTeam / child.AwayTeam
                    let pHome = parents.find(p => child.HomeTeam === p.Winner);
                    let pAway = parents.find(p => child.AwayTeam === p.Winner);
                    if (pHome) {
                        let d1 = createPath(pHome, child);
                        if (d1) paths.push({ d: d1, lineKey: `${pHome.Id}-${child.Id}-home` });
                    }
                    if (pAway) {
                        let d2 = createPath(pAway, child);
                        if (d2) paths.push({ d: d2, lineKey: `${pAway.Id}-${child.Id}-away` });
                    }
                });
            }
            // link R16->QF
            linkParents(orderedR16, orderedQF);
            // link QF->SF
            linkParents(orderedQF, orderedSF);
            // link SF->Final
            if (finalMatch && orderedSF.length >= 2) {
                linkParents(orderedSF, [finalMatch]);
            }

            // Mark a simple CSS class if home team’s winner or away team’s winner
            allMatches.forEach(m => {
                let w = m.Winner;
                if (w === m.HomeTeam) {
                    m.boxClass = 'match-box winner-home';
                } else if (w === m.AwayTeam) {
                    m.boxClass = 'match-box winner-away';
                } else {
                    m.boxClass = 'match-box';
                }
                m.inlineStyle = `left:${m.x}px; top:${m.y}px;`;
            });

            // compute bounding box
            let maxX = 0, maxY = 0;
            allMatches.forEach(m => {
                let rightEdge = m.x + this.matchBoxWidth;
                if (rightEdge > maxX) maxX = rightEdge;
                let bottomEdge = m.y + this.matchBoxHeight;
                if (bottomEdge > maxY) maxY = bottomEdge;
            });
            maxX += 50;
            maxY += 50;
            this.containerWidth = maxX;
            this.containerHeight = maxY;

            // optional round headings
            const roundX = {
                'Round of 16': this.xR16,
                'Quarter Finals': this.xQF,
                'Semi Finals': this.xSF,
                'Finals': this.xFinal
            };
            let headings = [];
            Object.keys(roundX).forEach(r => {
                headings.push({ roundName: r, style: `left:${roundX[r]}px; top:10px;` });
            });

            this.bracketData = allMatches;
            this.bracketPaths = paths;
            this.roundHeadings = headings;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.bracketData = [];
            this.bracketPaths = [];
            this.roundHeadings = [];
        }
    }

    get containerStyle() {
        return `
            position: relative;
            width:${this.containerWidth}px;
            height:${this.containerHeight}px;
            margin: 0 auto;
            overflow: auto;
        `;
    }
}
