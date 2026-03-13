/**
 * @author Nick Guia
 * @date 02-10-2020
 * @group Lead Management
 * @description test class for ExplodingLeadsContactMatcher 
 **/
@isTest(isParallel=true)
private class ExplodingLeadsFactoryV2_Test {

    @TestSetup
    static void makeData(){
        //create setup Contact
        List<Contact> conList = TestHelper.createProspectiveStudentContact(2);
        insert conList;

        //create Setup SPS
        List<Lead> leadList = TestHelper.createLeads(1);
        leadList[0].FirstName = conList[0].FirstName;
        leadList[0].LastName = conList[0].LastName;
        leadList[0].Email = conList[0].Email;
        leadList[0].Contact__c = conList[0].Id;
        leadList[0].RecordTypeId = StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT;
        insert leadList;

        //create courses which will eventually create course masters
		List<Course__c> courseList = new List<Course__c>();
		Integer ctr = 1;
		Set<String> courseCodeSet = new Set<String>();
		for(Course__c iCourse : TestHelper.createCourses(2)) {
			iCourse.Name = 'exLeadTest'+ctr;
			iCourse.Type__c = Label.Course_Type_Course_All;
			iCourse.Course_Code__c = iCourse.Name;
			courseList.add(iCourse);
			courseCodeSet.add(iCourse.Name);
			ctr++;
		}
        insert courseList;
        
        //setup Campaign
        List<Campaign> campaignList = new List<Campaign>();

        //setup subscription list campaign
		Id subsListRT = Schema.SObjectType.Campaign
            .getRecordTypeInfosByDeveloperName()
            .get('Subscription_List')
            .getRecordTypeId();
        Campaign subscriptionCampaign = new Campaign (
            Name = 'ExplodingLeadsFactoryV2_Test',
            Channel_Type__c = 'SMS;Email',
            RecordTypeId = subsListRT
        );
        campaignList.add(subscriptionCampaign);

        //setup Event Campaign
		Id nonMonRT = Schema.SObjectType.Campaign
            .getRecordTypeInfosByDeveloperName()
            .get('Non_Montrack')
            .getRecordTypeId();

        Campaign eventCampaign = new Campaign(
            Name = 'EventCampaign',
            RecordTypeId = nonMonRT
        );
        campaignList.add(eventCampaign);

        //setup acquisition source campaign
        Campaign acquisition = new Campaign(
            Name = 'AcquisitionCampaign',
            RecordTypeId = nonMonRT
        );
        campaignList.add(acquisition);
        
        insert campaignList;
    }

    private static Map<Id, StagedProspectiveStudentDAOV2> setupSpsDAO(Staged_Prospective_Student__c sps) {
        return setupSpsDAO(new List<Staged_Prospective_Student__c>{ sps });
    }

    private static Map<Id, StagedProspectiveStudentDAOV2> setupSpsDAO(List<Staged_Prospective_Student__c> spsList) {
        return new ExplodingLeadsFactoryV2().createSpsDAO(spsList);
    }

    /**
     * @description test create a DAO class for each SPS record grouped by Contact Id
     */
    @isTest
    static void shouldCreateSpsDao() {
        //given
        List<Contact> conList = [SELECT Id FROM Contact LIMIT 10];
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(3);
        //assign same Contact ID for the first two SPS records
        spsList[0].Exploded_Target__c = conList[0].Id;
        spsList[1].Exploded_Target__c = conList[0].Id;
        //assign a different contact ID
        spsList[2].Exploded_Target__c = conList[1].Id;

        Map<Id, StagedProspectiveStudentDAOV2> spsDaoMap;

        Test.startTest();

        //when
        spsDaoMap = new ExplodingLeadsFactoryV2().createSpsDAO(spsList);

        Test.stopTest();

        //then
        System.assert(spsDaoMap != null, 'Unexpected NULL value for spsDaoMap');
        System.assert(!spsDaoMap.isEmpty(), 'Unexpected empty list value for spsDaoMap');
        for(Contact iCon : conList) {
            System.assert(spsDaoMap.containsKey(iCon.Id), 'Unable to create a DAO class for Contact');
        }
    }

