/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group	SRA (Student Recruitment and Admissions) - BabyShark
 * @revision        inderpal.dhanoa@monash.edu - MCT-414 Add Logic to craete MC Campaign Members.
 * @revision        inderpal.dhanoa@monash.edu - MCT-456 Add Logic to close MC cases.
 * @revision        inderpal.dhanoa@monash.edu - MCT-504 Add Exclusion Logic for Student Support Cases.
 */
 @isTest //(isParallel=true) : In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
private class OutboundCallResultServices_Test {
    /**
     * @description test method to setup data
     */
    @testSetup
    static void setup() {
         Date futureDate;
         Date todayDate = Date.today();
         futureDate = todayDate.addDays(5);
        // Contact
        List<Contact> contacts = new List<Contact>();
        
         Contact contact1 = new Contact();
         contact1.LastName = 'LastName';
         contact1.Person_Id_Unique__c = '1';
         Contact contact2 = (Contact)TestDataFactory.createSObject(new Contact(LastName = 'LastName2', Person_Id_Unique__c = '2'), false);
         contacts.add(contact1);
         contacts.add(contact2);
        insert contacts;
            
        // Campaign
        List<Campaign> campaigns = new List<Campaign>();
        
         Campaign campaign1 = new Campaign();
         campaign1.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
         campaign1.CampaignMemberRecordTypeId = Schema.SObjectType.CampaignMember.getRecordTypeInfosByDeveloperName().get('Outbound_Call').getRecordTypeId();
         campaign1.Name = 'MonCon Support Outbound Call Campaign';
         campaign1.StartDate = Date.today();
         campaign1.EndDate = futureDate;
         campaigns.add(campaign1);
        
        insert campaigns;
        
        // Outbound_Call_Result__c
        List<Outbound_Call_Result__c> outboundCallResults = new List<Outbound_Call_Result__c>();
        
         Outbound_Call_Result__c outboundCallResult1 = new Outbound_Call_Result__c();
         outboundCallResult1.Campaign__c = campaign1.Id;
         outboundCallResult1.Contact__c = contact1.Id;
         outboundCallResult1.RecordTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
         outboundCallResults.add(outboundCallResult1);
        
        insert outboundCallResults;
       
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
        
        // User
        User u = new User(
            LastName = 'LN',
            FirstName='FN',
            Alias = 'Alias',
            Email = 'be12145f057545f8ba195fd2889b2121@monash.edu',
            Username = 'be12145f057545f8ba195fd2889b2121@monash.edu',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US'
        );
        
        insert u;
    }

    /**
     * @description : Test the "closeLinkedMCEnquiries" method if the Contact gets linked as a Campaign Member
     */
    @isTest
    static void testCloseLinkedMCEnquiries() {
        // GIVEN: A Case linked exists
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'LastName' AND Person_Id_Unique__c = '1' ORDER By CreatedDate DESC LIMIT 1];
        // Create Enquiry
        Case relEnq = (Case)TestDataFactory.createSObject(new Case(ContactId = con.Id, Subject = 'Test OutboundCallResultServices_Test', Status = 'Open', 
                                                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
                                                 Category_Level_2__c = 'Welfare meetings', Enquiry_Type__c = 'Current Course', Category_Level_1__c = 'Under 18s'), true);

        Outbound_Call_Result__c ocr = (Outbound_Call_Result__c)TestDataFactory.createSObject(new Outbound_Call_Result__c(Contact__c = con.Id, Call_Result__c = 'No Answer', 
                                        Case__c = relEnq.Id,
                                        RecordTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId()), true);
        
        ocr = [SELECT Id,Call_Status__c FROM Outbound_Call_Result__c WHERE Case__c = :relEnq.Id];
        
