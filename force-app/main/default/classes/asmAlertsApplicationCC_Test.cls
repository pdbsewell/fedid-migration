@isTest(isParallel=true)
private class asmAlertsApplicationCC_Test {
    
    TestMethod
    static void test_NoApplicationId()
    {
        Map<String, Object> mapAlerts = asmAlertsApplicationCC.GetApplicationAlerts(null);
        System.Debug('asmAlertsApplicationCC_Test:test_NoApplicationId:' + mapAlerts);
        System.assertNotEquals('', mapAlerts.get(asmAlertsApplicationCC.MESSAGE));
    }
    
    TestMethod
    static void test_ApplicationNotFound()
    {
        Contact c = new Contact();
        c.FirstName = 'Tester';
        c.LastName = 'Surname';
        insert c;
        
        // search for a bad id
        Map<String, Object> mapAlerts = asmAlertsApplicationCC.GetApplicationAlerts(c.Id);
        System.Debug('asmAlertsApplicationCC_Test:test_ApplicationNotFound:' + mapAlerts);
        System.assertNotEquals('', mapAlerts.get(asmAlertsApplicationCC.MESSAGE));
    }
    
    TestMethod
    static void test_NoAlerts()
    {
        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-20);
        insert c;
        
        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Fee_Payment__c = true;
        insert app;
        // create course
        Course__c course = StudFirst_Testhelper.createCourse();
        insert course;        
        // create course offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;                
        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        insert acp;        
        // test function
        Map<String, Object> mapAlerts = asmAlertsApplicationCC.GetApplicationAlerts(app.Id);
        System.Debug('asmAlertsApplicationCC_Test:test_NoAlerts:' + mapAlerts);
        
        // under 18
        Boolean under18AtApplication = (Boolean) mapAlerts.get(asmAlertsApplicationCC.IS_UNDER18_AT_APPLICATION);
        System.assertNotEquals(true, under18AtApplication);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsApplicationCC.HAS_ENCUMBRANCES);
        System.assertNotEquals(true, hasEncumbrance);                
        // access equity
        Boolean accessEquity = (Boolean) mapAlerts.get(asmAlertsApplicationCC.HAS_ACCESS_EQUITY);
        System.assertNotEquals(true, accessEquity);        
        
        // fee paid
        Boolean feePaid = (Boolean) mapAlerts.get(asmAlertsApplicationCC.APPLICATION_FEE_PAID);
        System.assertEquals(true, feePaid);        
        
        // GTE location
        Boolean gteLocation = (Boolean)  mapAlerts.get(asmAlertsApplicationCC.GTE_ALERT_SUBMISSION_LOCATION);
        System.assertNotEquals(true, gteLocation);                    
        
        // GTE qualification
        Boolean gteQualification = (Boolean)  mapAlerts.get(asmAlertsApplicationCC.GTE_ALERT_QUALIFICATION);
        System.assertNotEquals(true, gteQualification);                    
        
        // Credit Intention
        Boolean creditIntention = (Boolean) mapAlerts.get(asmAlertsApplicationCC.CREDIT_INTENTION);
        System.assertNotEquals(true, creditIntention);        
    }

    TestMethod
    static void test_AllAlerts()
    {
        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        
        Date dtToday = Date.today();
        // for under 18
        c.Birthdate = dtToday.addYears(-5);
        insert c;
        
        // create Country Attribute Object
        Country_Attribute__c countryAttr = StudFirst_TestHelper.createGTERiskCountryAttribute();
        countryAttr.GTE_Risk_Rating__c = '3';                
        insert countryAttr;
        
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
        // for access/equity
        app.Access_and_Equity_Question__c = 'Yes';
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
        cq.Qualification_Country__c = countryAttr.id;
        insert cq;
        
        
        // test function
        Map<String, Object> mapAlerts = asmAlertsApplicationCC.GetApplicationAlerts(app.Id);
        System.Debug('asmAlertsApplicationCC_Test:test_AllAlerts:' + mapAlerts);
        
        // under 18
        Boolean under18AtApplication = (Boolean) mapAlerts.get(asmAlertsApplicationCC.IS_UNDER18_AT_APPLICATION);
        System.assertEquals(true, under18AtApplication);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsApplicationCC.HAS_ENCUMBRANCES);
        System.assertEquals(true, hasEncumbrance);                
        // access equity
        Boolean accessEquity = (Boolean) mapAlerts.get(asmAlertsApplicationCC.HAS_ACCESS_EQUITY);
        System.assertEquals(true, accessEquity);        
        
        // fee paid
        Boolean feePaid = (Boolean) mapAlerts.get(asmAlertsApplicationCC.APPLICATION_FEE_PAID);
        System.assertNotEquals(true, feePaid);        
        
        // GTE location
        // Boolean gteLocation = (Boolean)  mapAlerts.get(asmAlertsApplicationCC.GTE_ALERT_SUBMISSION_LOCATION);
        // System.assertEquals(false, gteLocation);                    
        
        // GTE qualification
        Boolean gteQualification = (Boolean)  mapAlerts.get(asmAlertsApplicationCC.GTE_ALERT_QUALIFICATION);
        System.assertEquals(true, gteQualification);                    
        
        // Credit Intention
        Boolean creditIntention = (Boolean) mapAlerts.get(asmAlertsApplicationCC.CREDIT_INTENTION);
        System.assertEquals(true, creditIntention);        
    }
    
}