    /**
	 * @description Test if method is returning Contact with expected field values
	 */
	@isTest
	static void shouldBuildProspectiveStudentContact() {
        //given
        Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
        Contact con;
		ExplodingLeadsFactoryV2 exFactor = new ExplodingLeadsFactoryV2(sps);

        Test.startTest();
        
        //when
        con = new ExplodingLeadsFactoryV2(sps).buildProspectiveContact();
        
		Test.stopTest();

        //then
		//check if field mappings are correct
		System.assertEquals(sps.Birthdate__c, con.Birthdate, 'Unexpected value for Contact Birthdate');
		System.assertEquals(sps.Birth_year__c, con.Birth_year__c, 'Unexpected value for Contact Birth_year__c');
		System.assertEquals(sps.Country_of_Residence__c, con.Country_of_Residence__c, 'Unexpected value for Contact Country_of_Residence__c');
		System.assertEquals(sps.Email__c, con.Email, 'Unexpected value for Contact Email');
		System.assertEquals(sps.First_Name__c, con.FirstName, 'Unexpected value for Contact FirstName');
		System.assertEquals(sps.Gender__c, con.Gender__c, 'Unexpected value for Contact Gender__c');
		System.assertEquals(sps.Last_Name__c, con.LastName, 'Unexpected value for Contact LastName');
		System.assertEquals(sps.Nationality__c, con.Nationality__c, 'Unexpected value for Contact Nationality__c');
		System.assertEquals(sps.Salutation__c, con.Salutation, 'Unexpected value for Contact Salutation');
		System.assertEquals(StagedProspectiveStudentUtil.CONTACT_RECTYPE_PROPECTIVESTUDENT, con.RecordTypeId,'Unexpected value for Contact Record Type');
    }
    
    /**
	 * @description Test if method is returning an updated Contact with null values populated
	 */
	@isTest
	static void shouldMergeProspectiveContacts() {
        //given
		Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
		Contact existingCon = new Contact(
			FirstName = 'Test',
			LastName = 'con');
		Contact spsCon = new ExplodingLeadsFactoryV2(sps).buildProspectiveContact();
        Contact newcon;
        ExplodingLeadsFactoryV2 factory = new ExplodingLeadsFactoryV2();

        Test.startTest();
        
        //when
        newcon = factory.mergeProspectiveContact(existingCon, spsCon);
        
		Test.stopTest();

        //then
		//check if blank fields were populated
		System.assertEquals(sps.Birthdate__c, newcon.Birthdate, 'Unexpected value for Contact Birth_year__c');
		System.assertEquals(sps.Gender__c, newcon.Gender__c,'Unexpected value for Contact Gender__c');
		System.assertEquals(sps.Country_of_Residence__c, newcon.Country_of_Residence__c,'Unexpected value for Contact Country_of_Residence__c');
		System.assertEquals(sps.Nationality__c, newcon.Nationality__c,'Unexpected value for Contact Nationality__c');
		System.assertEquals(sps.Birth_year__c, newcon.Birth_year__c,'Unexpected value for Contact Birth_year__c');
    }
    
