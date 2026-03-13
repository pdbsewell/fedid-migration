/**************************************************************************************************   
Apex Controller Name :  LightningUpdateEnquiryController 
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This class will re open the case.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    17/05/2017                        Created.
***************************************************************************************************/
public without sharing class LightningUpdateEnquiryController {

    /**
    * @Method Name     : updateEnq
    * @Input Parameters: String, Id, boolean
    * @Return Type     : String
    * @Description     : This method updates case and runs assignment rule is owner has role monash connect officer other than posting feeds to case. 
    **/
    @AuraEnabled
    public static String updateEnq(String comments, Id caseId, boolean enquiryClosed) {
        CustomURLs__c settings=CustomURLs__c.getInstance();   
        caseComment newCaseComment=new caseComment();
        try
        {
            List<case> caseList=[select id,status,ownerId,caseNumber,owner.userrole.name,owner.userrole.DeveloperName,Case_Reference__c from case where id=:caseId];
            if(caseList.size()==0) {
                return null;
            }
            
            case caseRec=caseList[0];
            if(caseRec.status!='Closed' && enquiryClosed) {
                caseRec.Status='Closed';
                caseRec.Reason='Other';
                update caseRec;
                //return 'sucess';
            } else if(!enquiryClosed && (caseRec.status=='Closed' || caseRec.status=='Awaiting Customer Feedback')) {
                caseRec.Status='Open';
                //Force to run assignment rule
                if(caseRec.owner.userrole.DeveloperName=='Monash_Connect_Officer') {
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule = true;
                    caseRec.setOptions(dmo);  
                } 
                update caseRec;                
            }
            
            if(comments!=null && comments!='') {
                string commentString = comments + '</br> '+caseRec.Case_Reference__c;
                Messaging.SingleEmailMessage message=new Messaging.SingleEmailMessage();
                message.setHtmlBody(commentString);
                message.setPlainTextBody(commentString);
                message.setSubject('Enquiry updated by '+UserInfo.getName());
                message.setSenderDisplayName(UserInfo.getName());
                message.setWhatId(CaseId);
                message.setToAddresses(new List<String>{settings.EmailToCase__c});
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {message});
                system.debug('results is '+results);                 
            }
        }
        catch(Exception ex) {
            ExLog.add('ReOpen Enquiry','LightningUpdateEnquiryController','updateEnq', ex);
            return 'failure';
        }
        
        return 'sucess';
    } 
    
    @AuraEnabled
    public static boolean isUserLoggedIn()
    {
        Profile prof=[select id,name from profile where id =:userInfo.getProfileId()];
        return prof.name == System.Label.Guest_User_Profile_Name?false:true;
    }
    
        /**
    * @Method Name     : getSSOURL
    * @Input Parameters: none
    * @Return Type     : CustomURLs__c 
    * @Description     : This method custom setting storing external urls. 
    **/ 
    @AuraEnabled
    public static CustomURLs__c getSSOURL()
    {
        CustomURLs__c urls=CustomURLs__c.getInstance();
        return urls;
    }
    
    @AuraEnabled
    public static boolean getCaseStatus(Id caseId) {
        List<case> caseList=[select id,status from case where id=:caseId];
        if(caseList.size()==0) {
            return null;
        }
        return  caseList[0].Status=='Closed'?false:true;
    }
}