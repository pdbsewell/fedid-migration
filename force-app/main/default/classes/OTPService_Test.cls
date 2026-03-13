/**
 * @File Name          : OTPService_Test.cls
 * @Description        : Test class for OTPService.cls
 * @Author             : Peter Sewell
 */
@isTest(isParallel=true)
private class OTPService_Test {

    /*
    * @description Test data initialisation
    */
    @testSetup static void initialize() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;
        
        // Switch on mobile phone formatting.
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Format_Mobile__c = true;
        insert fs;
        
        // Create a contact with Phone__c records
        Contact aContact = new Contact(Person_ID_unique__c='22245678', LastName='User', FirstName='Test');
        insert aContact;
        
        // Create Phone__c records
        List<Phone__c> phoneLst = new List<Phone__c>();
        phoneLst.add(new Phone__c(Is_Active__c = true, Type__c = 'mobile', Is_Primary__c = true, Contact__c = aContact.id, Classification__c = 'Private', Name='0491 570 006'));
        phoneLst.add(new Phone__c(Is_Active__c = true, Type__c = 'mobile', Is_Primary__c = false, Contact__c = aContact.id, Classification__c = 'Private', Name='64 491 570 156'));
        phoneLst.add(new Phone__c(Is_Active__c = true, Type__c = 'mobile', Is_Primary__c = false, Contact__c = aContact.id, Classification__c = 'Private', Name='0491 570 157'));  
        insert phoneLst;

        // Create Email__c records
        List<Email__c> emailLst = new List<Email__c>();
        emailLst.add(new Email__c(Is_Active__c = true, Is_Primary__c = true, Contact__c = aContact.id, Classification__c = 'Private', Name='test@test.com'));
        emailLst.add(new Email__c(Is_Active__c = true, Is_Primary__c = false, Contact__c = aContact.id, Classification__c = 'Private', Name='test2@test.com'));
        insert emailLst;

        // Create a contact WITHOUT Phone__c or Email__c records
        Contact aContact2 = new Contact(Person_ID_unique__c='22245679', LastName='User2', FirstName='Test');
        insert aContact2;
        
    }
    
    /*
    * @description Test getContactOtpAddresses() SMS
    */
    @isTest static void test_getContactOtpAddressesSMS() {
        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'];

        Test.startTest();

            OTPService.ContactMobileNumbers contactMobileNumbers = OTPService.getContactOtpAddresses(aContact[0].Id, false, false).sms;

        Test.stopTest();

        // Asserts
        System.assertEquals('success', contactMobileNumbers.result, 'Phone numbers were not found for the contact');
        Boolean nzFound = false;
        for (String m:  contactMobileNumbers.mobileNumbers) {
            if (m.startsWith('+64')) {
                nzFound = true;
                break;
            }
        }
        System.assertEquals(true, nzFound, 'NZ phone number should have been found');
    }

    /*
    * @description Test getContactOtpAddresses() SMS with country exclusion
    */
    @isTest static void test_getContactOtpAddressesSMSexclusion() {
        // Create country exclusions for NZ and China in custom settings
        // Noting that one of our dummy contacts has an NZ number
        OTP_Widget__c c = new OTP_Widget__c();
        c.Country_Code_Exclusions__c = '+64,+86';
        insert c;

        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'];

        Test.startTest();

            OTPService.ContactMobileNumbers contactMobileNumbers = OTPService.getContactOtpAddresses(aContact[0].Id, false, false).sms;

        Test.stopTest();

        // Asserts
        System.assertEquals('success', contactMobileNumbers.result, 'Phone numbers were not found for the contact');
        for (String m:  contactMobileNumbers.mobileNumbers) {
            System.assertEquals(false, m.startsWith('+64'), 'NZ phone numbers should have been excluded');
        }
    }

    /*
    * @description Test getContactOtpAddresses() Email
    */
    @isTest static void test_getContactOtpAddressesEmail() {
        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'];

        Test.startTest();

            OTPService.ContactEmailAddresses contactEmailAddresses = OTPService.getContactOtpAddresses(aContact[0].Id, false, false).email;

        Test.stopTest();

        // Asserts
        System.assertEquals('success', contactEmailAddresses.result, 'Email addresses were not found for the contact');
    }

    /*
    * @description Test getContactOtpAddresses() Bad Contact Id
    */
    @isTest static void test_getContactOtpAddressesBadContactId() {

        Test.startTest();

            // Random contact id, should not exist
            OTPService.ContactMobileNumbers contactMobileNumbers = OTPService.getContactOtpAddresses('0035P00000Hrq3ZQAR', false, false).sms;

        Test.stopTest();

        // Asserts
        System.assertEquals('error', contactMobileNumbers.result, 'Should have returned error as contact does not exist');
    }

    /*
    * @description Test getContactOtpAddresses() No phone numbers
    */
    @isTest static void test_getContactOtpAddressesPhoneNumbersNotFound() {
        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245679'];

        Test.startTest();

            OTPService.ContactMobileNumbers contactMobileNumbers = OTPService.getContactOtpAddresses(aContact[0].Id, false, false).sms;

        Test.stopTest();

        // Asserts
        System.assertEquals('error', contactMobileNumbers.result, 'Phone numbers were found for the contact and should not have been');
    }

    /*
    * @description Test postToRecord()
    */
    @isTest static void test_postToRecord() {
        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'];

        Test.startTest();

            OTPService.postToRecord(aContact[0].Id, 'Hello World');

        Test.stopTest();

        // Asserts
        List<FeedItem> f = [SELECT id FROM FeedItem WHERE ParentId = :aContact[0].Id];
        System.assertEquals(1, f?.size(), 'No chatter message was posted to record');
    }

    /*
    * @description Test setVerificationCache()
    */
    @isTest static void test_setVerificationCache() {
        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'];

        Test.startTest();

            OTPService.setVerificationCache(aContact[0].Id, 300);

        Test.stopTest();

        // Asserts
        System.assertEquals(OTPService.isVerificationCached(aContact[0].Id), true, 'No cache entry found, but was expected');
    }

    /*
    * @description Test getVerificationCacheDateTime()
    */
    @isTest static void test_getVerificationCacheDateTime() {
        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'];

        Test.startTest();

            OTPService.setVerificationCache(aContact[0].Id, 300);
            String dtString = OTPService.getVerificationCacheDateTime(aContact[0].Id);

        Test.stopTest();

        // Asserts
        System.assertEquals(String.isNotBlank(dtString), true, 'Date time cache entry NOT found, but was expected');
    }

    /*
    * @description Test clearVerificationCache()
    */
    @isTest static void test_clearVerificationCache() {
        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'];

        Test.startTest();

            OTPService.setVerificationCache(aContact[0].Id, 300);
            OTPService.clearVerificationCache(aContact[0].Id);

        Test.stopTest();

        // Asserts
        System.assertEquals(OTPService.isVerificationCached(aContact[0].Id), false, 'Cache entry was found, but was not expected');
    }

    /*
    * @description Test publishPlatformEvent()
    */
    @isTest static void test_publishPlatformEvent() {
        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'];
        String contactId = aContact[0].Id;
        String userId = UserInfo.getUserId();
        String recordId = contactId;
        String channel = 'SMS';
        String eventType = 'VERIFIED';
        String address = 'XXXXXX7056';

        Test.startTest();

            OTPService.publishPlatformEvent(
                userId,
                recordId,
                contactId,
                eventType,
                channel,
                address
            );

        Test.stopTest();

        // Asserts
    }
 }