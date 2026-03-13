@isTest(isParallel=true)
private class VOL_Job_Before_Test {
    @TestSetup
    static void makeData() {
        Contact con = new Contact(Lastname='Testy', Firstname='Test', Email='test@testy.com');
        insert con;
        Campaign cmp = new Campaign(name='Test Job Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id, Display_on_Website__c=true);
        insert job;
        Volunteer_Recurrence_Schedule__c vrs = new Volunteer_Recurrence_Schedule__c(Contact__c = con.Id, Volunteer_Job__c = job.Id, Days_of_Week__c='Sunday', Weekly_Occurrence__c='Every',Duration__c=2,Schedule_Start_Date_Time__c=system.today());
        insert vrs;
    }

    static testMethod void myUnitTest() {
        Volunteer_Job__c jobToDelete = [SELECT ID FROM Volunteer_Job__c];
        test.startTest();
        delete jobToDelete;
        test.stopTest();

        List<Volunteer_Recurrence_Schedule__c> vrsList = [SELECT ID FROM Volunteer_Recurrence_Schedule__c];
        system.assert(vrsList.isEmpty());
    }
}