@isTest(isParallel=true)
public class WorkExperienceServices_Test {
    
    static PhoneServices.PhoneFormatCustomMetadataWrapper AustraliaFormat = new PhoneServices.PhoneFormatCustomMetadataWrapper(
        '+61',
        '^(?=.{10,})^((?:\\+|00|0011|\\+00|\\+0011)?61)?(0?[4])(\\d{8})$'
    );

    
    @testSetup 
    static void setupData(){
        // Switch on mobile phone formatting.
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Format_Mobile__c = true;
        insert fs;
        
        Contact con = new Contact(LastName='Smith');
        insert con;
        
        Map<String, String> phoneFormatDataByCountry = new Map<String, String>{
            'Australia' => JSON.serialize(AustraliaFormat)
		};
    }

	// Tests invalid characters are removed from work experience phone numbers, based on the org standard    
    @isTest
    static void checkTidyPhone() {
        Contact con = [select id from Contact where LastName='Smith' limit 1];
        String dirtyPhone = '+(66) [call me] 55-44-33-22';
        String tidyPhone  = phoneServices.tidyPhone(dirtyPhone);
        
        test.startTest();
        Work_Experience__c we = new Work_Experience__c (Contact_Person_Phone__c = dirtyPhone, contact__c = con.id);
        insert we;
        test.stopTest();
        
        we = [select id, Contact_Person_Phone__c from work_experience__c where id = :we.id];
        system.assertEquals(we.Contact_Person_Phone__c, tidyPhone, 'Phone number contains unexpected characters ' +we.Contact_Person_Phone__c );
    }

    @isTest
    static void checkFormatPhone() {
        Contact con = [select id from Contact where LastName='Smith' limit 1];
        String dirtyPhone = '0401717999 Oz mobile';
        String tidyPhone  = phoneServices.formatPhone(dirtyPhone);
        
        test.startTest();
        Work_Experience__c we = new Work_Experience__c (contact__c = con.id);
        insert we;
        we.Contact_Person_Phone__c = dirtyPhone;
        update we;
        test.stopTest();
        
        we = [select id, Contact_Person_Phone__c from work_experience__c where id = :we.id];
        system.assertEquals(we.Contact_Person_Phone__c, tidyPhone, 'Phone number should be formatted as an Australia Mobile, including +61 ' +we.Contact_Person_Phone__c );
    }

    
}