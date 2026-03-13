/**
 * @author          Kristian Vegerano
 * @description     Service class used by createPaymentRequestItemWizard lwc
 * @group           Service
 * @history         05/09/2020
 */
public with sharing class PaymentRequestItemWizard {
    @AuraEnabled 
    public static Map<String, Object> retrieveAgencyCourseAttempts(String paymentRequestId) {
        //Initialize results map
        List<Contact> contactList = new List<Contact>();
        List<Course_Attempt__c> courseAttempts = new List<Course_Attempt__c>();
        Map<String, Object> resultMap = new Map<String, Object>();

        //Retrieve payment request details
        Payment_Request__c paymentRequestRecord;
        for(Payment_Request__c loopPaymentRequest : [SELECT Id, Account__c, Account__r.Name, Account__r.Callista_Org_Unit_Code__c, Invoice_No__c FROM Payment_Request__c WHERE Id = :paymentRequestId LIMIT 1]){
            paymentRequestRecord = loopPaymentRequest;
        }

        //proceed processing if payment request record is valid
        if(paymentRequestRecord != null){
            //Unique person ids
            Set<String> personIdSet = new Set<String>();
            //Search for related course attempts
            for(Course_Attempt__c loopCourseAttempt : [SELECT Id, Application_Agent_Code__c, Application_Course_Preference__r.Application__r.Agent__c, 
                                                              Application_Course_Preference__r.Application__r.Agent__r.Name, Commencement_Date__c, Contact__c, Contact_Name__c,
                                                              Contact__r.Person_ID_unique__c, Contact_Person_Id__c, Course_Attempt_Status__c, Course_Title__c
                                                       FROM Course_Attempt__c
                                                       WHERE Application_Course_Preference__r.Application__r.Agent__c = :paymentRequestRecord.Account__c
                                                            AND Course_Attempt_Status__c = 'Enrolled'
                                                            AND Id NOT IN (SELECT Course_Attempt__c FROM Payment_Request_Item__c WHERE Payment_Request__r.Account__c  = :paymentRequestRecord.Account__c)
                                                       ORDER BY Contact__r.Person_ID_unique__c ASC, Contact__r.FirstName ASC, Contact__r.LastName ASC]){
                personIdSet.add(loopCourseAttempt.Contact_Person_Id__c);
                courseAttempts.add(loopCourseAttempt);
            }
            //Retrieve all related contacts
            if(!personIdSet.isEmpty()){
                for(Contact loopContact : [SELECT Id, Name, Person_ID_unique__c, FirstName, LastName
                                           FROM Contact
                                           WHERE Person_ID_unique__c IN :personIdSet]){
                    contactList.add(loopContact);
                }
            }
        }
        
        //return agency code
        resultMap.put('AgencyCode', paymentRequestRecord.Account__r.Callista_Org_Unit_Code__c);

        //return agency name
        resultMap.put('AgencyName', paymentRequestRecord.Account__r.Name);

        //return course attempts
        resultMap.put('CourseAttempts', courseAttempts);

        //return contacts
        resultMap.put('ContactList', contactList);

        //return invoice number
        resultMap.put('InvoiceNumber', paymentRequestRecord.Invoice_No__c);

        //Return result map
        return resultMap;
    }

    @AuraEnabled 
    public static Map<String, Object> doSearchStudent(String studentIdSearchKey) {
        //Initialize results map
        Set<String> studentIdSet = new Set<String>();
        List<Contact> contactList = new List<Contact>();
        List<Course_Attempt__c> courseAttempts = new List<Course_Attempt__c>();
        Map<String, Object> resultMap = new Map<String, Object>();

        //convert search key
        studentIdSearchKey = '%' + studentIdSearchKey + '%';

        //Retrieve payment request details
        for(Contact loopContact : [SELECT Id, Name, Person_ID_unique__c, FirstName, LastName
                                    FROM Contact
                                    WHERE Person_ID_unique__c LIKE :studentIdSearchKey
                                    ORDER BY LastName ASC, FirstName ASC]){
            studentIdSet.add(loopContact.Person_ID_unique__c);
            contactList.add(loopContact);
        }

        //check if there are contact results
        if(!studentIdSet.isEmpty()){
            //Search for related course attempts
            for(Course_Attempt__c loopCourseAttempt : [SELECT Id, Application_Agent_Code__c, Application_Course_Preference__r.Application__r.Agent__c, Application_Course_Preference__r.Application__r.Agent__r.Name, 
                                                              Commencement_Date__c, Contact__c, Contact_Name__c,
                                                              Contact_Person_Id__c, Course_Attempt_Status__c, Course_Title__c
                                                       FROM Course_Attempt__c
                                                       WHERE Contact__r.Person_ID_unique__c IN :studentIdSet]){
                courseAttempts.add(loopCourseAttempt);
            }
        }

        //return course attempts
        resultMap.put('CourseAttempts', courseAttempts);

        //return contacts
        resultMap.put('ContactList', contactList);

        //Return result map
        return resultMap;
    }
}