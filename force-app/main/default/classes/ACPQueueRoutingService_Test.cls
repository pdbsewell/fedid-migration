/**
 * @description       : ACP queue routing test class
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 30-07-2024
 * @last modified by  : jitender.padda@monash.edu
                        - moved test data setup to test data factory
**/
@isTest(isParallel=true)
public class ACPQueueRoutingService_Test {
    /**
    * @description Create test data.
    * @author   rajesh.punjabi@monash.edu | 17-07-2024 
    * @modified jitender.padda@monash.edu | 30-07-2024
                - moved test data setup to test data factory
    **/
    @testSetup
    static void setup() {

        Account facultyAccount = AssessmentsTestDataFactory.createFacultyAccount();
        insert facultyAccount;

        Contact applicant = AssessmentsTestDataFactory.createApplicant();
        insert applicant;

        Application__c application = AssessmentsTestDataFactory.createApplication('CAID-1239090', applicant.Id);
        insert application;

        Course__c busEcoCourse = AssessmentsTestDataFactory.createCourse(facultyAccount, 'Faculty of Business and Economics');
        insert busEcoCourse;
    }

    @IsTest
    static void routeACPtoQueuesSuccess(){

        // GIVEN: Two ACPs - BUSECO INT (AUSAID-PG) & BUSECO DOM (PG-CSP)
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Application__c application = [SELECT Id FROM Application__c LIMIT 1][0];
        Course__c busEcoCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Faculty of Business and Economics'];

        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'AUSAID-PG', 'CLAYTON', 'IN', null, '1'));
        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'PG-CSP', 'CLAYTON', 'IN', 'B6024', '2'));

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert acpList;
        acpList = [SELECT Managing_Faculty__c, Admission_Category__c, Attendance_Mode__c, Location_Code__c FROM Application_Course_Preference__c];
        TriggerCommon.enableTrigger('Application_Course_Preference__c');

        List<Queue_Routing_Rule_Condition__c> conditions = new List<Queue_Routing_Rule_Condition__c>();
        List<Map<String, String>> conditionsData = new List<Map<String, String>>();
        Queue_Routing_Rule__c rule;

        // GIVEN: ACP Queue Routing rule for BusEco International
        rule = AssessmentsTestHelper.createRule('Central Admissions BUSECO - INTERNATIONAL', 1, 'CENTRAL_ADMISSIONS_BUSECO', true);
        insert rule;

        AssessmentsTestHelper.addCondition(conditionsData, 'Managing_Faculty__c', 'EQUALS', 'Faculty of Business and Economics');
        AssessmentsTestHelper.addCondition(conditionsData, 'Admission_Category__c', 'EQUALS', 'AUSAID-PG; AUSAID-UG; UG-IS; PG-IS');
        AssessmentsTestHelper.addCondition(conditionsData, 'Attendance_Mode__c', 'NOT EQUAL TO', 'EX; MM; OL');
        AssessmentsTestHelper.addCondition(conditionsData, 'Location_Code__c', 'NOT EQUAL TO', 'MALAYSIA; INDONESIA');

        AssessmentsTestHelper.createConditions(rule.Id, conditionsData, conditions);
        insert conditions;
        
        Test.startTest();
        // WHEN: ACP Queue Routing Service is called 
        System.runAs(new User(Id = UserInfo.getUserId())) {
            System.enqueueJob(new ACPQueueRoutingService(acpList));
        }
        Test.stopTest();

        //THEN: BUSECO INT (AUSAID-PG) is routed to BusEco Queue
        Group busEcoQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :rule.Queue__c];
        Assert.areEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'AUSAID-PG'].OwnerId, busEcoQueue.Id);

        //THEN: BUSECO DOM (PG-CSP) is routed to Unallocated Queue
        Group unallocatedQueue = [SELECT Id FROM Group WHERE DeveloperName = :'Unallocated_ACP_Queue'];
        Assert.areEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'PG-CSP'].OwnerId, unallocatedQueue.Id);
    }

    @IsTest
    static void routeACPtoQueuesFail(){

        // GIVEN: Two ACPs - BUSECO INT (AUSAID-PG) & BUSECO DOM (PG-CSP)
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Application__c application = [SELECT Id FROM Application__c LIMIT 1][0];
        Course__c busEcoCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Faculty of Business and Economics'];

        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'AUSAID-PG', 'CLAYTON', 'IN', null,'1'));
        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'PG-CSP', 'CLAYTON', 'IN', 'B6024','2'));

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert acpList;
        acpList = [SELECT Managing_Faculty__c, Admission_Category__c, Attendance_Mode__c, Location_Code__c FROM Application_Course_Preference__c];
        TriggerCommon.enableTrigger('Application_Course_Preference__c');

        // GIVEN: No Queue Routing rules
        
        Test.startTest();
        // WHEN: ACP Queue Routing Service is called 
        System.runAs(new User(Id = UserInfo.getUserId())) {
            System.enqueueJob(new ACPQueueRoutingService(acpList));
        }
        Test.stopTest();

        //THEN: Exception is logged
        List<Nebula__LogEntry__c> logs =  [SELECT Id, Nebula__OriginLocation__c
                                            FROM Nebula__LogEntry__c
                                            WHERE Nebula__OriginLocation__c = 'ACPQueueRoutingService.handleFailures'];
        Assert.isTrue(!logs.isEmpty(), 'Unable to generate Exception Logs');

        Group unallocatedQueue = [SELECT Id FROM Group WHERE DeveloperName = :'Unallocated_ACP_Queue'];

        //THEN: BUSECO INT (AUSAID-PG) is routed to Unallocated Queue
        Assert.areEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'AUSAID-PG'].OwnerId, unallocatedQueue.Id);

        //THEN: BUSECO DOM (PG-CSP) is routed to Unallocated Queue
        Assert.areEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'PG-CSP'].OwnerId, unallocatedQueue.Id);
    }

    @IsTest
    static void isEqualTest(){

        // GIVEN: An instance of ACPQueueRoutingService
        ACPQueueRoutingService service = new ACPQueueRoutingService(new List<Application_Course_Preference__c>());
        
        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())){

            // WHEN : isEqual is called 

            // 1. null & blank checks

            // WHEN : with both null
            // THEN : result is true
            Assert.areEqual(true, service.isEqual(null, null));
            // WHEN : with both blanks
            // THEN : result is true
            Assert.areEqual(true, service.isEqual('', ''));

            // WHEN : with field blank & comparison null
            // THEN : result is false
            Assert.areEqual(false, service.isEqual('', null));
            // WHEN : with field null & comparison blank
            // THEN : result is false
            Assert.areEqual(false, service.isEqual(null, ''));

            // 2. delimeter checks

            // WHEN : with field valid & comparison delimeter
            // THEN : result is false
            Assert.areEqual(false, service.isEqual('Monash', ';'));
            // WHEN : with field null & comparison delimeter
            // THEN : result is false
            Assert.areEqual(false, service.isEqual(null, ';'));
            // WHEN : with field blank & comparison delimeter
            // THEN : result is false
            Assert.areEqual(false, service.isEqual('', ';'));

            // 3. equal value checks

            // WHEN : with equal values
            // THEN : result is true
            Assert.areEqual(true, service.isEqual('Faculty of Medicine, Nursing and Health Sciences', 'Faculty of Medicine, Nursing and Health Sciences'));
            Assert.areEqual(true, service.isEqual('AUSAID-PG', 'AUSAID-PG; AUSAID-UG; UG-IS; PG-IS'));
            Assert.areEqual(true, service.isEqual('MALAYSIA', 'MALAYSIA; INDONESIA'));
            Assert.areEqual(true, service.isEqual('EX', 'EX; MM; OL'));
            Assert.areEqual(true, service.isEqual('M6018', 'M6011; M6018'));

            // 4. different value checks

            // WHEN : with different values
            // THEN : result is false
            Assert.areEqual(false, service.isEqual('Faculty of Art, Design and Architecture', 'Faculty of Medicine, Nursing and Health Sciences'));
            Assert.areEqual(false, service.isEqual('PG-FEE', 'AUSAID-PG; AUSAID-UG; UG-IS; PG-IS'));
            Assert.areEqual(false, service.isEqual('CLAYTON', 'MALAYSIA; INDONESIA'));
            Assert.areEqual(false, service.isEqual('EX', 'MM; OL'));
            Assert.areEqual(false, service.isEqual('A6014', 'M6011; M6018'));
        }
       
        Test.stopTest();
        
    }
}