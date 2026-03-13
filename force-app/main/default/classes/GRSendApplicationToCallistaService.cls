/*******************************************************************************
* @author       Vishal Gupta
* @date         1/10/2024
* @description  invoke callista interface v1/admissions/sms/documents to post HDR Docs
* @revision      
* 01/10/2024 - Vishal Gupta - Created
*******************************************************************************/
public without sharing class GRSendApplicationToCallistaService extends UniCRMIntegrationPoint implements Database.AllowsCallouts {

    private static final String INTERFACE_NAME = 'IP11_GR_Callista_Application_Insert';
    private static final String TAG = 'Callista application callout';
    private static final String GRT_SCHOLARSHIP_APPLICATION_ONLY = 'Scholarship application only';
    private static final String GRADUATE_RESEARCH = 'Graduate Research';

    private Id applicationId;
    private Id contactId;
    private Application_Course_Preference__c acpInfo;

    /**
     * @author      Vishal Gupta
     * @description Constructor
     * @revision    01/10/2024 - Initial Version
     */
    public GRSendApplicationToCallistaService (Id applicationId, Id contactId) {
        this.applicationId = applicationId;
        this.contactId = contactId;
        this.doInit(INTERFACE_NAME);
    }

    /**
     * @author      Vishal Gupta
     * @description creates request body for the call out
     * @revision    01/10/2024 - Initial Version
     */
    public void createRequestBody(){
      
        try {
            GRApplicationJSON reqJson = new GRApplicationJSON();
            List<Contact> applicantData = new ContactsSelector().selectById(new Set<Id>{contactId});
            List<Application__c> applicationData = new ApplicationsSelector().selectByIdWithParentDetailsAndDocuments(new Set<Id>{applicationId});
            List<Contact_Qualification__c> qualificationData = new ContactQualificationsSelector().selectQualificationsWithDocumentsByApplicationId(new Set<Id>{applicationId});
            if(!applicantData.isEmpty() && !applicationData.isEmpty()) {
                Contact contactInfo = applicantData[0];
                Application__c applicationInfo = applicationData[0];
                List<Application_Course_Preference__c> lstACP = new ApplicationCoursePreferenceSelector().selectByApplicationIdWithParentDetails(new Set<Id>{applicationId});
                if(!lstACP.isEmpty()) {
                    acpInfo = lstACP[0];
                }
                GRApplicationJSON.Applicant grApplicant = new GRApplicationJSON.Applicant();
                if(!String.isBlank(contactInfo.Person_ID__c)){
                    grApplicant.studentId = contactInfo.Person_ID__c;
                }
                
                if(!String.isBlank(contactInfo.Previous_Monash_ID__c)){
                    grApplicant.previousMonashId = contactInfo.Previous_Monash_ID__c;
                }

                if(applicationInfo.Applied_For_Permanent_Residency__c) {
                    //visa details
                    grApplicant.visa = GRApplicationJSONMapper.getVisaInfo(applicationInfo);
                }
                //applicant additional details
                grApplicant.additionalDetails = GRApplicationJSONMapper.getApplicantAdditionalDetails(contactInfo);

                //qualification details
                grApplicant.qualifications = GRApplicationJSONMapper.getApplicantQualificationDetails(qualificationData);

                
                GRApplicationJSON.Application grApplication = new GRApplicationJSON.Application();
                
                //MGROI-485 Pass the Parent Application Callista Id for Scholarship application only
                if(applicationInfo.Type_of_Study__c == GRADUATE_RESEARCH 
                && applicationInfo.Graduate_Research_Application_Type__c == GRT_SCHOLARSHIP_APPLICATION_ONLY
                && applicationInfo.Parent_Application__c != null){
                    grApplicant.smsContactId = applicationInfo.Parent_Application__r.Callista_Applicant_Id__c;
                    grApplication.smsApplicationId = applicationInfo.Parent_Application__r.Callista_Application_Id__c;
                }else{
                    grApplicant.smsContactId = applicationInfo.Callista_Applicant_Id__c;
                    grApplication.smsApplicationId = applicationInfo.Callista_Application_Id__c;
                }

                grApplication.applicationType = new GRApplicationJSON.ApplicationType('HDR');
                grApplication.hdrApplicationDetails = GRApplicationJSONMapper.getHDRApplicationDetails(applicationInfo, acpInfo);
                grapplication.courseDetail = GRApplicationJSONMapper.getCourseDetails(applicationInfo, acpInfo);
                reqJson.applicant = grApplicant;
                reqJson.application = grApplication;                
            }
            String jsonCusString = JSON.serialize( reqJson, true );
            String sanitisedStr = jsonCusString.replaceAll('[^ -~]', '?');
            this.jsonRequest = (Object)JSON.deserializeUntyped(sanitisedStr);
            
        }catch (Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }

    /**
     * @author      Vishal Gupta
     * @description Read the web service call response & update fields on the Contact Document
     *              records after the call out
     * @revision    01/10/2024 - Initial Version
    */
    public void handleResponse()
    {
        try {
            acpInfo.API_Request__c = jSON.serializePretty(jsonRequest);
            Map<String,Object> respBody = this.getResponseBody();
            acpInfo.API_Response__c = jSON.serialize(respBody);
            acpInfo.Sync_In_Progress__c = false;
            acpInfo.Last_sync_date_time__c = DateTime.now();
            if (this.httpResponseCode == 200) {
                if(acpInfo != null && jsonRequest != null) {
                    if(respBody.containsKey('application')) {
                        Map<String,Object> respAppBody = (Map<String,Object>) respBody.get('application');
                        String hdrApplicationNumber = String.valueOf(respAppBody.get('hdrApplicationNumber'));
                        acpInfo.GradRes_Callista_Id__c = hdrApplicationNumber;
                        Nebula.logger.info('hdrApplicationNumber returned from callista: ' + hdrApplicationNumber).addTag(TAG);
                    }
                }
            } 
            else{
                Nebula.Logger.info('Response from GRSendApplicationToCallistaService: '+string.valueOf(this.httpResponseCode)).addTag(TAG);
            }
            update acpInfo;
        }catch (Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }
    
}