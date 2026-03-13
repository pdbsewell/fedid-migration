/**
 * @author  Shalini Mendu
 * @date 05 Dec 2019
 * @group Test Class
 * @description Covers the PerfectMatchingContactRestWS class
 */
@isTest(isParallel=true)
public class PerfectMatchingContactRestWS_Test {

    @IsTest
    static void testPositivePerfectMatchingContactRestWS() {

        PerfectMatchingContactRestWSMock mock = new PerfectMatchingContactRestWSMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Contact con = new Contact(
                SourceId__c = '003p000000WGKfQAAX',
                LastName = 'Ctwentysix',
                FirstName = 'Kptest',
                Birthdate_Dup__c = '19981212',
                Salutation = 'Ms',
                Gender__c = 'F',
                Previous_Monash_ID__c = 'null',
                Previously_Studied_at_Monash__c = true,
                Birthdate = Date.valueOf('1998-12-12'),
                Email = 'kptestctwentysix@mailinator.com',
                Personal_Email__c = 'kptestctwentysix@mailinator.com',
                MailingStreet = 'TEST',
                MailingCity = 'MELBOURNE',
                MailingState = 'VIC',
                MailingCountry = 'China',
                MailingPostalCode = '3000',
                MobilePhone ='0401717956',
                Phone = '0401717956',
                HasDisabilities__c = 'false',
                Previous_Surname__c = 'Melony'
                );
        insert con;
        PerfectMatchingContactPayload.PerfectMatchingContactPayloadRequest req = new PerfectMatchingContactPayload.PerfectMatchingContactPayloadRequest();

                req.sourceId = '003p000000WGKfQAAX';
                req.lastName = 'Ctwentysix';
                req.firstName = 'Kptest';
                req.birthDate = '1998-12-12';
                req.salutation = 'Ms';
                req.gender = 'F';
                req.PreviousMonashID = 'null';
                req.Email = 'kptestctwentysix@mailinator.com';
                req.mailingStreet = 'TEST';
                req.mailingCity = 'MELBOURNE';
                req.mobilePhone ='0401717956';
                req.mailingState = 'VIC';
                req.mailingCountry = 'New Zealand';
                req.mailingPostalCode = '3000';
                req.Phone = '0401717956';
                req.HasDisabilities = false;
                req.preferredName = 'Kp';
                req.countryOfBirth = 'Australia';
                req.pronouns = 'He/They';
                req.previousName = 'Melony';

        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = rReq;

        PerfectMatchingContactPayload.PerfectMatchingContactPayloadResponse res = PerfectMatchingContactRestWS.handleMatchingContacts();
        Test.stopTest();
        System.assertEquals('Success' , res.status);

}
    @IsTest
    static void testNegativePerfectMatchingContactRestWS() {

        PerfectMatchingContactRestWSMock mock = new PerfectMatchingContactRestWSMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Contact con = new Contact(
                SourceId__c = '003p000000WGKfQAAX',
                LastName = 'Ctwentysix',
                FirstName = 'Kptest',
                Birthdate_Dup__c = '19981212',
                Salutation = 'Ms',
                Gender__c = 'F',
                Previous_Monash_ID__c = 'null',
                Birthdate = Date.valueOf('1998-12-12'),
                Email = 'kptestctwentysix@mailinator.com',
                Personal_Email__c = 'kptestctwentysix@mailinator.com',
                MailingStreet = 'TEST',
                MailingCity = 'MELBOURNE',
                MailingState = 'VIC',
                MailingCountry = 'United Kingdom',
                MailingPostalCode = '3000',
                MobilePhone ='0401717956',
                Phone = '0401717956',
                HasDisabilities__c = 'false');
        insert con;
        PerfectMatchingContactPayload.PerfectMatchingContactPayloadRequest req = new PerfectMatchingContactPayload.PerfectMatchingContactPayloadRequest();

        req.sourceId = '003p000000WGKfQAAX';
        req.lastName = 'Ctwentysix';
        req.firstName = 'Kptest';
        req.birthDate = '19981212';
        req.salutation = 'Ms';
        req.gender = 'F';
        req.PreviousMonashID = 'null';
        req.Email = 'kptestctwentysix@mailinator.com';
        req.mailingStreet = 'TEST';
        req.mailingCity = 'MELBOURNE';
        req.mobilePhone ='0401717956';
        req.mailingState = 'VIC';
        req.mailingCountry = 'Narnia';
        req.mailingPostalCode = '3000';
        req.Phone = '0401717956';
        req.HasDisabilities = false;
        req.previousName = 'Jonas';
        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = rReq;

        PerfectMatchingContactPayload.PerfectMatchingContactPayloadResponse res = PerfectMatchingContactRestWS.handleMatchingContacts();

        Test.stopTest();
        System.assertEquals('Error' , res.status);

    }

}