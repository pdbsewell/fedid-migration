/**
 * @description       : Invocable Class; Flow [Record-Trigger: Key Dates After Update (MRO) with Async]
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 07-11-2023
 * @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class KeyDateInvocable {
    
    /**
    * @description 
    * @author rajesh.punjabi@monash.edu | 07-11-2023 
    * @param request 
    * @return List<String> 
    **/
    @InvocableMethod(label='Update Enquiry KeyDate' description='Update Enquiry KeyDate when KeyDates DueDate is modified.')
    public static List<String> updateEnquiryKeyDate(List<KeyDateRequest> request){
        List<String> lstResponse = new List<String>();
		ID jobID = System.enqueueJob(new KeyDateEnquiryQueuable(request.get(0).idKeyDateId, request.get(0).dKeyDate_Date));
        
        lstResponse.add('Success');
        return lstResponse;
    }
    
    /**
     * @description       : Request Wrapper
     * @author            : rajesh.punjabi@monash.edu
     * @group             : 
     * @last modified on  : 07-11-2023
     * @last modified by  : rajesh.punjabi@monash.edu
    **/
    public class KeyDateRequest{        
        @InvocableVariable
        public Id idKeyDateId;

        @InvocableVariable
        public Date dKeyDate_Date;
    }
}