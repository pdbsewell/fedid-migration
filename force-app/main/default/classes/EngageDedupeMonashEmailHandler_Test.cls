@isTest(isParallel=true)
public class EngageDedupeMonashEmailHandler_Test {
    
    @testSetup
    public static void testInterimEmailSetup() {

        
        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;

        Contact testContact = new Contact(LastName = 'Test',
                                          FirstName = 'Contact');
        
        Contact testContact2 = new Contact(LastName = 'Test2',
                                          FirstName = 'Contact2');
       
        Contact testContact3 = new Contact(LastName = 'Test3',
                                          FirstName = 'Contact3');
        
        insert new List<Contact>{testContact, testContact2, testContact3};
            
        Email__c email = new Email__c(Name = 'Email@Email.com', Classification__c = 'Private', Contact__c = testContact3.Id);
        Email__c email2 = new Email__c(Name = 'Email2@Email.com', Classification__c = 'Private', Contact__c = testContact3.Id,start_date__c = date.today().addDays(-2),end_date__c= date.today().addDays(-1));
        
        insert new List<Email__c>{email,email2};

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestEmail', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Email_1__c = 'Email@Email.com',
                                                                                ucinn_ascendv2__Contact__c = testContact.Id);
        //For manual review. Invalid typ1
        ucinn_ascendv2__Interim__c testInterim2 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestEmail1', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim2', 
                                                                                 ucinn_ascendv2__Manual_Review_Reason__c ='This interim should have been placed in manual review for invalid email type.',
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Email_1__c = 'Email@Email.com',
                                                                                ucinn_ascendv2__Contact__c = testContact2.Id);

        ucinn_ascendv2__Interim__c testInterim3 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestEmail2', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim2', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'In Progress',
                                                                                ucinn_ascendv2__Email_1__c = 'Email2@Email.com',
                                                                                ucinn_ascendv2__Contact__c = testContact3.Id);

        insert new List<ucinn_ascendv2__Interim__c> {testInterim, testInterim2, testInterim3};
            
        //Should cause manual review on invalid phone type
        testInterim2.ucinn_ascendv2__Email_1_Type__c = 'ERROR';
        
        update testInterim2;
    }
    
    @isTest
    public static void testInterimEmail() {
        Test.startTest();

        EngageDedupeProcessInProgressRE base = new EngageDedupeProcessInProgressRE();
        base.batchConstructor('Raisers Edge Interface');
        EngageDedupeProcessInProgressBatch batch = new EngageDedupeProcessInProgressBatch('Raisers Edge Interface', base);
        Database.executeBatch(batch, 5);
        
        Test.stopTest();
        
        ucinn_ascendv2__Interim__c testInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c = 'TestEmail'][0];
        ucinn_ascendv2__Interim__c testInterim1 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c = 'TestEmail1'][0];
        ucinn_ascendv2__Interim__c testInterim2 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c = 'TestEmail2'][0];
        
        Contact con3 = [select id ,(select end_date__c from Emails__r where Name = 'Email2@Email.com') from contact where LastName = 'Test3' ] ;
        
        System.assert(testInterim1.ucinn_ascendv2__Manual_Review_Reason__c != null, 'This interim should have been placed in manual review for invalid email type.');  
    }
}