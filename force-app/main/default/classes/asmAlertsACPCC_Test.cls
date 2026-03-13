@isTest(isParallel=false)
private class asmAlertsACPCC_Test {

    
    TestMethod
    static void test_NoACPId()
    {
        Map<String, Object> mapAlerts = asmAlertsACPCC.GetACPAlerts(null);
        System.Debug('asmAlertsACPCC_Test:test_NoACPId:' + mapAlerts);
        System.assertNotEquals('', mapAlerts.get(asmAlertsACPCC.MESSAGE));
    }
    
    TestMethod
    static void test_ACPNotFound()
    {
        Contact c = new Contact();
        c.FirstName = 'Tester';
        c.LastName = 'Surname';
        insert c;
        
        // search for a bad id
        Map<String, Object> mapAlerts = asmAlertsACPCC.GetACPAlerts(c.Id);
        System.Debug('asmAlertsACPCC:test_ACPNotFound:' + mapAlerts);
        System.assertNotEquals('', mapAlerts.get(asmAlertsACPCC.MESSAGE));
    }
    
    TestMethod
    static void test_NoAlerts()
    {
        User userApplicant = StudFirst_TestHelper.createContactAndCommunityUser();

        //Create a new Contact for testing
        Contact c = [SELECT Id FROM Contact WHERE id =: userApplicant.ContactId];
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-20);
        update c;
        
        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Fee_Payment__c = true;
        insert app;


        // create course
        Course__c course = StudFirst_Testhelper.createCourse();
        insert course;
        // create course offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        // for course age alert
        courseOffering.Start_Date__c = dtToday;
        insert courseOffering;
        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        insert acp;

        // test function
        Map<String, Object> mapAlerts = asmAlertsACPCC.GetACPAlerts(acp.Id);
        System.Debug('asmAlertsACPCC_Test:test_NoAlerts:' + mapAlerts);
        
