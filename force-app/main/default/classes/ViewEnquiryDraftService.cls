/**
 * @author          Kristian Vegerano
 * @description     Apex controller class for ViewEnquiryDraft lightning component
 * @history         08/11/2018
 *                  27/11/2018 - Ven V - Removed the Filter to retrieve the Last Modified Email Draft against the Case.
 */
public class ViewEnquiryDraftService {
    
    @AuraEnabled 
    public static String retrieveOwnerDraftEmailMessageHtmlBody(String enquiryId, String ownerId) {
        String emailHtmlBody;
        
        for(EmailMessage loopEmailMessage : [SELECT Id, Subject, FromAddress, ToAddress, CcAddress, BccAddress, TextBody, HtmlBody, Parent.RecordType.DeveloperName
                                             FROM EmailMessage WHERE ParentId = :enquiryId AND Status = '5' ORDER BY LastModifiedDate DESC LIMIT 1]){
            emailHtmlBody = loopEmailMessage.HtmlBody;
        }
        
        return emailHtmlBody;
    }
    
    @AuraEnabled 
    public static String retrieveRelevantEmailComposer(String enquiryRecordTypeDeveloperName) {
        String emailComposerApiName;
        
        for(Enquiry_Email_From_Address_Mapping__mdt mdt : [SELECT Id, MasterLabel, Active__c, From_Address__c, Order__c, Record_Type_DeveloperName__c, Send_Email_Quick_Action_API_Name__c 
                                                           FROM Enquiry_Email_From_Address_Mapping__mdt
                                                           WHERE Active__c = true AND Record_Type_DeveloperName__c = :enquiryRecordTypeDeveloperName
                                                           ORDER BY Order__c ASC LIMIT 1]){
            emailComposerApiName = mdt.Send_Email_Quick_Action_API_Name__c;
        }
        
        return emailComposerApiName;
    }
    
}