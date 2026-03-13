/*******************************************************************************
* @author:      Shalini Mendu
* @date:        11.Nov.2019
* @description: Business logic implementation for 'Update English Test score to Callisa'
*               interface.  Forms request JSON in object form, and initiates
*               actual request via inherited method from framework. - SFTN-154
* @revision: 6/2/2020 - SFTN-479-ACP Updates failing on English Test Scores
* @revision: 8/07/2025 - EPCP-4493 PB Migration to Flow
*
*******************************************************************************/
public  class EnglishTestScoreInterface extends UniCRMIntegrationPoint implements Queueable, Database.AllowsCallouts {

    public Id recordId{get;set;}
    public String personId{get;set;}
    Contact_Qualification__c cq = null;     

    //Constructor with Contact Qualification record Id
    public EnglishTestScoreInterface (Id recordId) {
        this.recordId = recordId;
        this.doInit('IP08_Callista_English_Test_Score');
        createRequestBody();
        
        //SFTN-479- Adding personId check 
        if(personId == null){
            ExLog.add('Unable to add English Test score as there is no Person ID for the Contact on the Contact Qualification record:'+recordId,'EnglishTestScoreInterface','execute','No PersonID');
            return;
        }
        buildURIWithParams(personId);
    }

    @InvocableMethod
    public static void fireOutboundRequest(List<Id> recordId){
        EnglishTestScoreInterface obj = new EnglishTestScoreInterface(recordId.get(0));
        if(obj.jsonRequest != null){
            System.enqueueJob(obj);
        }
    }

    // Build URI filling in a parameter which is the Contact.PersonID
    public void buildURIWithParams(String personId)
    {
        Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
        urlReplaceKeyValuePairs.put('{0}', personId);
        this.constructEndPoint(urlReplaceKeyValuePairs);
    }
    //create Request body
    public void createRequestBody() {
        try {
            cq = [
                    SELECT Verification_Status__c, Contact__r.Person_ID_unique__c, isTestCompleted__c, Expected_date_of_completion__c, Date_Achieved__c, Expiry_Date__c,Score__c,
                            Result_Type__c, Qualification__r.Callista_Code__c, Other_Qualification_Comments__c, Qualification__r.Sub_score_Type__c,
                            Writing__c, Listening__c, READING__c, Speaking__c, Test_of_Written_English__c,
                    (SELECT Application__r.Id FROM Application_Qualifications__r )
                    FROM Contact_Qualification__c
                    where id = :recordId ];

            personId = cq.Contact__r.Person_ID_unique__c;

            EnglishTestScoreRequest req = new EnglishTestScoreRequest();
            req.type = 'testScore';
            req.testType = cq.Qualification__r!=null?cq.Qualification__r.Callista_Code__c:'';
            req.verificationStatus = cq.Verification_Status__c!=null?cq.Verification_Status__c.toUpperCase():null;
            req.completed = cq.isTestCompleted__c;
            req.plannedDate = cq.Expected_date_of_completion__c!=null?convertDate(cq.Expected_date_of_completion__c):null;
            req.achievedDate = cq.Date_Achieved__c!=null?convertDate(cq.Date_Achieved__c):null;
            req.expiryDate = cq.Expiry_Date__c!=null?convertDate(cq.Expiry_Date__c):null;

            String resType = cq.Result_Type__c!=null?cq.Result_Type__c:'';
            req.resultType =  (String.isNotBlank(resType) && resType.toUpperCase()=='SATISFACTORY'|| String.isNotBlank(resType) && resType.toUpperCase()=='UNSATISFACTORY')?resType.toUpperCase():null;
            req.comments = cq.Other_Qualification_Comments__c!=null?cq.Other_Qualification_Comments__c:'';

            try{
                //when cq.Score__c is an Integer
                req.overallScore = Integer.valueOf(cq.Score__c);
            } catch(Exception ee) {
                //when cq.Score__c is unable to parse as an Integer as it is a String
                req.grade =  cq.Score__c;
            }

            // Callout requires existing application
            String appId;
            if(!cq.Application_Qualifications__r.isEmpty()){
                appId = cq.Application_Qualifications__r[0]?.Application__r?.Id;  
            }  
            if(appId == null){
                return;
            }    
                
            String subscoreTypes = cq?.Qualification__r?.Sub_score_Type__c;

            List<Application__c> appList  = [
                    SELECT Id, (SELECT  Admission_Application_Number__c, Course_Code__c FROM Application_Course_Preferences__r)
                    FROM Application__c
                    WHERE ID = :appId
            ];
            List<EnglishTestScoreRequest.applications> appsLR = new List<EnglishTestScoreRequest.applications>();

            for(Application__c app:appList)
            {
                EnglishTestScoreRequest.applications appR = new EnglishTestScoreRequest.applications();
                appR.type = 'application';
                List<EnglishTestScoreRequest.coursePreferences> acpList =
                        new List<EnglishTestScoreRequest.coursePreferences>();
                for(Application_Course_Preference__c acp:app.Application_Course_Preferences__r)
                {
                    if(Integer.valueOf(acp.Admission_Application_Number__c) == null){
                        // Callout requires existing Admission_Application_Number__c
                        return;
                    }
                    EnglishTestScoreRequest.coursePreferences acpR = new EnglishTestScoreRequest.coursePreferences();
                    acpR.type =  'coursePreference';
                    acpR.admissionApplNumber = Integer.valueOf(acp.Admission_Application_Number__c);
                    acpR.courseCode = acp.Course_Code__c;
                    acpList.add(acpR);
                }
                appR.coursePreferences = acpList;
                appsLR.add(appR);
            }
            req.applications = appsLR;
            List<String> splitStr = new List<String>();
            if(String.isNotBlank(subscoreTypes))
            {
                if(subscoreTypes.contains(';'))
                    splitStr = subscoreTypes.split(';');
                else
                        splitStr.add(subscoreTypes);
            }

            List<EnglishTestScoreRequest.subscores> subscoresRL = new List<EnglishTestScoreRequest.subscores>();
            for(String sp:splitStr)
            {
                EnglishTestScoreRequest.subscores ss = new EnglishTestScoreRequest.subscores();
                ss.type = 'testSubscore';
                switch on sp
                {
                    When 'Reading'
                    {
                        ss.score = cq.READING__c;
                        ss.scoreType = String.isNotBlank(sp)?sp.toUpperCase():'';
                    }
                    When 'Writing'
                    {
                        ss.score = cq.WRITING__C;
                        ss.scoreType = String.isNotBlank(sp)?sp.toUpperCase():'';
                    }
                    When 'Listening'
                    {
                        ss.score = cq.Listening__c;
                        ss.scoreType = String.isNotBlank(sp)?sp.toUpperCase():'';
                    }
                    When 'Speaking'
                    {
                        ss.score = cq.Speaking__c;
                        ss.scoreType = String.isNotBlank(sp)?sp.toUpperCase():'';
                    }
                    When 'Test of Written English'
                    {   // Replacing it with a shorter version to overcome callista character limit of 10
                        ss.score = cq.Test_of_Written_English__c;
                        ss.scoreType = 'TWE'; 
                    }
                }
                subscoresRL.add(ss);
            }
            req.subscores = subscoresRL;
            this.jsonRequest = req;
            Nebula.Logger.info('Class: EnglishTestScoreInterface ConQual Id: ' + recordId +' reqBody = ' + JSON.serializePretty(jsonRequest));
        } catch (Exception ex) {
            Nebula.Logger.exception('Class: EnglishTestScoreInterface Method: createRequestBody for ConQual Id: '+ recordId +', Message: ' + ex.getMessage(), ex);
        }
        finally {
            Nebula.Logger.saveLog();
        }
    }

