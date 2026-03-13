/**
* @author Shalini Mendu
* @date 10/08/2020
* @group Test Class
* @description Test class to cover the AP validation library
* @revision Trent   
* @revision Shalin Mendu - Improvised the coverage and System.enqueueJob replaced with
* execute to get around the 'You have uncommitted changes..' as System.enqueueJob is considered a DML
* @revision KL - Added tessts for ACPs with Agent Details for SFTLG-869
17.04.2023 Ken McGuire: Changed Comments__c (255 characters) to LongComments__c (4000 characters)
04.05.2023 Vinothraja: Moved some of the before trigger logic to the latest trigger framework. Removed disableTrigger from testSetup
* @Revission - BGreenland - 05/09/2024 - DANO-251 Fix test failures 
*/
//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: SourceMember

@isTest(isParallel=false)
public with sharing class ObdACPImplementation_Test {

        @TestSetup
        static void setup() {            
            //disable triggers on TestSetup
            TriggerCommon.disableTrigger('Contact');
            TriggerCommon.disableTrigger('Application__c');
            TriggerCommon.disableTrigger('Application_Course_Preference__c');
            
            List<Contact> conList = new List<Contact>();
            Contact c = StudFirst_TestHelper.createApplicant();
            c.Person_ID_unique__c = '12341578';
            conList.add(c);
            
            Contact c10 = StudFirst_TestHelper.createApplicant();
            c10.Person_ID_unique__c = '125754';
            conList.add(c10);

            Contact c11 = StudFirst_TestHelper.createApplicant();
            c11.Person_ID_unique__c = '120454';
            conList.add(c11);
            insert conList;
            
            Application__c app = StudFirst_TestHelper.createApplication(c);
            app.Source_System__c ='OES';
            insert app;

            //Insert custom settings for Bypass_Mute_Request__c
            Bypass_Mute_Request__c bmr = Bypass_Mute_Request__c.getOrgDefaults();
            bmr.Bypass_All_Flows__c = true;
            upsert bmr;

            List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
            
            Application_Course_Preference__c acpA7 = new Application_Course_Preference__c();
            acpA7.Applicant__c = c10.Id;
            acpA7.LongComments__c = 'ObdACPImplementationTest';
            //acpA7.Requirement_Satisfied_Code__c = 'ENGLISH';
            acpA7.Recruitment_Reference_Code__c='VCE-DIRECT - VCE STUDENT - DIRECT';
            acpA7.Callista_Sync_Successful__c = false;
            acpA7.Application__c = app.Id;
            acpA7.Callista_Unique_Key_ADM__c = '11111111_a_b_c76';
            acpList.add(acpA7) ;
            Application_Course_Preference__c acpA8 = new Application_Course_Preference__c();
            acpA8.Applicant__c = c11.Id;
            acpA8.LongComments__c = 'ObdACPImplementationTest';
            //acpA8.Requirement_Satisfied_Code__c = 'ENGLISH';
            acpA8.Recruitment_Reference_Code__c='VCE-DIRECT - VCE STUDENT - DIRECT';
            acpA8.Callista_Sync_Successful__c = false;
            acpA8.Application__c = app.Id;
            acpA8.Callista_Unique_Key_ADM__c = '11111111_a_b_c86';
            acpList.add(acpA8) ;
            insert acpList;
                
            // changes for SFTLG-869, real associated Agency scenario
            AgentMgmtTestUtil.loadAgenciesTestDataNoIntegration();
            Contact c2 = StudFirst_TestHelper.createApplicant();
            c2.Person_ID_unique__c = '2222222';
            insert c2;
    
            Application__c app2 = StudFirst_TestHelper.createApplication(c2);
            // link Appl to Agency
            app2.Agent_Org_Unit_Code__c = 'TAG1000';
            app2.Residency_Status__c = 'INTRNTNL';
            app2.Source_System__c = 'AgentPortal';
            insert app2;
            
            Application_Course_Preference__c acpB1 = new Application_Course_Preference__c();
            acpB1.Applicant__c = c2.Id;
            acpB1.LongComments__c = 'ObdACPImplementationTestAgency';
            acpB1.Callista_Sync_Successful__c = false;
            acpB1.Application__c = app2.Id;
            acpB1.Callista_Unique_Key_ADM__c = '11111111_x_y_z';
            insert acpB1;
    
            // changes for SFTLG-869, M-DIRECT scenario
            Contact c3 = StudFirst_TestHelper.createApplicant();
            c3.Person_ID_unique__c = '3333333';
            insert c3;
    
            Application__c app3 = StudFirst_TestHelper.createApplication(c3);
            app3.Residency_Status__c = 'INTRNTNL';
            app3.Source_System__c = 'my.app';
            insert app3;
    
            Application_Course_Preference__c acpC1 = new Application_Course_Preference__c();
            acpC1.Applicant__c = c3.Id;
            acpC1.LongComments__c = 'ObdACPImplementationTestM-DIRECT';
            acpC1.Callista_Sync_Successful__c = false;
            acpC1.Application__c = app3.Id;
            acpC1.Callista_Unique_Key_ADM__c = '11111111_m_n_o';
            insert acpC1;

            Contact c44 = StudFirst_TestHelper.createApplicant();
            c44.Person_ID_unique__c = null;
            insert c44;
            Application_Course_Preference__c noPersonIdACP = new Application_Course_Preference__c();
            noPersonIdACP.Applicant__c = c44.Id;
            noPersonIdACP.LongComments__c = 'ObdACPImplementationNoPersonIdTest';
           // acp_A.Requirement_Satisfied_Code__c = 'ENGLISH';
           noPersonIdACP.Recruitment_Reference_Code__c='VCE-DIRECT - VCE STUDENT - DIRECT';
           noPersonIdACP.Application__c = app.Id;
           noPersonIdACP.Callista_Unique_Key_ADM__c = null;
            insert noPersonIdACP;
        
            Contact c77 = StudFirst_TestHelper.createApplicant();
            c77.Person_ID_unique__c = '543455';
            insert c77;

            Application__c appCCT = StudFirst_TestHelper.createApplication(c77);
            appCCT.Source_System__c = 'CCT';
            insert appCCT;

            Application_Course_Preference__c acpCct = new Application_Course_Preference__c();
            acpCct.Applicant__c = c77.Id;
            acpCct.LongComments__c = 'ObdACPImplementationTestCCT';
            acpCct.Callista_Sync_Successful__c = false;
            acpCct.Application__c = appCCT.Id;
            acpCct.Callista_Unique_Key_ADM__c = '11111111_x_y_z11';
            acpCct.Admission_Calendar_Type__c  = 'ADM-1';
            acpCct.Deferred_Admission_Ci_Sequence__c = 12551;
            insert acpCct;
            
            Application__c appAgentMyApp = StudFirst_TestHelper.createApplication(c2);
            // link Appl to Agency
            appAgentMyApp.Agent_Org_Unit_Code__c = 'TAG1000';
            appAgentMyApp.Residency_Status__c = 'INTRNTNL';
            appAgentMyApp.Source_System__c = 'my.app';
            insert appAgentMyApp;
            
            Application_Course_Preference__c acpAgentMyApp = new Application_Course_Preference__c();
            acpAgentMyApp.Applicant__c = c2.Id;
            acpAgentMyApp.LongComments__c = 'ObdACPImplementationTestAgent_MyApp';
            acpAgentMyApp.Callista_Sync_Successful__c = false;
            acpAgentMyApp.Application__c = appAgentMyApp.Id;
            acpAgentMyApp.Callista_Unique_Key_ADM__c = '11111111_x_y_z200';
            insert acpAgentMyApp;

            Application__c testOESApp = StudFirst_TestHelper.createApplication(c11);
            testOESApp.Source_System__c = 'OES';
            testOESApp.External_Reference_Id__c = '123 Ext Ref';
            insert testOESApp;

            Application_Course_Preference__c oesACP = new Application_Course_Preference__c();
            oesACP.Callista_Unique_Key_AP__c = 'TestObdOESACP';
            oesACP.Application__c = testOESApp.Id;
            oesACP.Applicant__c = c77.Id;
            insert oesACP;
            
            //enable triggers on TestSetup
            TriggerCommon.enableTrigger('Contact');
            TriggerCommon.enableTrigger('Application__c');
            TriggerCommon.enableTrigger('Application_Course_Preference__c');
        }
            
        private static Map<Id, Application_Course_Preference__c> retrieveCoursePreferences (String longCommentsValue, Integer recordLimit) {
            Map<Id, Application_Course_Preference__c> prefs = new Map<Id, Application_Course_Preference__c>();
        
            for (Application_Course_Preference__c pref : [
                SELECT Id, 
                Name, 
                Applicant__r.Person_ID_unique__c, 
                Application__r.Residency_Status__c,
                LongComments__c,
                Callista_Sync_Successful__c,
                Callista_Error_Message__c,
                Callista_Submission_Message__c
                FROM Application_Course_Preference__c LIMIT :10
            ]) {
                if (pref.LongComments__c != null && pref.LongComments__c == longCommentsValue) {
                    if (prefs.size() < recordLimit) { prefs.put(pref.Id, pref); }
                }
                
            }
            return prefs;
        }


    
    
        @isTest
        static void testACPInsertSuccessfulUpdates() {
            
            Map<Id,Application_Course_Preference__c> prefs =retrieveCoursePreferences('ObdACPImplementationTest',2);
        
            Test.startTest();
            
            ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);
     
      
            ObdACPImplementation.fireCallistaOutboundRequest(new List<Id>(prefs.keySet()));
            Test.stopTest();
            
            List<Application_Course_Preference__c> pref = retrieveCoursePreferences ('ObdACPImplementationTest',2).values();
        
            System.assertEquals(true, pref[0].Callista_Sync_Successful__c);
        }
        //No PersonId test
        @isTest
        static void testACPNoPersonId() {
            Test.startTest();
            ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);
            
            Map<Id,Application_Course_Preference__c> prefs =retrieveCoursePreferences('ObdACPImplementationNoPersonIdTest',1);          
            if (prefs.size() > 0) {
                ObdACPImplementation.fireCallistaOutboundRequest(new List<Id>(prefs.keySet()));
            }
            Test.stopTest();
            List<Application_Course_Preference__c> pref = [
                SELECT Callista_Sync_Successful__c,Callista_Error_Message__c
                FROM Application_Course_Preference__c
                WHERE Person_ID__c =null and  Callista_Unique_Key_ADM__c = null
                LIMIT 1
            ];
            System.assertEquals(false, pref[0].Callista_Sync_Successful__c);
        }
                
        @isTest
        public static void test_ACPUpdateForCCTSource() {
            Test.startTest();
            ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);
        
            Map<Id, Application_Course_Preference__c> prefs = retrieveCoursePreferences('ObdACPImplementationTestCCT', 2);
        
            if (prefs.size() > 0) {
                ObdACPImplementation.fireCallistaOutboundRequest(new List<Id>(prefs.keySet()));
            }
            Test.stopTest();
        
            List<Application_Course_Preference__c> pref = retrieveCoursePreferences('ObdACPImplementationTestCCT', 1).values();
            System.assertEquals(true, pref[0].Callista_Sync_Successful__c);
        }


        @isTest
        static void testACPInsertUpdateWithTrueCreditIntention()
        {
            List<Application__c> appList = [
                SELECT Id, Name, Credit_Intention__c
                from Application__c
            ];
            appList[0].Credit_Intention__c = true;
            update appList;
            List<Application_Course_Preference__c> prefs =retrieveCoursePreferences( 'ObdACPImplementationTest',2).values();
            
            Test.startTest();
            
            ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);
            
            if (prefs.size() > 0) {
                ObdACPImplementation.fireCallistaOutboundRequest(new List<Id>{prefs[0].Id});
                
            }
            Test.stopTest();
            
            List<Application_Course_Preference__c> pref = retrieveCoursePreferences( 'ObdACPImplementationTest',2).values();

            System.assertEquals(true, pref[0].Callista_Submission_Message__c.contains(' "requestForAdvancedStandingIndicator" : true,'));
        }
        
        @isTest
        static void testACPInsertUpdateWithAgencyDetails() {
            List<Application_Course_Preference__c> prefs = retrieveCoursePreferences('ObdACPImplementationTestAgency', 2).values();
        
            Test.startTest();
        
            ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);
        
            if (prefs.size() > 0) {
                ObdACPImplementation.fireCallistaOutboundRequest(new List<Id>{prefs[0].Id});
            }
            Test.stopTest();
        
            List<Application_Course_Preference__c> pref = retrieveCoursePreferences('ObdACPImplementationTestAgency', 1).values();
        
            if (!pref.isEmpty()) {
                ObdACPRequest req = (ObdACPRequest) System.JSON.deserialize(pref[0].Callista_Submission_Message__c, ObdACPRequest.class);
                Assert.isNotNull(req, 'Request cannot be null');
            }
        }
    
        @isTest
        static void testACPInsertUpdateWithMDIRECT() {
            List<Application_Course_Preference__c> prefs2 = retrieveCoursePreferences('ObdACPImplementationTestM-DIRECT', 2).values();
        
            Test.startTest();
        
            ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);
        
            if (prefs2.size() > 0) {
                ObdACPImplementation.fireCallistaOutboundRequest(new List<Id>{prefs2[0].Id});
            }
        
            Test.stopTest();
        
            List<Application_Course_Preference__c> pref2 = retrieveCoursePreferences('ObdACPImplementationTestM-DIRECT', 1).values();
        
            if (!pref2.isEmpty()) {
                ObdACPRequest req2 = (ObdACPRequest) System.JSON.deserialize(pref2[0].Callista_Submission_Message__c, ObdACPRequest.class);
                System.assertEquals('M-DIRECT', req2.getApplication().getCoursePreference().agent.agentOrgUnitCode);
            }
        }

        @isTest
        static void testACPInsertUpdateWithAgentonMyApp() {
            List<Application_Course_Preference__c> prefs2 = retrieveCoursePreferences('ObdACPImplementationTestAgent_MyApp', 2).values();
        
            Test.startTest();
        
            ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);
        
            if (prefs2.size() > 0) {
                ObdACPImplementation.fireCallistaOutboundRequest(new List<Id>{prefs2[0].Id});
            }
        
            Test.stopTest();
        
            List<Application_Course_Preference__c> pref2 = retrieveCoursePreferences('ObdACPImplementationTestAgent_MyApp', 1).values();
        
            if (!pref2.isEmpty()) {
                ObdACPRequest req2 = (ObdACPRequest) System.JSON.deserialize(pref2[0].Callista_Submission_Message__c, ObdACPRequest.class);
                Assert.isNotNull(req2, 'Request cannot be null');
            }
        }

    /*
     * @author       Shalini Mendu
     * @date         13/10/2020
     * @description  Test to verify the data sent out to the client when ADM key is populated
     * @revision
     * Sachin Shetty - Sep 2023 - Updated to check for the event records created instead of the exception records
     */
        @istest
        static void testFiringOutboundACPPE() {

            // GIVEN : Retrieve the ACP record created from setup for the given Callista_Unique_Key_AP__c
            List<Application_Course_Preference__c> acpList =  [select id,name,Application__r.Source_System__c, Applicant__r.CRM_Id__c, Application__r.Name, Application__r.External_Reference_Id__c ,Callista_Unique_Key_ADM__c, Callista_Sync_Successful__c, Callista_Error_Message__c from Application_Course_Preference__c  where Callista_Unique_Key_AP__c = 'TestObdOESACP'];
            
            // WHEN : ACP is updated with an ADM key
            acpList[0].Callista_Unique_Key_ADM__c = '12343535';
            
            Test.startTest();
                ObdACPImplementation ObdACP = new ObdACPImplementation();
                List<ObdACP__e> publishACPEvList = ObdACP.publishObdACPPEs(acpList);
            Test.stopTest();
            
            // THEN : Verify that the event record which creates the exception log - is created
            Assert.areEqual(1, publishACPEvList.size(), 'There should be one record');
    
        }
}