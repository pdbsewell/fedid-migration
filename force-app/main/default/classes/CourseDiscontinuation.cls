/**
 * @description       : Create course discontinuation request for Callista
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 28-06-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class CourseDiscontinuation {
    /**
    * @description Send Course Discontinuation to Callista.
    * @author rajesh.punjabi@monash.edu | 25-05-2022 
    **/
    @InvocableMethod(label='Course Discontinuation Request' description='Returns the response message.')
    public static List<String> processCourseDiscontinuation(List<CourseDiscontinuationRequest> oDiscontinuationRequest){
        List<String> lstResponse = new List<String>();

        if(validateRecordAccess(oDiscontinuationRequest[0].strCaseID) && FeatureManagement.checkPermission('SS_AllowCourseDiscontinuation')) {
            CourseDisconWrapper oWrapper = new CourseDisconWrapper();
            CourseDisconWrapper.SpecificContent oSpecificContent = new CourseDisconWrapper.SpecificContent();
            CourseDisconWrapper.ItemData oItemData = new CourseDisconWrapper.ItemData();
            oSpecificContent.uniCRMCaseID = oDiscontinuationRequest[0].strCaseID;
            oSpecificContent.uniCRMEnquiryNo = oDiscontinuationRequest[0].strCaseNumber;
            oSpecificContent.personID = oDiscontinuationRequest[0].strPersonID;
            oSpecificContent.CourseCode = oDiscontinuationRequest[0].strCourseCode;
            oSpecificContent.DiscontinDate =  Datetime.newInstance(oDiscontinuationRequest[0].dtDiscontinDate.year(), oDiscontinuationRequest[0].dtDiscontinDate.month(), oDiscontinuationRequest[0].dtDiscontinDate.day()).format('dd/MM/yyyy');
            oSpecificContent.DiscontinReason = oDiscontinuationRequest[0].strDiscontinReason;
            oSpecificContent.SubmissionDate =  Datetime.newInstance(oDiscontinuationRequest[0].SubmissionDate.year(), oDiscontinuationRequest[0].SubmissionDate.month(), oDiscontinuationRequest[0].SubmissionDate.day()).format('dd/MM/yyyy');
            oSpecificContent.MonashConnectOfficerName = oDiscontinuationRequest[0].strOfficerName;
            oItemData.Name = System.Label.SS_CourseDiscontinuationQueueName;
            oItemData.Reference = oDiscontinuationRequest[0].strCaseID;
            oItemData.SpecificContent = oSpecificContent;
            oWrapper.itemData = oItemData;
            lstResponse.add(CourseDisconCalloutService.sendCallout(JSON.serialize(oWrapper)));
        }
        else{
            lstResponse.add('Access denied as the user does not have access to the Case record or this feature.');
        }
        return lstResponse;        
    }
    
    public static Boolean validateRecordAccess(Id caseId){
        Boolean bReturn = false;
		Case oCase = [SELECT Id FROM Case WHERE Id =: caseId WITH SECURITY_ENFORCED LIMIT 1];
        if(oCase != null){
            bReturn = true;
        }
        return bReturn;
    }

    /**
    * @description Inputs for Request.
    * @author rajesh.punjabi@monash.edu | 25-05-2022 
    **/
    public class CourseDiscontinuationRequest{
        @InvocableVariable
        public String strCaseID;
        @InvocableVariable
        public String strCaseNumber;
        @InvocableVariable
        public String strPersonID;
        @InvocableVariable
        public String strCourseCode;
        @InvocableVariable
        public Date dtDiscontinDate;
        @InvocableVariable
        public String strDiscontinReason;
        @InvocableVariable
        public Date SubmissionDate;
        @InvocableVariable
        public String strOfficerName;
    }
    /**
    * @description Inputs for Response.
    * @author rajesh.punjabi@monash.edu | 25-05-2022 
    **/
    public class CourseDiscontinuationResponse{
        @InvocableVariable
        public String strReturnMessage;
    }
}