/**
 * @description     :   Test class for Volunteer Hours : AS : Update Fields flow
 * @author          :   Sachin Shetty
 * @date            :   29-05-2025
 * @group           :   Platforms
 * @revision
 *  29-05-2025      Sachin Shetty    - EPCP-4512  created test class to test the Volunteer Hours : AS : Update Fields Flow
 */ 
@isTest (isParallel = true)
public class VolunteerHoursASUpdateFields_FT {
    @TestSetup
    static void makeData() {
        Account acc = new Account(
            name='Individual Test Account');
        insert acc;
        
        Contact con = new Contact(
            Lastname='Testy', 
            AccountId=acc.Id, 
            Volunteer_Status__c='Available');
        insert con;
        
        Campaign cmp = new Campaign(
            name='Test Campaign', 
            IsActive=true);
        insert cmp;
        
        Volunteer_Job__c job = new Volunteer_Job__c(
            name='Job1', 
            campaign__c=cmp.Id);
        insert job;
    }
    
    @isTest
    static void testSetEndDateInsert() {
        // GIVEN : Test contact, volunteer job, volunteer shift
        Contact con = [SELECT ID, Lastname, Volunteer_Status__c FROM Contact LIMIT 1];
        Volunteer_Job__c job = [SELECT ID, Name, campaign__c FROM Volunteer_Job__c limit 1];
        Volunteer_Shift__c shift = new Volunteer_Shift__c(
            Volunteer_Job__c=job.Id, 
            Duration__c=1,
        	Start_Date_Time__c=Datetime.now());
        insert shift;
        
        Date todayDate = System.today();

        // Test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id,
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Start_Date__c=todayDate,
                Status__c='Qualified');
            listHours.add(hours);
        }

        // WHEN : Volunteer Hour records are inserted
        test.startTest();
        	insert listHours;
        test.stopTest();

        // THEN : The End Date on the Volunteer Hours are populated with Start Date
        for(Volunteer_Hours__c hour : [SELECT Start_Date__c, End_Date__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id]){
            Assert.isTrue(hour.Start_Date__c==hour.End_Date__c, 'End Date should be same as Start Date');
        }
    }
    
    @isTest
    static void testSetEndDateUpdate() {
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
                Status__c='Qualified');
            listHours.add(hours);
        }
        insert listHours;
        
        listHours = [SELECT Id, Start_Date__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id];
		Date todayDate = System.today();
        for(Volunteer_Hours__c hour : listHours){
            hour.Start_Date__c = todayDate;
        }

        // WHEN : Volunteer Hour records are updated
        test.startTest();
        	update listHours;
        test.stopTest();

        // THEN : The End Date on the Volunteer Hours are populated with Start Date
        for(Volunteer_Hours__c hour : [SELECT Start_Date__c, End_Date__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id]){
            Assert.isTrue(hour.Start_Date__c==hour.End_Date__c, 'End Date should be same as Start Date');
        }
    }
    
    @isTest
    static void testSetEndDateNotUpdated() {
        // GIVEN : Test contact, volunteer job, volunteer shift
        Contact con = [SELECT ID, Lastname, Volunteer_Status__c FROM Contact LIMIT 1];
        Volunteer_Job__c job = [SELECT ID, Name, campaign__c FROM Volunteer_Job__c limit 1];
        Volunteer_Shift__c shift = new Volunteer_Shift__c(
            Volunteer_Job__c=job.Id, 
            Duration__c=1,
        	Start_Date_Time__c=Datetime.now());
        insert shift;
		Date todayDate = System.today();
        
        // Test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id,
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Start_Date__c=todayDate,
                Status__c='Qualified');
            listHours.add(hours);
        }
        insert listHours;
        
        listHours = [SELECT Id, Start_Date__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id];
		Date newDate = System.today().addMonths(-3);
        for(Volunteer_Hours__c hour : listHours){
            hour.Start_Date__c = newDate;
        }

        // WHEN : Volunteer Hour records are updated
        test.startTest();
        	update listHours;
        test.stopTest();

        // THEN : The End Date on the Volunteer Hours are not updated as they were already populated
        for(Volunteer_Hours__c hour : [SELECT Start_Date__c, End_Date__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id]){
            Assert.isFalse(hour.Start_Date__c==hour.End_Date__c, 'End Date should not be same as Start Date');
        }
    }
    
    @isTest
    static void testSetPlannedStartDateInsert() {
        // GIVEN : Test contact, volunteer job, volunteer shift
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Volunteer_Job__c job = [SELECT Id FROM Volunteer_Job__c limit 1];

        DateTime timeNow = Datetime.now();
        Volunteer_Shift__c shift = new Volunteer_Shift__c(
            Volunteer_Job__c=job.Id, 
            Duration__c=1,
        	Start_Date_Time__c=timeNow);
        insert shift;

        // Test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id,
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Status__c='Qualified');
            listHours.add(hours);
        }

        // WHEN : Volunteer Hour records are inserted
        test.startTest();
        	insert listHours;
        test.stopTest();

        // THEN : The Planned Start Date Time on the Volunteer Hours are populated with Shift Start Date Time
        for(Volunteer_Hours__c hour : [SELECT Planned_Start_Date_Time__c, Shift_Start_Date_Time__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id]){
            Assert.isTrue(hour.Planned_Start_Date_Time__c==hour.Shift_Start_Date_Time__c, 'Planned Start Date Time should be same as Shift Start Date Time');
        }
    }
    
    @isTest
    static void testSetPlannedStartDateUpdate() {
        // GIVEN : Test contact, volunteer job, volunteer shift
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Volunteer_Job__c job = [SELECT Id FROM Volunteer_Job__c limit 1];

        // Test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id,
                //Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Status__c='Qualified');
            listHours.add(hours);
        }
        insert listHours;
        
        DateTime timeNow = Datetime.now();
        Volunteer_Shift__c shift = new Volunteer_Shift__c(
            Volunteer_Job__c=job.Id, 
            Duration__c=1,
        	Start_Date_Time__c=timeNow);
        insert shift;

        
        listHours = [SELECT Id, Number_of_Volunteers__c, Volunteer_Shift__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id];
        for(Volunteer_Hours__c hour : listHours){
            hour.Number_of_Volunteers__c = 4;
            hour.Volunteer_Shift__c=shift.Id;
        }

        // WHEN : Volunteer Hour records are updated
        test.startTest();
        	update listHours;
        test.stopTest();

        // THEN : The Planned Start Date Time on the Volunteer Hours are populated with Shift Start Date Time
        for(Volunteer_Hours__c hour : [SELECT Planned_Start_Date_Time__c, Shift_Start_Date_Time__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id]){
            Assert.isNotNull(hour.Planned_Start_Date_Time__c, 'Planned Start Date is populated');
            Assert.isTrue(hour.Planned_Start_Date_Time__c==hour.Shift_Start_Date_Time__c, 'End Date should be same as Start Date');
        }
    }
    
    @isTest
    static void testSetPlannedStartDateNotUpdated() {
        // GIVEN : Test contact, volunteer job, volunteer shift
        Contact con = [SELECT ID, Lastname, Volunteer_Status__c FROM Contact LIMIT 1];
        Volunteer_Job__c job = [SELECT ID, Name, campaign__c FROM Volunteer_Job__c limit 1];

        // Test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Status__c='Qualified');
            listHours.add(hours);
        }
        insert listHours;
        
        DateTime timeNow = Datetime.now();
        Volunteer_Shift__c shift = new Volunteer_Shift__c(
            Volunteer_Job__c=job.Id, 
            Duration__c=1,
        	Start_Date_Time__c=timeNow);
        insert shift;
        
        listHours = [SELECT Id, Number_of_Volunteers__c, Volunteer_Shift__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id];
        for(Volunteer_Hours__c hour : listHours){
            hour.Number_of_Volunteers__c = 4;
            hour.Volunteer_Shift__c=shift.Id;
        }
        update listHours; // Should populate Planned_Start_Date_Time__c
        
        for(Volunteer_Hours__c hour : [SELECT Planned_Start_Date_Time__c, Shift_Start_Date_Time__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id]){
            Assert.isNotNull(hour.Planned_Start_Date_Time__c, 'Planned Start Date is populated');
            Assert.isTrue(hour.Planned_Start_Date_Time__c==hour.Shift_Start_Date_Time__c, 'End Date should be same as Start Date');
        }
        
        shift = [SELECT ID, Volunteer_Job__c, Duration__c, Start_Date_Time__c FROM Volunteer_Shift__c LIMIT 1];
        DateTime newtime = Datetime.now().addDays(-3);
        shift.Start_Date_Time__c = newtime;
        update shift;
        
        listHours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id];
        for(Volunteer_Hours__c hour : listHours){
            hour.Status__c='In Progress';
        }

        // WHEN : Volunteer Hour records are updated
        test.startTest();
        	update listHours;
        test.stopTest();

        // THEN : The Planned Start Date Time on the Volunteer Hours are not updated as they were already populated
        for(Volunteer_Hours__c hour : [SELECT Planned_Start_Date_Time__c, Shift_Start_Date_Time__c FROM Volunteer_Hours__c WHERE Contact__c=:con.Id]){
            Assert.isFalse(hour.Planned_Start_Date_Time__c==hour.Shift_Start_Date_Time__c, 'End Date should not be same as Start Date');
        }
    }
}