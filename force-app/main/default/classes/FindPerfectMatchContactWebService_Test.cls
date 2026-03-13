/**
 * @File Name          : FindPerfectMatchContactWebService_Test.cls
 * @Description        : Test class for FindPerfectMatchContactWebService
 * @Author             : Kristian Vegerano
 * @Group              : Admissions
 * @Revision
 * 	OCT.14.2021     Kristian Vegerano   Created class
 */
@isTest(isParallel=true)
public class FindPerfectMatchContactWebService_Test {

    /**
	 * @description     tests has match scenario
	 */
    @isTest
    static void testHasMatchPerfectMatchingContactRestWS() {
        //setup test data
        PerfectMatchingContactPayload.FindPerfectMatchContactRequest requestWrapper = new PerfectMatchingContactPayload.FindPerfectMatchContactRequest();
        requestWrapper.lastName = 'Ctwentysix';
        requestWrapper.firstName = 'Kptest';
        requestWrapper.birthDate = '1998-12-12';
        requestWrapper.email = 'kptestctwentysix@mailinator.com';
        requestWrapper.mobilePhone = '0401717956';

        String tmpBDate;
        if (String.isNotEmpty(requestWrapper.birthDate)) {
            Datetime bDate = Date.valueOf(requestWrapper.birthDate); // implicit cast
            tmpBDate = bDate.format('yyyyMMdd');
        }        
        
        Contact testContact = new Contact(FirstName = requestWrapper.firstName,
                                          First_Name__c = requestWrapper.firstName,
                                          LastName = requestWrapper.lastName,
                                          Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                          Birthdate_Dup__c = tmpBDate,
                                          MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                          MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?phoneservices.rawFormatPhone(requestWrapper.mobilePhone):null,
                                          Account_Record_Type_Name__c = 'Household_Account',//ADDED BY SEEVA FOR EPCP 2739              
                                          Email = requestWrapper.email);
        insert testContact;

        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = rReq;

        //start test callout
        Test.startTest();
        PerfectMatchingContactPayload.FindPerfectMatchContactResponse res = FindPerfectMatchContactWebService.handleMatchingContacts();
        Test.stopTest();

        //check asserts
        System.assertEquals('Success' , res.status);
        System.assertEquals(testContact.Id , res.unicrmContactId);
    }

    /**
	 * @description     tests has no match scenario
	 */
    @isTest
    static void testNoMatchPerfectMatchingContactRestWS() {
        PerfectMatchingContactPayload.FindPerfectMatchContactRequest requestWrapper = new PerfectMatchingContactPayload.FindPerfectMatchContactRequest();
        requestWrapper.lastName = 'Ctwentysix';
        requestWrapper.firstName = 'Kptest';
        requestWrapper.birthDate = '1998-12-12';
        requestWrapper.email = 'kptestctwentysix@mailinator.com';
        requestWrapper.mobilePhone = '0401717956';

        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = rReq;

        //start test callout
        Test.startTest();  
        PerfectMatchingContactPayload.FindPerfectMatchContactResponse res = FindPerfectMatchContactWebService.handleMatchingContacts();
        Test.stopTest();

        //check asserts
        System.assertEquals('Success' , res.status);
        System.assertEquals(PerfectMatchingContactPayload.NO_MATCH, res.warningMessage);
    }

    /**
	 * @description     tests has multiple match scenario
	 */
    @isTest
    static void testMultipleMatchPerfectMatchingContactRestWS() {
        //setup test data
        PerfectMatchingContactPayload.FindPerfectMatchContactRequest requestWrapper = new PerfectMatchingContactPayload.FindPerfectMatchContactRequest();
        requestWrapper.lastName = 'Ctwentysix';
        requestWrapper.firstName = 'Kptest';
        requestWrapper.birthDate = '1998-12-12';
        requestWrapper.email = 'kptestctwentysix@mailinator.com';
        requestWrapper.mobilePhone = '0401717956';

        //setup test data
        List<Contact> testContactList = new List<Contact>();
        testContactList.add(new Contact(FirstName = requestWrapper.firstName,
                                        First_Name__c = requestWrapper.firstName,
                                        LastName = requestWrapper.lastName,
                                        Birthdate =  Date.valueOf(requestWrapper.birthDate),
                                        Birthdate_Dup__c = requestWrapper.birthDate.replace('-',''),
                                        MobilePhone = requestWrapper.mobilePhone,
                                        Email = requestWrapper.email,
										Account_Record_Type_Name__c = 'Household_Account'));//ADDED BY SEEVA FOR EPCP 2739
                                                        
        testContactList.add(new Contact(FirstName = requestWrapper.firstName,
                                        First_Name__c = requestWrapper.firstName,
                                        LastName = requestWrapper.lastName,
                                        Birthdate =  Date.valueOf(requestWrapper.birthDate),
                                        Birthdate_Dup__c = requestWrapper.birthDate.replace('-',''),
                                        MobilePhone = requestWrapper.mobilePhone,
                                        Email = requestWrapper.email,
                                       	Account_Record_Type_Name__c = 'Household_Account'));//ADDED BY SEEVA FOR EPCP 2739));
        insert testContactList;

        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = rReq;

        //start test callout
        Test.startTest();  
        PerfectMatchingContactPayload.FindPerfectMatchContactResponse res = FindPerfectMatchContactWebService.handleMatchingContacts();
        Test.stopTest();

        //check asserts
        System.assertEquals('Success' , res.status);
        System.assertEquals(PerfectMatchingContactPayload.MULTIPLE_MATCH, res.warningMessage);
    }
}