        // under 18
        Boolean under18AtApplication = (Boolean) mapAlerts.get(asmAlertsACPCC.IS_UNDER18_AT_APPLICATION);
        System.assertNotEquals(true, under18AtApplication);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsACPCC.HAS_ENCUMBRANCES);
        System.assertNotEquals(true, hasEncumbrance);                
        // access equity
        Boolean accessEquity = (Boolean) mapAlerts.get(asmAlertsACPCC.HAS_ACCESS_EQUITY);
        System.assertNotEquals(true, accessEquity);        
        
        // fee paid
        Boolean feePaid = (Boolean) mapAlerts.get(asmAlertsACPCC.APPLICATION_FEE_PAID);
        System.assertEquals(true, feePaid);        
        
        // GTE location
        Boolean gteLocation = (Boolean)  mapAlerts.get(asmAlertsACPCC.GTE_ALERT_SUBMISSION_LOCATION);
        System.assertNotEquals(true, gteLocation);                    
        
        // GTE qualification
        Boolean gteQualification = (Boolean)  mapAlerts.get(asmAlertsACPCC.GTE_ALERT_QUALIFICATION);
        System.assertNotEquals(true, gteQualification);                    
        
        // Credit Intention
        Boolean creditIntention = (Boolean) mapAlerts.get(asmAlertsACPCC.CREDIT_INTENTION);
        System.assertNotEquals(true, creditIntention);        
    }
    
    
    TestMethod
    static void test_AllAlerts()
    {
        System.debug('asmAlertsACPCC_Test::AllAlerts Begin');
        Date dtToday = Date.today();

        //create a community user
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        Contact c = new Contact();
        c.FirstName = 'First';
        c.LastName = 'Last';
        c.AccountId = accountRecord.Id;
        c.Residency_Status__c = 'INT-TEP';
        c.Birthdate = dtToday.addYears(-10);
        c.MailingCountry = 'AUSTRALIA';
        insert c;

        Integer rnd = Integer.valueOf(Math.random()*9999);
        User applicant = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                ContactId = c.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'DOM-AUS',
                App_Aboriginal_or_Torres_Strait_Islander__c = 'No',
                App_HasDisabilities__c = 'Yes',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert applicant;
        
        /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
         * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = applicant.Id);
            insert psa;
        }

        // create Country Attribute Object
        Country_Attribute__c countryAttr = StudFirst_TestHelper.createGTERiskCountryAttribute();
        countryAttr.Country__c = c.MailingCountry;
        countryAttr.Name = c.MailingCountry;
        insert countryAttr;

        Country_Attribute__c countryAttr2 = StudFirst_TestHelper.createGTERiskCountryAttribute();
        countryAttr2.Country__c = 'India';
        countryAttr2.Name = 'India';
        countryAttr2.GTE_Risk_Rating__c = '3';
        insert countryAttr2;


        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);

        // GTE submission location
        app.Submission_Location_Country__c = countryAttr.id;
        // for fee payment alert
        app.Fee_Payment__c = false;
        // for application age alert
        app.Submitted_Date__c = dtToday;
        // for credit intention
        app.Credit_Intention__c = true;
        // for access/equity - using User.Has_Disability__C instead
        //app.Access_and_Equity_Question__c = 'Yes';
        app.Manual_Assessment_Override__c = true;
        insert app;


        // create course
        Course__c course = StudFirst_Testhelper.createCourse();
        insert course;
        // create course offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        // for course age alert
        courseOffering.Start_Date__c = dtToday;
        insert courseOffering;
        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        insert acp;

        // create an admin encumbrance
        Encumbrance__c enc = StudFirst_TestHelper.createEncumbranceAdmin(c.id);
        insert enc;

        // create GTE risk qualification
        Qualification__c qualification = StudFirst_TestHelper.createTertiaryQualification();
        qualification.Overseas__c = true;
        insert qualification;
        Contact_Qualification__c cq = StudFirst_TestHelper.createContactQualification(c, qualification, 'Tertiary Education');
        cq.Qualification_Country__c = countryAttr2.id;
        insert cq;


        // test function
        Map<String, Object> mapAlerts = asmAlertsACPCC.GetACPAlerts(acp.Id);
        System.Debug('asmAlertsACPCC_Test:test_AllAlerts:' + mapAlerts);
        
        // under 18
        Boolean under18AtApplication = (Boolean) mapAlerts.get(asmAlertsACPCC.IS_UNDER18_AT_APPLICATION);
        System.assertEquals(true, under18AtApplication);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsACPCC.HAS_ENCUMBRANCES);
        System.assertEquals(true, hasEncumbrance);                
        // access equity
        //Boolean accessEquity = (Boolean) mapAlerts.get(asmAlertsACPCC.HAS_ACCESS_EQUITY);
        //System.assertEquals(true, accessEquity);        
        
        // fee paid
        Boolean feePaid = (Boolean) mapAlerts.get(asmAlertsACPCC.APPLICATION_FEE_PAID);
        System.assertNotEquals(true, feePaid);        
        
        // GTE location
        Boolean gteLocation = (Boolean)  mapAlerts.get(asmAlertsACPCC.GTE_ALERT_SUBMISSION_LOCATION);
        System.assertEquals(true, gteLocation);                    
        
        // GTE qualification
        Boolean gteQualification = (Boolean)  mapAlerts.get(asmAlertsACPCC.GTE_ALERT_QUALIFICATION);
        System.assertEquals(true, gteQualification);                    
        
        // Credit Intention
        Boolean creditIntention = (Boolean) mapAlerts.get(asmAlertsACPCC.CREDIT_INTENTION);
        System.assertEquals(true, creditIntention);

        // Manual Assessment Override
        Boolean mao = (Boolean) mapAlerts.get(asmAlertsACPCC.MANUAL_ASSESSMENT_OVERRIDE);
        System.assertEquals(true, mao);
    }
    
}