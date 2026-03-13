/*
 * @author Charlie Park, UC Innovation
 * @date 11/10/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for get involved page
 */
@IsTest //(IsParallel=true) System.DmlException: Insert failed. First exception on row 0; first error: APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public class PORTAL_UCIN_GetInvolvedController_Test {
    @testSetup
    static void setupData() {
        Campaign camp = new Campaign();
        camp.isActive = true;
        camp.Name = 'test';
        insert camp;

        List<Volunteer_Job__c> volJobs = new List<Volunteer_Job__c>();
        Volunteer_Job__c job = new Volunteer_Job__c();
        job.Campaign__c = camp.Id;
        job.Externally_Visible__c = true;
        job.Areas_of_Interest__c = 'Education';
        volJobs.add(job);
        
        Volunteer_Job__c job2 = new Volunteer_Job__c();
        job2.Campaign__c = camp.Id;
        job2.Externally_Visible__c = true;
        job2.Areas_of_Interest__c = 'Art and Design';
        job2.Volunteer_Type__c = 'Other';
        volJobs.add(job2);

        Volunteer_Job__c job3 = new Volunteer_Job__c();
        job3.Campaign__c = camp.Id;
        job3.Externally_Visible__c = true;
        job3.Areas_of_Interest__c = 'Art and Design';
        job3.Skills_Needed__c = 'Sales';
        volJobs.add(job3);
        
         Volunteer_Job__c job4 = new Volunteer_Job__c();
        job4.Name = 'Interesting Job';
        job4.Campaign__c = camp.Id;
        job4.Externally_Visible__c = true;
        job4.End_Date__c = Date.today().addDays(10);
        volJobs.add(job4);
        
        insert volJobs;
        
        /*
        Volunteer_Shift__c shift = new Volunteer_Shift__c();
        shift.Volunteer_Job__c = job.Id;
        shift.Start_Date_Time__c = system.today();
        shift.Duration__c = 8;
        insert shift;*/
    }

    @isTest
    public static void test_SERVER_getVolunteerJobs() {
        test.startTest();
        list<Volunteer_Job__c> jobList = PORTAL_UCIN_GetInvolvedController.SERVER_getVolunteerJobs('', '', '', '10');
        test.stopTest();

        // Retrieve jobs successfully
        System.assertNotEquals(jobList.size(), 0); 
    }



    @isTest
    public static void test_SERVER_searchVolunteerJob() {
        test.startTest();
        List<Volunteer_Job__c> jobList = PORTAL_UCIN_GetInvolvedController.SERVER_searchVolunteerJob('rt and design');
        test.stopTest();

        // Should find based on Art and Design search 
        System.assertNotEquals(jobList.size(), 0);
    }

    @isTest
    public static void test_SERVER_expressInterest() {
        Volunteer_Job__c thisJob = [select id, Start_Date__c from Volunteer_Job__c WHERE Name = 'Interesting Job'  LIMIT 1];

        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];

        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'test2@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);

        Id contactId;
        String username =  System.now().millisecond() + 'testEmail925@gmail.com';
        System.runAs ( portalAccountOwner1 ) {
            //Create account
            Account portalAccount1 = new Account(
            Name = 'TestAccount',
            OwnerId = portalAccountOwner1.Id);
            Database.insert(portalAccount1);       

            //create contact (needed by user)
            Contact contact = new contact(LastName = 'LastName', Firstname = 'FirstName');
            contact.Birthdate =  Date.valueOf('2019-09-24');
            contact.AccountId = portalAccount1.Id;
            contact.Volunteer_Areas_of_Interest__c = 'Education';
            contact.Volunteer_Roles__c = 'Mentor';
            contact.Volunteer_Skills__c = 'Sales';
            insert contact;

            User user = new User();
            user.FirstName = 'Customer';
            user.LastName = 'User';
            user.Alias = 'test';
            user.CommunityNickname = 'Test1';
            user.TimeZoneSidKey = 'America/New_York';
            user.LocaleSidKey = 'en_US';
            user.EmailEncodingKey = 'UTF-8';
            user.Email = 'testEmail925@gmail.com';
            user.Username =  username;
            user.IsActive = true;
            user.LanguageLocaleKey = 'en_US';
            user.App_Birthdate__c = Date.valueOf('2019-09-24');        
            
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name ='Customer Community General User']; 
            system.debug('PROFILES SIZE: ' + profiles.size());
            if(profiles.size() > 0)
            {
                
                user.ProfileID = profiles[0].Id;       		
                user.ContactId = contact.Id;
                insert user;
                PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Alumni_Portal_Permission_Set'];
                insert new PermissionSetAssignment(AssigneeId = user.id, PermissionSetId = ps.Id);
            }     
            Volunteer_Hours__c volHours = new Volunteer_Hours__c(Contact__c = contact.Id, Volunteer_Job__c = thisJob.Id, Status__c = 'Web Sign Up', 
                                                                Start_Date__c = thisJob.Start_Date__c, Number_of_Volunteers__c = 1);
            insert volHours;
        }

        test.startTest();
        User portalUser = [SELECT ID FROM User WHERE Username   = :username LIMIT 1];
        
        system.runAs(portalUser) {
            PORTAL_UCIN_GetInvolvedController.SERVER_expressInterest(thisJob.Id);
            List<Volunteer_Job__c> volPrint = PORTAL_UCIN_GetInvolvedController.SERVER_getVolunteerJobs('', '', '', '10');
            for(Volunteer_Job__c v :volPrint) {
                System.assertNotEquals(thisJob.Id, v.Id);
            }
            List<Volunteer_Job__c> myJobs = PORTAL_UCIN_GetInvolvedController.SERVER_getVolunteerJobs('', 'Me', '', '10');
            System.assert(myJobs.size() > 0);
            
            System.assertNotEquals(PORTAL_UCIN_GetInvolvedController.SERVER_getContactInfo(), null);
        }
        
        test.stopTest();
    }
}