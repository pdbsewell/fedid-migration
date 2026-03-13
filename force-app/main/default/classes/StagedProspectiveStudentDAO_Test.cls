/**
 * @File Name          : StagedProspectiveStudentDAO_Test.cls
 * @Description        : Test class for StagedProspectiveStudentDAO
 * @Author             : Nick Guia
 * @Group              : Lead Management
**/
@isTest(isParallel=true)
private class StagedProspectiveStudentDAO_Test {
    
    @TestSetup
    static void setup(){
        //create Course Masters
        List<Course__c> courseList = new List<Course__c>();
        for(Course__c iCourse : TestHelper.createCourses(1)) {
            iCourse.Type__c = Label.Course_Type_Course_All;
            iCourse.Course_Code__c = iCourse.Name;
            courseList.add(iCourse);
        }
        insert courseList;

        //create Campaigns
        List<Campaign> campaignList = new List<Campaign>();
        
        //get non montrack record type ID
        Id nonMonRT = Schema.SObjectType.Campaign
                        .getRecordTypeInfosByDeveloperName()
                        .get('Non_Montrack')
                        .getRecordTypeId();
        //get subscription list record type ID
        Id subsListRT = Schema.SObjectType.Campaign
                        .getRecordTypeInfosByDeveloperName()
                        .get('Subscription_List')
                        .getRecordTypeId();

        //acquisition campaign
        Campaign acquisition = new Campaign(Name = 'AcquisitionCampaign');
        campaignList.add(acquisition);

        //Subscription Campaign
        Campaign subscriptionCampaign = new Campaign(Name = 'SubscriptionCampaign',
                                                    Channel_Type__c = 'Email;SMS',
                                                    RecordTypeId = subsListRT);
        campaignList.add(subscriptionCampaign);
        
        //Event Campaigns
        Campaign eventCampaign = new Campaign(Name = 'EventCampaign');
        campaignList.add(eventCampaign);
        
        //insert campaigns
        insert campaignList;
    }

    /**
     * @description test add a single sps record in the dao class
     */
    @isTest
    static void addSpsTest() {
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(2);
        StagedProspectiveStudentDAO dao;

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsList[0]);
            dao.addSps(spsList[1]);
        Test.stopTest();

