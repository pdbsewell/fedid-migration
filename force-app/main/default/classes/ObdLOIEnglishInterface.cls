/*******************************************************************************
* @author:      Shalini Mendu
* @date:        10.Feb.2020
* @description: SFTN-455-Admission Test Result: Language of Instruction/ Country of schooling pass to Callista
* @revision: 
*******************************************************************************/
public class ObdLOIEnglishInterface extends UniCRMIntegrationPoint implements Queueable, Database.AllowsCallouts {
        public Id recordId{get;set;}
        public String personId{get;set;}
        public String englishEntryMode, meetsEnglish = null;

        // Called from the Application trigger handler
        public static void fireOutboundRequest(Id appId, String englishEntryMode, String meetsEnglish){
            ObdLOIEnglishInterface obj = new ObdLOIEnglishInterface(appId, englishEntryMode, meetsEnglish);
            System.enqueueJob(obj);
        }
        //constructor
        public ObdLOIEnglishInterface (Id appId, String englishEntryMode, String meetsEnglish){
            this.recordId = appId;
            this.englishEntryMode = englishEntryMode;
            this.meetsEnglish  = meetsEnglish;
            this.doInit('IP08_Callista_English_Test_Score');
            createRequestBody();
            if(personId == null){
                ExLog.add('Unable to add LOI English score as there is no Person ID for the related Contact of the Application record:'+recordId,'EnglishTestScoreInterface','execute','No PersonID');
                return;
            }
            buildURIWithParams(personId);
        }

        //Queuable execute method
        public void execute(QueueableContext ctx) {
            this.ctx = ctx;
           
            if(personId!=null) {
        
                if(!Test.isRunningTest() ) {
                    this.sendMessage();
                }
            }
        }
        
        //  Build URI populating parameter
        public void buildURIWithParams(String personId)
        {
            Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
            urlReplaceKeyValuePairs.put('{0}', personId);
            this.constructEndPoint(urlReplaceKeyValuePairs);
        }

        //create Request body
        public void createRequestBody() {
            try {

                Application__c app1 = 
                [SELECT  Applicant__r.Person_ID_unique__c,
                                Meets_Minimum_English__c, English_Entry_Mode__c 
                                FROM Application__c where Id = :recordId];
                personId = app1.Applicant__r.Person_ID_unique__c;
                ObdLOIEnglishInterfaceRequest req = new ObdLOIEnglishInterfaceRequest();
                req.type = 'testScore';
                req.testType = app1.English_Entry_Mode__c.startsWith('English')?'LOI':'VCE-Y12';
                req.verificationStatus = 'UNKNOWN';
                req.completed = true;
                req.resultType =  app1.Meets_Minimum_English__c.equals('Yes')?'SATISFACTORY':'UNSATISFACTORY';
             
                List<Application__c> appList  = [
                        SELECT Id, (SELECT  Admission_Application_Number__c, Course_Code__c FROM Application_Course_Preferences__r)
                        FROM Application__c
                        WHERE ID = :recordId
                ];
                List<ObdLOIEnglishInterfaceRequest.applications> appsLR = new List<ObdLOIEnglishInterfaceRequest.applications>();

                for(Application__c app:appList)
                {
                    ObdLOIEnglishInterfaceRequest.applications appR = new ObdLOIEnglishInterfaceRequest.applications();
                    appR.type = 'application';
                    List<ObdLOIEnglishInterfaceRequest.coursePreferences> acpList =
                            new List<ObdLOIEnglishInterfaceRequest.coursePreferences>();
                    for(Application_Course_Preference__c acp:app.Application_Course_Preferences__r)
                    {
                        ObdLOIEnglishInterfaceRequest.coursePreferences acpR = new ObdLOIEnglishInterfaceRequest.coursePreferences();
                        acpR.type =  'coursePreference';
                        acpR.admissionApplNumber =  Integer.valueOf(acp.Admission_Application_Number__c);
                        acpR.courseCode = acp.Course_Code__c;
                        acpList.add(acpR);
                    }
                    appR.coursePreferences = acpList;
                    appsLR.add(appR);
                }
                req.applications = appsLR;

                List<ObdLOIEnglishInterfaceRequest.subscores> subscoresRL = new List<ObdLOIEnglishInterfaceRequest.subscores>();
                req.subscores = subscoresRL;
                this.jsonRequest = req;
                System.debug(LoggingLevel.DEBUG, 'Class: ObdLOIEnglishInterface req =='+this.jsonRequest);
            } catch (Exception ex) {
                System.debug(LoggingLevel.DEBUG, 'Class: ObdLOIEnglishInterface, Method: createRequestBody, Message: ' + ex.getMessage()+' Line number:'+ex.getLineNumber()+' Cause:'+ex.getCause());
                ExLog.add('ObdLOIEnglishInterface','LOI English Integration','createRequestBody', ex);
            }

        }
    
}