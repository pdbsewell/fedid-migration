@isTest(isParallel=true)
private class asmAlertsContactCC_Test {
    
    TestMethod
    static void test_NoContactId()
    {
		Map<String, Object> mapAlerts = asmAlertsContactCC.GetContactAlerts(null);
        //System.Debug('asmAlertsContactCC_Test:test_NoContactId:' + mapAlerts);        
        System.assertNotEquals(null, mapAlerts); 
    }
    
    TestMethod
    static void test_InvalidContactId()
    {
        Course__c course = StudFirst_Testhelper.createCourse();
        insert course;
        
        Map<String, Object> mapAlerts = asmAlertsContactCC.GetContactAlerts(course.id);
        //System.Debug('asmAlertsContactCC_Test:test_InvalidContactId:' + mapAlerts);        
        System.assertNotEquals(null, mapAlerts);
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
        Map<String, Object> mapAlerts = asmAlertsContactCC.GetContactAlerts(c.id);
        System.Debug('asmAlertsContactCC_Test:test_NoAlerts:' + mapAlerts);
        
        // under 18
        Boolean isUnder18 = (Boolean) mapAlerts.get(asmAlertsContactCC.IS_UNDER18);
        System.assertNotEquals(true, isUnder18);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_ENCUMBRANCES);
        System.assertNotEquals(true, hasEncumbrance);                
        // disabilities
        Boolean hasDisability = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_DISABILITIES);
        System.assertNotEquals(true, hasDisability);        
                   
        // Citizenship
        Boolean hasCitizenshipAlert = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_CITIZENSHIP_ALERT);
        System.assertNotEquals(true, hasCitizenshipAlert);        
    }
 
    TestMethod
    static void test_Under18()
    {
        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-17);
        insert c;
        
        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
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
        Map<String, Object> mapAlerts = asmAlertsContactCC.GetContactAlerts(c.id);
        //System.Debug('asmAlertsContactCC_Test:test_under18:' + mapAlerts);
        
        // under 18
        Boolean isUnder18 = (Boolean) mapAlerts.get(asmAlertsContactCC.IS_UNDER18);
        System.assertEquals(true, isUnder18);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_ENCUMBRANCES);
        System.assertNotEquals(true, hasEncumbrance);                
        // disabilities
        Boolean hasDisability = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_DISABILITIES);
        System.assertNotEquals(true, hasDisability);        
                 
        // Citizenship
        Boolean hasCitizenshipAlert = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_CITIZENSHIP_ALERT);
        System.assertNotEquals(true, hasCitizenshipAlert);        
    }
    
    TestMethod
    static void test_HasEncumbranceAdmin()
    {
        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-20);        
        insert c;
        
        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);        
        insert app;
        // create course
        Course__c course = StudFirst_Testhelper.createCourse();
        insert course;        
        // create course offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;                
        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        //acp.Has_Encumbrance__c = true;
        insert acp;
        
        // create an admin encumbrance
        Encumbrance__c enc = StudFirst_TestHelper.createEncumbranceAdmin(c.id);
        insert enc;
                
        // test function
        Map<String, Object> mapAlerts = asmAlertsContactCC.GetContactAlerts(c.id);
        //System.Debug('asmAlertsContactCC_Test:test_HasEncumbrances:' + mapAlerts);
        
        // under 18
        Boolean isUnder18 = (Boolean) mapAlerts.get(asmAlertsContactCC.IS_UNDER18);
        System.assertNotEquals(true, isUnder18);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_ENCUMBRANCES);
        System.assertEquals(true, hasEncumbrance);                
        // disabilities
        Boolean hasDisability = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_DISABILITIES);
        System.assertNotEquals(true, hasDisability);        
                 
        // Citizenship
        Boolean hasCitizenshipAlert = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_CITIZENSHIP_ALERT);
        System.assertNotEquals(true, hasCitizenshipAlert);        
    }
    
    
    TestMethod
    static void test_HasEncumbranceAcademic()
    {
        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-20);        
        insert c;
        
        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);        
        insert app;
        // create course
        Course__c course = StudFirst_Testhelper.createCourse();
        insert course;        
        // create course offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;                
        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        //acp.Has_Encumbrance__c = true;
        insert acp;
        
        // create an admin encumbrance
        Encumbrance__c enc = StudFirst_TestHelper.createEncumbranceAcademic(c.id, course);
        insert enc;
                
        // test function
        Map<String, Object> mapAlerts = asmAlertsContactCC.GetContactAlerts(c.id);
        //System.Debug('asmAlertsContactCC_Test:test_HasEncumbranceAcademic:' + mapAlerts);
        
        // under 18
        Boolean isUnder18 = (Boolean) mapAlerts.get(asmAlertsContactCC.IS_UNDER18);
        System.assertNotEquals(true, isUnder18);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_ENCUMBRANCES);
        System.assertEquals(true, hasEncumbrance);                
        // disabilities
        Boolean hasDisability = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_DISABILITIES);
        System.assertNotEquals(true, hasDisability);        
                 
        // Citizenship
        Boolean hasCitizenshipAlert = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_CITIZENSHIP_ALERT);
        System.assertNotEquals(true, hasCitizenshipAlert);        
    }
    
    TestMethod
 	static void test_HasDisabilities()
    {
        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-20);
        c.HasDisabilities__c = 'Yes';
        insert c;
        
        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
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
        Map<String, Object> mapAlerts = asmAlertsContactCC.GetContactAlerts(c.id);
        //System.Debug('asmAlertsContactCC_Test:test_HasDisabilities:' + mapAlerts);
        
        // under 18
        Boolean isUnder18 = (Boolean) mapAlerts.get(asmAlertsContactCC.IS_UNDER18);
        System.assertNotEquals(true, isUnder18);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_ENCUMBRANCES);
        System.assertNotEquals(true, hasEncumbrance);                
        // disabilities
        Boolean hasDisability = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_DISABILITIES);
        System.assertEquals(true, hasDisability);                           
        // Citizenship
        Boolean hasCitizenshipAlert = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_CITIZENSHIP_ALERT);
        System.assertNotEquals(true, hasCitizenshipAlert);        
    }   
    
    TestMethod
    static void test_HasCitizenshipAlert()
    {
        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.INTERNATIONAL;
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-20);        
        insert c;
        
        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
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
        Map<String, Object> mapAlerts = asmAlertsContactCC.GetContactAlerts(c.id);
        //System.Debug('asmAlertsContactCC_Test:test_HasDisabilities:' + mapAlerts);
        
        // under 18
        Boolean isUnder18 = (Boolean) mapAlerts.get(asmAlertsContactCC.IS_UNDER18);
        System.assertNotEquals(true, isUnder18);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_ENCUMBRANCES);
        System.assertNotEquals(true, hasEncumbrance);                
        // disabilities
        Boolean hasDisability = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_DISABILITIES);
        System.assertNotEquals(true, hasDisability);        
                  
        // Citizenship
        Boolean hasCitizenshipAlert = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_CITIZENSHIP_ALERT);
        System.assertEquals(true, hasCitizenshipAlert);        
    }  
    
    
    TestMethod
    static void test_HasGTEAlert()
    {
        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-20);
        insert c;
        
        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
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
        
        // create Country Attribute Object
        Country_Attribute__c countryAttr = StudFirst_TestHelper.createGTERiskCountryAttribute();        
        insert countryAttr;
        // create GTE risk qualification
        Qualification__c qualification = StudFirst_TestHelper.createTertiaryQualification();
        qualification.Overseas__c = true;        
        insert qualification;
        Contact_Qualification__c cq = StudFirst_TestHelper.createContactQualification(c, qualification, 'Tertiary Education');
        cq.Qualification_Country__c = countryAttr.id;
        insert cq;
        
        
        // test function
        Map<String, Object> mapAlerts = asmAlertsContactCC.GetContactAlerts(c.id);
        //System.Debug('asmAlertsContactCC_Test:test_HasGTEAlert:' + mapAlerts);
        
        // under 18
        Boolean isUnder18 = (Boolean) mapAlerts.get(asmAlertsContactCC.IS_UNDER18);
        System.assertNotEquals(true, isUnder18);                
        // encumbrances
        Boolean hasEncumbrance = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_ENCUMBRANCES);
        System.assertNotEquals(true, hasEncumbrance);                
        // disabilities
        Boolean hasDisability = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_DISABILITIES);
        System.assertNotEquals(true, hasDisability);        
                  
        // Citizenship
        Boolean hasCitizenshipAlert = (Boolean) mapAlerts.get(asmAlertsContactCC.HAS_CITIZENSHIP_ALERT);
        System.assertNotEquals(true, hasCitizenshipAlert);        
    }
    
}