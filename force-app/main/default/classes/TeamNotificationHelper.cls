public class TeamNotificationHelper {
    public static void sendTeamCreationEmail(List<Team__c> teams) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Team__c team : teams) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{'ofathallah@salesforce.com'});  // Change this to the real recipient
            email.setSubject('New Team Created: ' + team.Name);
            email.setPlainTextBody('A new team named "' + team.Name + '" has been created in the system.');

            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
