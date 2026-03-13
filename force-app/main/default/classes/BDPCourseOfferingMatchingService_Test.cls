/**
 * @author David Browaeys
 * @description Test class for BDPCourseOfferingMatchingService
 * @group Bulk Data Processing
 */
@isTest(isParallel=true)
public inherited sharing class BDPCourseOfferingMatchingService_Test {
    @TestSetup
    static void makeData(){
        TriggerCommon.disableTrigger('Calendar__c');
        TriggerCommon.disableTrigger('Course_Offering__c');
        Country_Attribute__c country = (Country_Attribute__c)TestDataFactory.createSObject(new Country_Attribute__c(Name = 'MALAYSIA'), true); 
        Calendar__c calendar = (Calendar__c) TestDataFactory.createSObject(new Calendar__c(), true);
        Course_Offering__c co = (Course_Offering__c) TestDataFactory.createSObject(new Course_Offering__c(
            Calendar__c = calendar.Id, 
            Course_Title__c = 'Hello World',
            Admission_Category__c = 'UG-IS',
            Course_Code__c = 'DUP101',
            Location_Code__c = 'CLAYTON',
            Unit_Set_Code__c = 'U101',
            Active__c = true,
            Citizenship_Type__c = BDPConstants.DEFAULT_CITIZENSHIP
        ), true);
    }

	@isTest
    private static void testFindDuplicateMatch(){
        Calendar__c calendar = [SELECT Id FROM Calendar__c LIMIT 1 ];
        Course_Offering__c courseOffering = [SELECT Id, Course_Title__c, Calendar__c, Admission_Category__c, Course_Code__c, Location_Code__c, Unit_Set_Code__c, Active__c, Citizenship_Type__c FROM Course_Offering__c WHERE 
                                    Admission_Category__c = 'UG-IS' AND
                                    Calendar__c = :calendar.Id AND
                                    Course_Code__c = 'DUP101' AND 
                                    Location_Code__c = 'CLAYTON' AND
                                    Active__c = true AND
                                    Citizenship_Type__c =: BDPConstants.DEFAULT_CITIZENSHIP LIMIT 1];

        System.assert(courseOffering != null, 'Created the right CO!');

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        Application_Course_Preference__c acp = (Application_Course_Preference__c) TestDataFactory.createSObject(new Application_Course_Preference__c(Course_Offering__c = courseOffering.Id), true);

        Test.startTest();
            BDPCourseOfferingMatchingService service = new BDPCourseOfferingMatchingService();
            service.init();
            service.sobjectDao = (SObjectDao) Test.createStub(SObjectDao.class, new SObjectDaoMocks());
            TriggerCommon.disableTrigger('Bulk_Data_Processing__c');
            Bulk_Data_Processing__c[] bdps = (Bulk_Data_Processing__c[]) TestDataFactory.createSObjectList(
                    new Bulk_Data_Processing__c(
                        Status__c = 'New',
                        Current_Course_Campus__c = 'MALAYSIA', 
                        Current_Course_Code__c = 'DUP101',
                        Person_ID__c = '123456', 
                        Calendar__c = calendar.Id,
                        Transfer_From__c = acp.Id,
                        Transfer_Admission_Category__c = 'UG-IS', 
                        Transfer_Course_Campus__c = 'CLAYTON',  
                        Transfer_Unit_Set__c = 'U101',
                        Transfer_Course_Code__c = String.valueOf(Math.random()),
                        Transfer_Calendar__c = '2021/1')
                    , 1);
            bdps.addAll((Bulk_Data_Processing__c[]) TestDataFactory.createSObjectList(
                    new Bulk_Data_Processing__c(
                        Status__c = 'New',
                        Current_Course_Campus__c = 'CAUFIELD', 
                        Current_Course_Code__c = 'DUP101',
                        Person_ID__c = '123456', 
                        Calendar__c = calendar.Id,
                        Transfer_Admission_Category__c = 'UG-IS', 
                        Transfer_Course_Campus__c = 'CLAYTON',  
                        Transfer_Unit_Set__c = 'U101',
                        Transfer_Course_Code__c = String.valueOf(Math.random()),
                        Transfer_Calendar__c = '2021/1')
                    , 199));
            insert bdps;
            TriggerCommon.disableTrigger('Suggested_Course_Offering__c');
            service.execute(bdps);
            service.createSuggestedCourseOffering(bdps[0], courseOffering);
            service.commitAll();
        Test.stopTest();
        System.assert(service.suggestedCourseOfferings.size() > 0,'Found at least one match');
    }
    
    @isTest static void testHandleDuplicateResults(){
        TriggerCommon.disableTrigger('Bulk_Data_Processing__c');
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', true);
		Test.startTest();
        BDPCourseOfferingMatchingService service = new BDPCourseOfferingMatchingService();
        service.init();
        service.handleDuplicateResults(bdp, new Suggested_Course_Offering__c[]{
            new Suggested_Course_Offering__c(),
            new Suggested_Course_Offering__c()
        });
        System.assert(service.bdpsUpdate.get(bdp.Id).Log__c == BDPConstants.MULTI_CO_FOUND_MSG, 'Multi. course offering found.');
        
        service.handleDuplicateResults(bdp, new Suggested_Course_Offering__c[]{
            new Suggested_Course_Offering__c()
        });
        System.assert(service.bdpsUpdate.get(bdp.Id).Log__c == null, 'One course offering  found.');
        
        service.handleDuplicateResults(bdp, new Suggested_Course_Offering__c[]{});
        System.assert(service.bdpsUpdate.get(bdp.Id).Log__c == BDPConstants.CO_NOT_FOUND_MSG, 'No course offering found.');
        Test.stopTest();
        
    }

    @isTest
    private static void testFindDuplicateNoMatch(){
        BDPCourseOfferingMatchingService service = new BDPCourseOfferingMatchingService();
        service.init();
        service.sobjectDao = (SObjectDao) Test.createStub(SObjectDao.class, new SObjectDaoMocks());
        service.execute(new Bulk_Data_Processing__c[]{
            (Bulk_Data_Processing__c) TestDataFactory.createSObject(new Bulk_Data_Processing__c(
                Person_ID__c = '123456', 
                Transfer_Course_Campus__c = 'KGHKUHIHU', 
                Transfer_Course_Code__c = 'jygiug'), 'TestDataFactorySettings.BulkDataProcessingDefaults', false)
        });
        System.assert(service.suggestedCourseOfferings.size() == 0,'No match found here');
    }
    
    private class SObjectDaoMocks implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            System.debug(stubbedObject);
            System.debug(stubbedMethodName);
            System.debug(returnType);
            System.debug(listOfParamTypes);
            System.debug(listOfParamNames);
            System.debug(listOfArgs);
            return null;
        }
    }
}