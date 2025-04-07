import { LightningElement, track, wire } from 'lwc';
import getKnockoutMatchesByTournament from '@salesforce/apex/KnockoutMatchesController.getKnockoutMatchesByTournament';
import getTournaments from '@salesforce/apex/TournamentController.getTournaments';

export default class KnockoutMatches extends LightningElement {
    @track selectedTournamentId = '';
    @track tournamentOptions = [];
    bracketData = [];
    bracketPaths = [];
    roundHeadings = [];
    error;

    // Layout properties
    containerWidth = 1200;
    containerHeight = 800;
    matchBoxWidth = 160;
    matchBoxHeight = 100;

    // X positions for rounds
    xR16   = 100;   // Round of 16
    xQF    = 400;   // Quarter Finals
    xSF    = 700;   // Semi Finals
    xFinal = 1000;  // Finals

    // Placement properties for Round of 16 matches
    r16StartY = 160;
    r16Spacing = 150;

    // Wire the tournaments for the dropdown
    @wire(getTournaments)
    wiredTournaments({ data, error }) {
        if (data) {
            this.tournamentOptions = data.map(t => ({
                label: t.Name,
                value: t.Id
            }));
            if (!this.selectedTournamentId && data.length > 0) {
                this.selectedTournamentId = data[0].Id;
            }
        } else if (error) {
            this.error = error;
            console.error('Error fetching tournaments', error);
        }
    }

