public with sharing class RunMockBatchController {
    public RunMockBatchController(ApexPages.StandardController controller){

    }
    @AuraEnabled(cacheable=false)
    public static String runBatch(Id recordId) {
        // Optionally, you can use recordId if you need to reference the current tournament
        try {
            Database.executeBatch(new MockTournamentDataBatch(), 1);
            return 'Batch started successfully!';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    public void runMockTournament() {
        try {
            Database.executeBatch(new MockTournamentDataBatch(), 1);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}
