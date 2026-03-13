/*******************************************************************************
* @author       Anterey Custodio
* @date         2.Mar.2017         
* @description  extension class for RedirectToEmailSend global action page
* @revision     
*******************************************************************************/
public class RedirectToEmailSendCE {
    public String emailToUse {get;set;}
    private Case caseRecord {get;set;}
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         2.Mar.2017         
    * @description  on initialise, get the custom setting that contains the list of 
    *                   emails the users cannot reply to
    * @revision     
    *******************************************************************************/
    public RedirectToEmailSendCE (ApexPages.StandardController controller) {
        caseRecord = [  SELECT Id, Contact.Email_To__c, SuppliedEmail 
                        FROM Case 
                        WHERE Id =: controller.getRecord().Id];
        emailToUse = caseRecord.SuppliedEmail;
        //this will return a record if the Web Email field is on the exclusion list
        List<Enquiry_Email_Exclusion_List__c> excludedEmailList = [ SELECT  Name 
                                                                    FROM    Enquiry_Email_Exclusion_List__c 
                                                                    WHERE   Name =: caseRecord.SuppliedEmail ];
        //if the supplied email is blank OR if the Web email is included on the exclusion list, use the contact's email address
        if ((caseRecord.SuppliedEmail == null || caseRecord.SuppliedEmail == '') ||
            !excludedEmailList.isEmpty()) {
            //check the contact first before referencing
            emailToUse = (caseRecord.ContactId != null) ? caseRecord.Contact.Email_To__c : '';
        }                                               
    }
}