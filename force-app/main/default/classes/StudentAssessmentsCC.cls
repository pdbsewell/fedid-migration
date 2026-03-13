/**
 * @description      : Uses MIX API to retrieve Student Assessments from Moodle
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @version           : Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   04-10-2021 - Angelo Rivera - Initial Creation
**/

public with sharing class StudentAssessmentsCC {

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 04-10-2021
    * @description  Retrieves Student Assessments from Moodle
    * @param caseUnitAttemptId - Case_Unit_Attempt__c Id
    * @return strResponse - that will be displayed as a message in lightning component
    * @revision 04-10-2021 - APRivera - Created
    *******************************************************************************/
    @AuraEnabled
    public static List<StudentAssessmentWrapper> retrieveAssessments(String caseUnitAttemptId) {
        List<StudentAssessmentWrapper> strResponse = new List<StudentAssessmentWrapper>();
        Case_Unit_Attempt__c cua = new Case_Unit_Attempt__c();
        cua = getCaseUnitAttempt(caseUnitAttemptId);

        if(cua.UserRecordAccess.HasEditAccess){
            if(cua.Person_ID__c == null){
                return null;
            } else{
                Integer strUnitOfferingId = Integer.valueOf(getUnitOffering(cua));

                //send callout
                strResponse = sendCallout(strUnitOfferingId, cua);
            }
        } else {
            return null;
        }
        System.debug(LoggingLevel.DEBUG, '!@#@$ strResponse: ' + JSON.serializePretty(strResponse));
        return strResponse;
    }
    

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 04-10-2021
    * @description  Sends Callout to MIX
    * @param unitOfferingId - payload
    * @param cua - Case_Unit_Attempt__c
    * @return lstStudentAssessments - Callout response
    * @revision 04-10-2021 - APRivera - Created
    *******************************************************************************/
    public static List<StudentAssessmentWrapper> sendCallout(Integer unitOfferingId, Case_Unit_Attempt__c cua){
        List<StudentAssessmentWrapper> lstStudentAssessments = new List<StudentAssessmentWrapper>();

        //Create Request
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Monash_MiX_APIs/'+'unicrm-student-admin/v1/students/'+cua.Person_ID__c+'/assessments?unitOfferingId='+unitOfferingId);
        req.setMethod('GET');

        //Set headers
        req.setHeader('client_id', '{!$Credential.Username}');
        req.setHeader('client_secret', '{!$Credential.Password}');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);
        // send request
        HttpResponse res = null;
        res = h.send(req);

        String resp =  res.getBody();
        if (res.getStatusCode() == 200){
            lstStudentAssessments = (List<StudentAssessmentWrapper>) System.JSON.deserialize(res.getBody(), List<StudentAssessmentWrapper>.class);
        } else{
            LogUtilityException.logExceptionMSG('StudentAssessmentsCC_sendCallout', 'Case Unit Attempt: ' + cua.Name, 'Endpoint: \n' + req.getEndpoint() + '\n\n\n Response: \n' + resp );
        }
        System.debug('!@#@$ lstStudentAssessments: ' + lstStudentAssessments.size());
        return lstStudentAssessments;
    }


    /*******************************************************************************
    * @author Angelo Rivera
    * @date  04-10-2021
    * @description  Retrieves Case_Unit_Attempt__c
    * @revision 04-10-2021 - APRivera - Created
    * @return Case_Unit_Attempt__c
    *******************************************************************************/
    public static Case_Unit_Attempt__c getCaseUnitAttempt(String caseUnitAttemptId){
        return [SELECT UserRecordAccess.HasEditAccess, Id, Name, Unit_Attempt__c, Person_ID__c, Unit_Attempt__r.Unit_Code__c, Unit_Attempt__r.Title__c
                    FROM Case_Unit_Attempt__c WHERE Id =: caseUnitAttemptId ];
    }


    /*******************************************************************************
    * @author Angelo Rivera
    * @date  04-10-2021
    * @description  Retrieves Unit Offering
    * @revision 04-10-2021 - APRivera - Created
    * @return Unit_Offering__r.UOO_ID__c
    *******************************************************************************/
    public static String getUnitOffering(Case_Unit_Attempt__c cua){
        return [SELECT Id, Unit_Offering__c, Unit_Offering__r.UOO_ID__c FROM Unit_Attempt__c WHERE Id =: cua.Unit_Attempt__c].Unit_Offering__r.UOO_ID__c;
    }


}