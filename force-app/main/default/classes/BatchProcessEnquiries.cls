global class BatchProcessEnquiries implements Database.Batchable<sObject> {

    global final String query;

    global BatchProcessEnquiries(String q) {
        query=q;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC,List<sObject> scope) {

        List<Case> lstCase = new list<Case>();

        List<Case> cases = (List<Case>)scope;
        List<String> legacyCourseIds = new List<String>();
        List<String> legacyContactIds = new List<String>();

        for(Case enq : cases) {
            if(enq.Legacy_Course_Id__c != null)
                legacyCourseIds.add(enq.Legacy_Course_Id__c);
            if(enq.Legacy_Contact_ID__c != null)
                legacyContactIds.add(enq.Legacy_Contact_Id__c);
        }

        System.debug('!@#$% legacyCourseIds : ' + legacyCourseIds);
        System.debug('!@#$% legacyContactIds : ' + legacyContactIds);

        List<Course__c> courses = [SELECT Id, Legacy_Course_Id__c, Fee__c, APST_Standards__c, Hours_of_Attendance__c, Points__c, Level__c FROM Course__c WHERE Legacy_Course_Id__c IN :legacyCourseIds];
        Map<String, String> courseIds = new Map<String, String>();
        for(Course__c course : courses) {
            courseIds.put(course.Legacy_Course_Id__c, course.Id);
        }

        List<Contact> contacts = [SELECT Id, Legacy_Contact_Id__c, Email FROM Contact WHERE Legacy_Contact_Id__c IN :legacyContactIds];
        Map<String, String> contactIds = new Map<String, String>();
        for(Contact contact : contacts) {
            contactIds.put(contact.Legacy_Contact_Id__c, contact.Id);
        }

        System.debug('!@#$% courseIds : ' + courseIds);
        System.debug('!@#$% contactIds : ' + contactIds);

        for(Sobject s : scope) {
            Case c = (Case)s;
            c.Legacy_Processed_Flag__c = true;
            c.Course__c = courseIds.get(c.Legacy_Course_ID__c);
            c.ContactId = contactIds.get(c.Legacy_Contact_ID__c);
            c.Preferred_Time__c = DataLoadHelper.getPartOfTheDay(c.Legacy_Preferred_Time_ID__c);
            System.debug('!@#$% Updated Enquiry : ' + c);
            lstCase.add(c);
        }
        update lstCase;


    }

    global void finish(Database.BatchableContext BC) {
        LogUtilityException.debug('Batch Process Enquiries Finished');
        //Send an email to the User after your batch completes
        /* Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'vineeth.batreddy@monash.edu'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Apex Batch Job is done');
        mail.setPlainTextBody('The batch Apex job processed : BatchProcessEnquiries');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); */
    }

}