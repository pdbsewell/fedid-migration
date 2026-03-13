/**
 * @description Monash College Services class to provide Case sObject centric logical support
 * @revision
 *  MAR.01.2019     APRivera    - Created
 */

public class MonashCollegeCaseServices{

    public static Id PROFESSIONALYEAR_RECTYPEID {
        get {
            if(PROFESSIONALYEAR_RECTYPEID == null) PROFESSIONALYEAR_RECTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Year_Enquiry').getRecordTypeId();
            return PROFESSIONALYEAR_RECTYPEID;
        }
        set;
    }

    /**
     * @author          Kristian Vegerano
     * @description     Associates a Monash College Enquiry to a contact record on create
     * @param           caseList - filtered trigger.new context variable
     * @revision        JUN.11.2019 APRivera    - Refactored
     *                  SEPT.12.2019 KVegerano  - Added filter to not process enquiries without supplied name (enquiries not from email-to-case) - EPCS-49
     *                                          - Added substrings to ensure values added on contact first name and last name does not overflow from the field character limit - EPCS-50
     */
    public static void associateContactToMonashCollegeEnquiries(List<Case> caseList) {
        //Initialize Variables
        Contact newContact;
        Map<String, Contact> emailToContactMap = new Map<String, Contact>();

        //Process enquiries
        for(Case caseRecord : caseList){
            //Filter out non-email-to-case enquiries from being processed (supplied name is blank)
            if(caseRecord.SuppliedName != null){
                //Filter out enquiries already associated to contact records
                if(caseRecord.ContactId == null){
                    Integer counter = 1;
                    List<String> contactFullName = caseRecord.SuppliedName.split(' ');
                    
                    //Initialize new contact record
                    newContact = new Contact(Email = caseRecord.SuppliedEmail, Personal_Email__c = caseRecord.SuppliedEmail);

                    //Default Contact First and Last Name - split name by white space - put the last word as the last name and all previous words counts as first name
                    newContact.FirstName = '';
                    newContact.LastName = '';
                    for(String contactName : contactFullName){
                        if(counter == contactFullName.size()){
                            //Get only first 80 characters for the last name if characters are more than 80
                            String lastNameValue = contactName;
                            if(lastNameValue.length() > 80){
                                lastNameValue = lastNameValue.substring(0, 80);
                            }
                            newContact.LastName = lastNameValue;
                        }else{
                            newContact.FirstName = contactName + ' ' + newContact.FirstName;
                        }
                        counter = counter + 1;
                    }
                    //Add first name is available
                    if(newContact.FirstName != null){
                        //Get only first 40 characters for the first name if characters are more than 40
                        String firstNameValue = newContact.FirstName;
                        if(firstNameValue.length() > 40){
                            firstNameValue = firstNameValue.substring(0, 40);
                        }
                        newContact.FirstName = firstNameValue;
                    }
                    //Commit the new contact to the map to be inserted
                    emailToContactMap.put(caseRecord.SuppliedEmail, newContact);
                }
            }
        }

        //Create contacts
        if(emailToContactMap.size() > 0){
            insert emailToContactMap.values();
            //Associate created contacts to the enquiries
            for(Case caseRecord : caseList){
                if(emailToContactMap.containsKey(caseRecord.SuppliedEmail)){
                    caseRecord.ContactId = emailToContactMap.get(caseRecord.SuppliedEmail).Id;
                }
            }
        }
    }


    /**
     * @author          Kristian Vegerano
     * @description     Defaults the enquiry's enquiry type to current course if the related contact has Monash Person ID
     * @param           caseList - filtered trigger.new context variable
     */
    public static void defaultMonashCollegeEnquiryType(List<Case> caseList) {
        //Initialize Variables
        Map<Id, Contact> contactMap = new Map<Id, Contact>();

        //Retrieve all the contacts related to the enquiry
        for(Case loopCase : caseList){
            contactMap.put(loopCase.ContactId, new Contact());
        }

        //Query all the contacts related to the enquiry
        for(Contact loopContact : [SELECT Id, Person_ID__c
        FROM Contact
        WHERE Id IN :contactMap.keySet()]){
            contactMap.put(loopContact.Id, loopContact);
        }

        //Process enquiries
        for(Case loopCase : caseList){
            if(contactMap.containsKey(loopCase.ContactId)){
                if(contactMap.get(loopCase.ContactId).Person_ID__c != null){
                    loopCase.Enquiry_Type__c = Label.Current_Course;
                }
            }
        }
    }

}