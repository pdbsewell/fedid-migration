/**
 * @author	Inderpal Dhanoa (inderpal.dhanoa@monash.edu)
 * @group	Monash Connect
 * @revision        inderpal.dhanoa@monash.edu - MCT-456 Logic to move MC Enqs to Solved
 */
@isTest (isParallel=true)
public class OutboundCallResultUtility_Test {
    /**
     * @description test method to setup data
     */
    @testSetup
    static void setup() {
        Contact contact2 = (Contact)TestDataFactory.createSObject(new Contact(LastName = 'LastName2', Person_Id_Unique__c = '2'), true);

        // Create Enquiry
        Case relEnq = (Case)TestDataFactory.createSObject(new Case(ContactId = contact2.Id, Subject = 'Test OutboundCallResultUtility_Test', Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
                                                Category_Level_2__c = 'Welfare meetings', Enquiry_Type__c = 'Current Course', Category_Level_1__c = 'Under 18s'), true);

        // Outbound_Call_Result__c
        TestDataFactory.createSObject(new Outbound_Call_Result__c(Contact__c = contact2.Id, Case__c = relEnq.Id, 
                                RecordTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId()), true);
        
        //create a test Contact
		List<Contact> conList = TestHelper.createProspectiveStudentContact(1);
		Contact con = conList[0];
		con.FirstName = 'setupPS';
		con.LastName = 'setupPS';
		con.Email = 'setupPS@test.org';
		insert con;
        
        //create setup Lead
		Lead setupLead = TestHelper.createLeads(1)[0];
        setupLead.Contact__c = con.Id;
		setupLead.Active_Lead_Contact_Id__c = con.Id;
		setupLead.RecordTypeId = Schema.SObjectType.Lead
		                         .getRecordTypeInfosByName()
		                         .get(Label.Lead_Rectype_ProspectiveStudent)
		                         .getRecordTypeId();

        insert setupLead;
    }

    /**
     * @description : Test the "closeLinkedMCEnquiries" method if the Contact gets linked as a Campaign Member
     */
    @isTest
    static void testCloseMCEnquiry() {
        
        Case cse = [SELECT Id FROM Case WHERE Subject = 'Test OutboundCallResultUtility_Test' ORDER By CreatedDate DESC LIMIT 1];
        Set<Id> enqIdSet = new Set<Id>();
        enqIdSet.add(cse.Id);
        // GIVEN: A Case linked exists

        Test.startTest();
        // WHEN: An OCR record is created
        OutboundCallResultUtility.closeMCEnquiry(enqIdSet);    
        Test.stopTest();
        // THEN: The campaign Memb is created
        cse = [SELECT Id,Status FROM Case WHERE Subject = 'Test OutboundCallResultUtility_Test' ORDER By CreatedDate DESC LIMIT 1];
        Assert.areEqual(cse.Status, 'Solved', 'Linked Case not closed');
    }
    
     @isTest
    static void testSetOutboundCallStatus(){
        //GIVEN: a lead exists
        lead l = [SELECT id,Contact__c FROM Lead WHERE name != null Limit 1];
        Test.startTest();
        Outbound_Call_Result__c ocr = (Outbound_Call_Result__c)TestDataFactory.createSObject(new Outbound_Call_Result__c(Lead__c = l.Id, call_Status__c = 'Open',
            RecordTypeId = OutboundCallResultUtility.DOMESTIC_PRE_APP, Contact__c = l.Contact__c),true);
        Test.stopTest();

        l = [SELECT id,Outbound_Call_Status__c FROM Lead];
        Assert.areEqual(l.Outbound_Call_Status__c, 'In Progress', 'OutboundCall status not updated');
    }
}