        //Run as Admin, as code runs in without sharing mode
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND Username = 'be12145f057545f8ba195fd2889b2121@monash.edu'
                            AND isActive = TRUE
                            Limit 1];

        System.runAs(adminUser) {
            Test.startTest();
            // WHEN: An OCR record is updated
            ocr.Call_Status__c = 'Closed';
            update ocr;    
            Test.stopTest();
            // THEN: The Case is solved
            ocr = [SELECT Id, Case__r.Status FROM Outbound_Call_Result__c WHERE Id = :ocr.Id];
            Assert.areEqual(ocr.Case__r.Status, 'Solved', 'Linked Case not closed');
        }
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
    
    /**
     * @description : Test the "createCampaignMember" method if the Contact gets linked as a Campaign Member
     */
    @isTest
    static void testCreateMCCampaignMember() {
        // GIVEN: A Campaign and COntact exists
        Date futureDate;
        Date todayDate = Date.today();
        futureDate = todayDate.addDays(5);
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'LastName2' AND Person_Id_Unique__c = '2' ORDER By CreatedDate DESC LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'MonCon Support Outbound Call Campaign' ORDER By CreatedDate DESC LIMIT 1];

        //Run as Admin, as code runs in without sharing mode
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND Username = 'be12145f057545f8ba195fd2889b2121@monash.edu'
                            AND isActive = TRUE
                            Limit 1];

        System.runAs(adminUser) {
            Test.startTest();
            // WHEN: An OCR record is created
            TestDataFactory.createSObject(new Outbound_Call_Result__c(Contact__c = con.Id, Campaign__c = camp.Id, 
                                        RecordTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId()), true);
                    
            Test.stopTest();
            // THEN: The campaign Memb is created
            List<CampaignMember> linkedRecds = [SELECT Id FROM CampaignMember WHERE CampaignId = :camp.Id AND ContactId = :con.Id];
            Assert.areEqual(linkedRecds.size(), 1, 'Campaign Member not mapped');
        }
    }
    
    static testMethod void testUnassignedQueueOwnerAssignment() {
        Test.startTest();
        
        Outbound_Call_Result__c ocr = [SELECT Owner_Name__c FROM Outbound_Call_Result__c LIMIT 1];
        
        Test.stopTest();
        
        System.assertEquals('Outbound Call: Unassigned', ocr.Owner_Name__c);
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         26.Aug.2024
     * @description  Tests updation of Student Support OCR records
    *******************************************************************************/
	@isTest 
    static void testCallResultEnquiryNotCreated() {
        
        // GIVEN: A User already exists
        Test.startTest();
        User u = [SELECT Id FROM User WHERE UserName = 'be12145f057545f8ba195fd2889b2121@monash.edu' ORDER BY CreatedDate DESC LIMIT 1];
        
        System.runAs(u) {
            Outbound_Call_Result__c ocr = [SELECT Id, Call_Result__c, Comments__c, Engagement_Type__c, Retention_Status__c, Risk_Category_V2__c, Number_Of_Attempts__c, OwnerId FROM Outbound_Call_Result__c LIMIT 1];
            
            ocr.OwnerId = u.Id;
            ocr.Comments__c = 'Comments';
            ocr.Engagement_Type__c = 'Student Support';
            ocr.Risk_Category__c = 'COVID-19';
            ocr.Number_Of_Attempts__c = '1';
            // WHEN: An OCR is updated
            update ocr;
        }
        
        Test.stopTest();
        // THEN: The field is updated
        Assert.areEqual(0, [SELECT Id FROM Case].size(), 'Case creation not working for Call Result = Student Support');
    }
    
    static testMethod void testCallResultEnquiryCreated() {
        
        // GIVEN: A User already exists
        Test.startTest();
        User u = [SELECT Id FROM User WHERE UserName = 'be12145f057545f8ba195fd2889b2121@monash.edu' ORDER BY CreatedDate DESC LIMIT 1];
        
        System.runAs(u) {
            Outbound_Call_Result__c ocr = [SELECT Id, Call_Result__c, Comments__c, Engagement_Type__c, Retention_Status__c, Risk_Category_V2__c, Number_Of_Attempts__c, OwnerId FROM Outbound_Call_Result__c LIMIT 1];
            
            ocr.OwnerId = u.Id;
            ocr.Call_Result__c = 'Enquiry Created';
            ocr.Comments__c = 'Comments';
            ocr.Engagement_Type__c = 'Conversion';
            ocr.Retention_Status__c = 'Declined Offer';
            ocr.Risk_Category__c = 'COVID-19';
            ocr.Number_Of_Attempts__c = '1';
            // WHEN: An OCR is updated
            update ocr;
        }
        
        Test.stopTest();
        // THEN: The field is updated
        System.assertEquals(1, [SELECT Id FROM Case].size(), 'Case creation not working for Call Result = Enquiry Created');
    }
    
    static testMethod void testCallResultNoAnswer() {
        
        // GIVEN: A User already exists
        User u = [SELECT Id FROM User WHERE UserName = 'be12145f057545f8ba195fd2889b2121@monash.edu' ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        System.runAs(u) {
            Outbound_Call_Result__c ocr = [SELECT Id, Call_Result__c, Number_Of_Attempts__c, OwnerId FROM Outbound_Call_Result__c LIMIT 1];
            
            ocr.Call_Result__c = 'No Answer';
            ocr.Number_Of_Attempts__c = '2';
            ocr.OwnerId = u.Id;
            // WHEN: An OCR is updated
            update ocr;
        }
        
        Test.stopTest();
        // THEN: The field is updated
        System.assertEquals(1, [SELECT Id FROM Case].size(), 'Case creation not working for Call Result = No Answer');
    }
    
    static testMethod void testCallResultWrongNumber() {
                
        User u = [SELECT Id FROM User WHERE UserName = 'be12145f057545f8ba195fd2889b2121@monash.edu' ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        // GIVEN: A User already exists
        System.runAs(u) {
            Outbound_Call_Result__c ocr = [SELECT Id, Call_Result__c, Number_Of_Attempts__c, OwnerId FROM Outbound_Call_Result__c LIMIT 1];
            
            ocr.Call_Result__c = 'Wrong Number';
            ocr.Number_Of_Attempts__c = '1';
            ocr.OwnerId = u.Id;
            // WHEN: An OCR is updated
            update ocr;
        }
        
        Test.stopTest();
        // THEN: The field is updated
        System.assertEquals(1, [SELECT Id FROM Case].size(), 'Case creation not working for Call Result = Wrong Number');
    }
    
    static testMethod void testTrackOutboundCallsDateTimeClosed() {
        User u = [SELECT Id FROM User WHERE UserName = 'be12145f057545f8ba195fd2889b2121@monash.edu' ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
        // GIVEN: A User already exists
        Outbound_Call_Result__c ocr = [SELECT Id, Call_Result__c, Call_Status__c, Date_Time_Closed__c FROM Outbound_Call_Result__c LIMIT 1];
        
        System.assert(ocr.Date_Time_Closed__c == null, 'Test data setup is not correct.');
        
        ocr.Call_Result__c = 'No - Not Applicable';
        ocr.Call_Status__c = 'Closed';
        ocr.OwnerId = u.Id;
        // WHEN: An OCR is updated
        update ocr;
        
        ocr = [SELECT Id, Call_Status__c, Date_Time_Closed__c FROM Outbound_Call_Result__c LIMIT 1];
        
        Test.stopTest();
        // THEN: The field is updated
        System.assert(ocr.Date_Time_Closed__c != null, 'Date/Time Closed tracking is not working.');
    }
}