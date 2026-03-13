/**
 * @author          Kristian Vegerano
 * @description     Apex controller class for ManageEnquiryContact lightning component
 * @history         24/08/2018
 */
public with sharing class ManageEnquiryContactService {
    
    @AuraEnabled 
    public static String searchContact(String searchText) {
        //Retrieve contacts
        String searchResult = '';
        String contactSearch = 'FIND :searchText IN SIDEBAR FIELDS RETURNING Contact(Id, Name, Person_ID__c, Monash_Email_Address__c, MobilePhone, Phone, Email ORDER BY LastModifiedDate DESC LIMIT 100)';
        List<List<SObject>> results = Search.query(contactSearch);
        
        List<Contact> contactResultList = (List<Contact>) results[0];
        
        if(!contactResultList.isEmpty()) {
            searchResult = JSON.serialize(contactResultList,true);
        }

        return searchResult;
    }
    
    @AuraEnabled 
    public static Case copyContactDetailsFromEnquiry(Id enquiryId) {
        Case pageEnquiry = new Case();
        
        //Derive case field values from metadata for setting copy enquiry details
        //Copy mapped fields from Case to contact record
        List<Case_to_Contact_Field_Mapping__mdt> fieldMappings = new List<Case_to_Contact_Field_Mapping__mdt>([SELECT Id, Case_API_name__c, Contact_Field_API_name__c  
                                                                                                               FROM Case_to_Contact_Field_Mapping__mdt]);
        
        //Query all case records in scope, ensuring we retrieve the fields of interest, and only records where contact wants info copied over
        String queryString = 'SELECT ';
        for(Case_to_Contact_Field_Mapping__mdt mapping : fieldMappings){ 
            queryString += mapping.Case_API_name__c + ',';
        }
        queryString += 'Id, ContactId, RecordTypeId FROM Case WHERE Id = :enquiryId';
        
        //Retrieve enquiry details
        for(Case loopCase : Database.query(queryString)){
            pageEnquiry = loopCase;
        }
        
        return pageEnquiry;
    }
}