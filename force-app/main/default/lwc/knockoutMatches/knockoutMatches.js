import { LightningElement, wire } from 'lwc';
import getKnockoutMatches from '@salesforce/apex/KnockoutMatchesController.getKnockoutMatches';

export default class KnockoutMatches extends LightningElement {
    bracketData = [];
    bracketPaths = [];
    roundHeadings = [];
    error;

    // Dynamically sized container
    containerWidth = 0;
    containerHeight = 0;

    // Rounds in bracket order
    roundOrder = ['Round of 16','Quarter Finals','Semi Finals','Finals'];

    // Dimensions for line calculations
    matchBoxWidth = 140;
    matchBoxHeight = 80;

    @wire(getKnockoutMatches)
    wiredMatches({ data, error }) {
        if (data) {
            // 1) Group matches by round
            const roundsMap = {};
            this.roundOrder.forEach(r => { roundsMap[r] = []; });
            data.forEach(m => {
                const matchObj = {
                    Id: m.Id,
                    Round__c: m.Round__c,
                    HomeTeam: m.Home_Team__r?.Name || '',
                    AwayTeam: m.Away_Team__r?.Name || '',
                    HomeScore: m.Score_Home_Team__c,
                    AwayScore: m.Score_Away_Team__c,
                    Penalty: m.Penalty_Shootout__c,
                    HomePenalty: m.Home_Penalty_Score__c,
                    AwayPenalty: m.Away_Penalty_Score__c,
                    MatchDatetime: m.Match_Datetime__c,
                    x: 0,
                    y: 0,
                    inlineStyle: '',
                    winner: '',
                    boxClass: ''
                };
                if (!roundsMap[m.Round__c]) {
                    roundsMap[m.Round__c] = [];
                }
                roundsMap[m.Round__c].push(matchObj);
            });

            // 2) Sort each round by Id
            for (let r of this.roundOrder) {
                roundsMap[r].sort((a, b) => (a.Id > b.Id ? 1 : -1));
            }

            // 3) Position each round
            const r16 = roundsMap['Round of 16'];
            let startY = 70;
            let spacing = 120;
            let xR16 = 50;
            r16.forEach((m, i) => {
                m.x = xR16;
                m.y = startY + i * spacing;
            });

            const qf = roundsMap['Quarter Finals'];
            let xQF = 250;
            qf.forEach((m, i) => {
                const p1 = r16[2*i];
                const p2 = r16[2*i + 1];
                if (p1 && p2) {
                    m.x = xQF;
                    m.y = (p1.y + p2.y) / 2;
                }
            });

            const sf = roundsMap['Semi Finals'];
            let xSF = 450;
            sf.forEach((m, i) => {
                const p1 = qf[2*i];
                const p2 = qf[2*i + 1];
                if (p1 && p2) {
                    m.x = xSF;
                    m.y = (p1.y + p2.y) / 2;
                }
            });

            const finals = roundsMap['Finals'];
            let xFinal = 650;
            if (finals.length > 0 && sf.length >= 2) {
                finals[0].x = xFinal;
                finals[0].y = (sf[0].y + sf[1].y) / 2;
            }

            // 4) Determine winner
            const computeWinner = (match) => {
                if (match.HomeScore != null && match.AwayScore != null) {
                    if (match.HomeScore > match.AwayScore) return 'home';
                    if (match.HomeScore < match.AwayScore) return 'away';
                    if (match.Penalty) {
                        if (match.HomePenalty > match.AwayPenalty) return 'home';
                        if (match.HomePenalty < match.AwayPenalty) return 'away';
                        return 'draw';
                    }
                    return 'draw';
                }
                return '';
            };

            const allMatches = [...r16, ...qf, ...sf, ...finals];
            allMatches.forEach(m => {
                m.winner = computeWinner(m);
                m.boxClass = 'match-box' + (
                    m.winner === 'home' ? ' winner-home' :
                    m.winner === 'away' ? ' winner-away' : ''
                );
                m.inlineStyle = `left:${m.x}px; top:${m.y}px;`;
            });

            // 5) Build bracket lines
            const paths = [];
            const offset = 30;
            const createPath = (parent, child) => {
                if (!parent || !child) return null;
                const px = parent.x + this.matchBoxWidth;
                const py = parent.y + this.matchBoxHeight / 2;
                const cx = child.x;
                const cy = child.y + this.matchBoxHeight / 2;
                return `M ${px},${py} C ${px+offset},${py} ${cx-offset},${cy} ${cx},${cy}`;
            };

            // R16 -> QF
            qf.forEach((child, i) => {
                const p1 = r16[2*i];
                const p2 = r16[2*i + 1];
                if (p1 && p2) {
                    let path1 = createPath(p1, child);
                    let path2 = createPath(p2, child);
                    if (path1) paths.push({ d: path1, lineKey: `${p1.Id}-${child.Id}-1` });
                    if (path2) paths.push({ d: path2, lineKey: `${p2.Id}-${child.Id}-2` });
                }
            });

            // QF -> SF
            sf.forEach((child, i) => {
                const p1 = qf[2*i];
                const p2 = qf[2*i + 1];
                if (p1 && p2) {
                    let path1 = createPath(p1, child);
                    let path2 = createPath(p2, child);
                    if (path1) paths.push({ d: path1, lineKey: `${p1.Id}-${child.Id}-1` });
                    if (path2) paths.push({ d: path2, lineKey: `${p2.Id}-${child.Id}-2` });
                }
            });

            // SF -> Finals
            if (finals.length > 0 && sf.length >= 2) {
                let path1 = createPath(sf[0], finals[0]);
                let path2 = createPath(sf[1], finals[0]);
                if (path1) paths.push({ d: path1, lineKey: `${sf[0].Id}-${finals[0].Id}-1` });
                if (path2) paths.push({ d: path2, lineKey: `${sf[1].Id}-${finals[0].Id}-2` });
            }

            // 6) Round headings
            const roundX = {
                'Round of 16': xR16,
                'Quarter Finals': xQF,
                'Semi Finals': xSF,
                'Finals': xFinal
            };
            const headings = [];
            this.roundOrder.forEach(r => {
                headings.push({
                    roundName: r,
                    style: `left:${roundX[r]}px; top:10px;`
                });
            });

            // 7) Compute container size
            let maxX = 0, maxY = 0;
            allMatches.forEach(m => {
                let rightEdge = m.x + this.matchBoxWidth;
                if (rightEdge > maxX) {
                    maxX = rightEdge;
                }
                let bottomEdge = m.y + this.matchBoxHeight;
                if (bottomEdge > maxY) {
                    maxY = bottomEdge;
                }
            });
            maxX += 50; // margin for lines
            maxY += 50;

            this.containerWidth = maxX;
            this.containerHeight = maxY;

            // 8) Save final data
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

    // Inline style to center the bracket horizontally
    get containerStyle() {
        return `
            position: relative;
            width:${this.containerWidth}px;
            height:${this.containerHeight}px;
            margin: 0 auto; /* center horizontally */
            overflow: auto;
        `;
    }
}
