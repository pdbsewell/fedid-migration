/**
 * @author Nick Guia
 * @date 12-09-2020
 * @group Person 360
 * @description Test class for ContactPointBuilderFactory
 **/
@istest(isParallel=true)
private class ContactPointBuilderFactory_Test {

    /**
     * @description build an Address Contact Point
     */
    @IsTest
    static void shouldCreateAddressContactPoint() {
        //given
        Address__c rec;
        String classification = 'Private';
        String streetName = '123 Collins St';
        String city = 'Melbourne';
        String postcode = '3000';
        String type = 'Mailing';
        String source = 'Contact supplied';

        Test.startTest();

        //when
        ContactPointBuilderFactory.AddressContactPointBuilder builder = 
            (ContactPointBuilderFactory.AddressContactPointBuilder) new ContactPointBuilderFactory(new Address__c())
                                                                        .createContactPoint();
        rec = (Address__c) builder.withClassification(classification)
                            .withStreetName(streetName)
                            .withCity(city)
                            .withPostCode(postcode)
                            .withType(type)
                            .withChannel(null)
                            .withSource(source)
                            .getContactPoint();
        Test.stopTest();

        //then
        System.assertEquals(classification, rec.Classification__c, 'Unexpected value for Classification');
        System.assertEquals(streetName, rec.Street_Name__c, 'Unexpected value for Street Name');
        System.assertEquals(city, rec.City__c, 'Unexpected value for City');
        System.assertEquals(postcode, rec.Post_code__c, 'Unexpected value for Post Code');
        System.assertEquals(type, rec.Type__c, 'Unexpected value for Type');
        System.assertEquals(source, rec.Source__c, 'Unexpected value for Source');
    }

    /**
     * @description build an Email Contact Point
     */
    @IsTest
    static void shouldCreateEmailContactPoint() {
        //given
        Email__c rec;
        String classification = 'Private';
        String emailId = 'ContactPointBuilderFactory@test.org';
        String source = 'Contact supplied';

        Test.startTest();

        //when
        ContactPointBuilderFactory.EmailContactPointBuilder builder = 
            (ContactPointBuilderFactory.EmailContactPointBuilder) new ContactPointBuilderFactory(new Email__c())
                                                                    .createContactPoint();
        rec = (Email__c) builder.withClassification(classification)
                            .withEmailId(emailId)
                            .withChannel(null)
                            .withSource(source)
                            .getContactPoint();
        Test.stopTest();

        //then
        System.assertEquals(classification, rec.Classification__c, 'Unexpected value for Classification');
        System.assertEquals(emailId, rec.Name, 'Unexpected value for Email Address (Name)');
        System.assertEquals(source, rec.Source__c, 'Unexpected value for Source');
    }

    /**
     * @description build a Phone Contact Point
     */
    @IsTest
    static void shouldCreatePhoneContactPoint() {
        //given
        Phone__c rec;
        String classification = 'Private';
        String phone = '+61123456789';
        String type = 'Mobile';
        String source = 'Contact supplied';

        Test.startTest();

        //when
        ContactPointBuilderFactory.PhoneContactPointBuilder builder = 
            (ContactPointBuilderFactory.PhoneContactPointBuilder) new ContactPointBuilderFactory(new Phone__c())
                                                                .createContactPoint();
        rec = (Phone__c) builder.withClassification(classification)
                                .withPhoneNumber(phone)
                                .withType(type)
                                .withChannel(null)
                                .withSource(source)
                                .getContactPoint();
        Test.stopTest();

        //then
        System.assertEquals(classification, rec.Classification__c, 'Unexpected value for Classification');
        System.assertEquals(phone, rec.Name, 'Unexpected value for Phone (Name)');
        System.assertEquals(type, rec.Type__c, 'Unexpected value for Type');
        System.assertEquals(source, rec.Source__c, 'Unexpected value for Source');
    }

    /**
     * @description build a Social Contact Point
     */
    @IsTest
    static void shouldCreateSocialContactPoint() {
        //given
        Social__c rec;
        String classification = 'Private';
        String name = 'Facebook Account';
        String type = 'Facebook';
        String url = 'https://facebook.com/';
        String source = 'Contact supplied';

        Test.startTest();

        //when
        ContactPointBuilderFactory.SocialContactPointBuilder builder = 
            (ContactPointBuilderFactory.SocialContactPointBuilder) new ContactPointBuilderFactory(new Social__c())
                                                                        .createContactPoint();
        rec = (Social__c) builder.withClassification(classification)
                            .withName(name)
                            .withType(type)
                            .withUrl(url)
                            .withSource(source)
                            .getContactPoint();
        Test.stopTest();

        //then
        System.assertEquals(classification, rec.Classification__c, 'Unexpected value for Classification');
        System.assertEquals(name, rec.Name, 'Unexpected value for Name');
        System.assertEquals(type, rec.Type__c, 'Unexpected value for Type');
        System.assertEquals(url, rec.Url__c, 'Unexpected value for URL');
        System.assertEquals(source, rec.Source__c, 'Unexpected value for Source');
    }

    /**
     * @description build a Name Contact Point
     */
    @IsTest
    static void shouldCreateNameContactPoint() {
        //given
        Name__c rec;
        String salutation = 'Mr';
        String firstName = 'Test';
        String midName = 'Contact Point';
        String lastName = 'Name';
        String suffix = 'Jr';
        String type = 'Legal name';
        String source = 'Contact supplied';

        Test.startTest();

        //when
        ContactPointBuilderFactory.NameContactPointBuilder builder = 
            (ContactPointBuilderFactory.NameContactPointBuilder) new ContactPointBuilderFactory(new Name__c())
                                                                .createContactPoint();
        rec = (Name__c) builder.withSalutation(salutation)
                            .withName(firstName, lastName)
                            .withName(firstName, midName, lastName)
                            .withSuffix(suffix)
                            .withType(type)
                            .withSource(source)
                            .getContactPoint();
        Test.stopTest();

        //then
        System.assertEquals(salutation, rec.Salutation__c, 'Unexpected value for Salutation');
        System.assertEquals(firstName, rec.First_Name__c, 'Unexpected value for First Name');
        System.assertEquals(midName, rec.Middle_Name__c, 'Unexpected value for Middle Name');
        System.assertEquals(lastName, rec.Last_Name__c, 'Unexpected value for Last Name');
        System.assertEquals(suffix, rec.Suffix__c, 'Unexpected value for Post Suffix');
        System.assertEquals(type, rec.Type__c, 'Unexpected value for Type');
        System.assertEquals(source, rec.Source__c, 'Unexpected value for Source');
    }
}