/**
 * @description     :   Test class for Volunteer Hours Trigger
 * @author          :   Sachin Shetty
 * @date            :   29-05-2025
 * @group           :   Platforms
 * @revision
 *  17-08-2019      Sachin Shetty    - Created
 *  29-05-2025      Sachin Shetty    - EPCP-4512 - Test class updated to handle updated trigger
 */ 
@isTest(isParallel=true)
private class VOL_VolunteerHours_AddToCampaign_Test {
    @TestSetup
    static void makeData() {
        Account acc = new Account(name='Individual Test Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', AccountId=acc.Id, Volunteer_Status__c='inactive');
        insert con;
        Campaign cmp = new Campaign(name='Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
    }

    @isTest
    static void testCampaignMemberCreation() {
        // GIVEN : Test contact, volunteer job, volunteer shift
        Contact con = [SELECT ID, Lastname, Volunteer_Status__c FROM Contact LIMIT 1];
        Volunteer_Job__c job = [SELECT ID, Name, campaign__c FROM Volunteer_Job__c limit 1];
        
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, Start_Date_Time__c=System.now());
        insert shift;
        shift = [SELECT ID, Volunteer_Job__c, Duration__c, Start_Date_Time__c FROM Volunteer_Shift__c LIMIT 1];
        Campaign cmp = [SELECT ID FROM Campaign LIMIT 1];

        // test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id,
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Start_Date__c=System.today(),
                Status__c='Confirmed'
                );
            listHours.add(hours);
        }

        // WHEN : Volunteer Hour records are inserted
        test.startTest();
        	insert listHours;
        test.stopTest();

        // THEN : Campaign Members are created
        List<CampaignMember> campaignMembers = [SELECT Status FROM CampaignMember WHERE CampaignId =: cmp.Id];
        Assert.isTrue(!campaignMembers.isEmpty(), 'Campaign Member should be present');
    }
    
        
    @isTest
    static void testVolunteerStatusOnContactSet() {
        // GIVEN : Test contact, volunteer job, volunteer shift
        Contact con = [SELECT ID, Lastname, Volunteer_Status__c FROM Contact LIMIT 1];
        Volunteer_Job__c job = [SELECT ID, Name, campaign__c FROM Volunteer_Job__c limit 1];
        Volunteer_Shift__c shift = new Volunteer_Shift__c(
            Volunteer_Job__c=job.Id, 
            Duration__c=1,
        	Start_Date_Time__c=Datetime.now());
        insert shift;
        
        // Test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id,
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Status__c='Completed');
            listHours.add(hours);
        }

        // WHEN : Volunteer Hour records are inserted
        test.startTest();
        	insert listHours;
        test.stopTest();

        // THEN : Contact - Volunteer Status should be set to 'Active'
        con = [SELECT ID, Volunteer_Status__c FROM Contact LIMIT 1];
        Assert.areEqual('Active', con.Volunteer_Status__c, 'Contact - Volunteer Status should be Active');
    }
    
    @isTest
    static void testVolunteerStatusOnContactSetOnUpdate() {
        // GIVEN : Test contact, volunteer job, volunteer shift
        Contact con = [SELECT ID, Lastname, Volunteer_Status__c FROM Contact LIMIT 1];
        Volunteer_Job__c job = [SELECT ID, Name, campaign__c FROM Volunteer_Job__c limit 1];
        Volunteer_Shift__c shift = new Volunteer_Shift__c(
            Volunteer_Job__c=job.Id, 
            Duration__c=1,
        	Start_Date_Time__c=Datetime.now());
        insert shift;

        // Test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id,
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Status__c='Prospect');
            listHours.add(hours);
        }
        insert listHours;
        
		// Contact - Volunteer Status is not set to 'Active'
        con = [SELECT Id, Volunteer_Status__c FROM Contact LIMIT 1];
        Assert.areNotEqual('Active', con.Volunteer_Status__c, 'Contact - Volunteer Status should not be Active');
        
        /*listHours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id];
        for(Volunteer_Hours__c hour : listHours){
            hour.Status__c='In Progress';
        }*/
        Volunteer_Hours__c ss = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id LIMIT 1];
        ss.Status__c='In Progress';

        // WHEN : Volunteer Hour records are updated
        test.startTest();
        	//update listHours;
        	update ss;
        test.stopTest();

        // THEN : Contact - Volunteer Status is updated to 'Active'
        con = [SELECT Volunteer_Status__c FROM Contact LIMIT 1];
        Assert.areEqual('Active', con.Volunteer_Status__c, 'Contact - Volunteer Status should be Active');
    }
    
    @isTest
    static void testVolunteerStatusOnContactNotActive() {
        // GIVEN : Test contact, volunteer job, volunteer shift
        Contact con = [SELECT ID, Lastname, Volunteer_Status__c FROM Contact LIMIT 1];
        Volunteer_Job__c job = [SELECT ID, Name, campaign__c FROM Volunteer_Job__c limit 1];
        Volunteer_Shift__c shift = new Volunteer_Shift__c(
            Volunteer_Job__c=job.Id, 
            Duration__c=1,
        	Start_Date_Time__c=Datetime.now());
        insert shift;

        // Test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id,
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Status__c='Prospect');
            listHours.add(hours);
        }
        insert listHours;

		test.startTest();        
			// Contact - Volunteer Status is not set to 'Active'
            con = [SELECT Id, Volunteer_Status__c FROM Contact LIMIT 1];
            Assert.areNotEqual('Active', con.Volunteer_Status__c, 'Contact - Volunteer Status should not be Active');
        
        	con.Volunteer_Status__c = 'Available';
        	update con;
            
            listHours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id];
            for(Volunteer_Hours__c hour : listHours){
                hour.Status__c='Withdrawn'; 
            }
    
            // WHEN : Volunteer Hour records are updated 
            // 	(Volunteer Hours - Status neither 'Completed' nor 'In Progress' and Contact - Volunteer Status is 'Available' )
            update listHours;
    
            // THEN : Contact - Volunteer Status is updated to 'Active'
            con = [SELECT Id, Volunteer_Status__c FROM Contact LIMIT 1];
            Assert.areNotEqual('Active', con.Volunteer_Status__c, 'Contact - Volunteer Status should not be Active');
        
        
            con.Volunteer_Status__c = 'Not Active - Do Not Engage';
        	update con;
            
            listHours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id];
            for(Volunteer_Hours__c hour : listHours){
                hour.Status__c='Completed';
            }
    
            // WHEN : Volunteer Hour records are updated 
            // 	(Volunteer Hours - Status is 'Completed' but Contact - Volunteer Status is neither ‘Active’ nor ‘Not Active - Do Not Engage’ nor 'Not Active - Withdrawn')
            update listHours;
    
            // THEN : Contact - Volunteer Status is updated to 'Active'
            con = [SELECT Volunteer_Status__c FROM Contact LIMIT 1];
            Assert.areNotEqual('Active', con.Volunteer_Status__c, 'Contact - Volunteer Status should not be Active');
        
        test.stopTest();
    }
}