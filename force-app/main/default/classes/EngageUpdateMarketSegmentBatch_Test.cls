@IsTest(IsParallel=true)
private class EngageUpdateMarketSegmentBatch_Test {
    @TestSetup static void setupData() {
        List<Contact> contactList = new List<Contact>();
        
        Contact newAlumni = new Contact();
        newAlumni.LastName = 'New Alumni';
        newAlumni.Contact_Profile__c = 'Alumni';
        newAlumni.Birthdate = Date.today().addYears(-25);
        contactList.add(newAlumni);

        // create test contact where age is not defined
        Contact newAlumni2 = new Contact();
        newAlumni2.LastName = 'New Alumni';
        newAlumni2.Contact_Profile__c = 'Alumni';
        contactList.add(newAlumni2);

        Contact newAlumni3 = new Contact();
        newAlumni3.LastName = 'New Alumni';
        newAlumni3.Contact_Profile__c = 'Alumni';
        contactList.add(newAlumni3);

        Contact newAlumniWithoutDegree = new Contact();
        newAlumniWithoutDegree.LastName = 'New Alumni';
        newAlumniWithoutDegree.Contact_Profile__c = 'Alumni';
        newAlumniWithoutDegree.Birthdate = Date.today().addYears(-25);
        contactList.add(newAlumniWithoutDegree);
        
        insert contactList;
        
        Contact_Qualification__c cq = new Contact_Qualification__c();
        cq.Obtained_Status__c = 'MONASH-OBTAINED';
        cq.Institution_Name__c = 'Monash University';
        cq.Verification_Status__c = 'Verified';
        cq.Contact__c = newAlumni.Id;
        
        //Qualification achieved today. Therefore market segment should be updated.
        cq.Date_Achieved__c = System.today();
        insert cq;

        // create new qualification for the contact where age is not defined.
        Contact_Qualification__c cq2 = new Contact_Qualification__c();
        cq2.Obtained_Status__c = 'MONASH-OBTAINED';
        cq2.Institution_Name__c = 'Monash University';
        cq2.Verification_Status__c = 'Verified';
        cq2.Contact__c = newAlumni2.Id;
        cq2.Date_Achieved__c = System.today().addYears(-25);
        insert cq2;

        Contact_Qualification__c cq3 = new Contact_Qualification__c();
        cq3.Obtained_Status__c = 'MONASH-OBTAINED';
        cq3.Institution_Name__c = 'Monash University';
        cq3.Verification_Status__c = 'Verified';
        cq3.Contact__c = newAlumni3.Id;
        cq3.Honorary_Degree__c = true;
        cq3.Date_Achieved__c = System.today().addYears(-25);
        insert cq3;
    }
    
    static testMethod void updateMarketSegment() {
        Database.executeBatch(new EngageUpdateMarketSegmentBatch(), 10);
        
        List<Market_Segment_Criteria__mdt> criteriaList = [SELECT Age_High__c,Age_Low__c,Transition_Date_Range_High__c,Transition_Date_Range_Low__c,Market_Segment__c 
                                                            FROM Market_Segment_Criteria__mdt];
        
        Contact con = [SELECT Market_Segment__c, Age__c FROM Contact WHERE LastName = 'New Alumni'][0];
        
        //Test based on simple criteria of existing metadata with no lower transition range.
        for (Market_Segment_Criteria__mdt thisCriteria : criteriaList) {
            if (((thisCriteria.Age_Low__c == -1  && thisCriteria.Age_High__c == -1) || (con.Age__c != null && con.Age__c > thisCriteria.Age_Low__c && con.Age__c < thisCriteria.Age_High__c)) && 
                  thisCriteria.Transition_Date_Range_Low__c == null) {
                      
                System.assert(con.Market_Segment__c != null);
            }
        }
       
        System.debug(con.Market_Segment__c);
        
    }
}