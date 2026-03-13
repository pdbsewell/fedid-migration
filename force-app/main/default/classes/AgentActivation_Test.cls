@isTest(isParallel=true)
public with sharing class AgentActivation_Test {

    @TestSetup
    static void makeData() {
        List < Account > accList = new List < Account > ();

        //create Agency account
        Account acc1 = new Account(
            Callista_Org_Unit_Code__c = 'TRISTAR',
            name = 'TRISTAR'
        );
        accList.add(acc1);

        //create Agency account
        Account acc2 = new Account(
            Callista_Org_Unit_Code__c = 'STUDIO1',
            name = 'STUDIO1'
        );
        accList.add(acc2);

        insert accList;
        Id agencyRTId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency Contact').getRecordTypeId();
        //Create Agent contact
        List < Contact > conList = new List < Contact > ();
        Contact con = new Contact(RecordTypeid = agencyRTId,
            AccountId = acc1.Id,
            email = 'jdoe@tristar.com',
            FirstName = 'john',
            LastName = 'doe',
            Agency_Contact_Roles__c = 'Branch Manager;Counsellor;Delegated Admin;');
        conList.add(con);
        Contact con2 = new Contact(RecordTypeid = agencyRTId,
            AccountId = acc1.Id,
            email = 'jackdoe@tristar.com',
            FirstName = 'jack',
            LastName = 'doe',
            Agency_Contact_Roles__c = 'Counsellor;');
        conList.add(con2);

        insert conList;
    }

    /**
     *  @author         SMendu
     *  @description    Testing with an existing Contact - to verify it updates the Agency Contact Roles field appropriately
     */
    @isTest
    static void contactUpdateTest() {
        // create a file
        ContentVersion cv1 = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.csv',
            VersionData = Blob.valueOf('DELTA,Jake,Cupp,jcupp@delta.com\nTRISTAR,john,doe,jdoe+abc@tristar.com'),
            IsMajorVersion = true
        );
        insert cv1;
        // GIVEN: A file is uploaded with new contacts against the Agencies
        Test.startTest();
         // WHEN: AgentActivation asynchrnous job runs with the uploaded information on Agencies/contacts
        AgentActivation.run(cv1.Id);
        Test.stopTest();
        // THEN: Newly created contacts should have the appropriate Agency contact role assigned
        Assert.isTrue([select id, Agency_Contact_Roles__c from Contact where email = 'jdoe+abc@tristar.com'].Agency_Contact_Roles__c.contains('Branch Manager'));
    }

    /**
     *  @author         SMendu
     *  @description    Testing for inserting a Contact - to verify it creates the contact with the appropriate Agency Contact Roles field
     */
    @isTest
    static void contactinsertTest() {
        // create a file
        ContentVersion cv1 = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.csv',
            VersionData = Blob.valueOf('DELTA,Jake,Cupp,jcupp@delta.com\nSTUDIO1,Jen,Lopez,jloz@studio1.com'),
            IsMajorVersion = true
        );
        insert cv1;
        // GIVEN: A file is uploaded with existing contacts against the Agencies
        Test.startTest();
         // WHEN: AgentActivation asynchrnous job runs with the uploaded information on Agencies/contacts
        AgentActivation.run(cv1.Id);
        Test.stopTest();
        // THEN: Updated contacts should have the appropriate Agency contact role assigned
        Assert.isTrue([select id, Agency_Contact_Roles__c from Contact where email = 'jloz@studio1.com'].Agency_Contact_Roles__c.contains('Branch Manager'));
    }
}