    //Queuable execute method
    public void execute(QueueableContext ctx) {
        this.ctx = ctx;
        //SFTN-479- Adding personId check 
        if(personId!=null) {
                if(!Test.isRunningTest() ) {
                this.sendMessage();
            }
            handleResponse();
        }
    }
    
    //handle response from the framework
    private void handleResponse() {
        try {
            Map<String, Object> respBody = this.getResponseBody();
            // check http response
            if (this.httpResponseCode == 200) {
                //successful response
                Nebula.Logger.info('EnglishTestScoreInterface\'s handleResponse method, ConQual Id: ' + this.recordId + ', Response Code = ' + this.httpResponseCode + ' respBody = ' + JSON.serializePretty(respBody));
            } else {
                //unsuccessful response
                Nebula.Logger.error('EnglishTestScoreInterface\'s handleResponse method, ConQual Id: ' + this.recordId + ', Response Code = ' + this.httpResponseCode + ' respBody = ' + JSON.serializePretty(respBody));
            }
        } catch (Exception ex) {
            // log exception
            Nebula.Logger.exception('Class: EnglishTestScoreInterface Method: handleResponse, Message: ' + ex.getMessage(), ex);
        }
        finally {
            Nebula.Logger.saveLog();
        }
    }

    // Date formatter
    public static String convertDate(Date dt) {
        String retDt = '';

        if(dt != null)
        {
            DateTime dtTime = Datetime.newInstance(dt.year(), dt.month(), dt.day());
            retDt = dtTime.format('yyyy-MM-dd');
        }
        return retDt;
    }

}