/**
 * @author          Ajitabh
 * @description     Test class for Batch class for PDFSendEmailReviewTranBatch
 * @revision
 * Date         Author              Modification
 * 18/07/2022   Chaldrin Cruz       Replaced rt with rtv2
 */
@isTest(isParallel=false) // disabling due to APEX_DATA_ACCESS_RESTRICTION: In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public class PDFSendEmailReviewTranBatch_Test {

    @testSetup
    static void setup(){
        String guid = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        id p = [select id from profile where name = 'ascendportal Profile'].Id;
        User u = (User)TestDataFactory.createSObject(new User(
            alias = 'test123',
            email='test123@noemail.com',
            emailencodingkey='UTF-8',firstname='ascendportal', lastname='Site Guest User', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p, country='United States',IsActive =true,
            timezonesidkey='America/Los_Angeles', username='tester@noemail12.com'), true);

        // Create Appeal Codes
        System.runAs(u){
            PORTAL_UCIN_Domain_Name__c setting  = (PORTAL_UCIN_Domain_Name__c)TestDataFactory.createSObject(new PORTAL_UCIN_Domain_Name__c(
                Domain_Name__c ='https://unicrm--engageuat.my.salesforce.com/'), true);

            // given: appeal used for gift
            Campaign cmp = (Campaign)TestDataFactory.createSObject(new Campaign(
                Name = 'A-'+guid,
                IsActive = true,
                Status = 'Planned',
                ucinn_ascendv2__Motivation_Code__c = 'A-'+guid), true);

            // given: designation used for gift
            ucinn_ascendv2__Designation__c des1 = (ucinn_ascendv2__Designation__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation__c(
                Name = 'D-'+guid+'1',
                ucinn_ascendv2__External_System_ID__c = 'D-'+guid+'1',
                ucinn_ascendv2__G_L_Effective_Date__c = Date.today().addMonths(-1),
                ucinn_ascendv2__G_L_Expiration_Date__c = Date.today().addMonths(1),
                ucinn_ascendv2__Program_Code__c = 'GL_Acc', // 7 char
                ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack', // 6 char
                ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD', // 6 char
                Tax_Status_Code__c = 'S1'), true);

            // given: donor
            TriggerCommon.disableTrigger('Contact');
            Contact con1 = (Contact)TestDataFactory.createSObject(new Contact(
                Firstname = 'Contact',
                Lastname = guid,
                ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street',
                ucinn_ascendv2__Preferred_Address_City__c = 'Test City',
                ucinn_ascendv2__Preferred_Address_State__c = 'CA',
                ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999'), true);
            TriggerCommon.enableTrigger('Contact');

            ucinn_ascendv2__Interim__c intm = (ucinn_ascendv2__Interim__c)TestDataFactory.createSObject(new ucinn_ascendv2__Interim__c(
                ucinn_ascendv2__Email_1__c = 'abc@abc.com'), false);

            // given: review transaction record to create gift
            // Create Review Transactions
            ucinn_ascendv2__Review_Transaction_v2__c rt1 = (ucinn_ascendv2__Review_Transaction_v2__c)TestDataFactory.createSObject(new ucinn_ascendv2__Review_Transaction_v2__c(
                Name = 'PRAX'+guid,
                ucinn_ascendv2__Status__c = 'New',
                ucinn_ascendv2__External_System_ID__c = 'PRAX'+guid,
                ucinn_ascendv2__Designation_1__c = des1.Id,
                ucinn_ascendv2__Contact__c = con1.Id,
                ucinn_ascendv2__Campaign__c = cmp.Id,
                ucinn_ascendv2__Payment_Amount_1_1__c = 1200,
                ucinn_ascendv2__Transaction_Date__c = Date.today(),
                ucinn_ascendv2__Payment_Date_1_1__c = Date.today(),
                ucinn_ascendv2__Transaction_Type__c = 'Gift',
                ucinn_ascendv2__Opportunity_Type__c = 'Outright',
                ucinn_ascendv2__Tender_Type_1__c = 'Cash'), true);
        }
    }
    static testmethod void pdfSendEmailReviewTranBatchTest() {
        Test.startTest();
        PDFSendEmailReviewTranBatch uca = new PDFSendEmailReviewTranBatch();
        Id batchId = Database.executeBatch(uca);
        // when: attach receipt to review transaction
        Test.stopTest();
        List< ucinn_ascendv2__Review_Transaction_v2__c> reTranList = [SELECT Id,ucinn_ascendv2__Transaction_Type__c,(SELECT Id FROM ContentDocumentLinks LIMIT 1)
                                                                      FROM ucinn_ascendv2__Review_Transaction_v2__c];
        // then: verify receipt was attached
        system.assertEquals(1, reTranList[0].ContentDocumentLinks.size());

    }

}