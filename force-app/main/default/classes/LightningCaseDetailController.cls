/**************************************************************************************************   
Apex Controller Name :  LightningCaseDetailController
Version              :  1.0                                                                          
Created Date         :  16/06/2017                                                            
Function             :  This controller is for Case Detail component for communities.                                                                         
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    16/06/2017                        Created.
***************************************************************************************************/
public without sharing class LightningCaseDetailController
{
    public static List<attachment> attachmentListNew;
    public static final List<Contact> conList = [SELECT id,Email_Addresses__c,Email FROM contact WHERE Authcate__c !=  null and Authcate__c = : LightningCreateCaseController.currentUser.FederationIdentifier];
    
    /**
    * @Method Name     : getCaseDetails
    * @Input Parameters: case Id
    * @Return Type     : caseWrapper 
    * @Description     : Fetch case details along with email(with attachment) and attachments. 
    **/ 
    @AuraEnabled
    public static caseWrapper getCaseDetails(Id caseId) {
        try {
            CustomURLs__c urls = CustomURLs__c.getInstance();
            Set<Id> emailIdSet = new Set<Id>();
            List<emailWrapper> emailWrapperList = new List<emailWrapper>();
            List<emailWrapper> lastEmailWrapperList = new List<emailWrapper>();
            List<attachmentWrapper> attachmentWrapperList = new List<attachmentWrapper>();
            Set<String> emailSet = new Set<String>();
            Map<String,boolean> isPortalUser = new Map<String,boolean>();
            Map<Id,List<attachmentWrapper>> emailAttachmentMap = new Map<Id,List<attachmentWrapper>>();
            List<Schema.FieldSetMember> caseFields = SObjectType.case.FieldSets.Enquiry_Detail_Field_Community.getFields();
            Map<String, Schema.SObjectType> schemaMap  =  Schema.getGlobalDescribe();
            Schema.SObjectType caseSchema  =  schemaMap.get('Case');
            Map<String, Schema.SObjectField> fieldMap  =  caseSchema.getDescribe().fields.getMap();
            List<fieldWrapper> fieldWrapperList = new List<fieldWrapper>();
            String query  =  'SELECT ';
            String oldConversation = null;        
            List<String> userEmailAddresses = new List<String>();
            if(conList.size()>0) {
                userEmailAddresses = conList[0].Email_Addresses__c != null?conList[0].Email_Addresses__c.split(';'):new List<String>();
            }
            List<emailMessage> emailMsgList = new List<emailMessage>();
            for(Schema.FieldSetMember f : caseFields) {
                query +=  f.getFieldPath() + ', ';
            }
            query = query+'id,subject,Community_Status__c,status,Case_Reference__c,createdBy.Name,Description,recordtype.developerName,(SELECT id,Subject,FROMAddress,TextBody,createddate,FROMName,HtmlBody,ToAddress,CCAddress FROM emailmessages order by createddate desc),(SELECT id,name,ContentType,createdDate FROM attachments order by createddate desc) FROM case WHERE id = :caseId';
            List<case> caseRecList = database.query(query);        
            for(Schema.FieldSetMember f : caseFields) {
                fieldWrapperList.add(new fieldWrapper(f.getLabel(),fieldMap.get(f.getFieldPath()).getDescribe().getType(),caseRecList[0].get(f.getFieldPath()),f.getFieldPath()));
            }
            system.debug('userEmailAddresses is '+userEmailAddresses);
            for(emailmessage message: caseRecList[0].emailmessages) {    
                for(String emailAdd: userEmailAddresses) {
                    if((message.ToAddress != null && message.ToAddress.contains(emailAdd)) ||
                    (message.FROMAddress != null && message.FROMAddress.contains(emailAdd)) ||
                    (message.CCAddress != null && message.CCAddress.contains(emailAdd))) {
                        emailMsgList.add(message);
                        break;
                    }
                }
            }
            system.debug('fieldWrapperList is '+fieldWrapperList);
            for(emailmessage message: emailMsgList) {
                emailSet.add(message.FROMAddress);
                emailIdSet.add(message.Id);
            }
            for(attachment attach: [SELECT id,name,ContentType,createdDate,ParentId FROM attachment WHERE parentId in :emailIdSet order by createddate desc])
            {
                attachmentWrapper attachWrapper = new attachmentWrapper(attach);
                if(emailAttachmentMap.containsKey(attach.ParentId)) {
                    emailAttachmentMap.get(attach.ParentId).add(attachWrapper);
                }
                else {
                    emailAttachmentMap.put(attach.ParentId,new List<attachmentWrapper>{attachWrapper});
                }            
            }
            for(User u: [SELECT id,IsPortalEnabled,email FROM user WHERE email in :emailSet]) {
                isPortalUser.put(u.email,u.IsPortalEnabled);
            }        
            for(Integer i  =  emailMsgList.size() - 1; i > =  0; i--){
                emailmessage message = emailMsgList[i];
                boolean isVisible = emailMsgList.size()< = 5 || i == 0?true:false;
                if(isPortalUser!=null) {
                    emailWrapperList.add(new emailWrapper(message.Id,message.Subject,message.FROMName,message.TextBody,message.createddate,emailAttachmentMap.get(message.Id),isPortalUser.containsKey(message.FROMAddress)?isPortalUser.get(message.FROMAddress):false,caseRecList[0].Case_Reference__c,message.HtmlBody == null?message.TextBody:message.HtmlBody,urls.Email_Body_Seperator__c,isVisible));
                }
            }        
            for(attachment attach: caseRecList[0].attachments) {
                attachmentWrapperList.add(new attachmentWrapper(attach));
            }
            if(emailMsgList.size()>0)
            {
                oldConversation = emailMsgList[0].HtmlBody != null?emailMsgList[0].HtmlBody:emailMsgList[0].TextBody;
            }
            caseWrapper wrap = new caseWrapper(caseRecList[0],attachmentWrapperList,emailWrapperList,Integer.valueOf(urls.Pagination_Size__c),fieldWrapperList,oldConversation,urls.ToName__c,userInfo.getName(),urls.attachmentLink__c);
            system.debug('wrap is '+wrap);
            return wrap; 
        }
         catch(Exception ex) {
            system.debug('Excception is ' + ex.getmessage());
            return null;
        }
    }
    
    /**
    * @Method Name     : updateEnq
    * @Input Parameters: String, Id, boolean
    * @Return Type     : String
    * @Description     : This method reopen/close case and send email to case if reopened. 
    **/
    @AuraEnabled
    public static String updateEnq(String comments, Id caseId, boolean enquiryClosed) {
        try {
            CustomURLs__c settings = CustomURLs__c.getInstance();   
            Set<String> allowedRoles = new Set<String>();
            Set<String> allowedProfile = new Set<String>();
            Set<String> allowedPermissionSet = new Set<String>();
            Set<String> updatableStatuses = new Set<String>();
            updatableStatuses.addAll(Label.CaseStatusEligibleToBeUpdated.split(','));
            if(settings.Permission_Set_for_Assignment_Rule__c != null) {
                allowedPermissionSet.addAll(settings.Permission_Set_for_Assignment_Rule__c.split(','));
            }
            if(settings.Roles_for_Assignment_Rule__c != null) {
                allowedRoles.addAll(settings.Roles_for_Assignment_Rule__c.split(','));
            }
            if(settings.Profile_for_Assignment_Rule__c != null) {
                allowedProfile.addAll(settings.Profile_for_Assignment_Rule__c.split(','));
            }
            User u = [SELECT id,profile.Name,profileId,userrole.developerName FROM user WHERE id = :userInfo.getUserId()];
            List<PermissionSetAssignment> PSAList = [SELECT AssigneeId,Id FROM PermissionSetAssignment WHERE PermissionSet.Name in :allowedPermissionSet and AssigneeId = :userInfo.getUserId()];
            String userEmail = UserInfo.getUserEmail();
            List<Attachment> attachmentList = [SELECT id,name,body,ContentType FROM Attachment WHERE parentId = :caseId and name like '$community$%' and createdbyId = :userInfo.getUserId() and createddate = today];
            
            case caseRec = [SELECT id,IsClosed,RecordType.developerName,Enquiry_Type__c,Category_Level_1__c,Category_Level_2__c,status,ownerId,caseNumber,owner.userrole.name,owner.userrole.DeveloperName,Case_Reference__c,owner.Profile.Name FROM case WHERE id = :caseId];
            
            if(caseRec.status != 'Closed' && caseRec.status != 'Solved' && enquiryClosed) {
                caseRec.Status = caseRec.RecordType.developerName == 'HR'?'Closed':'Solved';
                caseRec.Reason = 'Other';
                caseRec.Enquiry_Type__c = caseRec.Enquiry_Type__c == null || caseRec.Enquiry_Type__c == ''?'Current Course':caseRec.Enquiry_Type__c;
                caseRec.Category_Level_1__c = caseRec.Category_Level_1__c == null || caseRec.Category_Level_1__c == ''?'General Services':caseRec.Category_Level_1__c;
                caseRec.Category_Level_2__c = caseRec.Category_Level_2__c == null || caseRec.Category_Level_2__c == ''?'Abandoned':caseRec.Category_Level_2__c;
                caseRec.Managing_Faculty__c = caseRec.Managing_Faculty__c == null || caseRec.Managing_Faculty__c == ''?'Other':caseRec.Managing_Faculty__c;
                update caseRec;
                caseComment comment = new caseComment();
                comment.CommentBody = 'Customer solved own enquiry via community.';
                comment.parentId = caseRec.Id;
                insert comment;
                return 'sucess';
            }
            
            else if(!enquiryClosed) {                
                //Force to run assignment rule
                if(((caseRec.RecordType.developerName == 'HR' && caseRec.IsClosed) || caseRec.RecordType.developerName != 'HR') && (allowedRoles.contains(u.userrole.developerName) || allowedProfile.contains(u.Profile.Name) || PSAList.size()>0)) {
                    if(caseRec.RecordType.developerName != 'Monash_Connect_Enquiry' && caseRec.status != 'Open'){   
                        Database.DMLOptions dmo  =  new Database.DMLOptions();
                        dmo.assignmentRuleHeader.useDefaultRule  =  true;
                        caseRec.setOptions(dmo);
                    }
                }                 
                if(caseRec.RecordType.developerName == 'HR' && updatableStatuses.contains(caseRec.Status)) { 
                    caseRec.Status = 'Updated';
                }
                else if(caseRec.RecordType.developerName == 'HR' && caseRec.IsClosed) {
                    caseRec.Status = 'Reopened';
                }
                else if(caseRec.RecordType.developerName != 'HR'){
                    if(caseRec.Status != 'Open' && (caseRec.RecordType.developerName == 'Monash_Connect_Enquiry' || caseRec.RecordType.developerName == 'Special_Consideration' || caseRec.RecordType.developerName == 'SR_Enquiry')){
                        caseRec.Latest_Inbound_Email__c = System.NOW();
                        
                        //Run the assignment rule
                        if(caseRec.RecordType.developerName == 'Monash_Connect_Enquiry' || caseRec.RecordType.developerName == 'Special_Consideration'){
                            Database.DMLOptions dmo  =  new Database.DMLOptions();
                            dmo.assignmentRuleHeader.useDefaultRule  =  true;
                            caseRec.setOptions(dmo);
                        }
                    }
                    caseRec.Status = 'Open';
                }
                update caseRec;                
            }
            
            if(comments != null && comments != '') {
                List<Emailmessage> emailList = [SELECT id,TextBody,HTMLBody FROM emailmessage WHERE ParentId = :caseRec.Id and (FROMAddress = :userEmail or ToAddress = :userEmail) order by createddate desc limit 1];
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                List<String> toAddresses = new List<String>();                
                message.setSenderDisplayName(UserInfo.getName());
                message.setWhatId(CaseId);                
                if(emailList.size()>0) {
                    message.setSubject('RE: ' + UserInfo.getName()+' commented on case '+caseRec.caseNumber+' '+caseRec.Case_Reference__c);
                    message.setHtmlBody(comments+settings.Email_Body_Seperator__c+emailList[0].HTMLBody);
                    message.setPlainTextBody(comments+settings.Email_Body_Seperator__c+emailList[0].TextBody);
                }     
                else {
                    message.setSubject(UserInfo.getName()+' commented on case '+caseRec.caseNumber+' '+caseRec.Case_Reference__c);
                    message.setHtmlBody(comments);
                    message.setPlainTextBody(comments);
                }           
                toAddresses.add(caseRec.RecordType.developerName == 'HR'?settings.EmailToCase__c:settings.EmailToCaseNonHR__c);
                if(conList.size()>0) {
                    if(conList[0].email != null) {
                        toAddresses.add(conList[0].email);
                    }
                }
                message.setToAddresses(toAddresses);
                List<Messaging.Emailfileattachment> fileAttachments  =  new List<Messaging.Emailfileattachment>();
                for (Attachment a : attachmentList)
                {
                    Messaging.Emailfileattachment efa  =  new Messaging.Emailfileattachment();
                    efa.setFileName(a.Name.remove('$community$'));
                    efa.setBody(a.Body);
                    efa.setContentType(a.contentType);
                    fileAttachments.add(efa);
                }
                message.setFileAttachments(fileAttachments);
                Messaging.SendEmailResult[] results  =  Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {message});
                system.debug('results is '+results);    
            }
            delete attachmentList;
        }
        catch(Exception ex) {
            ExLog.add('ReOpen Enquiry','LightningUpdateEnquiryController','updateEnq', ex.getmessage());
            return 'failure';
        }        
        return 'success';
    }   
    
    @AuraEnabled
    public static String closeEnq(Id caseId) { 
        try {
            case caseRec = [SELECT id,RecordType.developerName,Enquiry_Type__c,Category_Level_1__c,Category_Level_2__c,status,ownerId,caseNumber,owner.userrole.name,owner.userrole.DeveloperName,Case_Reference__c,owner.Profile.Name FROM case WHERE id = :caseId];
            caseRec.Status = caseRec.RecordType.developerName == 'HR'?'Closed':'Solved';
            caseRec.Reason = 'Other';
            caseRec.Enquiry_Type__c = caseRec.Enquiry_Type__c == null || caseRec.Enquiry_Type__c == ''?'Current Course':caseRec.Enquiry_Type__c;
            caseRec.Category_Level_1__c = caseRec.Category_Level_1__c == null || caseRec.Category_Level_1__c == ''?'General Services':caseRec.Category_Level_1__c;
            caseRec.Category_Level_2__c = caseRec.Category_Level_2__c == null || caseRec.Category_Level_2__c == ''?'Abandoned':caseRec.Category_Level_2__c;
            caseRec.Managing_Faculty__c = caseRec.Managing_Faculty__c == null || caseRec.Managing_Faculty__c == ''?'Other':caseRec.Managing_Faculty__c;
            update caseRec;
            caseComment comment = new caseComment();
            comment.CommentBody = 'Customer solved own enquiry via community.';
            comment.parentId = caseRec.Id;
            insert comment;
            system.debug('caseRec is '+caseRec);
            return 'sucess';  
        } 
        catch(Exception ex) {
            system.debug('Excception is ' + ex.getmessage());
            return 'failure';
        }
    }
    /**
    * @Method Name     : saveTheFile
    * @Input Parameters: Id, String, String, String
    * @Return Type     : String
    * @Description     : This method will add attachment to required parent. 
    **/
    @AuraEnabled
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType,String fileId) {          
        return saveTheChunk(parentId,fileName, base64Data,contentType,fileId);     
    }  
    /**
    * @Method Name     : saveTheChunk
    * @Input Parameters: Id, String, String, String, String
    * @Return Type     : Id
    * @Description     : This method will return the fileId having concatenated data. 
    **/  
    @AuraEnabled
    public static Id saveTheChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) { 
        try {
            if (fileId  ==  '' || fileId  == null) {
                fileId = saveTheFile(parentId, fileName, base64Data, contentType);
            } else {
                fileId = appendToFile(fileId, base64Data);
            }
            return Id.valueOf(fileId);
        }
        catch(Exception ex) {
            system.debug('Excception is ' + ex.getmessage());
            return null;
        }
    }
    /**
    * @Method Name     : appendToFile
    * @Input Parameters: Id, String
    * @Return Type     : Id
    * @Description     : This method will add data to existing attachment. 
    **/  
    private static Id appendToFile(Id fileId, String base64Data) {
        try {
            base64Data  =  EncodingUtil.urlDecode(base64Data, 'UTF-8');        
            Attachment a  =  [
            SELECT Id, Body
            FROM Attachment
            WHERE Id  =  :fileId
            ];        
            String existingBody  =  EncodingUtil.base64Encode(a.Body);
            a.Body  =  EncodingUtil.base64Decode(existingBody + base64Data);         
            update a;
            return a.Id;
        }
        catch(Exception ex) {
            system.debug('Excception is ' + ex.getmessage());
            return null;
        }
    }
    /**
    * @Method Name     : saveTheFile
    * @Input Parameters: Id, String, String, String
    * @Return Type     : Id
    * @Description     : This method will save the attachment. 
    **/  
    @AuraEnabled
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) { 
        try {
            base64Data  =  EncodingUtil.urlDecode(base64Data, 'UTF-8');        
            Attachment a  =  new Attachment();
            a.parentId  =  parentId;        
            a.Body  =  EncodingUtil.base64Decode(base64Data);
            a.Name  =  fileName;
            a.ContentType  =  contentType;        
            insert a;        
            return a.Id;
        }
        catch(Exception ex) {
            system.debug('Excception is ' + ex.getmessage());
            return null;
        }
    } 
     /*******************************************************************************
    * @author       Vaibhav B, PwC
    * @date         9.Spetember.2017       
    * @description  method to return allowed File Types
    * @Input Parameters: 
    * @return type: List<string>
    * @revision         
    *******************************************************************************/
    
    @AuraEnabled
    public static List<string> getAllowedFileTypes() {
        try {
            return Label.AllowedAttachmentTypes.replaceAll(' ','').split(',');
        }
        catch(Exception ex) {
            system.debug('Excception is ' + ex.getmessage());
            return new List<String>();
        }
    }
}