    // Wire knockout matches filtered by selected tournament
    @wire(getKnockoutMatchesByTournament, { tournamentId: '$selectedTournamentId' })
    wiredMatches({ data, error }) {
        if (data) {
            // 1) Convert raw data, format date, set up winner styling placeholders
            let raw = data.map(m => ({
                Id: m.Id,
                Round__c: m.Round__c,
                HomeTeam: m.Home_Team__r?.Name || '',
                AwayTeam: m.Away_Team__r?.Name || '',
                HomeScore: m.Score_Home_Team__c,
                AwayScore: m.Score_Away_Team__c,
                Penalty: m.Penalty_Shootout__c,
                HomePenalty: m.Home_Penalty_Score__c,
                AwayPenalty: m.Away_Penalty_Score__c,
                Winner: m.Winner__c || '',
                MatchDatetime: this.formatDate(m.Match_Datetime__c),
                x: 0, 
                y: 0,
                boxClass: 'match-box',
                inlineStyle: '',
                homeTeamClass: '', // will be bold if home wins
                awayTeamClass: ''  // will be bold if away wins
            }));

            // 2) Group matches by round, sort by date
            let r16 = raw.filter(r => r.Round__c === 'Round of 16');
            let qf  = raw.filter(r => r.Round__c === 'Quarter Finals');
            let sf  = raw.filter(r => r.Round__c === 'Semi Finals');
            let finals = raw.filter(r => r.Round__c === 'Finals');

            [r16, qf, sf, finals].forEach(arr => {
                arr.sort((a, b) => a.MatchDatetime.localeCompare(b.MatchDatetime));
            });

            // 3) Reorder Semi Finals based on Final result
            let finalMatch = finals.length ? finals[0] : null;
            let orderedSF = sf;
            if (finalMatch && sf.length >= 2) {
                let topSF = sf.find(s => s.Winner === finalMatch.HomeTeam);
                let bottomSF = sf.find(s => s.Winner === finalMatch.AwayTeam);
                if (topSF && bottomSF && topSF !== bottomSF) {
                    orderedSF = [topSF, bottomSF];
                }
            }

            // 4) Reorder Quarter Finals based on newly ordered SF
            let orderedQF = [];
            if (orderedSF.length >= 2) {
                let topSF = orderedSF[0];
                let bottomSF = orderedSF[1];
                let qfForTop = qf.filter(q => q.Winner === topSF.HomeTeam || q.Winner === topSF.AwayTeam);
                let qfForBottom = qf.filter(q => q.Winner === bottomSF.HomeTeam || q.Winner === bottomSF.AwayTeam);
                orderedQF = [...qfForTop, ...qfForBottom];
                if (orderedQF.length < qf.length) {
                    orderedQF = qf;
                }
            } else {
                orderedQF = qf;
            }

            // 5) Reorder Round of 16 based on newly ordered QF
            let orderedR16 = [];
            orderedQF.forEach(q => {
                let rHome = r16.find(r => r.Winner === q.HomeTeam);
                let rAway = r16.find(r => r.Winner === q.AwayTeam);
                if (rHome) orderedR16.push(rHome);
                if (rAway && rAway !== rHome) orderedR16.push(rAway);
            });
            if (orderedR16.length < r16.length) {
                orderedR16 = r16;
            }

            // 6) Place Round of 16 matches uniformly from top to bottom
            orderedR16.forEach((m, i) => {
                m.x = this.xR16;
                m.y = this.r16StartY + i * this.r16Spacing;
            });

            // 7) Place Quarter Finals by centering each QF between its two Round of 16 parent matches
            orderedQF.forEach(q => {
                let pHome = orderedR16.find(r => r.Winner === q.HomeTeam);
                let pAway = orderedR16.find(r => r.Winner === q.AwayTeam);
                q.x = this.xQF;
                if (pHome && pAway) {
                    q.y = (pHome.y + pAway.y) / 2;
                } else {
                    q.y = this.r16StartY;
                }
            });

            // 8) Place Semi Finals by centering each SF between its two QF parent matches
            orderedSF.forEach(s => {
                let pHome = orderedQF.find(q => q.Winner === s.HomeTeam);
                let pAway = orderedQF.find(q => q.Winner === s.AwayTeam);
                s.x = this.xSF;
                if (pHome && pAway) {
                    s.y = (pHome.y + pAway.y) / 2;
                } else {
                    s.y = this.r16StartY;
                }
            });

            // 9) Place Final by centering between the two Semi Final matches
            if (finalMatch && orderedSF.length >= 2) {
                finalMatch.x = this.xFinal;
                finalMatch.y = (orderedSF[0].y + orderedSF[1].y) / 2;
            }

            // 10) Combine all matches
            let allMatches = [...orderedR16, ...orderedQF, ...orderedSF];
            if (finalMatch) allMatches.push(finalMatch);

            // 11) Build bracket paths (Z-shaped lines)
            let paths = [];
            const createBracketPathZ = (parent, child) => {
                if (!parent || !child) return null;
                let px = parent.x + this.matchBoxWidth;
                let py = parent.y + this.matchBoxHeight / 2;
                let cx = child.x;
                let cy = child.y + this.matchBoxHeight / 2;
                let bridgingX = (px + cx) / 2;
                return `M ${px},${py} L ${bridgingX},${py} L ${bridgingX},${cy} L ${cx},${cy}`;
            };
            const linkMatches = (parents, children) => {
                children.forEach(child => {
                    let pHome = parents.find(p => p.Winner === child.HomeTeam);
                    let pAway = parents.find(p => p.Winner === child.AwayTeam);
                    if (pHome) {
                        let d1 = createBracketPathZ(pHome, child);
                        if (d1) paths.push({ d: d1, lineKey: `${pHome.Id}-${child.Id}-home` });
                    }
                    if (pAway) {
                        let d2 = createBracketPathZ(pAway, child);
                        if (d2) paths.push({ d: d2, lineKey: `${pAway.Id}-${child.Id}-away` });
                    }
                });
            };
            linkMatches(orderedR16, orderedQF);
            linkMatches(orderedQF, orderedSF);
            if (finalMatch) {
                linkMatches(orderedSF, [finalMatch]);
            }

            // 12) Bold the winning team’s name in each match
            allMatches.forEach(m => {
                if (m.Winner === m.HomeTeam) {
                    m.homeTeamClass = 'winner-team';
                    m.awayTeamClass = '';
                } else if (m.Winner === m.AwayTeam) {
                    m.homeTeamClass = '';
                    m.awayTeamClass = 'winner-team';
                } else {
                    m.homeTeamClass = '';
                    m.awayTeamClass = '';
                }
            });

            // 13) Compute container dimensions
            let maxX = 0, maxY = 0;
            allMatches.forEach(m => {
                let rightEdge = m.x + this.matchBoxWidth;
                if (rightEdge > maxX) maxX = rightEdge;
                let bottomEdge = m.y + this.matchBoxHeight;
                if (bottomEdge > maxY) maxY = bottomEdge;
            });
            maxX += 100;
            maxY += 100;
            this.containerWidth = Math.max(1200, maxX);
            this.containerHeight = Math.max(800, maxY);

            // 14) Set inline style for each match box
            allMatches.forEach(m => {
                m.inlineStyle = `left:${m.x}px; top:${m.y}px;`;
            });

            // 15) Set round headings
            let headings = [];
            headings.push({ roundName: 'Round of 16',   style: `left:${this.xR16}px; top:20px;` });
            headings.push({ roundName: 'Quarter Finals', style: `left:${this.xQF}px; top:20px;` });
            headings.push({ roundName: 'Semi Finals',    style: `left:${this.xSF}px; top:20px;` });
            headings.push({ roundName: 'Finals',         style: `left:${this.xFinal}px; top:20px;` });
            this.roundHeadings = headings;
            this.bracketData = allMatches;
            this.bracketPaths = paths;
            this.error = undefined;
        } else if(error) {
            this.error = error;
            this.bracketData = [];
            this.bracketPaths = [];
            this.roundHeadings = [];
        }
    }

    // Helper: Format date as "yyyy-mm-dd"
    formatDate(dateStr) {
        if (!dateStr) return '';
        const d = new Date(dateStr);
        if (isNaN(d.getTime())) return dateStr;
        const year = d.getFullYear();
        const month = ('0' + (d.getMonth() + 1)).slice(-2);
        const day = ('0' + d.getDate()).slice(-2);
        return `${year}-${month}-${day}`;
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

    // Handle tournament dropdown change
    handleTournamentChange(event) {
        this.selectedTournamentId = event.detail.value;
    }
}
