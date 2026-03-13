/**
 * @File Name          : ProspectiveStudentLeadDAO_Test.cls
 * @Description        : Test class for ProspectiveStudentLeadDAO
 * @Author             : Nick Guia
 * @Group              : Lead Management
**/
@isTest(isParallel=true)
private class ProspectiveStudentLeadDAO_Test {
    
    private static final Integer LCA_NUM = 2;

    @testSetup 
    static void setup() {

        //create Course Masters
        List<Course__c> courseList = new List<Course__c>();
        for(Course__c iCourse : TestHelper.createCourses(LCA_NUM)) {
            iCourse.Type__c = Label.Course_Type_Course_All;
            iCourse.Course_Code__c = iCourse.Name;
            courseList.add(iCourse);
        }
        insert courseList;
        
    }

    /**
     * @description test if getLead() method of ProspectiveStudentLeadDAO
     *  returns the expected value : Lead
     */
    @isTest
    static void getLeadTest() {
        Lead testLead = TestHelper.createLeads(1)[0];
        Test.startTest();
            ProspectiveStudentLeadDAO psDao = new ProspectiveStudentLeadDAO(testLead);
            Lead leadRec = psDao.getLead();
        Test.stopTest();
        System.assert(leadRec != null, 'Unexpected return value from ProspectiveStudentLeadDAO.getLead()');
    }

    /**
     * @description test if getCourseInterests() method of ProspectiveStudentLeadDAO
     *  returns the expected value : List<Lead_Course_Association__c>
     */
    @isTest
    static void getCourseInterestsTest() {
        Lead testLead = TestHelper.createLeads(1)[0];
        List<Lead_Course_Association__c> testLcaList = setupLcaList();
        ProspectiveStudentLeadDAO psDao = new ProspectiveStudentLeadDAO(testLead);
        psDao.setCourseInterest(testLcaList);

        Test.startTest();
            List<Lead_Course_Association__c> lcaList =  psDao.getCourseInterests();
        Test.stopTest();

        System.assert(!lcaList.isEmpty(), 'Unable to get Lead Course Interest list');
    }

    /**
     * @description test if getCourseInterestsMap() method of ProspectiveStudentLeadDAO
     *  returns the expected value : Map<Id, Lead_Course_Association__c>
     */
    @isTest
    static void getCourseInterestsMapTest() {
        Lead testLead = TestHelper.createLeads(1)[0];
        List<Lead_Course_Association__c> testLcaList = setupLcaList();

        ProspectiveStudentLeadDAO psDao = new ProspectiveStudentLeadDAO(testLead);
        psDao.setCourseInterest(testLcaList);

        Test.startTest();
            Map<Id, Lead_Course_Association__c> lcaMap =  psDao.getCourseInterestsMap();
        Test.stopTest();

        System.assert(!lcaMap.isEmpty(), 'Unable to get Lead Course Interest map');
    }

    /**
     * @description test setLead() method of ProspectiveStudentLeadDAO
     */
    @isTest
    static void setLeadTest() {
        Lead testLead = TestHelper.createLeads(1)[0];
        ProspectiveStudentLeadDAO psDao = new ProspectiveStudentLeadDAO(testLead);

        //create new test lead
        Lead leadRec = TestHelper.createLeads(1)[0];
        insert leadRec;

        Test.startTest();
            psDao.setLead(leadRec);
        Test.stopTest();

        //check that this returned tha new test lead
        Lead leadGet = psDao.getLead();
        System.assertEquals(leadRec.Id, leadGet.Id, 'Unable to set Lead in ProspectiveStudentLeadDAO');
    }

