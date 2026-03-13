/**
 * @author Kristian Vegerano
 * @description Service class for retrieving contacts and inserting enquiry records against the contact records
 * @revision
 *  July.18.2019   Ven Vairavan - Added Intended Commencement field for Monash College Enquiry Form. 
 *  April.29.2021  Kristian Vegerano - Added all enquiry insert to be called from the inner class
 */
public with sharing class MonashCollegeEnquiryFormService {
    
    public MonashCollegeEnquiryFormService(){
        
    }
    
    /*
     *  @author      Kristian Vegerano
     *  @description Retrieve picklist values of a field
     */
    @AuraEnabled        
    public static List<String> getPickListValuesIntoList(String objectType, String selectedField){
        List<String> pickListValuesList = new List<String>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        return pickListValuesList;
    }

    /*
     *  @author      Kristian Vegerano
     *  @description Retrieve contact records for current course enquiries
     */
    @AuraEnabled 
    public static String retrieveContact(String studentId, String monashEmail) {
        MonashCollegeEnquiryFormInner internalCalls = new MonashCollegeEnquiryFormInner();
        String result;
        try{
            Contact studentContact;
            //Retrieve resulting contact
            for(Contact loopContact : (List<Contact>)internalCalls.queryCurrentContact(studentId, monashEmail)){
                studentContact = loopContact;    
            }
            
            if(studentContact != null){
                result = 'Success';
            }else{
                result = 'No Match';
            }
        }catch(Exception ex){
            System.debug(ex);
            result = 'FATAL ERROR';
        }
        
        return result;
    }
    
    /*
     *  @author      Kristian Vegerano
     *  @description Submits general professional year enquiry against the current student
     */
    @AuraEnabled 
    public static String submitGeneralEnquiry(String studentId, String monashEmail, String enquiryProgram, 
                                              String selectedTopic, String enteredAdditionalDescription) {
        MonashCollegeEnquiryFormInner internalCalls = new MonashCollegeEnquiryFormInner();
        try{
            //Specify enquiry details based on the selected program
            Id enquiryOwnerGroupId = CaseServices.CASE_PROFESSIONALYEAR_QUEUE;
            Id enquiryRecordTypeId = CaseServices.CASE_PROFESSIONALYEAR_RECTYPE;
            
            //Retrieve resulting contact
            Contact studentContact;
            for(Contact loopContact : (List<Contact>)internalCalls.queryCurrentContact(studentId, monashEmail)){
                studentContact = loopContact;    
            }
            
            //Create case record
            Case submittedCase = new Case(RecordTypeId = enquiryRecordTypeId,
                                          Subject = studentContact.Name + ' - ' + selectedTopic,
                                          Description = enteredAdditionalDescription,
                                          ContactId = studentContact.Id,
                                          Category_Level_1__c = selectedTopic,
                                          Enquiry_Type__c = 'Current Course',
                                          OwnerId = enquiryOwnerGroupId,
                                          Origin = 'Web - General enquiry',
                                          SuppliedEmail = monashEmail);
                                          
            Database.DMLOptions autoResponseOptions = new Database.DMLOptions();
            autoResponseOptions.EmailHeader.triggerAutoResponseEmail = true;
     
            submittedCase.setOptions(autoResponseOptions);
            submittedCase = (Case)internalCalls.insertSobject(submittedCase);
            
            //Retrieve Enquiry Number
            Case submittedEnquiry;
            submittedEnquiry = internalCalls.queryEnquiry(submittedCase.Id);
            
            //Return enquiry id
            return JSON.serialize(submittedEnquiry);
        }catch(Exception ex){
            System.debug(ex);
            return 'Fatal Error';
        }
        return 'Fatal Error';        
    }
    
    /*
     *  @author      Kristian Vegerano
     *  @description Submits professional year enquiry against the current student for notification or requests
     */
    @AuraEnabled 
    public static String submitNotificationEnquiry(String studentId, String monashEmail, String enquiryProgram, String selectedClassDay, 
                                                   String enteredDepartureDate, String enteredReturnDate, String selectedNotificationType, 
                                                   String selectedReasonChange, String otherReasonChange, String enteredAdditionalDescription, String transferDate, String deferralDuration) {
        MonashCollegeEnquiryFormInner internalCalls = new MonashCollegeEnquiryFormInner();
        try{
            //Specify enquiry details based on the selected program
            Id enquiryOwnerGroupId = CaseServices.CASE_PROFESSIONALYEAR_QUEUE;
            Id enquiryRecordTypeId = CaseServices.CASE_PROFESSIONALYEAR_RECTYPE;
            
            //Retrieve resulting contact
            Contact studentContact;
            for(Contact loopContact : (List<Contact>)internalCalls.queryCurrentContact(studentId, monashEmail)){
                studentContact = loopContact;    
            }

            //Create case record - default category level 1
            String selectedTopic = 'Notification';
            
            //Create case record - construct description
            String enteredDescription = '';
            //Add current class day
            if(selectedClassDay != ''){
                if(enteredDescription != ''){
                    enteredDescription += '\n\n';
                }
                enteredDescription += 'Preferred Class Day:\n' + selectedClassDay;
            }
            
            //Add leave dates
            if((enteredDepartureDate != null && enteredDepartureDate != '') || (enteredReturnDate != null && enteredReturnDate != '')){
                if(enteredDescription != ''){
                    enteredDescription += '\n\n';
                }
                if((enteredDepartureDate != null && enteredDepartureDate != '') && (enteredReturnDate != null && enteredReturnDate != '')){
                    enteredDescription += 'Leave Dates:\n' + Date.valueOf(enteredDepartureDate).format() + ' to ' + Date.valueOf(enteredReturnDate).format();
                }else if((enteredDepartureDate != null && enteredDepartureDate != '') && (enteredReturnDate == null || enteredReturnDate == '')){
                    enteredDescription += 'Leave Date:\n' + Date.valueOf(enteredReturnDate).format();
                }else if((enteredDepartureDate == null && enteredDepartureDate == '') || (enteredReturnDate == null || enteredReturnDate == '')){
                    enteredDescription += 'Leave Date:\n' + Date.valueOf(enteredDepartureDate).format();
                }
            }
            
            //Add Transfer Date
            if(transferDate != null){
                if(enteredDescription != ''){
                    enteredDescription += '\n\n';
                }
                enteredDescription += 'Transfer Date:\n' + Date.valueOf(transferDate).format();
            }
            
            //Add Deferral Duration
            if(deferralDuration != null){
                if(enteredDescription != ''){
                    enteredDescription += '\n\n';
                }
                enteredDescription += 'Deferral Duration:\n' + deferralDuration;
            }
            
            //Add reason for change
            if(selectedReasonChange != null){
                if(enteredDescription != ''){
                    enteredDescription += '\n\n';
                }
                enteredDescription += 'Reason:\n' + (selectedReasonChange != 'Other' ? selectedReasonChange : selectedReasonChange + ' - ' + otherReasonChange);
            }
            //Add additional information
            if(enteredAdditionalDescription != ''){
                if(enteredDescription != ''){
                    enteredDescription += '\n\n';
                }
                enteredDescription += 'Student Situation:\n' + enteredAdditionalDescription;
            }
            
            //Create case record
            Case submittedCase = new Case(RecordTypeId = enquiryRecordTypeId,
                                          Subject = studentContact.Name + ' - ' + selectedNotificationType + ' Request',
                                          Description = enteredDescription,
                                          ContactId = studentContact.Id,
                                          Category_Level_1__c = selectedNotificationType == 'Leave' ? 'Attendance/Leave' : selectedNotificationType,
                                          Enquiry_Type__c = 'Current Course',
                                          OwnerId = enquiryOwnerGroupId,
                                          Origin = 'Web - Request for leave, transfer or deferral',
                                          SuppliedEmail = monashEmail);
                                          
            Database.DMLOptions autoResponseOptions = new Database.DMLOptions();
            autoResponseOptions.EmailHeader.triggerAutoResponseEmail = true;
     
            submittedCase.setOptions(autoResponseOptions);
            submittedCase = (Case)internalCalls.insertSobject(submittedCase);
            
            //Retrieve Enquiry Number
            Case submittedEnquiry;
            submittedEnquiry = internalCalls.queryEnquiry(submittedCase.Id);
            
            //Return enquiry id
            return JSON.serialize(submittedEnquiry);
        }catch(Exception ex){
            System.debug(ex);
            return 'Fatal Error';
        }
        return 'Fatal Error';        
    }
    
    /*
     *  @author      Kristian Vegerano
     *  @description Submits professional year enquiry against the current student for special considerations
     */
    @AuraEnabled 
    public static String submitSpecialConsiderationEnquiry(String studentId, String monashEmail, String enquiryProgram, String selectedClassDay, 
                                                           String selectedNotificationType, String otherNotificationType, String enteredAdditionalDescription) {
        MonashCollegeEnquiryFormInner internalCalls = new MonashCollegeEnquiryFormInner();
        try{
            //Specify enquiry details based on the selected program
            Id enquiryOwnerGroupId = CaseServices.CASE_PROFESSIONALYEAR_QUEUE;
            Id enquiryRecordTypeId = CaseServices.CASE_PROFESSIONALYEAR_RECTYPE;
            
            //Retrieve resulting contact
            Contact studentContact;
            for(Contact loopContact : (List<Contact>)internalCalls.queryCurrentContact(studentId, monashEmail)){
                studentContact = loopContact;    
            }

            //Create case record - default category level 1
            String selectedTopic = 'Support';
            
            //Create case record - get professional year record type id
            Id professionalYearEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Year Enquiry').getRecordTypeId();
            
            //Create case record - construct description
            String enteredDescription = '';
 
            //Add reason for change
            if(selectedNotificationType != null){
                if(enteredDescription != ''){
                    enteredDescription += '\n\n';
                }
                enteredDescription += 'Reason:\n' + (selectedNotificationType != 'Other' ? selectedNotificationType : selectedNotificationType + ' - ' + otherNotificationType);
            }
            //Add Additional Information
            if(enteredAdditionalDescription != ''){
                if(enteredDescription != ''){
                    enteredDescription += '\n\n';
                }
                enteredDescription += 'Student Situation:\n' + enteredAdditionalDescription;
            }
            
            //Create case record
            Case submittedCase = new Case(RecordTypeId = enquiryRecordTypeId,
                                          Subject = studentContact.Name + ' - ' + selectedTopic,
                                          Description = enteredDescription,
                                          ContactId = studentContact.Id,
                                          Category_Level_1__c = selectedTopic,
                                          Category_Level_2__c = (selectedNotificationType != 'Other' ? selectedNotificationType : selectedNotificationType + ' - ' + otherNotificationType),
                                          Enquiry_Type__c = 'Current Course',
                                          OwnerId = enquiryOwnerGroupId,
                                          Origin = 'Web - Request for support',
                                          SuppliedEmail = monashEmail);
                                          
            Database.DMLOptions autoResponseOptions = new Database.DMLOptions();
            autoResponseOptions.EmailHeader.triggerAutoResponseEmail = true;
     
            submittedCase.setOptions(autoResponseOptions);
            submittedCase = (Case)internalCalls.insertSobject(submittedCase);
            
            //Retrieve Enquiry Number
            Case submittedEnquiry;
            submittedEnquiry = internalCalls.queryEnquiry(submittedCase.Id);
            
            //Return enquiry id
            return JSON.serialize(submittedEnquiry);
        }catch(Exception ex){
            System.debug(ex);
            return 'Fatal Error';
        }
        return 'Fatal Error';        
    }

    /*
     *  @author      Kristian Vegerano
     *  @description Submits general professional year enquiry against the future student
     *  @revision
     *  JUL.04.2019     Ven Vairavan   - Added Case Fields for Future Program Enquiry. 
     */
    @AuraEnabled 
    public static String submitFutureGeneralEnquiry(String studentFirstName, String studentLastName, String enteredTitle, String studentEmail, 
                                                    Date enteredBirthDate, String selectedTopic, String enteredTelephone,
                                                    String otherTopic, String enteredAdditionalDescription, String enteredCountryOfResidence,
                                                    String enteredNationality, String enteredResidency, String enteredCity, 
                                                    String enteredCommencement, String enteredHighestLevelOfStudy, String enteredInstitution,
                                                    String enteredProgramStream, String enteredLevelOfStudy, String enteredAboutUs) {
        MonashCollegeEnquiryFormInner internalCalls = new MonashCollegeEnquiryFormInner();
        try{
            //Specify enquiry details based on the selected program
            Id enquiryOwnerGroupId = CaseServices.CASE_PROFESSIONALFUTUREYEAR_QUEUE;
            Id enquiryRecordTypeId = CaseServices.CASE_PROFESSIONALYEAR_RECTYPE;
            
            //Get relevant contact
            Contact formContact;
            for(Contact loopContact : (List<Contact>)internalCalls.queryContact(studentFirstName, studentLastName, studentEmail, enteredBirthDate)){
                formContact = loopContact;
            }
            if(formContact == null){
                //Create contact if no match   
                formContact = new Contact(Salutation = enteredTitle,
                    					  FirstName = studentFirstName,
                                          LastName = studentLastName,
                                          Email = studentEmail,
                                          Birthdate = enteredBirthDate);
                formContact = (Contact)internalCalls.insertSobject(formContact);
            }
            
            //Create case record - construct description
            String enteredDescription = '';
            
            //Add Question
            if(enteredAdditionalDescription != ''){
                if(enteredDescription != ''){
                    enteredDescription += '\n\n';
                }
                enteredDescription += enteredAdditionalDescription;
            }
                                          
            //Create case record
            Case submittedCase = new Case(RecordTypeId = enquiryRecordTypeId,
                                          Subject = 'Future Program Enquiry: ' + studentFirstName + ' ' + studentLastName,                                         
                                          ContactId = formContact.Id,
                                          Category_Level_1__c = (selectedTopic != 'Other' ? selectedTopic : selectedTopic + ' - ' + otherTopic),
                                          Enquiry_Type__c = 'Future Course',
                                          Enquiry_Program__c = 'Professional Year',
                                          OwnerId = enquiryOwnerGroupId,
                                          Origin = 'Web - Future Program Enquiry',
                                          Supplied_Salutation__c = enteredTitle,
                                          Supplied_First_Name__c = studentFirstName,
                                          Supplied_Last_Name__c = studentLastName,
                                          Supplied_Date_of_Birth__c = enteredBirthDate,
                                          Supplied_Mobile__c = enteredTelephone,
                                          SuppliedEmail = studentEmail,
                                          Supplied_Country_of_Residence__c = enteredCountryOfResidence,
                                          Supplied_Nationality__c = enteredNationality,
                                          Residency_Status__c = enteredResidency,
                                          Supplied_City__c = enteredCity,
                                          Intended_Commencement__c = enteredCommencement,
                                          Highest_Level_of_Study__c = enteredHighestLevelOfStudy,
                                          Supplied_Name_of_Institution__c = enteredInstitution,
                                          Level_of_Study__c = enteredLevelOfStudy, 
                                          Program_Stream__c = enteredProgramStream,
                                          Description = enteredDescription,
                                          Heard_About_From__c = enteredAboutUs);          
            Database.DMLOptions autoResponseOptions = new Database.DMLOptions();
            autoResponseOptions.EmailHeader.triggerAutoResponseEmail = true;
            
            submittedCase.setOptions(autoResponseOptions);
            submittedCase = (Case)internalCalls.insertSobject(submittedCase);

            //Retrieve Enquiry Number
            Case submittedEnquiry;
            submittedEnquiry = internalCalls.queryEnquiry(submittedCase.Id);
            
            //Return enquiry id
            return JSON.serialize(submittedEnquiry);
        }catch(Exception ex){
            System.debug(ex);
            return 'Fatal Error';
        }
        return 'Fatal Error';        
    }
    
    /**
     * @author Kristian Vegerano
     * @description Inner class to query and dml records in without sharing context
     * @revision
     *  July.18.2019  Kristian Vegerano - Added all enquiry insert to be called from the inner class
     */
    private without sharing class MonashCollegeEnquiryFormInner {
        public List<Contact> queryContact(String newFirstName, String newLastName, String newEmail, Date newBirthDate){
            return [SELECT Id 
                    FROM Contact
                    WHERE FirstName = :newFirstName
                        AND LastName = :newLastName
                        AND email= :newEmail
                        AND BirthDate= :newBirthDate];
        }
        
        public List<Contact> queryCurrentContact(String studentId, String monashEmail){
            return [SELECT Name
                    FROM Contact 
                    WHERE Person_ID_unique__c = :studentId 
                        AND Email = :monashEmail 
                    LIMIT 1];
        }
        
        public Case queryEnquiry(Id enquiryId){
            return [SELECT Id, CaseNumber 
                    FROM Case 
                    WHERE Id = :enquiryId 
                    LIMIT 1];
        }
        
        public SObject insertSobject(SObject dmlSObject){
            insert dmlSObject;
            return dmlSObject;
        }
    }
}