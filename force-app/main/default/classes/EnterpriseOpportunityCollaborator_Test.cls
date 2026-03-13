/**
* @description Test class for flow Enterprise Opportunity Collaborator
*
* @author Ajitabh
* @date 22/10/2020
*
* @group Common
* @revision
* Date			Name		Change made
* 3-Jun-2022 	idha0002 	changed test class data to independent of running user
* 29-Mar-2022 	idha0002 	changed test class to execute, independent of running user
* 14-Mar-2022 	idha0002 	changed data in the externalCollaboratorFlow method to test the validation rules
* 12-Nov-2020 	Ajitabh 	changed account record type in externalCollaboratorFlow to accommodate validation rules
**/
@isTest//(isParallel=true)  In parallel Apex tests, DML operations aren't permitted on this type of object: User: []s
public class EnterpriseOpportunityCollaborator_Test {

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         29.Apr.2022
    * @description  Test setup
    *******************************************************************************/
    @TestSetup
    static void setupData(){
        
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // Insert a new User 
        
        System.runAs(thisUser) {
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Enterprise Base Profile' LIMIT 1];
            User user = new User(
                UserName = random + 'testusername@testemail.com',
                FirstName = 'TestFirstName',
                LastName = 'TestLast',
                Alias = 'ssoxtst8', 
                email = random + 'testusername@testemail.com',
                ProfileId = profile.Id,
                IsActive = true,
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'Australia/Sydney',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );

            Database.insert(user); // Avoid mixed DML error

            PermissionSet enterpUserPermSet = [SELECT Id, name FROM permissionSet where name = 'Enterprise_Base'];
            
            PermissionSetAssignment permSet1 = new PermissionSetAssignment(AssigneeId=user.Id,PermissionSetId=enterpUserPermSet.Id);
            insert permSet1;
        }
    }

    /**
     *  Opportunity Collaborator Internal with Opportunity available
     */
     static testMethod void internalCollaboratorFlow()
    {
        User enterpriseUser = [SELECT Id, IsActive, Profile.Name FROM User WHERE Profile.name = 'Enterprise Base Profile' AND isActive = true LIMIT 1];

        System.runAs(enterpriseUser) {
            string testname= 'name '+String.valueOf(System.now());
            id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();
            Account testaccount = new Account(name=testname,recordtypeid=recordtypeids);
            insert testaccount;

            Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = testaccount.Id), true);

            Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = testaccount.Id, PrimaryContact__c = contact.Id) ,false);
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
            insert opp;

            Test.startTest();
            Opportunity_Collaborator__c opc = new Opportunity_Collaborator__c();
            opc.Relationship_Type__c  ='Internal Organisation';
            opc.Organisation__c = testaccount.id;
            opc.Lead__c = true;
            opc.Opportunity__c = opp.id;
            insert opc;
            Test.stopTest();

            List<Opportunity_Collaborator__c> opcList =[select id,Relationship_Type__c,Organisation__c,Opportunity__r.Opportunity_Owning_FacultyArea__c
                                                    from Opportunity_Collaborator__c limit 1];
            system.assertEquals(opcList[0].Opportunity__r.Opportunity_Owning_FacultyArea__c,opcList[0].Organisation__c);
        }
    }

    /**
     * Opportunity Collaborator External with Opportunity available
     */
     static testMethod void externalCollaboratorFlow()
    {
        User enterpriseUser = [SELECT Id FROM User WHERE Profile.name = 'Enterprise Base Profile' AND isActive = true LIMIT 1];

        System.runAs(enterpriseUser) {
            List<Account> relAcc = new List<Account>();
            string testname = 'name_0'+String.valueOf(System.now());
            id recordtypeids = Schema.SObjectType.Account.getRecordTypeInfosByName().get('External Organisation').getRecordTypeId();
            Account testaccount = new Account(name=testname,recordtypeid=recordtypeids);
            relAcc.add(testaccount);
            
            testname = 'name_1'+String.valueOf(System.now());
            Account testaccount1 = new Account(name=testname,recordtypeid=recordtypeids);
            
            relAcc.add(testaccount1);
            insert relAcc;

            Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = testaccount.Id), true);

            Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = testaccount.Id, PrimaryContact__c = contact.Id) ,false);
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
            insert opp;

            Opportunity_Collaborator__c opc = new Opportunity_Collaborator__c();
            opc.Relationship_Type__c  ='External Organisation';
            opc.Organisation__c = testaccount.id;
            opc.Lead__c = true;
            opc.Opportunity__c = opp.id;
            insert opc;

            Test.startTest();
            Opportunity_Collaborator__c opc1 = new Opportunity_Collaborator__c(); 
            opc1.Relationship_Type__c  ='External Organisation';
            opc1.Organisation__c = testaccount1.id;
            opc1.Lead__c = true;
            opc1.Opportunity__c = opp.id;
            insert opc1;
            Test.stopTest();

            List<Opportunity_Collaborator__c> opcList =[select id,Lead__c,Relationship_Type__c,Organisation__c,Opportunity__r.Opportunity_Owning_FacultyArea__c
                                                        from Opportunity_Collaborator__c Where Organisation__r.name like '%name_0%'];
            system.assertEquals(opcList[0].Lead__c,false);

            opcList =[select id,Lead__c,Relationship_Type__c,Organisation__c,Opportunity__r.Opportunity_Owning_FacultyArea__c
                                                        from Opportunity_Collaborator__c Where Organisation__r.name like '%name_1%'];
            system.assertEquals(opcList[0].Lead__c,true);
        }
    }
}