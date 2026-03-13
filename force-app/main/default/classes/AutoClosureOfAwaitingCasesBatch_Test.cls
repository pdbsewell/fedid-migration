/**
* @description  : Test class of AutoClosureOfAwaitingCasesBatcs Class which runs daily and check 
if there is any enquiry in awaiting feedback(Monash Connect BAU)
* @author       : Seeva
* @group        : Test Class
* @date         : 22-02-2023
* @revision     : 2022-11-10 - Seeva Singh - MCT-4 - Initial version
* @revision     : 2023-02-06 - Inderpal Singh - MCT-87 - Revised version
* Ver   Date         Author         Modification
* 
**/
@isTest
public class AutoClosureOfAwaitingCasesBatch_Test {
    static final string USER_NAME_1 = 'amazing.test@test.com.what11';
    @TestSetup
    static void setup() {
        User testUser = PersonaExtractorTestHelper.generateStandardUser(USER_NAME_1);
        List <String> roleNameList =  Label.Monash_Connect_Roles_Subordinates.split(','); // TO STORE MONASH CONNECT ROLE NAMES
        List<userRole> RoleIDs = [select id from userRole where name in:roleNameList limit 1];
        if(!RoleIDs.isEmpty())
            testUser.UserRoleId = RoleIDs[0].Id;
        update testUser;
    }
    @isTest static void testAutoClosureOfAwaitingCasesBatch() {
        TriggerCommon.disableTrigger('Case');
        
        final Integer numCasesPerContact = 5;
        final Integer numUsers = 2;
        List<User> listOfUsers = [SELECT Id,userName,UserRoleId,UserRole.name FROM User WHERE userName =:USER_NAME_1];

        Contact cont1 = (Contact)TestDataFactory.createSObject(new Contact(FirstName='FN1', LastName='LN1', Email='fn1.ln1@example.com'), false);
        Contact cont2 = (Contact)TestDataFactory.createSObject(new Contact(FirstName='FN2', LastName='LN2', Email='fn2.ln2@example.com'), false);
        Contact cont3 = (Contact)TestDataFactory.createSObject(new Contact(FirstName='FN3', LastName='LN3', Email='fn3.ln2@example.com'), false);

        Contact[] contacts = new Contact[]{cont1, cont2, cont3};
        insert contacts;
        
        Id MCRt = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
        
        // create cases that are older than cutoff
        datetime AwaitingFeedbackTime = System.now().addDays(-2);
        Case[] cases = new Case[0];
        for(Contact c :contacts) {
            for(Integer i = 0; i < numCasesPerContact; i++) {
                cases.add(new Case(
                    RecordTypeId = MCRt, ContactId = c.Id, Monash_Connect_Awaiting_Feedback_Time__c = AwaitingFeedbackTime,status='Awaiting Customer Feedback'
                ));
            }
        }
        
        // create a case that is more recent than cutoff
        Case recentCase = cases[0].clone();
        recentCase.ContactId = cont1.Id;
        recentCase.Monash_Connect_Awaiting_Feedback_Time__c = AwaitingFeedbackTime.addDays(-3);
        cases.add(recentCase);
        insert cases;
        for(Case c:cases)
        {
            c.ownerID=listOfUsers[0].id;
        }
        update cases;

        // GIVEN: The Cases are in Status Awaiting feedback
        Test.startTest();
        System.schedule('AutoClosureOfAwaitingCasesBatch', '0 0 7 * * ?', new AutoClosureOfAwaitingCasesBatch());
        Database.executeBatch(new AutoClosureOfAwaitingCasesBatch());
        Test.stopTest();
		// WHEN: Batch is trigerred
        List<Case> resultCase = new List<Case>([select id,ownerId,status, recordtypeId from case where status!='Closed']);
        // THEN: Check the case Status
        Assert.areEqual('Awaiting Customer Feedback', resultCase[0].status, 'Case in Awaiting Status');
    }
}