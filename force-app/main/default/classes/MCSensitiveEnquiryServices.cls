/**
 * @author          Russell Cadapan
 * @description     A controller class for the Email Message Encrypt and Decrupt button
 * @revision        05/08/2019 - Created
 *                  03/01/2020 - APRivera - Additional validation on NULL HTML/Text body
 *                  29/07/2020 - APRivera - Replaced masking data to clearing it totally.
                                            Removed Connect officers from users with access to the feature.
                    21/07/2022 - VVairavan - EPCP- 2314. Access to Student Finace team to use this feature.
 */
 public class MCSensitiveEnquiryServices{    
    
    /**
     * @author          Russell Cadapan
     * @description     Wrapper Class for Lightning Component variable references
     * @revision        05/08/2019 - Created
     */
    public class thisWrapper{
        @AuraEnabled
        public String encryptionKey {get;set;} // encryption Key
        @AuraEnabled
        public String encryptedData {get;set;} // encrypted data
        @AuraEnabled
        public Boolean isEncrypted {get;set;} // encrypted data
        @AuraEnabled
        public String emailMessageId {get;set;} // email message Id
        @AuraEnabled
        public Boolean hasAccess {get;set;} // user access
        
        // wrapper constructor
        public thisWrapper(String encryptionKey, String encryptedData, Boolean isEncrypted, String emailMessageId, Boolean hasAccess){
            // set encryption key
            this.encryptionKey = encryptionKey;
            this.encryptedData = encryptedData;
            this.isEncrypted = isEncrypted;
            this.emailMessageId = emailMessageId;
            this.hasAccess = hasAccess;
        }
    }
    
    /**
     * @author          Russell Cadapan
     * @description     Encryption Key getter
     * @revision        05/08/2019 - Created
     */
    public static MC_Encryption_Settings__c encryptionSettings{
        get{
            return MC_Encryption_Settings__c.getOrgDefaults();
        }
        set;
    }
    
    /**
     * @author          Russell Cadapan
     * @description     Manage method for the Encrypt button
     * @revision        05/08/2019 - Created
     */
    @AuraEnabled
    public static thisWrapper manageSensitiveData(Id emailMessageId){
        thisWrapper wrapper;
        
        if(emailMessageId != null){
            
            // email message query builder
            String queryString = CommonUtilities.queryBuilder('EmailMessage') + ' WHERE Id =: emailMessageId';
            // email message query
            List<EmailMessage> emailMessages = Database.query(queryString);
            // clone and delete the original email message
            if(!emailMessages.isEmpty()){     
                EmailMessage originalEmailMessage = emailMessages[0];
                if(String.isBlank(originalEmailMessage.Sensitive_Information__c)){
                    return new thisWrapper(encryptionSettings.Key__c, originalEmailMessage.Sensitive_Information__c, false, originalEmailMessage.Id, true);
                }
                
                // if the email is not yet encrypted, encrypt it
                if(!originalEmailMessage.Is_Encrypted__c){
                
                    // if the user is not an MC officer/leader
                    if(!checkEncryptionAccess()){
                        return new thisWrapper(encryptionSettings.Key__c, originalEmailMessage.Sensitive_Information__c, originalEmailMessage.Is_Encrypted__c, originalEmailMessage.Id, false);
                    }
                    
                    // cloning  
                    EmailMessage newEmailMessage = cloneAndMaskSensitiveData(emailMessages[0]);
                    // deleting
                    delete emailMessages[0];
                    
                    // generate the wrapper with the arguments mapped
                    wrapper = new thisWrapper(encryptionSettings.Key__c, originalEmailMessage.Sensitive_Information__c, originalEmailMessage.Is_Encrypted__c, newEmailMessage.Id, true);
                }
                // if the email is already encrypted, return the original email message
                else{
                    // generate the wrapper with the arguments mapped
                    wrapper = new thisWrapper(encryptionSettings.Key__c, decryptData(originalEmailMessage.Sensitive_Information__c), originalEmailMessage.Is_Encrypted__c, originalEmailMessage.Id, checkDecryptionAccess());
                }
            }
        }
        
        // return the new email message Id for page navigation
        return wrapper;
    }
    
    /**
     * @author          Russell Cadapan
     * @description     Cloning and masking of sensitive information
                        1) clones and mask the email message content with the identified sensitive information
                        2) encrypts sensitive information field
     * @revision        05/08/2019 - Created
     */
    private static EmailMessage cloneAndMaskSensitiveData(EmailMessage originalEmailMessage){
        
        // clone the original message preserving timestamps
        EmailMessage newEmailMessage = originalEmailMessage.clone(false, false, true, false);
        newEmailMessage.ValidatedFromAddress = null;
        
        // retrieve related enquiry and it's client question field where the identified sensitive information potentially is stored.
        Case relatedEnquiry = [SELECT Description FROM Case WHERE Id =: originalEmailMessage.ParentId];
        
        // masking email message content
        String strSensitiveData = newEmailMessage.Sensitive_Information__c;
        List<String> listSensitiveData = strSensitiveData.split('\n');
        
        
        // mask each sensitive data instance from the email message content Html and Text body
        for(String s: listSensitiveData){ //encryptionSettings.Mask_Format__c
        if(!String.isBlank(newEmailMessage.HtmlBody)){
            newEmailMessage.HtmlBody = newEmailMessage.HtmlBody.replaceAll(s.trim(), '');
        }
        if(!String.isBlank(newEmailMessage.TextBody)){
            newEmailMessage.TextBody = newEmailMessage.TextBody.replaceAll(s.trim(), '');
        }
            relatedEnquiry.Description = String.valueOf(relatedEnquiry.Description).replaceAll(s.trim(), '');
        }
        
        // data encryption
        encryptData(newEmailMessage);
        
        // cloned email message insertion
        insert newEmailMessage;
        
        // update the enquiry
        update relatedEnquiry;
        
        return newEmailMessage;
    }
    
    /**
     * @author          Russell Cadapan
     * @description     Encryption of the sensitive information
     * @revision        05/08/2019 - Created
     */
    private static void encryptData(EmailMessage newEmailMessage){
        // define the sensitive data
        String stringTFN = newEmailMessage.Sensitive_Information__c;
        
        // encrypt the sensitive data
        Blob encryptedData = Crypto.encryptWithManagedIV(encryptionSettings.Algorithm__c, Blob.valueOf(encryptionSettings.Key__c), Blob.valueOf(stringTFN));
        
        // encode the encrypted data
        String encodedDataText = EncodingUtil.base64Encode(encryptedData);
        
        //store back the encoded data into the field        
        newEmailMessage.Sensitive_Information__c = encodedDataText;
        newEmailMessage.Is_Encrypted__c = true;
                
    }
    
    /**
     * @author          Russell Cadapan
     * @description     Decryption of the sensitive information
     * @revision        05/08/2019 - Created
     */
     @AuraEnabled
    public static String decryptData(String sensitiveData){
        
        // define the encoded data and decode it
        Blob decodedData = EncodingUtil.base64Decode(sensitiveData);
        
        // decrypt the decoded data
        Blob decryptedData = Crypto.decryptWithManagedIV(encryptionSettings.Algorithm__c, Blob.valueOf(encryptionSettings.Key__c), decodedData);
        
        // parse the decrypted data to string
        String decryptedDataText = decryptedData.toString();
        
        // return the decrypted value
        return decryptedDataText;
    }
    
    private static Boolean checkDecryptionAccess(){
        Set<Id> allowedUsers = new Set<Id>();
        
        for(GroupMember gm: [SELECT UserOrGroupId FROM GroupMember WHERE GroupId =: encryptionSettings.Decryption_Group_Id__c]){
            allowedUsers.add(gm.UserOrGroupId);
        }
        
        if(allowedUsers.contains(UserInfo.getUserId())){
            return true;
        }
        
        return false;
    }
    
    private static Boolean checkEncryptionAccess(){
        Set<Id> allowedUsers = new Set<Id>();
        
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        
        for(PermissionSetAssignment psa: [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name IN ('Monash_Connect_Leader','EncryptEmailMessages')]){
            allowedUsers.add(psa.AssigneeId);
        }
        
        if(allowedUsers.contains(UserInfo.getUserId()) || UserInfo.getProfileId() == adminProfileId){
            return true;
        }
        
        return false;
    }
}