/**
 * @author : [Babyshark]
 * @description : Test class for AOStudentHomeController
 * @group : Abroad Outbound
 * @date : 16/05/2024
 * @rev
 * 
 */ 
@IsTest(isParallel=true)
private with sharing class AOStudentHomeController_Test {

    @TestSetup
    static void makeData(){
        AOTestDataFactory.setupForms();
        
        List<Account> accs = TestHelper.createStudent(1);
        insert accs;
        
        List<Contact> cons = TestHelper.createStudentContacts(1, accs);
        cons[0].Preferred_Name__c = 'Preferred';
        insert cons;
        
        List<Course__c> course = TestHelper.createCoursesWithType(1, 'Course-All');
        insert course;
        
        List<Course_Attempt__c> attempts = TestHelper.createCourseAttempts(1, cons[0].Id, course[0].Id);
        insert attempts;
        
        Id proId =[select id from profile where name ='Customer Community Student User'].id;
        Integer rnd = Integer.valueOf(Math.random()*9999);
        User u= new User();
        u.Username = String.valueOf(rnd) + 'testLastName@TestEmail.com.domain';
        u.email = String.valueOf(rnd) + 'testLastName@TestEmail.com';
        u.ContactId = cons[0].id; 
        u.LastName ='test';
        u.Alias ='test123';
        u.isActive = true;
        u.TimeZoneSidKey ='Australia/Sydney';
        u.LocaleSidKey ='en_AU';
        u.EmailEncodingKey ='ISO-8859-1';
        u.ProfileId = proId;
        u.LanguageLocaleKey ='en_US';
        
        System.runAs(new User(Id = UserInfo.getUserId())){ 
        	insert u;
        }
        
    }
    /**
     * @description - test GetFormSubmissions method 
     * @revision
     */
    @isTest
    static void testGetFormSubmissions(){
        User us = [SELECT Id from User WHERE Alias='test123' LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'AO_Customer_Comunity_Abroad_User'];
        
        System.runAs(new User(Id = UserInfo.getUserId())){ 
        	insert new PermissionSetAssignment(AssigneeId = us.Id, PermissionSetId = ps.Id);
        }
        
        //AO_Program__c program = [SELECT Id FROM AO_Program__c LIMIT 1];
        AO_Program_Form_Map__c formM = [SELECT Id FROM AO_Program_Form_Map__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        System.runAs(us){
            AO_Form_Submission__c formS = new AO_Form_Submission__c(
                AO_Program_Form_Map__c = formM.Id,
                AO_Student__c = con.Id,
                AO_Status__c = 'Submitted',
                AO_Submitted_Date__c = Date.Today()
            );
            insert formS;
            List<AOStudentHomeController.ApplicationWrapper> wrapper = AOStudentHomeController.getFormSubmissions();
           
            Assert.areEqual('Submitted',wrapper[0].status,'Status Mismatch');
            Assert.areEqual('Global Study Test 01',wrapper[0].programName, 'Program mismatch');
            Assert.areEqual(Date.Today(),wrapper[0].submittedDate, 'Difefrent Submission date on Form Submisison');
            
        }
    }
    /**
     * @description - test GetUserInfo method 
     * @revision
     */
    @isTest
    static void testGetUserInfo(){
        User us = [SELECT Id from User WHERE Alias='test123' LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'AO_Customer_Comunity_Abroad_User'];
        System.runAs(new User(Id = UserInfo.getUserId())){ 
        	insert new PermissionSetAssignment(AssigneeId = us.Id, PermissionSetId = ps.Id);
        }
        
        
        //Contact con = [SELECT Id FROM Contact LIMIT 1];
        System.runAs(us){
            Map<String,String> userInfo = AOStudentHomeController.getUserInfo();
            Assert.isNotNull(userInfo, 'User Info is not found');
            Assert.areEqual(80,Integer.valueOf(userInfo.get('WAM')), 'Right WAM value is not updated');
        }
    }
}