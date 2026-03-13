/*
  @Author: Victor Cheng
  @Description: Test class for appHomeOffersCC
  @Revision  20/01/2020 - Shalini Mendu - SFTN-673 - Do not show VTAC applications / offers on my.app until an offer response is received from the applicant
*/
@IsTest
public class appHomeOffersCC_Test {

    @TestSetup
    private static void setupData()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();

        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        insert application;

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        insert offering;

        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        insert acp;

        // submit the application
        application.Status__c = 'Submitted';
        application.Residency_Status__c = 'DOM-AUS';
        update application;


   }
  @isTest
    private static void test_noACPs()
    {
        User applicant = [select Id from User where LastName ='TestingUser'];
        Application__c application = [select Id, Status__c from Application__c ];



        Test.startTest();
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = appHomeOffersCC.getInitLoadOffers();
            System.assertNotEquals(null, mapResults, 'Results should not be null');
        }
        Test.stopTest();
    }


    @isTest
    private static void test_doAcceptACP()
    {
        //Create Outcome LOV's
        List<List_of_Values__c> lovs = new List<List_of_Values__c>();
        // create Offer LOVs
        List_of_Values__c lovOffer = new List_of_Values__c(Value__c = 'OFFER'
        , Type__c='ADM_OUTCOME_STATUS'
        , System_Code__c='OFFER');
        lovs.add(lovOffer);
        List_of_Values__c lovCOND = new List_of_Values__c(Value__c = 'OFFER-COND'
        , Type__c='ADM_OUTCOME_STATUS'
        , System_Code__c='OFFER-COND');
        lovs.add(lovCOND);
        List_of_Values__c lovPROV = new List_of_Values__c(Value__c = 'OFFER-PROV'
        , Type__c='ADM_OUTCOME_STATUS'
        , System_Code__c='OFFER-PROV');
        lovs.add(lovPROV);

        //Create Response LOV's
        List_of_Values__c lovAccept = new List_of_Values__c(Value__c = appHomeOffersCC.VALUE_ACCEPTED
        , Type__c= appHomeOffersCC.TYPE_OFFER_RESPONSE
        , System_Code__c = appHomeOffersCC.VALUE_ACCEPTED);
        lovs.add(lovAccept);
        List_of_Values__c lovAcceptCOND = new List_of_Values__c(Value__c = appHomeOffersCC.VALUE_ACCEPT_CND
        , Type__c= appHomeOffersCC.TYPE_OFFER_RESPONSE
        , System_Code__c = appHomeOffersCC.VALUE_ACCEPT_CND);
        lovs.add(lovAcceptCOND);
        List_of_Values__c lovAcceptPROV = new List_of_Values__c(Value__c = appHomeOffersCC.VALUE_ACCEPT_PRV
        , Type__c= appHomeOffersCC.TYPE_OFFER_RESPONSE
        , System_Code__c = appHomeOffersCC.VALUE_ACCEPT_PRV);
        lovs.add(lovAcceptPROV);
        List_of_Values__c lovReject = new List_of_Values__c(Value__c = appHomeOffersCC.VALUE_REJECTED
        , Type__c= appHomeOffersCC.TYPE_OFFER_RESPONSE
        , System_Code__c = appHomeOffersCC.VALUE_ACCEPTED);
        lovs.add(lovReject);

        insert lovs;

        Application__c application = [select Id from Application__c LIMIT 1];
        Contact c = [select Id from Contact LIMIT 1 ];
        Course_Offering__c offering = [select Id from Course_Offering__c LIMIT 1];
        Course__c course = [select Id from Course__c LIMIT 1];
        User applicant = [select Id from User where LastName ='TestingUser'];

        // create ACPs
        List<Application_Course_Preference__c> listAcps = new List<Application_Course_Preference__c>();
        Application_Course_Preference__c acpFull = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        acpFull.Outcome_Status_LOV__c = lovOffer.Id;
        acpFull.Conditional_Offer_Status_LOV__c = lovOffer.Id;
        listAcps.add(acpFull);

        Application_Course_Preference__c acpCond = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        acpCond.Outcome_Status_LOV__c = lovCOND.Id;
        acpCond.Conditional_Offer_Status_LOV__c = lovCOND.Id;

        listAcps.add(acpCond);

        Application_Course_Preference__c acpProv = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        acpProv.Outcome_Status_LOV__c = lovPROV.Id;
        acpProv.Conditional_Offer_Status_LOV__c = lovPROV.Id;
        listAcps.add(acpProv);

        Application_Course_Preference__c acpReject = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        acpReject.Outcome_Status_LOV__c = lovOffer.Id;
        acpReject.Conditional_Offer_Status_LOV__c = lovOffer.Id;
        listAcps.add(acpReject);
        insert listAcps;


        // need to retrieve them again to get the proper LOV values

        acpFull = [SELECT Id, Outcome_Status_LOV__r.Value__c,Conditional_Offer_Status_LOV__r.Value__c, Conditional_Offer_Status_LOV__r.Applicant_Value__c,Documentation_Status_LOV__r.Value__c  FROM Application_Course_Preference__c where id=:acpFull.Id];
        acpCond = [SELECT Id, Outcome_Status_LOV__r.Value__c,Conditional_Offer_Status_LOV__r.Value__c, Conditional_Offer_Status_LOV__r.Applicant_Value__c,Documentation_Status_LOV__r.Value__c  FROM Application_Course_Preference__c where id=:acpCond.Id];
        acpProv = [SELECT Id, Outcome_Status_LOV__r.Value__c,Conditional_Offer_Status_LOV__r.Value__c, Conditional_Offer_Status_LOV__r.Applicant_Value__c,Documentation_Status_LOV__r.Value__c  FROM Application_Course_Preference__c where id=:acpProv.Id];
        acpReject = [SELECT Id, Outcome_Status_LOV__r.Value__c,Conditional_Offer_Status_LOV__r.Value__c, Conditional_Offer_Status_LOV__r.Applicant_Value__c,Documentation_Status_LOV__r.Value__c  FROM Application_Course_Preference__c where id=:acpReject.Id];



        Test.startTest();
        System.runAs(applicant)
        {
            List_of_Values__c lovResult;
            Map<String, Object> mapResult = appHomeOffersCC.doAcceptACP(acpFull);
            lovResult = (List_of_Values__c) mapResult.get(appHomeOffersCC.FIELD_LOV_RESPONSE);
            System.assertEquals(lovAccept.Id, lovResult.Id, 'Offer should be full acceptance '  + lovResult);

            mapResult = appHomeOffersCC.doAcceptACP(acpCond);
            lovResult = (List_of_Values__c) mapResult.get(appHomeOffersCC.FIELD_LOV_RESPONSE);
            System.assertEquals(lovAcceptCOND.Id, lovResult.Id, 'Offer should be conditional acceptance ' + lovResult);

            mapResult = appHomeOffersCC.doAcceptACP(acpProv);
            lovResult = (List_of_Values__c) mapResult.get(appHomeOffersCC.FIELD_LOV_RESPONSE);
            System.assertEquals(lovAcceptPROV.Id, lovResult.Id, 'Offer should be provisional acceptance ' + lovResult);


            mapResult = appHomeOffersCC.doRejectACP(acpReject);
            lovResult = (List_of_Values__c) mapResult.get(appHomeOffersCC.FIELD_LOV_RESPONSE);
            System.assertEquals(lovReject.Id, lovResult.Id, 'Offer should be rejected ' + lovResult);
        }
        Test.stopTest();
    }


    TestMethod
    private static void test_noLOVs()
    {
        Application__c application = [select Id from Application__c LIMIT 1];
        Contact c = [select Id from Contact  LIMIT 1];
        Course_Offering__c offering = [select Id from Course_Offering__c  LIMIT 1];
        Course__c course = [select Id from Course__c  LIMIT 1];
        User applicant = [select Id from User where LastName ='TestingUser'];


        Application_Course_Preference__c acp = [select Id,Outcome_Status_LOV__r.Value__c from Application_Course_Preference__c  LIMIT 1];

        Test.startTest();
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = appHomeOffersCC.doAcceptACP(acp);
            List_of_Values__c lovResult = (List_of_Values__c) mapResults.get(appHomeOffersCC.FIELD_LOV_RESPONSE);
            System.assertEquals(null, lovResult, 'ACCEPT:: no LOVs have been inserted');

            mapResults = appHomeOffersCC.doRejectACP(acp);
            lovResult = (List_of_Values__c) mapResults.get(appHomeOffersCC.FIELD_LOV_RESPONSE);
            System.assertEquals(null, lovResult, 'REJECT:: no LOVs have been inserted');
        }
        Test.stopTest();
    }

    @isTest
    public static void test_getInitLoadOffersForVTAC()
    {
        Test.startTest();
        User applicant = [select Id from User where lastname='TestingUser'];

        Application_Course_Preference__c acp = [SELECT Application__c,Admission_Category__c from Application_Course_Preference__c ];
        Application__c app = [SELECT Source_System__c FROM Application__c  WHERE ID =:acp.Application__c];
        List_Of_Values__c lov = new List_Of_Values__c (value__c= 'AP-LAPSED', system_code__c = 'REJECTED', type__c='ADM_OFFER_RESP_STATUS', name = 'Outcome Status', is_Active__c = true);
        insert lov;
        acp.Offer_Response_Status_LOV__c = lov.Id;
        acp.Admission_Category__c = 'VTAC-MC-IS';
        update acp;
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = appHomeOffersCC.getInitLoadOffers();
            System.assertNotEquals(null, mapResults, 'Results should not be null');
            List<Map<String, Object>> groupedByApplication = (List<Map<String, Object>>)  mapResults.get(appHomeOffersCC.FIELD_SUBMITTED_APPLICATIONS);
            System.assertEquals(1, groupedByApplication.size(), '1 application group should be returned');
        }
        Test.stopTest();
    }


    @isTest
    public static void test_getInitLoadOffersForMyApp()
    {
        Test.startTest();
        User applicant = [select Id from User where lastname='TestingUser'];

        Application_Course_Preference__c acp = [SELECT Application__c,Admission_Category__c from Application_Course_Preference__c ];
        Application__c app = [SELECT Source_System__c FROM Application__c  WHERE ID =:acp.Application__c];
        app.Source_System__c = 'my.app';
        update app;
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = appHomeOffersCC.getInitLoadOffers();
            System.assertNotEquals(null, mapResults, 'Results should not be null');
            List<Map<String, Object>> groupedByApplication = (List<Map<String, Object>>)  mapResults.get(appHomeOffersCC.FIELD_SUBMITTED_APPLICATIONS);
            System.assertEquals(1, groupedByApplication.size(), '1 application group should be returned');
        }
        Test.stopTest();
    }
}