    /**
	 * @description test Prospective Student Lead builder with an existing Lead.
     * This should produce an updated Lead record with new information from SPS
	 */
	@isTest
	static void shouldBuildProspectiveLead() {
        //given
        //get existing Contact and Lead
        Map<Id, Contact> conMap = new Map<Id, Contact>(
            [SELECT Id, FirstName, LastName, Email, Monash_Email_Address__c, Nationality__c,
            Personal_Email__c, Birthdate, AccountId, Gender__c, Country_of_Residence__c, 
            LastModifiedDate, CreatedDate, Birth_year__c
            FROM Contact
            LIMIT 10]
        );

        List<Lead> leadList = new ExplodingLeadsSelector().selectExistingLeads(conMap.keySet());
        Lead existingLead = leadList[0];
        Contact existingContact = conMap.get(existingLead.Contact__c);

        //create test SPS
        List<Staged_Prospective_Student__c> spsList = new List<Staged_Prospective_Student__c>();
        for(Staged_Prospective_Student__c iSps : TestHelper.createSPS(2)) {
            iSps.First_Name__c = existingContact.FirstName;
            iSps.Last_Name__c = existingContact.LastName;
            iSps.Email__c = existingContact.Email;
            iSps.Exploded_Target__c = existingContact.Id;
            //test if one text field (to be parsed as checkbox) receives 'T' (or 1)
		    iSps.Interested_in_Monash_College_Text__c = 'T';
            spsList.add(iSps);
        }
        Map<Id, StagedProspectiveStudentDAOV2> spsDaoMap = setupSpsDAO(spsList);
        System.assert(spsDaoMap != null, 'Unable to generate SPS DAO');
        System.assert(spsDaoMap.size() == 1, 'Unexpected number of SPS DAO generated');
        System.assert(spsDaoMap.containsKey(existingContact.Id), 'Unable to generate DAO class for Contact');

        Lead psLead;

        Test.startTest();

        //when
        StagedProspectiveStudentDAOV2 dao = spsDaoMap.get(existingContact.Id);
        List<Staged_Prospective_Student__c> daoSpsList = dao.getSpsList();
        psLead = new ExplodingLeadsFactoryV2.ProspectiveLeadBuilder(daoSpsList)
                    .setExistingLead(existingLead)
                    .build()
                    .getLead();

        Test.stopTest();

        //then
        System.assertEquals(psLead.Company, 'N/A', 'Unexpected value for Lead Company');
		System.assertEquals(psLead.Status, 'Open', 'Unexpected value for Lead Status');
		System.assertEquals(TRUE, psLead.Interested_in_Monash_College__c, 'Unexpected value for Lead Interested_in_Monash_College__c');
		System.assertEquals(psLead.RecordTypeId, StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT, 'Unexpected value for Lead Record Type');
    }

    /**
	 * @description test create a new LCA record provided that there's already an existing one.
     * This scenario is expected to rank LCA's according to the order that Course Masters
     * were provided in the list
	 */
	@isTest
	static void shouldBuildLeadCourseAssociation() {
        //given
        //get setup Course Masters and map them by course codes
        Map<String, Course_Master__c> cmMap = new Map<String, Course_Master__c>();
        for(Course_Master__c iCm : [SELECT Id, Name FROM Course_Master__c LIMIT 10]) {
            cmMap.put(iCm.Name, iCm);
        }
        System.assert(cmMap.containsKey('exLeadTest1'), 'Setup Course Master not found!');
        System.assert(cmMap.containsKey('exLeadTest2'), 'Setup Course Master not found!');
        //setup an existing LCA
        Lead_Course_Association__c existingLca = new Lead_Course_Association__c(
            Course_Master__c = cmMap.get('exLeadTest1').Id,
            Associated_Date__c = System.now(),
            Last_Associated_Rank__c = 1
        );

        Course_Master__c newInterest = cmMap.get('exLeadTest2');
        List<Lead_Course_Association__c> newLcaList;

        Test.startTest();

        //when
        newLcaList = new ExplodingLeadsFactoryV2.LeadCourseAssociationBuilder(cmMap.values())
                        .setExistingLca(new List<Lead_Course_Association__c> {existingLca})
                        .build()
                        .getLCA();
        Test.stopTest();

        //then
        System.assert(newLcaList != null, 'Unexpected null value for new LCA List');
        System.assert(newLcaList.size() == 2, 'Unexpected number of LCA found');
        for(Lead_Course_Association__c iLCa : newLcaList) {
            if(iLCa.Last_Associated_Rank__c == 1) {
                //rank 1 = existing LCA (first in order)
                System.assertEquals(existingLca.Course_Master__c, iLCa.Course_Master__c);
            } else if(iLCa.Last_Associated_Rank__c == 2) {
                //rank 2 = new interest (second in order)
                System.assertEquals(newInterest.Id, iLCa.Course_Master__c);
            }
        }
    }