    /**
     * @description test addCourseInterest() method of ProspectiveStudentLeadDAO.
     *  This should add a Lead_Course_Association__c record to the existing list
     */
    @isTest
    static void addCourseInterestTest() {
        Lead testLead = TestHelper.createLeads(1)[0];
        List<Lead_Course_Association__c> testLcaList = setupLcaList();
        ProspectiveStudentLeadDAO psDao = new ProspectiveStudentLeadDAO(testLead);

        Test.startTest();
            psDao.addCourseInterest(testLcaList[0]);
        Test.stopTest();

        List<Lead_Course_Association__c> lcaList = psDao.getCourseInterests();
        System.assertEquals(1, lcaList.size(), 'Unexpected number of LCA records found in DAO');
    }

    /**
     * @description test setCourseInterest() method of ProspectiveStudentLeadDAO.
     *  This should relace the existing List<Lead_Course_Association__c> in the class
     */
    @isTest
    static void setCourseInterestTest() {
        Lead testLead = TestHelper.createLeads(1)[0];
        List<Lead_Course_Association__c> testLcaList = setupLcaList();
        ProspectiveStudentLeadDAO psDao = new ProspectiveStudentLeadDAO(testLead);

        Test.startTest();
            psDao.setCourseInterest(testLcaList);
        Test.stopTest();

        List<Lead_Course_Association__c> lcaList = psDao.getCourseInterests();
        System.assertEquals(LCA_NUM, lcaList.size(), 'Unexpected number of LCA records found in DAO');
    }

    /**
     * @description test commit all properties of ProspectiveStudentLeadDAO.
     *  - Lead should relate to the input Contact record
     *  - Lead Course Association records should be related to the Lead record
     */
    @isTest
    static void resolveDependenciesTest() {
        BaseClass bc = new BaseClass(
        new List<Schema.SObjectType> {
            Contact.SObjectType,
            Lead.SObjectType,
            Lead_Course_Association__c.SObjectType
        });

        //create test contact record
        List<Contact> testConList = TestHelper.createProspectiveStudentContact(1);
        System.assert(!testConList.isEmpty(), 'Unable to create Prospective Student Contact');
        bc.push(testConList[0]);

        //create test lead
        Lead testLead = TestHelper.createLeads(1)[0];
        //create test Lead Course Association
        List<Lead_Course_Association__c> testLcaList = setupLcaList();
        ProspectiveStudentLeadDAO psDao = new ProspectiveStudentLeadDAO(testLead);
        psDao.setCourseInterest(testLcaList);

        Test.startTest();
            psDao.resolveDependencies(bc, testConList[0]);
        Test.stopTest();

        Boolean isSuccess = bc.commitRecords();
        System.assert(isSuccess, 'BaseClass unable to commit records');

        List<Contact> conList = [SELECT Id FROM Contact LIMIT 1];
        List<Lead> leadList = [SELECT Id, Contact__c FROM Lead LIMIT 1];
        List<Lead_Course_Association__c> lcaList = [SELECT Id, Lead__C from Lead_Course_Association__c];

        System.assert(!conList.isEmpty(), 'Unable to insert Contact record');
        System.assert(!leadList.isEmpty(), 'Unable to insert Lead record');
        System.assertEquals(conList[0].Id, leadList[0].Contact__c, 'Unable to relate Prospective Lead with Contact record');
        System.assert(!lcaList.isEmpty(), 'Unable to insert Lead Course Association records');
        for(Lead_Course_Association__c iLca : lcaList) {
            System.assertEquals(leadList[0].Id, iLca.Lead__c, 'Unable to relate LCA with Lead');
        }
    }

    
    /**
     * @description for generating setup List of Lead Course Association record (1 per Course Master)
     * @return List<Lead_Course_Association__c> 
     */
    private static List<Lead_Course_Association__c> setupLcaList() {
        List<Lead_Course_Association__c> testLcaList = new List<Lead_Course_Association__c>();
        List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
        System.assert(!cmList.isEmpty(), 'Unexpected error occurred. Course Masters were not generated');
        for(Course_Master__c iCm : cmList) {
            //create a Lead Course Association record per Course Master ID
            List<Lead_Course_Association__c> lcaList = TestHelper.createLCA(iCm.Id, null, 1);
            testLcaList.add(lcaList[0]);
        }
        return testLcaList;
    }

}