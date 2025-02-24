@isTest
private class TeamNotificationHelperTest {
    @isTest
    static void testSendTeamCreationEmail() {
        Test.startTest();

        // Create test team record
        Tournament_Team__c testTeam = new Tournament_Team__c(Name = 'Test FC');
        insert testTeam;

        Test.stopTest();

        // Query the inserted team to verify its existence
        Tournament_Team__c insertedTeam = [SELECT Id, Name FROM Tournament_Team__c WHERE Name = 'Test FC' LIMIT 1];
        System.assertNotEquals(null, insertedTeam, 'The team should be created successfully.');
    }
}