    /**
	 * @description generate a subscription list campaign member
	 */
	@isTest
	static void shouldBuildSubscriptionMember() {
        //given
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id subsListRT = Schema.SObjectType.Campaign
            .getRecordTypeInfosByDeveloperName()
            .get('Subscription_List')
            .getRecordTypeId();
        Campaign subList = [SELECT Id, Channel_Type__c 
                            FROM Campaign 
                            WHERE RecordTypeId = :subsListRT LIMIT 1];
        CampaignMember subMember;

        Test.startTest();

        //when
        subMember = new ExplodingLeadsFactoryV2.SubscriptionListMemberBuilder(subList, con.Id)
                    .build('Web')
                    .getMember();

        Test.stopTest();

        //then
        System.assert(subMember != null, 'Unepxected null value for sub member');
        System.assertEquals(con.Id, subMember.ContactId, 'Unepxected contact Id for Sub member');
        System.assertEquals(subList.Id, subMember.CampaignId, 'Unepxected campaign Id for Sub member');
    }

    /**
	 * @description generate an event campaign member
	 */
	@isTest
	static void shouldBuildEventMember() {
        //given
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id nonMonRT = Schema.SObjectType.Campaign
            .getRecordTypeInfosByDeveloperName()
            .get('Non_Montrack')
            .getRecordTypeId();
        Campaign evCampaign = [SELECT Id, Channel_Type__c 
                                FROM Campaign 
                                WHERE RecordTypeId = :nonMonRT 
                                AND Name = 'EventCampaign'
                                LIMIT 1];
        CampaignMember evMember;
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];

        Test.startTest();

        //when
        evMember = new ExplodingLeadsFactoryV2.EventMemberBuilder(evCampaign, con.Id)
                    .build(spsRec)
                    .getMember();

        Test.stopTest();

        //then
        System.assert(evMember != null, 'Unepxected null value for event member');
        System.assertEquals(true, evMember.Active__c, 'Unexpected Active value for Event Campaign member');
        System.assertEquals(spsRec.Web_Lead_Source__c, evMember.Web_Lead_Source__c, 'Unexpected Web Lead Source for Event Campaign member');
        System.assertEquals(spsRec.Number_of_Attendees__c, evMember.Number_of_Attendees__c, 'Unexpected number of attendees for Event Campaign member');
        System.assertEquals(spsRec.Dietary_Requirements__c, evMember.Dietary_Requirements__c, 'Unexpected Dietary Requirements for Event Campaign member');
        System.assertEquals(spsRec.Session__c, evMember.Session__c, 'Unexpected Session value for Event Campaign member');
    }

    /**
	 * @description generate an Acquisition Source campaign Member
	 */
	@isTest
	static void shouldBuildAcquisitionSourceMember() {
        //given
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id nonMonRT = Schema.SObjectType.Campaign
            .getRecordTypeInfosByDeveloperName()
            .get('Non_Montrack')
            .getRecordTypeId();
        Campaign acqCampaign = [SELECT Id, Channel_Type__c 
                                FROM Campaign 
                                WHERE RecordTypeId = :nonMonRT 
                                AND Name = 'AcquisitionCampaign'
                                LIMIT 1];
        CampaignMember acqMember;

        Test.startTest();

        //when
        acqMember = new ExplodingLeadsFactoryV2.AcquisitionMemberBuilder(acqCampaign, con.Id)
                    .build('Web')
                    .getMember();

        Test.stopTest();

        //then
        System.assert(acqMember != null, 'Unepxected null value for Acquisition Campaign member');
        System.assertEquals(true, acqMember.Active__c, 'Unexpected Active value for Acquisition Campaign member');
        System.assertEquals('Web', acqMember.Web_Lead_Source__c, 'Unexpected Web Lead Source for Acquisition Campaign member');
    }
}