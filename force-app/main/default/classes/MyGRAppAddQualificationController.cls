/**
 * @author      Vishal Gupta
 * @description controller for MyGRAppAddQualification lwc which shows the existing contact 
 *              qualifications for Graduate research and performs dmls on contact qualifications
 * @group       My App Community Services for graduate research
 * @created on  29/07/2024
 */
public with sharing class MyGRAppAddQualificationController {

    /**
     * @description reusable function to get picklist options for lightning components
     * @return Map<String, Object>
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPicklistValues(){
        Map<String, Object> pickListValues = new Map<String, Object>();
        Schema.DescribeFieldResult grQualificationTypePickList = MyGRAppSetting__mdt.Qualification_Type__c.getDescribe();
        pickListValues.put('QUAL_TYPE', populatePicklistAsOptions(grQualificationTypePickList));
        
        Schema.DescribeFieldResult grAwardNamePickList = MyGRAppSetting__mdt.Award_Name__c.getDescribe();
        pickListValues.put('AWARD_NAME', populatePicklistAsOptions(grAwardNamePickList));

        Schema.DescribeFieldResult grMusicPickList = MyGRAppSetting__mdt.Performance_or_Composition__c.getDescribe();
        pickListValues.put('PERFORMANCE_COMPOSITION', populatePicklistAsOptions(grMusicPickList));
        
        Schema.DescribeFieldResult grMusicStatusPickList = MyGRAppSetting__mdt.Music_Status__c.getDescribe();
        pickListValues.put('MUSIC_STATUS', populatePicklistAsOptions(grMusicStatusPickList));

        Schema.DescribeFieldResult grPublicationStatusPickList = MyGRAppSetting__mdt.Publication_Status__c.getDescribe();
        pickListValues.put('PUBLICATION_STATUS', populatePicklistAsOptions(grPublicationStatusPickList));

        Schema.DescribeFieldResult grPublicationTypePickList = MyGRAppSetting__mdt.Publication_Type__c.getDescribe();
        pickListValues.put('PUBLICATION_TYPE', populatePicklistAsOptions(grPublicationTypePickList));

        Schema.DescribeFieldResult grTheatrePerformanceStatusPickList = MyGRAppSetting__mdt.Theatre_Performance_Status__c.getDescribe();
        pickListValues.put('PERFORMANCE_STATUS', populatePicklistAsOptions(grTheatrePerformanceStatusPickList));

        Schema.DescribeFieldResult grCreativeWorkStatusPickList = MyGRAppSetting__mdt.Creative_Work_Status__c.getDescribe();
        pickListValues.put('CREATIVE_WORK_STATUS', populatePicklistAsOptions(grCreativeWorkStatusPickList));

        Schema.DescribeFieldResult grExhibitionTypePickList = MyGRAppSetting__mdt.Exhibition_Type__c.getDescribe();
        pickListValues.put('EXHIBITION_TYPE', populatePicklistAsOptions(grExhibitionTypePickList));

        Schema.DescribeFieldResult grTenurePickList = Contact_Qualification__c.Tenure__c.getDescribe();
        pickListValues.put('TENURE', populatePicklistAsOptions(grTenurePickList));

        Schema.DescribeFieldResult grLanguagePickList = Contact_Qualification__c.Language__c.getDescribe();
        pickListValues.put('LANGUAGE', populatePicklistAsOptions(grLanguagePickList));

        Schema.DescribeFieldResult grPublisherTypePickList = Contact_Qualification__c.Type_of_publisher__c.getDescribe();
        pickListValues.put('PUBLISHER_TYPE', populatePicklistAsOptions(grPublisherTypePickList));

        Schema.DescribeFieldResult grSoloOrGroupExhibitionList = Contact_Qualification__c.Solo_or_Group_Exhibition__c.getDescribe();
        pickListValues.put('EXHIBITION_SOLO_GROUP', populatePicklistAsOptions(grSoloOrGroupExhibitionList));

        List<Map<String,String>> countries= CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_SAAC,false);
        pickListValues.put('COUNTRY_OPTIONS', countries);

        return pickListValues;
    }

    /**
     * @description reusable function to get picklist options for lightning components
     *
     * @param fieldResult
     *
     * @return List<Map<String,String>>
     */
    private static List<Map<String,String>> populatePicklistAsOptions(Schema.DescribeFieldResult fieldResult)
    {
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Map<String,String>> options = new List<Map<String,String>> ();
        for( Schema.PicklistEntry f : ple)
        {
            Map<String,String> mapOption = new Map<String, String>();
            mapOption.put('value', f.getValue());
            mapOption.put('label', f.getLabel());

            options.add(mapOption);
        }
        return options;
    }

    /**
     * @description get declaration options as a string for my.app HDR applicants
     * @return      List<MyGRAppSetting__mdt> returns all the declaration options from metadata
     * @author      Sethu venna
     * @revision    created - 09/10/2024 - Initial version
     */
    @AuraEnabled(cacheable=true)
    public static List<MyGRAppSetting__mdt> fetchDeclarationOptions()
    {
        return [SELECT Declaration_Text__c, Declaration_Option_Order__c 
                FROM MyGRAppSetting__mdt 
                WHERE Declaration_Option_Order__c != NULL AND IsDeleted__c = false
                ORDER BY Declaration_Option_Order__c ASC];
    }

    /**
     * @description function to get Contact Qualifications options for Graduate Research
     *
     * @param applicationId
     * @param recordTypeName
     * @return List<Contact_Qualification__c>
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact_Qualification__c> getContactQualifications(Id applicationId, String recordTypeName){
        Id recordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
        List<Contact_Qualification__c> qualifications = new List<Contact_Qualification__c>();
        for(Contact_Qualification__c cq : new ContactQualificationsSelector().selectByApplicationId(new Set<Id>{applicationId})){
            if(cq.RecordTypeId == recordTypeId) {
                qualifications.add(cq);
            }
        }
        return qualifications;
    }

    /**
     * @description function to upsert the Contact Qualifications options for Graduate Research
     *
     * @param contactId
     * @param applicationId
     * @param contactQualification
     * @param recordTypeName
     *
     * @return  Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> upsertQualificationToContact(Id contactId, Id applicationId, Contact_Qualification__c contactQualification, String recordTypeName)
    {   
        //authentication for the applicant
        Application__c app = [SELECT Applicant__c FROM Application__c WHERE Id=:applicationId AND Status__c = 'Draft'];
        if(!isRecordOwnedByTheUser(app)) {
            throw new AuraHandledException('Invalid application');
        }

        //Guard
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{contactId,applicationId})) {return unsafeParameterMessage();}
		if (ExperienceAuthenticationServices.isUnsafe(contactQualification)) {return unsafeUserInputMessage();}
        Map<String, Object> objResults = new Map<String, Object>();
        String sMessage;
        Boolean isExisting = false;
        if(contactQualification.Id != null) {
            isExisting = true;
        }
        try {
            contactQualification.recordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
            contactQualification.Contact__c = contactId;                        
            Database.UpsertResult upr = Database.upsert(contactQualification);
            sMessage = 'Upsert Result:' + upr;
            objResults.put('contact_qualification_id', contactQualification.Id);

            if(!isExisting)
            {
                // new qualification, attach to current application
                Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
                aqp.Contact_Qualification__c = contactQualification.Id;
                aqp.Application__c = applicationId;

                Database.SaveResult sr = Database.insert(aqp);
                objResults.put('app_qualification_id', aqp.Id);
                sMessage += ', Insert AQP Result:' + sr;
            }
            Nebula.Logger.info('upsertQualificationToContact msg: '+sMessage).addTag('upsertQualificationToContact');
        }
        catch (Exception e)
        {
            // TODO: exception handling ExLog.add()
            sMessage = 'UPESRT Errored:' + e.getMessage();
            Nebula.Logger.error(e.getMessage(), e);
        }
        Nebula.Logger.saveLog();

        objResults.put('message', sMessage);
        return objResults;

    }

    /**
     * @description function to delete the Contact Qualifications options for Graduate Research
     *
     * @param contactQualificationId
     * @param applicationId
     * @return  Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> deleteContactQualification(Id contactQualificationId, Id applicationId) {
        //authentication for the applicant
        Application__c app = [SELECT Applicant__c FROM Application__c WHERE Id=:applicationId AND Status__c = 'Draft'];
        if(!isRecordOwnedByTheUser(app)) {
            throw new AuraHandledException('Invalid application');
        }

        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{contactQualificationId,applicationId})) {return unsafeParameterMessage();}
        Map<String, Object> objResults = new Map<String, Object>();
        String sMessage;

        try {
            // get the contact qualification
            List<Contact_Qualification__c> listConQuals = [SELECT id, Contact__c
                                                           FROM Contact_Qualification__c
                                                           WHERE id =: contactQualificationId WITH USER_MODE];
            if(listConQuals.size() > 0) {
                Contact_Qualification__c cqToDelete = listConQuals[0];

                // get the current user for permission checking
                User currentUser = getCurrentUser();
                
                // check still required due to test class evaluation against this...
                if(currentUser.ContactId == cqToDelete.Contact__c) {
                    //delete the related documents if any 
                    deleteIrrelevantContactDocuments(contactQualificationId, applicationId);
                    Database.DeleteResult[] drConQual = Database.delete(listConQuals);
                    objResults.put('result', 'SUCCESS = ' + drConQual[0].isSuccess());
            	}
                else {
                    // error: contact does not own this record
                    sMessage = 'DELETE error:: User does not own this record';
                }
            }
            else {
                // error handling
                sMessage = 'DELETE error:: found ' + listConQuals.size() + ' records for ' + contactQualificationId;
            }
        }
        catch(Exception e) {
            sMessage = 'DELETE ERROR:' + e.getMessage();
            Nebula.Logger.error(e.getMessage(), e);
        }
        Nebula.Logger.saveLog();

        objResults.put('message', sMessage);
        return objResults;
    }

    /**
     * @description function to delete the documents related to Contact Qualifications 
     * @param contactQualificationId
     * @param applicationId
     * @return  void
     */
    private static void deleteIrrelevantContactDocuments(Id contactQualificationId, Id applicationId) {        
        //Initialize Variables
        Set<Id> toDeleteContentDocumentIds = new Set<Id>();
        Set<Id> toDeleteContactDocumentIds = new Set<Id>();
        
        //Collect contact document ids related to the checklist        
        for(Contact_Document__c loopContactDocument : [SELECT Id, (SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks) 
                                                        FROM Contact_Document__c 
                                                        WHERE Contact_Qualification__c = :contactQualificationId
                                                        AND Application__c = :applicationId]){
            //Add the contact document id to be deleted
            toDeleteContactDocumentIds.add(loopContactDocument.Id);

            //Collect document links
            if(loopContactDocument.ContentDocumentLinks != null){
                for(ContentDocumentLink loopLink : loopContactDocument.ContentDocumentLinks){
                    toDeleteContentDocumentIds.add(loopLink.ContentDocumentId);
                }
            }
        }

        //Delete contact documents
        if(!toDeleteContactDocumentIds.isEmpty()){
            delete [SELECT Id FROM Contact_Document__c WHERE Id IN :toDeleteContactDocumentIds];
        }

        //Delete content documents
        if(!toDeleteContentDocumentIds.isEmpty()){
            delete [SELECT Id FROM ContentDocument WHERE Id IN :toDeleteContentDocumentIds];
        }
    }

    /**
     * @description get the logged in user details
     * @return  User
     */
    @AuraEnabled
    public static User getCurrentUser()
    {
        List<User> listUsers = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];

        return listUsers[0];
    }

    /**
     * @description checking the authentication
     * @return  Map<String,String>
     */
    private static Map<String,String> unsafeUserInputMessage() {
        return ExperienceAuthenticationServices.userMessageCC(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT);
    }
    /**
     * @description checking the authentication
     * @return  Map<String,String>
     */
    private static Map<String,String> unsafeParameterMessage() {
        return ExperienceAuthenticationServices.userMessageCC(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_PARAMETERS);
    }

    /**
     * @author      Vishal Gupta
     * @description method to check if the application is related to the logged in user
     * @revision    27/6/2025 - Initial Version
    */
    private static boolean isRecordOwnedByTheUser(Application__c app){
        MyAppApplicationAuthenticator checker = new MyAppApplicationAuthenticator(app);
        if (checker.isRecordRelatedToCurrentUser()) {
            return true;
        } else {
            return false;
        }
    }
}