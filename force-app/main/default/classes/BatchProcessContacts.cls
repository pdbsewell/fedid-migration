global class BatchProcessContacts implements Database.Batchable<sObject> {

    global final String query;

    global BatchProcessContacts(String q) {
        query=q;
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext context,List<sObject> scope) {

        List<Contact> contacts = (List<Contact>)scope;

        for(Contact contact : contacts) {
            if(contact.Email != null && String.isNotBlank(contact.Email) && !contact.Email.endsWithIgnoreCase('.test')) {
                contact.Email = contact.Email + '.test';
            }
        }

        update contacts;
           
    }

    global void finish(Database.BatchableContext context) {
        //Send an email to the User after your batch completes
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'vineeth.batreddy@monash.edu'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Apex Batch Job is done');
        mail.setPlainTextBody('The batch Apex job processed : BatchProcessContacts');
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}