/**
 * @description      : Uses MIX API to initiate an update to the relevant assignments due date in Moodle eLMS
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @version           : Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-07-02 - Angelo Rivera - Initial Creation
 * 1.1   2021-09-21 - Angelo Rivera - Added timestamp to Assignment New Date payload
 *                                              - Added logic to update Moodle Integration Status field after successful response from Moodle.
 * 2.0   2023-07-20 - Tom Gangemi - Updates for SpecCon Short Ext Project. Includes some refactoring
 * 2.1   2023-10-21 - Tom Gangemi - Update payload's newDueDate to match Unit Attempt Location's local time
**/
public with sharing class UpdateMoodleCC {

    @InvocableMethod(Label='Moodle - Update Assignment' Description='Update Assignment in Moodle via integration')
    public static List<String> updateAssignmentInvocable(List<Id> caseUnitAttemptIds) {
        String message = '';
        if(caseUnitAttemptIds.size() > 1) {
            message = 'Only one id per invocation supported';
        } else {
            message = updateAssignment(caseUnitAttemptIds[0]);
        }
        String[] ret = new String[0];
        for(Id cuaId :caseUnitAttemptIds) {
            ret.add(message);
        }
        return ret;
    }

    /*******************************************************************************
	* @author Angelo Rivera
	* @date 2021-07-02
	* @description  Updates Due Date in Moodle via MIX API
	* @param caseUnitAttemptId - Case_Unit_Attempt__c Id
	* @return strResponse - that will be displayed as a message in lightning component
	* @revision 2021-07-02 - APRivera - Created
	*******************************************************************************/
    @AuraEnabled
    public static String updateAssignment(String caseUnitAttemptId) {
        String strResponse;

        Case_Unit_Attempt__c cua = getCaseUnitAttempt(caseUnitAttemptId);

        if(cua.UserRecordAccess.HasEditAccess) {
            if(cua.Assessment_Due_Date_New__c == null || cua.Assessment_Due_Date_Original__c == null){
                strResponse = Label.Moodle_Integration_Missing_Dates;
            } else{
                if(cua.Person_ID__c == null){
                    strResponse = Label.Moodle_Integration_No_Person_Id;
                } else{
                    // build payload
                    MoodleAssignmentWrapper moodlePayload = buildCRMDara(cua, cua.Unit_Attempt__r.Location__c);

                    // send callout (logs errors)
                    CalloutResponse cr = sendCallout(moodlePayload, cua);
                    strResponse = cr.message;

                    // handle response
                    if(cr.success) {
                        insert createCaseComment(cua);
                        cua.Moodle_Integration_Status__c = Label.Moodle_Integration_Status_Success;
                    } else {
                        cua.Moodle_Integration_Status__c = ('Failed - Logged');
                    }
                    update cua;
                }
            }
        } else{
            strResponse = Label.Moodle_Integration_No_Access;
        }

        return strResponse;
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date  2021-07-02
    * @description  builds payload
    * @param cua - Case_Unit_Attempt__c
    * @return maw - Callout MoodleAssignmentWrapper
    * @revision 2021-07-02 - APRivera - Created
    *******************************************************************************/
    public static MoodleAssignmentWrapper buildCRMDara(Case_Unit_Attempt__c cua, String location) {
        MoodleAssignmentWrapper maw = new MoodleAssignmentWrapper();

        maw.newDueDate = SpecConMoodleCalloutService.createNewLocalDueDatetime(cua.Assessment_Due_Date_New__c, location);

        return  maw;
    }

    public class CalloutResponse {
        public Boolean success;
        public String message;
        public String body;
    }

    public static final String SYS_SETTINGS_FEATURE_MOODLE_MOCK = 'SPEC_CON_MOODLE_MOCK';
    /**
     * @return the mock response from System Settings - null if there is no active mock setting
     */
    public static String getMoodleMockResponse() {
        System_Settings__mdt[] mockSetting = SystemSettingsUtil.getInstance().getByFeature(SYS_SETTINGS_FEATURE_MOODLE_MOCK);
        if(mockSetting.size() > 0 && String.isNotBlank(mockSetting[0].Value__c)) {
            return mockSetting[0].Value__c;
        } else {
            return null;
        }
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date  2021-07-02
    * @description  Sends Callout to MIX
    * @param payload - payload
    * @param cua - Case_Unit_Attempt__c
    * @return strReturn - Callout response
    * @revision 2021-07-02 - APRivera - Created
    *******************************************************************************/
    public static CalloutResponse sendCallout(MoodleAssignmentWrapper payload, Case_Unit_Attempt__c cua){
        CalloutResponse cr = new CalloutResponse();

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:MIX_API_Assignment_Extension/'+cua.Person_ID__c+'/assignments/'+cua.Moodle_Assessment_ID__c+'/extensions');
        req.setMethod('POST');

        // set headers
        req.setHeader('client_id', '{!$Credential.Username}');
        req.setHeader('client_secret', '{!$Credential.Password}');
        req.setHeader('Content-Type', 'application/json');

        // set request json body
        String body = JSON.serialize(payload);
        req.setBody(body);

        // do callout, if a mock is present, mock the response
        HttpResponse res;
        String mockRespBody = getMoodleMockResponse();
        if(String.isNotBlank(mockRespBody)) {
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody(mockRespBody);
            insert new CaseComment(
                ParentId = cua.Enquiry__c,
                CommentBody = 'Moodle Callout Mocked.\nReq Endpoint:\n' + req.getEndpoint() + '\nReq Body:\n' + body + '\nResp Body:\n' + mockRespBody
            );
            cr.message = '-- MOCKED RESPONSE - Moodle Not Updated! ---   ';
        } else {
            res = h.send(req);
            cr.message = '';
        }

        // get response and log any errors
        cr.body = res.getBody();
        if(res.getBody().contains('error') || res.getBody().contains('fail')) {
            cr.success = false;
            cr.message += Label.Moodle_Integration_Failed_Toast_Message;
            cr.message = cr.message.replace('Unit Code', cua.Unit_Attempt__r.Unit_Code__c + ' - ' + cua.Unit_Attempt__r.Title__c);
            cr.message += '\nError: Status ' + res.getStatusCode() + ' - ' + res.getStatus();
            LogUtilityException.logExceptionMSG('UpdateMoodleCC_sendCallout', 'Case Unit Attempt: ' + cua.Name + '\n\nPayload: \n' +body, 'Endpoint: \n' + req.getEndpoint() + '\n\n\n Response: \n' + res.getBody() );
        }else{
            cr.success = true;
            cr.message += Label.Moodle_Integration_Success_Toast_Message;
            cr.message = cr.message.replace('Unit Code', cua.Unit_Attempt__r.Unit_Code__c + ' - ' + cua.Unit_Attempt__r.Title__c);
        }

        return cr;
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date  2021-07-02
    * @description  Generates CaseComment
    * @param cua - Case_Unit_Attempt__c record
    * @return caseComment
    * @revision 2021-07-02 - APRivera - Created
    *******************************************************************************/
    public static CaseComment createCaseComment(Case_Unit_Attempt__c cua){
        Date origDate = cua.Assessment_Due_Date_Original__c;
        Date newDate = cua.Assessment_Due_Date_New__c;
        String origDateStr = '';
        if(origDate != null) {
            origDateStr = Datetime.newInstance(origDate.year(),origDate.month(),origDate.day()).format('yyyy-MM-dd');
        }
        String newDateStr = Datetime.newInstance(newDate.year(),newDate.month(),newDate.day()).format('yyyy-MM-dd');
        CaseComment caseComment = new CaseComment();
        caseComment.ParentId = cua.Enquiry__c;
        caseComment.CommentBody = Label.Moodle_Integration_Success_Toast_Message +'\n'
                + 'Case Unit Attempt: ' + cua.Name + '\n'
                + 'Original Due Date: ' + origDateStr + '\n'
                + 'New Due Date: ' + newDateStr;
        return  caseComment;
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date  2021-07-02
    * @description  Retrieves Case_Unit_Attempt__c
    * @revision 2021-07-02 - APRivera - Created
    * @return Case_Unit_Attempt__c
    *******************************************************************************/
    public static Case_Unit_Attempt__c getCaseUnitAttempt(String caseUnitAttemptId){
        return [
            SELECT UserRecordAccess.HasEditAccess, Name, Unit_Attempt__r.Unit_Code__c, Unit_Attempt__r.Title__c,
            Status__c, Enquiry__c, Person_ID__c, Moodle_Assessment_ID__c, Moodle_Integration_Status__c, Origin__c,
            RecordTypeId, Requested_Outcome__c, Assessment_Due_Date_New__c, Assessment_Due_Date_Original__c,
            Assessment_Type__c, Unit_Attempt__r.Location__c
            FROM Case_Unit_Attempt__c
            WHERE Id = :caseUnitAttemptId
        ];
    }


}