        System.assertEquals(2, dao.spsList.size(),'Unexpected number of SPS records stored in DAO class');
    }

    /**
     * @description test the function for getting a "merged" version of SPS without
     *  considering the DNO value. i.e. first in - first out
     */
    @isTest
    static void getMergedSpsRecordsWithDNOTest() {
        
        //create a DNO = true SPS record
        Staged_Prospective_Student__c dno = new Staged_Prospective_Student__c();
        dno.First_Name__c = 'testFirst';
        dno.Last_Name__c = 'testLast';
        dno.Email__c = 'test@test.org';
        dno.Mobile__c = '123456789';
        dno.Do_Not_Overwrite__c = true;

        //create a DNO = false SPS record
        Staged_Prospective_Student__c ow = new Staged_Prospective_Student__c();
        ow.First_Name__c = 'testFirst';
        ow.Last_Name__c = 'testLast';
        ow.Email__c = 'test@test.org';
        ow.Mobile__c = '999999';
        ow.Do_Not_Overwrite__c = false;

        Staged_Prospective_Student__c mergedSps;

        Test.startTest();
            //add the "overwrite" sps first
            StagedProspectiveStudentDAO dao = new StagedProspectiveStudentDAO(ow);
            //now, add the "do not overwrite" sps
            dao.addSps(dno);
            mergedSps = dao.getMergedSpsRecords(true);
        Test.stopTest();
        //the do not overwrite sps should supersede field values since it's the latest
        System.assertEquals(dno.Mobile__c, mergedSps.Mobile__c, 'Unable to get expected value of merged sps');
    }

    /**
     * @description test the function for getting a "merged" version of SPS while
     *  considering the DNO value. i.e. DNO = false supersedes the value of DNO = true SPS
     */
    @isTest
    static void getMergedSpsRecordsWithoutDNOTest() {

        //create a DNO = true SPS record
        Staged_Prospective_Student__c dno = new Staged_Prospective_Student__c();
        dno.First_Name__c = 'testFirst';
        dno.Last_Name__c = 'testLast';
        dno.Email__c = 'test@test.org';
        dno.Mobile__c = '123456789';
        dno.Do_Not_Overwrite__c = true;

        //create a DNO = false SPS record
        Staged_Prospective_Student__c ow = new Staged_Prospective_Student__c();
        ow.First_Name__c = 'testFirst';
        ow.Last_Name__c = 'testLast';
        ow.Email__c = 'test@test.org';
        ow.Mobile__c = '999999';
        ow.Do_Not_Overwrite__c = false;

        Test.startTest();
            //add the "overwrite" sps first
            StagedProspectiveStudentDAO dao = new StagedProspectiveStudentDAO(ow);
            //now, add the "do not overwrite" sps
            dao.addSps(dno);
            Staged_Prospective_Student__c mergedSps = dao.getMergedSpsRecords(false);
        Test.stopTest();
        //the overwrite sps should supersede field values since we respect the Do_Not_Overwrite__c field
        System.assertEquals(ow.Mobile__c, mergedSps.Mobile__c, 'Unable to get expected value of merged sps');
    }

    /**
     * @description test get all sps records stored in the DAO class
     */
    @isTest
    static void getSpsRecordsTest() {

        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
        StagedProspectiveStudentDAO dao;

        List<Staged_Prospective_Student__c> daoSpsList;

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsList[0]);
            daoSpsList = dao.getSpsRecords();
        Test.stopTest();

        System.assertEquals(1, daoSpsList.size(),'Unexpected number of SPS records stored in DAO class');
    }

    /**
     * @description test get all sps records with Do Not Overwrite = true
     */
    @isTest
    static void getSpsDNOTest() {
        
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(5);
        //set 1 sps record with DNO = true
        spsList[0].Do_Not_Overwrite__c = TRUE;

        StagedProspectiveStudentDAO dao;

        List<Staged_Prospective_Student__c> daoDnoSpsList;

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsList[0]);
            dao.addSps(spsList[1]);
            dao.addSps(spsList[2]);
            dao.addSps(spsList[3]);
            dao.addSps(spsList[4]);
            daoDnoSpsList = dao.getSpsDNO();
        Test.stopTest();

        System.assertEquals(1, daoDnoSpsList.size(), 'Unexpected number of DNO SPS records stored in DAO class');
    }

    /**
     * @description test get all sps records with Do Not Overwrite = false
     */
    @isTest
    static void getSpsOWTest() {
        
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(5);
        //set 1 sps record with DNO = true
        spsList[0].Do_Not_Overwrite__c = TRUE;

        StagedProspectiveStudentDAO dao;

        List<Staged_Prospective_Student__c> daoOwSpsList;

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsList[0]);
            dao.addSps(spsList[1]);
            dao.addSps(spsList[2]);
            dao.addSps(spsList[3]);
            dao.addSps(spsList[4]);
            daoOwSpsList = dao.getSpsOW();
        Test.stopTest();

        System.assertEquals(4, daoOwSpsList.size(), 'Unexpected number of Overwrite SPS records stored in DAO class');
    }

    /**
     * @description test get a merged version of SPS records with
     *  Do Not Overwrite = false;
     *  In this test, the merged sps value should pick up the
     *  Mobile and Mailing Street field value from the Do_Not_Overwrite__c = false SPS records
     */
    @isTest
    static void getMergedSpsOwTest() {

        //create a DNO = true SPS record
        Staged_Prospective_Student__c dno = new Staged_Prospective_Student__c();
        dno.First_Name__c = 'testFirst';
        dno.Last_Name__c = 'testLast';
        dno.Email__c = 'test@test.org';
        dno.Mobile__c = '123456789';
        dno.Do_Not_Overwrite__c = true;

        //create DNO = false SPS records
        Staged_Prospective_Student__c ow1 = new Staged_Prospective_Student__c();
        ow1.First_Name__c = 'testFirst';
        ow1.Last_Name__c = 'testLast';
        ow1.Email__c = 'test@test.org';
        ow1.Mobile__c = '999999';
        ow1.Do_Not_Overwrite__c = false;

        Staged_Prospective_Student__c ow2 = new Staged_Prospective_Student__c();
        ow2.First_Name__c = 'testFirst';
        ow2.Last_Name__c = 'testLast';
        ow2.Email__c = 'test@test.org';
        ow2.Mailing_Street__c = 'test street';
        ow2.Do_Not_Overwrite__c = false;

        StagedProspectiveStudentDAO dao;
        Staged_Prospective_Student__c mergedSpsOw;
        
        Test.startTest();
            dao = new StagedProspectiveStudentDAO(dno);
            dao.addSps(ow1);
            dao.addSps(ow2);
            mergedSpsOw = dao.getMergedSpsOw();
        Test.stopTest();

        System.assertEquals(ow1.Mobile__c, mergedSpsOw.Mobile__c, 'Unexpected value from merged SPS overwrite');
        System.assertEquals(ow2.Mailing_Street__c, mergedSpsOw.Mailing_Street__c, 'Unexpected value from merged SPS overwrite');
    }

    /**
     * @description test get a merged version of SPS records with
     *  Do Not Overwrite = true;
     *  In this test, the merged sps value should pick up the
     *  Mobile__c value from the sps record with Do_Not_Overwrite__c = true
     */
    @isTest
    static void getMergedSpsDNOTest() {
        
        //create a DNO = true SPS record
        Staged_Prospective_Student__c dno = new Staged_Prospective_Student__c();
        dno.First_Name__c = 'testFirst';
        dno.Last_Name__c = 'testLast';
        dno.Email__c = 'test@test.org';
        dno.Mobile__c = '123456789';
        dno.Do_Not_Overwrite__c = true;

        //create DNO = false SPS records
        Staged_Prospective_Student__c ow1 = new Staged_Prospective_Student__c();
        ow1.First_Name__c = 'testFirst';
        ow1.Last_Name__c = 'testLast';
        ow1.Email__c = 'test@test.org';
        ow1.Mobile__c = '999999';
        ow1.Do_Not_Overwrite__c = false;

        Staged_Prospective_Student__c ow2 = new Staged_Prospective_Student__c();
        ow2.First_Name__c = 'testFirst';
        ow2.Last_Name__c = 'testLast';
        ow2.Email__c = 'test@test.org';
        ow2.Mailing_Street__c = 'test street';
        ow2.Do_Not_Overwrite__c = false;

        StagedProspectiveStudentDAO dao;
        Staged_Prospective_Student__c mergedSpsOw;
        
        Test.startTest();
            dao = new StagedProspectiveStudentDAO(dno);
            dao.addSps(ow1);
            dao.addSps(ow2);
            mergedSpsOw = dao.getMergedSpsDNO();
        Test.stopTest();

        System.assertEquals(dno.Mobile__c, mergedSpsOw.Mobile__c, 'Unexpected value from merged SPS DNO');
    }

    /**
     * @description get all collected Subscription List Campaign
     *  IDs from the transaction.
     */
    @isTest
    static void getSubscriptionListIdsTest() {
        Campaign subList = [SELECT Id 
                            FROM Campaign 
                            WHERE Name = 'SubscriptionCampaign' 
                            LIMIT 1];
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
        spsRec.Subscription_Lists__c = '' + subList.Id;
        StagedProspectiveStudentDAO dao;
        Set<Id> sublistIds = new Set<Id>();

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsRec);
            sublistIds = dao.getSubscriptionListIds();
        Test.stopTest();

        System.assertEquals(1, sublistIds.size(), 'Unexpected number of Subscription List Campaign IDs found');
    }

    /**
     * @description get all collected Event Campaign
     *  IDs from the transaction.
     */
    @isTest
    static void getEventCampaignIdsTest() {
        Campaign evtCmp = [SELECT Id 
                            FROM Campaign 
                            WHERE Name = 'EventCampaign' 
                            LIMIT 1];
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
        spsRec.Event_Campaigns__c = '' + evtCmp.Id;
        StagedProspectiveStudentDAO dao;
        Set<Id> eventIds = new Set<Id>();

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsRec);
            eventIds = dao.getEventCampaignIds();
        Test.stopTest();

        System.assertEquals(1, eventIds.size(),'Unexpected number of Event Campaign IDs found');
    }

    /**
     * @description get all collected Acquisition Source Campaign
     *  IDs from the transaction.
     */
    @isTest
    static void getAcquisitionSourceIdsTest() {
        Campaign acq = [SELECT Id 
                            FROM Campaign 
                            WHERE Name = 'AcquisitionCampaign' 
                            LIMIT 1];
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
        spsRec.Acquisition_Source_Campaign__c = acq.Id;
        StagedProspectiveStudentDAO dao;
        Set<Id> acqIds = new Set<Id>();

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsRec);
            acqIds = dao.getAcquisitionSourceIds();
        Test.stopTest();

        System.assertEquals(1, acqIds.size(),'Unexpected number of Acquisition Source Campaign IDs found');
    }

    /**
     * @description get all course Interest IDs collected from SPS. In this test,
     *  the number should be the same as the Course Master records created from setup.
     */
    @isTest
    static void getInterestedCourseIdsTest() {
        //query course masters
        List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
        //create test SPS record with course interests
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
        for(Course_Master__c iCm : cmList) {
            spsRec.Interested_Course_List__c = '' + iCm.Id + ';';
        }
        StagedProspectiveStudentDAO dao;
        List<String> courseInterestList = new List<String>();

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsRec);

            //create a test Lead. this is required to get/store course interests
            Lead ld = new Lead(FirstName = spsRec.First_Name__c, LastName = spsRec.Last_Name__c, Company = 'N/A');
            dao.setLead(ld);
            courseInterestList = dao.getInterestedCourseIds();
        Test.stopTest();

        System.assertEquals(cmList.size(), courseInterestList.size(), 'Unexpected number of course interests found!');
    }

    /**
     * @description sort the provided Course IDs in the SPS 
     *  with a corresponding Rank for creating Lead Course Association.
     */
    @isTest
    static void sortCourseIdByRankTest() {
        Map<String, Integer> rankByLcaID = new Map<String, Integer>();
        List<Id> cmIdList = new List<Id>();

        //query course masters
        List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
        //create test SPS record with course interests
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
        for(Course_Master__c iCm : cmList) {
            cmIdList.add(iCm.Id);
            spsRec.Interested_Course_List__c = '' + iCm.Id + ';';
        }
        StagedProspectiveStudentDAO dao;

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsRec);
            rankByLcaID = dao.sortCourseIdByRank(cmIdList);
        Test.stopTest();

        System.assertEquals(cmIdList.size(), rankByLcaID.size(), 'Unexpected number of course master Ids found!');
    }

    /**
     * @description get the new Contact Qualification records based on the 
     *  Contact Qualification JSON string in the SPS record. In this test,
     *  we should product 2 Contact Qualification records (based on TestHelper data)
     */
    @isTest
    static void getAllContactQualificationsTest() {
        //test helper will create 2 contact qualification records
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
        StagedProspectiveStudentDAO dao;
        Map<String, Contact_Qualification__c> cqMap = new Map<String, Contact_Qualification__c>();

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsRec);
            cqMap = dao.getAllContactQualifications();
        Test.stopTest();

        System.assertEquals(2, cqMap.size(), 'Unexpected number of Contact Qualification records found!');
    }

    /**
     * @description test getting the "Staged" cases - an on the fly
     *  created Case that only contains Subject and Description
     */
    @isTest
    static void getStagedCasesTest() {
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
        spsRec.Enquiry_Subject__c = 'Test Enq';
        spsRec.Enquiry_Description__c = 'Test enq description';
        insert spsRec;
        StagedProspectiveStudentDAO dao;
        Map<Id, Case> caseMap = new Map<Id, Case>();
        
        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsRec);
            caseMap = dao.getStagedCases();
        Test.stopTest();

        System.assert(!caseMap.isEmpty(), 'Unable to retrieve Staged Cases');
        for(Case iCase : caseMap.values()) {
            System.assertEquals(spsRec.Enquiry_Subject__c, iCase.Subject, 'Invalid Case Subject found');
            System.assertEquals(spsRec.Enquiry_Description__c, iCase.Description, 'Invalid Case Description found');
        }
    }

    /**
     * @description test setting the "staged" cases - an on the fly
     *  created Case that only contains Subject and Description
     */
    @isTest
    static void setStagedCasesTest() {
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
        spsRec.Enquiry_Subject__c = 'Test Enq';
        spsRec.Enquiry_Description__c = 'Test enq description';
        insert spsRec;
        StagedProspectiveStudentDAO dao;
        Map<Id, Case> caseMap = new Map<Id, Case>{
            spsRec.Id => new Case(Subject = 'Test', Description = 'Test')
        };

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsRec);
            dao.setStagedCases(caseMap);
        Test.stopTest();

        Map<Id, Case> resMap = dao.getStagedCases();
        System.assert(!resMap.isEmpty(), 'Unable to retrieve Staged Cases');
        for(Case iCase : resMap.values()) {
            System.assertEquals('Test', iCase.Subject, 'Unable to properly set Staged Cases');
            System.assertEquals('Test', iCase.Description,  'Unable to properly set Staged Cases');
        }
    }

    /**
     * @description get the latest SPS ID in transaction.
     */
    @isTest
    static void getLatestSPSIdTest() {
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(2);
        insert spsList;

        Id latestSpsId = spsList[1].Id;
        Id daoLatestId;
        StagedProspectiveStudentDAO dao;

        Test.startTest();
            dao = new StagedProspectiveStudentDAO(spsList[0]);
            dao.addSps(spsList[1]);
            daoLatestId = dao.getLatestSPSId();
        Test.stopTest();

        System.assertEquals(latestSpsId, daoLatestId, 'Unable to get the latest SPS ID');
    }

    /**
     * @description test the propagation of Contact IDs to SPS records.
     *  upon creation (or finding an existing) of Contact, it's ID should be
     *  linked back to the SPS Exploded_Target__c field
     */
    @isTest
    static void propagateContactIdsTest() {
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
        spsRec.First_Name__c = 'propagateContactIdsTest';
        spsRec.Last_Name__c = 'propagateContactIdsTest';
        spsRec.Email__c = 'propagateContactIdsTest@test.org';

        //create test Contact
        Contact con = new Contact();
        con.FirstName = 'propagateContactIdsTest';
        con.LastName = 'propagateContactIdsTest';
        con.Email = 'propagateContactIdsTest@test.org';

        StagedProspectiveStudentDAO dao = new StagedProspectiveStudentDAO(spsRec);
        dao.setPerson(con);
        insert con;

        Test.startTest();
            dao.propagateContactIds();
        Test.stopTest();

        System.assertEquals(con.Id, spsRec.Exploded_Target__c, 'Incorrect or null Exploded Target value on SPS');
    }
}