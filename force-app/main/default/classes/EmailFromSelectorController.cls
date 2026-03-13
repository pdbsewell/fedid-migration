/*******************************************************************************
* @author       Angelo Rivera
* @date         22/10/2018
* @group        Monash Connect
* @description  purpose is a controller extension to extract Email From Metadata
* @revision     1.0 - APRivera - Initial create.
* @revision     1.1 - JPadda - Added Faculty filter
* @revision     1.2 - Seeva - Added saveDefaultFromAddress method
* @revision     1.3 - DYU   - Added School Filter for MNHS and Science faculties
*******************************************************************************/
public class EmailFromSelectorController {
    @AuraEnabled
    public static ThisWrapperClass init(String recordId) {
        ThisWrapperClass thisWrapper = new ThisWrapperClass();
        
        //Get component enquiry record type's developername
        Case enquiry = [SELECT Id, Faculty__c, School__c, RecordType.DeveloperName FROM Case WHERE Id = :recordId LIMIT 1];
        
        //Retrieve email from addresses based on the enquiry's record type
        thisWrapper.lstEmailFrom = getEmailFrom(enquiry);
        /* Added For Graduate Research User Custom Permission Check */
        if(enquiry.RecordType.DeveloperName =='MGE_Enquiry' || enquiry.RecordType.DeveloperName =='Faculty_Graduate_Research'){
            thisWrapper.graduateResearchUserPermission = hasGraduateResearchCustomPermission();
        }
        return thisWrapper;
    }
    
    public static List<Enquiry_Email_From_Address_Mapping__mdt> getEmailFrom(Case enquiry) {
        List<Enquiry_Email_From_Address_Mapping__mdt> lstEmailFrom = new List<Enquiry_Email_From_Address_Mapping__mdt>();
        for (Enquiry_Email_From_Address_Mapping__mdt enquiryFromMapping : [
            SELECT
            Id,
            MasterLabel,
            Applied_to_Faculty__c,
            Applied_to_School__c,
            Active__c,
            From_Address__c,
            Order__c,
            Record_Type_DeveloperName__c,
            Send_Email_Quick_Action_API_Name__c
            FROM Enquiry_Email_From_Address_Mapping__mdt
            WHERE Active__c = TRUE AND Record_Type_DeveloperName__c = :enquiry.RecordType.DeveloperName
            ORDER BY From_Address__c, Order__c ASC
        ]) {
            // if mapping has additional filter for Faculty field
            if(enquiryFromMapping.Applied_to_School__c != null) {
                if (enquiry.School__c == enquiryFromMapping.Applied_to_School__c) {
                    lstEmailFrom.add(enquiryFromMapping);
                 }
            } else if (enquiryFromMapping.Applied_to_Faculty__c != null) {
                if (enquiry.Faculty__c == enquiryFromMapping.Applied_to_Faculty__c) {
                    lstEmailFrom.add(enquiryFromMapping);
                }
            } else
                lstEmailFrom.add(enquiryFromMapping);
        }
        return lstEmailFrom;
    }
    /* @description To check if the logged in user has custom permission.
    * @param void
    * @return true if the logged in user has Graduate_Research_User custom permission
    */ 
    @AuraEnabled
    public static Boolean hasGraduateResearchCustomPermission(){         
        return FeatureManagement.checkPermission('Graduate_Research_User');  
    }
    /* @description Update Default From Address on User Level
    * @param defaultEmail the email address selected by User
    * @return 
    */
    @AuraEnabled
    public static void saveLatestEnquiryFromAddress(String defaultEmail){ 
        User loggedinUser =[Select id,Latest_Selected_Enquiry_From_Address__c from User where id=:UserInfo.getUserId()];
        if(loggedinUser != null)
        {
            if(!string.isEmpty(defaultEmail) && loggedinUser.Latest_Selected_Enquiry_From_Address__c != defaultEmail)
            {
                loggedinUser.Latest_Selected_Enquiry_From_Address__c = defaultEmail;
            } 
            update loggedinUser;
        }
    }
    public class ThisWrapperClass {
        @AuraEnabled
        public List<Enquiry_Email_From_Address_Mapping__mdt> lstEmailFrom { get; set; }
        @AuraEnabled
        public Boolean graduateResearchUserPermission {get; set;}
    }
}