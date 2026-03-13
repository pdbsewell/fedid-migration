/**
 * @description       : HTTP Callout to MIX/RPA to process confirmation Of Enrolment
 * 						This is used in screen flow(Process Confirmation Of Enrolment Request) which 
 * 						opens on click of a quick action(Process COE Request)
 * 						Only Users who have custom permission "Monash_Connect_Process_COE_Request_Custom_Permission" assigned 
 * 						should be able to access this functionality.
 * @author            : Seeva Singh
 * @group             : 
 * @last modified on  : 01-03-2023
 * @last modified by  : Seeva
**/
public with sharing class ProcessRequestForCOE {
    /**
    * @description Send Confirmation Of Enrolment to Callista.
    * @author Seeva | 01-03-2023
    **/
    @InvocableMethod(label='Process COE Request' description='Returns the response message.')
    public static List<String> processConfirmationOfEnrolment(List<COERequest> ObjCOERequest){
        List<String> lstResponse = new List<String>();
        if(validateRecordAccess(ObjCOERequest[0].strCaseID) && FeatureManagement.checkPermission('Monash_Connect_Process_COE_Request_Custom_Permission')) {
            ProcessCOERequestWrapper oWrapper = new ProcessCOERequestWrapper();
            ProcessCOERequestWrapper.SpecificContent oSpecificContent = new ProcessCOERequestWrapper.SpecificContent();
            ProcessCOERequestWrapper.ItemData oItemData = new ProcessCOERequestWrapper.ItemData();
            oSpecificContent.uniCRMCaseID = ObjCOERequest[0].strCaseID;
            oSpecificContent.uniCRMEnquiryID = ObjCOERequest[0].strCaseNumber;
            oSpecificContent.personID = ObjCOERequest[0].strPersonID;
            oSpecificContent.CoEReason = ObjCOERequest[0].strCOEReason;
            oSpecificContent.monashConnectOfficerEmail = ObjCOERequest[0].strOfficerName;
            oSpecificContent.DiscontinCourseCode = ObjCOERequest[0].strCourseCode;
            oItemData.Name = System.Label.COERequestQueueName;
            oItemData.Reference = ObjCOERequest[0].strCaseID;
            oItemData.SpecificContent = oSpecificContent;
            oWrapper.itemData = oItemData;
            lstResponse.add(COERequestCalloutService.sendCallout(JSON.serialize(oWrapper)));
        }
        else{
            lstResponse.add('Access denied as the user does not have access to the Case record or this feature.');
        }
        return lstResponse;        
    }
    
    public static Boolean validateRecordAccess(Id caseId){
        Boolean bReturn = false;
		Case oCase = new Case();
        oCase = [SELECT Id FROM Case WHERE Id =: caseId WITH SECURITY_ENFORCED LIMIT 1];
        if(oCase != null){
            bReturn = true;
        }
        return bReturn;
    }

    /**
    * @description Inputs for Request.
    * @author Seeva | 01-03-2023 
    **/
    public class COERequest{
        @InvocableVariable
        public String strCaseID;
        @InvocableVariable
        public String strCaseNumber;
        @InvocableVariable
        public String strPersonID;
        @InvocableVariable
        public String strCourseCode;
        @InvocableVariable
        public String strCOEReason;
        @InvocableVariable
        public String strOfficerName;
    }
    /**
    * @description Inputs for Response.
    * @author Seeva | 01-03-2023 
    **/
    public class CourseDiscontinuationResponse{
        @InvocableVariable
        public String strReturnMessage;
    }
}