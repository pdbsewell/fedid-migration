/**
 * @description AddressServices test class
 * 
 * Testing primary calculation logic
 * 
 **/
@isTest(isParallel=true)
private class AddressServices_Test {

    @testSetup 
    static void setupData(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;
    }

    /**
	 * @description 
     * GIVEN Contact is a student
     * WHEN when there is new callista address inserted
     * THEN primary will be the callista address (with the lowest rollup rank), ignoring a more recent start date
     */
    @isTest
    static void validateStudentCallista() {

        String contactStr = '{"Person_ID_unique__c":"12345555","FirstName":"Addy","LastName":"Test","MailingStreet":"350 Bourke Street","MailingCity":"Melbourne","MailingState":"Vic","MailingPostalCode":"3000","MailingCountry":"Australia"}';
        Contact contactRecord = (Contact)JSON.deserialize(contactStr, Contact.class);
        contactRecord.Is_Student__c = true;
        insert contactRecord;
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');

        Test.startTest();
        List<Channel__c> chanlst = new List<Channel__c>();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Street__c = '55 Collin St',
                Post_Code__c = '3000',
                State__c = 'Vic',
                City__c = 'Melbourne',
                Country__c = 'Australia',
                Source_System__c = 'Callista',
                Start_Date__c = Date.today()-720
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();

        // A channel breakup should have occuured. The above address should be primary even though the start date is older that the existing address.
        List<Address__c> addressList = [SELECT Id, source__c, start_date__c FROM Address__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = TRUE];
        Assert.areEqual(1, addressList.size());
        Assert.areEqual( addressList[0].Source__c, chanlst[0].Source_System__c, 'New primary should have a Callista source');
        Assert.areEqual( addressList[0].start_date__c, chanlst[0].start_date__c);
    }

    /**
     * @description
     * GIVEN Contact is a student
     * WHEN when there is no callista address
     * THEN primary will be the latest start date
     */
    @isTest
    static void validatestudentLatestStartDate() {
        String contactStr = '{"Person_ID_unique__c":"12345555","FirstName":"Addy","LastName":"Test","MailingStreet":"350 Bourke Street","MailingCity":"Melbourne","MailingState":"Vic","MailingPostalCode":"3000","MailingCountry":"Australia"}';
        Contact contactRecord = (Contact)JSON.deserialize(contactStr, Contact.class);
        contactRecord.Is_Student__c = true;
        insert contactRecord;
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');
        
        Test.startTest();
        Address__c addRess = new Address__c();
        addRess.Contact__c = contactRecord.Id;
        addRess.Start_Date__c = Date.today();
        addRess.Is_Primary__c = true;
        addRess.Is_Active__c = true;
        addRess.Source__c = 'Undefined';
        addRess.Type__c = 'Physical';
        addRess.Classification__c = 'Private';
        addRess.Street_Name__c = '120 Collins Street';
        addRess.City__c = 'Melbourne';
        addRess.State__c = 'Victoria';
        addRess.Post_Code__c = '3000';
        addRess.Country2__c = 'Australia';
        insert addRess;
        Test.getEventBus().deliver();
        Test.stopTest();
        
        List<Address__c> addressList = [SELECT Id, Source__c, start_date__c FROM Address__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = TRUE];
        Assert.areEqual(1, addressList.size());
        Assert.areNotEqual('Callista', addressList[0].Source__c, 'New primary should not have a Callista source');
        Assert.areEqual(Date.today(), addressList[0].start_date__c);
    }

    /**
     * @description
     * GIVEN Contact is a not student
     * WHEN whether there is a Callista or not
     * THEN primary will be the latest start date
     */
    @isTest
    static void validatenonStudentLatestStartDate() {
        String contactStr = '{"Person_ID_unique__c":"12345555","FirstName":"Addy","LastName":"Test","MailingStreet":"350 Bourke Street","MailingCity":"Melbourne","MailingState":"Vic","MailingPostalCode":"3000","MailingCountry":"Australia"}';
        Contact contactRecord = (Contact)JSON.deserialize(contactStr, Contact.class);
        insert contactRecord;
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');
        
        Test.startTest();
        Address__c addRess = new Address__c();
        addRess.Contact__c = contactRecord.Id;
        addRess.Start_Date__c = Date.today();
        addRess.Is_Primary__c = true;
        addRess.Is_Active__c = true;
        addRess.Source__c = 'Undefined';
        addRess.Type__c = 'Physical';
        addRess.Classification__c = 'Private';
        addRess.Street_Name__c = '120 Collins Street';
        addRess.City__c = 'Melbourne';
        addRess.State__c = 'Victoria';
        addRess.Post_Code__c = '3000';
        addRess.Country2__c = 'Australia';
        insert addRess;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Address__c> addressList = [SELECT Id, source__c, start_date__c FROM Address__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = TRUE];
        Assert.areEqual(1, addressList.size());
        Assert.areNotEqual('Callista', addressList[0].Source__c, 'New primary should not have a Callista source');
        Assert.areEqual(Date.today(), addressList[0].start_date__c);
    }
}