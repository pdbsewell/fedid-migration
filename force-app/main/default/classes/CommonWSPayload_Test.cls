/**
 * @description Test class for CommonWSPayload. This is Payload class, so no functional testing
 * @author      Nick Guia
 * @since       AUG.02.2024
 */
@isTest(isParallel=true)
private class CommonWSPayload_Test {

    /**
     * @description an example of how to map Country Attribute fields
     * into the wrapper. No functional testing
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldCreateCountry() {
        // GIVEN : a Country Attribute record
        Country_Attribute__c country = new Country_Attribute__c(
            Id = fflib_IDGenerator.generate(Country_Attribute__c.SObjectType),
            Name = 'SomeCountry',
            Callista_Code__c = 'SOMECODE',
            Callista_Country__c = 'CALLISTA_COUNTRY'
        );

        CommonWSPayload.Country wrapper;

        // WHEN : I initialise the wrapper and map fields
        Test.startTest();
        wrapper = new CommonWSPayload.Country();
        wrapper.id = country.Id;
        wrapper.name = country.name;
        wrapper.callistaCode = country.Callista_Code__c;
        wrapper.callistaCountry = country.Callista_Country__c;
        Test.stopTest();

        // THEN the wrapper should be created
        Assert.isNotNull(wrapper, 'Unable to initialize CommonWSPayload.Country');
        Assert.areEqual(country.Id, wrapper.id, 'Country ID mismatch');
        Assert.areEqual(country.Name, wrapper.name, 'Country Name mismatch');
        Assert.areEqual(country.Callista_Code__c, wrapper.callistaCode, 'Callista Code mismatch');
        Assert.areEqual(country.Callista_Country__c, wrapper.callistaCountry, 'Callista Country mismatch');
    }

    /**
     * @description Test the Email class
     */
    @isTest
    static void shouldCreateEmail() {
        // GIVEN a type and email
        String testType = 'Personal';
        String testEmail = 'test@example.com';

        // WHEN I create an email
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.type = testType;
        email.email = testEmail;

        // THEN
        Assert.areEqual(testType, email.type, 'Email type mismatch');
        Assert.areEqual(testEmail, email.email, 'Email address mismatch');
    }

    /**
     * @description Test the Phone class
     */
    @isTest
    static void shouldCreatePhone() {
            // GIVEN a type and phone number
        String testType = 'Mobile';
        String testPhoneNumber = '1234567890';

        // WHEN I create a phone
        CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
        phone.type = testType;
        phone.phoneNumber = testPhoneNumber;

        // THEN the wrapper should be created
        Assert.areEqual(testType, phone.type, 'Phone type mismatch');
        Assert.areEqual(testPhoneNumber, phone.phoneNumber, 'Phone number mismatch');
    }

    /**
     * @description Test the Address class
     */
    @isTest
    static void shouldCreateAddress() {
        // GIVEN a street, city, country, postal code, state, and type
        CommonWSPayload.Address address = new CommonWSPayload.Address();
        address.street = '123 Test St';
        address.city = 'Test City';
        address.country = 'Test Country';
        address.postalCode = '12345';
        address.state = 'Test State';
        address.type = 'Home';

        // THEN
        Assert.areEqual('123 Test St', address.street, 'Street mismatch');
        Assert.areEqual('Test City', address.city, 'City mismatch');
        Assert.areEqual('Test Country', address.country, 'Country mismatch');
        Assert.areEqual('12345', address.postalCode, 'Postal code mismatch');
        Assert.areEqual('Test State', address.state, 'State mismatch');
        Assert.areEqual('Home', address.type, 'Address type mismatch');
    }

    /**
     * @description Test the getPhoneNumber method
     */
    @isTest
    static void shouldGetPhoneNumber() {
        // GIVEN a list of phones with different types and numbers
        List<CommonWSPayload.Phone> phones = new List<CommonWSPayload.Phone>();
        CommonWSPayload.Phone mobilePhone = new CommonWSPayload.Phone();
        mobilePhone.type = 'Mobile';
        mobilePhone.phoneNumber = '1234567890';
        phones.add(mobilePhone);

        CommonWSPayload.Phone homePhone = new CommonWSPayload.Phone();
        homePhone.type = 'Home';
        homePhone.phoneNumber = '0987654321';
        phones.add(homePhone);

        // WHEN I get the phone number for a specific type
        String resultMobile = CommonWSPayload.getPhoneNumber(phones, 'Mobile');
        String resultHome = CommonWSPayload.getPhoneNumber(phones, 'Home');
        String resultWork = CommonWSPayload.getPhoneNumber(phones, 'Work');

        // THEN the phone number should be returned
        Assert.areEqual('1234567890', resultMobile, 'Mobile phone number mismatch');
        Assert.areEqual('0987654321', resultHome, 'Home phone number mismatch');
        Assert.areEqual('', resultWork, 'Work phone number should be empty');
    }

    /**
     * @description Test the getEmail method
     */
    @isTest
    static void shouldGetEmail() {
        // GIVEN a list of emails with different types and addresses
        List<CommonWSPayload.Email> emails = new List<CommonWSPayload.Email>();
        CommonWSPayload.Email personalEmail = new CommonWSPayload.Email();
        personalEmail.type = 'Personal';
        personalEmail.email = 'personal@example.com';
        emails.add(personalEmail);

        CommonWSPayload.Email workEmail = new CommonWSPayload.Email();
        workEmail.type = 'Work';
        workEmail.email = 'work@example.com';
        emails.add(workEmail);

        // WHEN I get the email for a specific type
        String resultPersonal = CommonWSPayload.getEmail(emails, 'Personal');
        String resultWork = CommonWSPayload.getEmail(emails, 'Work');
        String resultOther = CommonWSPayload.getEmail(emails, 'Other');

        // THEN
        Assert.areEqual('personal@example.com', resultPersonal, 'Personal email mismatch');
        Assert.areEqual('work@example.com', resultWork, 'Work email mismatch');
        Assert.areEqual('', resultOther, 'Other email should be empty');
    }
}