/* 
 * Email Services test classes
 */ 
@isTest(isParallel=true)
public class EmailServices_Test {
    

    /*
     * @description Set up test environment
     */ 
    @testSetup 
    static void setupData(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;
    }
    
    
    /*
     * @description Ensure that Monash Email remains primary when channel break up occurs
     */ 
    @isTest
    static void validateStudent() {

        String contactStr = '{"Person_ID_unique__c":"12345555","FirstName":"Eddy","LastName":"Test","Is_Student__c" : true,"Monash_Email_Address__c":"12345555@monash.edu"}';
        Contact contactRecord = (Contact)JSON.deserialize(contactStr, Contact.class);
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
                Email__c = 'personal_postal@postal.com',
                Start_Date__c = Date.today()-720
            )
        ); 
        chanlst.add(
            new Channel__c(
                type__c = 'HOME',
                Contact__c = contactRecord.id,
                Street__c = '55 Collin St',
                Post_Code__c = '3000',
                State__c = 'Vic',
                City__c = 'Melbourne',
                Country__c = 'Australia',
                Source_System__c = 'Callista',
                Email__c = 'personal_home@home.com',
                Start_Date__c = Date.today()-360
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();

        // A channel breakup should have happened
        // Personal emails from channels will be ignored
        List<email__c> emailList = [SELECT Id, name, source__c, start_date__c FROM email__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = TRUE];
        Assert.areEqual(1, emailList.size());
        Assert.areNotEqual( chanlst[0].Source_System__c,emailList[0].Source__c, 'New primary should have an undefined source'); // active student, so monash email, but was created as part of rolldown
        Assert.areEqual( date.today() , emailList[0].start_date__c); // most recent
    }
    
    /*
     * @description Ensure that Personal Email becomes primary when channel break up occurs
     */ 
    @isTest
    static void validate_NonStudent() {

        String contactStr = '{"Person_ID_unique__c":"12345555","FirstName":"Eddy","LastName":"Test","Is_Student__c" : false,"Monash_Email_Address__c":"12345555@monash.edu"}';
        Contact contactRecord = (Contact)JSON.deserialize(contactStr, Contact.class);
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
                Email__c = 'personal_postal@postal.com',
                Start_Date__c = Date.today()-1
            )
        ); 
        chanlst.add(
            new Channel__c(
                type__c = 'HOME',
                Contact__c = contactRecord.id,
                Street__c = '55 Collin St',
                Post_Code__c = '3000',
                State__c = 'Vic',
                City__c = 'Melbourne',
                Country__c = 'Australia',
                Source_System__c = 'Callista',
                Email__c = 'personal_home@home.com',
                Start_Date__c = Date.today()
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();

        // A channel breakup should have happened
        // Personal emails from channels will not be ignored
        List<email__c> emailList = [SELECT Id, name, source__c, start_date__c FROM email__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = TRUE];
        Assert.areEqual(1, emailList.size());
        Assert.areEqual( chanlst[0].Source_System__c,emailList[0].Source__c, 'New primary should have a Callista source'); 
        Assert.areEqual( 'personal_home@home.com', emailList[0].name); // most recent
    }
    
}