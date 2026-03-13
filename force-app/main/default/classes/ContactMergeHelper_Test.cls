/**
 * Created by rcad0001 on 1/03/2021.
 */

@IsTest
private class ContactMergeHelper_Test {
    @testSetup
    static void testData() {
        // Primary contact
        Contact primaryContact = new Contact(
                FirstName = 'Chuck',
                LastName = 'Norris',
                Email = 'chuck.norrise_testonly@student.monash.edu',
                Personal_Email__c = 'chuck.norrise_testonly@testdomain.com',
                Person_ID_unique__c = String.valueOf(math.random()).substring(0,6).replaceAll('.',''),
                MobilePhone = '0423470137',
                Monash_Email_Address__c = 'chuck.norrise_testonly@student.monash.edu',
                Contact_Profile__c = 'Alumni',
                BirthDate = Date.valueOf('1991-12-12')
        );

        // Duplicate contact
        Contact duplicateContact = new Contact(
                FirstName = 'Chuck',
                LastName = 'Norris',
                Email = 'chuck.norrise_testonly@student.monash.edu',
                Personal_Email__c = 'chuck.norrise_testonly@testdomain.com',
                Person_ID_unique__c = String.valueOf(math.random()).substring(0,6).replaceAll('.',''),
                MobilePhone = '0423470138',
                Monash_Email_Address__c = 'chuck.norrise_testonly@student.monash.edu',
                Contact_Profile__c = 'Alumni',
                BirthDate = Date.valueOf('1991-12-12')
        );

        // Duplicate contact
        Contact duplicateContact2 = new Contact(
                FirstName = 'Chuck',
                LastName = 'Norris',
                Email = 'chuck.norrise_testonly@student.monash.edu',
                Personal_Email__c = 'chuck.norrise_testonly@testdomain.com',
                Person_ID_unique__c = String.valueOf(math.random()).substring(0,6).replaceAll('.',''),
                MobilePhone = '0423470139',
                Monash_Email_Address__c = 'chuck.norrise_testonly@student.monash.edu',
                Contact_Profile__c = 'Alumni',
                BirthDate = Date.valueOf('1991-12-12')
        );

        insert new List<Contact>{primaryContact, duplicateContact, duplicateContact2};

        // Primary user
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Customer Community General User' Limit 1];

        User primaryUser = new User(
                UserName = primaryContact.Email+ math.random(),
                FirstName = primaryContact.FirstName,
                LastName = primaryContact.LastName,
                Alias = 'prim'+String.valueOf(math.random()).substring(0,4),
                email = primaryContact.Email,
                ContactId = primaryContact.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = String.valueOf(math.random()).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
        );

        // Duplicate user
        User duplicateUser = new User(
                UserName = duplicateContact.Email+ math.random(),
                FirstName = duplicateContact.FirstName,
                LastName = duplicateContact.LastName,
                Alias = 'dupl'+String.valueOf(math.random()).substring(0,4),
                email = duplicateContact.Email,
                ContactId = duplicateContact.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = String.valueOf(math.random()).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                FederationIdentifier = 'dupltest',
                MonashObjectId__c = 'zzzzzzzz-1111-zzzz-11zz11-zzzzzzzzzzzz'
        );

        List<User> users = new List<User>{
                primaryUser, duplicateUser
        };
        insert users;

        // Permission set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Alumni_Portal_Permission_Set' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = duplicateUser.Id;
        psa.PermissionSetId = ps.Id;
        UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(new List<PermissionSetAssignment>{psa}, false); // do not fail all records if a particular item fails
        Id jobId = System.enqueueJob(insertQueuable);
    }
    @IsTest
    static void testDataRetrieve() {

        // get contacts
        List<Contact> contactList = ContactMergeHelper.getContacts('Chuck', 'Norris', 'chuck.norrise_testonly@student.monash.edu', null, new Set<Id>());
        // assert that there are three contact records matching with the parameters above
        System.assertEquals(contactList.size(),3);

        // find which records duplicates in email field, return the record Ids
        Set<Id> contactIds = ContactMergeHelper.findPotentialDuplicateContactsByEmail('chuck.norrise_testonly@student.monash.edu');
        // assert that there are no email records
        System.assertEquals(contactIds.size(), 0);

        // find which records duplicates in name fields, return the record Ids
        Set<Id> contactIdsByName = ContactMergeHelper.findPotentialDuplicateContactsByName('testNoFName', 'testNoLName');
        // assert that there are no name records
        System.assertEquals(contactIdsByName.size(), 0);

        Set<Id> dupConIds = new Set<Id>();
        for(Contact c: contactList){
            dupConIds.add(c.Id);
        }

        // execute the Datacloud.FindDuplicatesResult to scan through the contact records and leverage the dup rules
        Map<Id, DuplicateFieldInfo> duplicateRuleResultMap = ContactMergeHelper.findDuplicateContacts(dupConIds);
        // assert that the duplicate rule scan is complete and has result
        System.assert(!duplicateRuleResultMap.isEmpty());

        // format the a datetime field to a String
        DateTime conLastModifiedDate = contactList[0].LastModifiedDate;
        String conLMDString = ContactMergeHelper.dateFormatter(conLastModifiedDate);
        // assert the string formatted
        System.assertEquals(conLMDString, String.valueOf(Date.today().Day()) +'/'+ String.valueOf(Date.today().Month()) +'/'+ String.valueOf(Date.today().Year()));

        // query all object fields from all the records from above contacts
        List<sObject> sObjectList = ContactMergeHelper.queryAllObjectFields(dupConIds);
        // assert that the query method will return a record set
        System.assertEquals(sObjectList.size(), 3);

        // primary account compare
        List<Account> primaryAccount = (List<Account>) ContactMergeHelper.queryAllObjectFields(new Set<Id>{contactList[0].Account.Id});
        List<Account> duplicateAccount =  (List<Account>) ContactMergeHelper.queryAllObjectFields(new Set<Id>{contactList[1].Account.Id});

        Account masterAccount = ContactMergeHelper.mapCompareAccount(primaryAccount[0], duplicateAccount[0]);
        System.assertEquals(masterAccount.Id,primaryAccount[0].Id);

        // primary contact compare
        List<Contact> primaryContact = (List<Contact>) ContactMergeHelper.queryAllObjectFields(new Set<Id>{contactList[0].Id});
        List<Contact> duplicateContact =  (List<Contact>) ContactMergeHelper.queryAllObjectFields(new Set<Id>{contactList[1].Id});

        Contact masterContact = ContactMergeHelper.mapCompareContact(primaryContact[0], duplicateContact[0]);
        System.assertEquals(masterContact.Id,primaryContact[0].Id);

    }
}