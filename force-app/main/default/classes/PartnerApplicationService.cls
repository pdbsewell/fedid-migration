/**
 * @author      Kristian Vegerano
 * @description Services class primarily used on partner experience pages
 * @group       Services
 * @revision    03/02/2021 - Kristian Vegerano - Created
 */ 
public with sharing class PartnerApplicationService {
    /**
     * @author      Kristian Vegerano
     * @description Retrieves current user (Partner User) details and details about the partner account's partner agreement details
     * @revision    27/02/2021 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> retrievePartnerUserDetails(String userId) {
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();

        try{
            //Query user details
            User currentUser = [SELECT Id, Contact.AccountId FROM User WHERE Id = :userId];

            //Retrieve partner agreement details - latest agreement
            Set<String> allowedApplicationTypes = new Set<String>();
            List<Partner_Agreement__c> partnerAgreementList = new List<Partner_Agreement__c>();
            for(Partner_Agreement__c loopPartnerAgreement : [SELECT Id, Study_Type_Supported__c, Expiry_Date__c 
                                                            FROM Partner_Agreement__c
                                                            WHERE Partner_Account__c = :currentUser.Contact.AccountId
                                                            ORDER BY CreatedDate ASC]){
                if(loopPartnerAgreement.Expiry_Date__c == null || System.TODAY() < loopPartnerAgreement.Expiry_Date__c){
                    if(loopPartnerAgreement.Study_Type_Supported__c != null){
                        allowedApplicationTypes.addAll(loopPartnerAgreement.Study_Type_Supported__c.split(';'));
                    }
                }
            }

            //Retrieve which study type has unit related to it
            Map<String, Set<String>> typeToUnitMap = retrieveAvailableVirtualCourseUnits();

            //add result to return
            resultMap.put('STATUS', 'SUCCESS');
            resultMap.put('ALLOWED_APP_TYPES', JSON.serialize(allowedApplicationTypes));
            resultMap.put('PARTNER_ACCOUNT_ID', JSON.serialize(currentUser.Contact.AccountId));
            resultMap.put('NOT_KNOWN_TO_MONASH_ID', JSON.serialize(Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId()));    
            resultMap.put('STUDYTYPE_UNITS', JSON.serialize(typeToUnitMap)); 
        }catch(Exception ex){
            //add error
            resultMap.put('STATUS', 'ERROR');
            resultMap.put('MESSAGE', ex.getMessage());
        }

        //Return results
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Creates an applicant, application and/or user lodged by the partner
     * @revision    27/02/2021 - Kristian Vegerano - Created
     *              31/03/2021 - Vinothraja - added Location param while Application creation
     *              07/06/2021 - SFTG-2007 - added citizenship type options and removed send to Student 
     */
    @AuraEnabled
    public static Map<String, Object> createApplication(String applicantJSON, String partnerAccountId, String applicationType, String studyDuration, String location, String citizenshipType) {
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();
        
        //Create a savepoint before all processing
        Savepoint registerUserSavePoint = Database.setSavepoint();

        try{
            Boolean hasExistingContact = false;
            //create applicant
            Contact newApplicant = (Contact)JSON.deserialize(applicantJSON, Contact.class);            
            
            //check if there are duplicates first name, last name, birthdate
            for(Contact matchedContact : [SELECT Id 
                                          FROM Contact
                                          WHERE First_Name__c = :newApplicant.First_Name__c
                                                AND Last_Name__c = :newApplicant.Last_Name__c
                                                AND Email = :newApplicant.Email
                                                AND BirthDate = :newApplicant.BirthDate
                                          ORDER BY CreatedDate ASC
                                          LIMIT 100]){
                hasExistingContact = true;
                newApplicant.Id = matchedContact.Id;
            }
            upsert newApplicant;

            //retrieve partner agreement for the partner account
            Id partnerAgreementId;
            String partnerName;
            for(Partner_Agreement__c loopAgreement : [SELECT Id, Partner_Account__r.Name FROM Partner_Agreement__c WHERE Partner_Account__c = :partnerAccountId LIMIT 1]){
                partnerAgreementId = loopAgreement.Id;
                partnerName = loopAgreement.Partner_Account__r.Name;
            }

            //create application
            Application__c newApplication = new Application__c(Agent__c = partnerAccountId,
                                                               Applicant__c = newApplicant.Id,
                                                               Submission_Progress__c = 'Study Preferences',
                                                               Furthest_Progress__c = 'Review',
                                                               Source_System__c = 'Partner',
                                                               Campus_Location__c = location,
                                                               Partner_Controlled__c = true,
                                                               Type_of_Study__c = applicationType,
                                                               Duration_of_Study__c = studyDuration,
                                                               Residency_Status__c = citizenshipType,
                                                               Partner_Agreement__c = partnerAgreementId,
                                                               Partner_Name__c = partnerName,
                                                               From_Portal__c = true);     
            StudyLocationController.setResidencySubStatuses(newApplication);
            StudyLocationController.setCountryOfCitizenship(newApplication);
            insert newApplication;

            // Proceed with generating user if theres no existing contact
            /*if(!hasExistingContact){
                //generate user
                if(isSendToStudent){
                    resultMap.putAll(ExperienceAuthenticationServices.generateUserResetApplicationProgressStatus(newApplication.Id));
                }
            }else{
                // Send email notification to the applicant for the new email
            }*/

            //add result to return
            resultMap.put('STATUS', 'SUCCESS');
            resultMap.put('APPLICANT', JSON.serialize(newApplicant));
            resultMap.put('APPLICATION', JSON.serialize(newApplication));
        }catch(Exception ex){
            //Rollback to when the user isnt created yet
            Database.rollback(registerUserSavePoint);

            //log error
            ExLog.add('PartnerApplicationService', 'Partner Experience', 'createApplication', ex);

            //add error
            resultMap.put('STATUS', 'ERROR');
            resultMap.put('MESSAGE', ex.getMessage());
        }

        //Return results
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves available course study type to unit association metadata
     * @revision    12/05/2021 - Kristian Vegerano - Created
     */
    public static Map<String, Set<String>> retrieveAvailableVirtualCourseUnits(){
        //Retrieve available course - unit offering links (for virtual)
        Map<String, Set<String>> courseCodeMap = new Map<String, Set<String>>();
        for(Available_Virtual_Course_Unit__mdt loopCourseUnit : [SELECT Id, Course_Code__c, Unit_Code__c FROM Available_Virtual_Course_Unit__mdt]){
            if(!courseCodeMap.containsKey(loopCourseUnit.Course_Code__c)){
                courseCodeMap.put(loopCourseUnit.Course_Code__c, new Set<String>());
            }
            courseCodeMap.get(loopCourseUnit.Course_Code__c).add(loopCourseUnit.Unit_Code__c);
        }

        Set<String> checkedCourseCode = new Set<String>();
        Map<String, Set<String>> typeToUnitMap = new Map<String, Set<String>>();
        for(Course_Offering__c loopCourseOffering : [SELECT Id, Course_Code__c, Course_Title__c FROM Course_Offering__c WHERE Course_Code__c IN :courseCodeMap.keySet()]){
            //check if the course code has already been processed
            if(!checkedCourseCode.contains(loopCourseOffering.Course_Code__c)){
                String studyType;
                if(loopCourseOffering.Course_Title__c != null){
                    //check if the course offering description
                    if(loopCourseOffering.Course_Title__c.containsIgnoreCase(Constants.MONASH_ABROAD_SA_STUDY_TYPE)){
                        studyType = Constants.MONASH_ABROAD_SA_STUDY_TYPE;
                    }else if(loopCourseOffering.Course_Title__c.containsIgnoreCase(Constants.MONASH_ABROAD_EX_STUDY_TYPE)){
                        studyType = Constants.MONASH_ABROAD_EX_STUDY_TYPE;
                    }

                    //check if the course code map has a unit for the course offering's course code
                    if(!typeToUnitMap.containsKey(studyType)){
                        typeToUnitMap.put(studyType, new Set<String>());
                    }
                    //check if there is a unit related to the course code
                    if(courseCodeMap.containsKey(loopCourseOffering.Course_Code__c)){
                        typeToUnitMap.get(studyType).addAll(courseCodeMap.get(loopCourseOffering.Course_Code__c));
                    }
                }
            }
            checkedCourseCode.add(loopCourseOffering.Course_Code__c);
        }

        return typeToUnitMap;
    }
    
    /**
     * @author      Shalini Mendu
     * @description Retrieves Partner Agreement quota details
     * @revision   8/June/2021 - Created
     */
    @AuraEnabled
    public static  Map<String, Object> retrievePartnerAgreementDetails(String userId) {
        User currentUser = [SELECT Id, Contact.AccountId FROM User WHERE Id = :userId];
        List<Partner_Agreement__c> pa =[select Quota__c, Study_Type_Supported__c,Remaining_quota__c, Expiry_date__c from Partner_Agreement__c
        WHERE Partner_Account__c = :currentUser.Contact.AccountId AND Study_Type_Supported__c INCLUDES ('EXCHANGE')
        ];
        
        Map<String, Object> resMap = new Map<String,Object>();
        resMap.put('Quota', pa[0].quota__c);
        resMap.put('RemainingQuota', pa[0].Remaining_quota__c);
        resMap.put('ExpiryDate', pa[0].Expiry_date__c);
        return  resMap;
    }
}