/**
 * @author Nick Guia
 * @date 30-09-2020
 * @group Lead Management
 * @description test class for ExplodingLeadsContactMatcher 
 **/
@isTest(isParallel=true)
private class ExplodingLeadsContactMatcher_Test {

    private static final Integer SETUP_RECORD_COUNT = 1;

    @TestSetup
    static void makeData(){
        Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Contact_Loose_Match_Duplicate_Rule_Name__c = 'Contact_Loose_Match';
		insert envSettings;

		List<Contact> duplicateContacts = new List<Contact>();

		for(Contact con : TestHelper.createProspectiveStudentContact(SETUP_RECORD_COUNT)) {
			con.FirstName = 'ExplodingLeadsContactMatcher_Test';
			con.LastName = 'ExplodingLeadsContactMatcher_Test';
			con.Email = 'Test@test.org';
			duplicateContacts.add(con);
		}
		insert duplicateContacts;
    }

    /**
     * @description test create an SPS whose First Name, Last Name and
     * Email matches with the setup Contact record. Subsequently, create
     * another SPS without any existing matching - which should create a
     * new Contact record
     */
    @isTest
    static void shouldSetExplodedContactOnSpsRecords() {
        //given
        Contact con = [SELECT Id 
                    FROM Contact
                    WHERE FirstName = 'ExplodingLeadsContactMatcher_Test'
                    AND LastName = 'ExplodingLeadsContactMatcher_Test'
                    AND Email = 'Test@test.org'
                    ORDER BY CreatedDate DESC
                    LIMIT 1];
        Staged_Prospective_Student__c spsWithMatch;
        Staged_Prospective_Student__c spsNoMatch;
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(2);
        spsWithMatch = spsList[0];
        spsNoMatch = spsList[1];

        spsWithMatch.First_Name__c = 'ExplodingLeadsContactMatcher_Test';
        spsWithMatch.Last_Name__c = 'ExplodingLeadsContactMatcher_Test';
        spsWithMatch.Email__c = 'Test@test.org';

        spsNoMatch.First_Name__c = 'NO MATCH';
        spsNoMatch.Last_Name__c = 'NO MATCH';
        spsNoMatch.Email__c = 'Test@test.org';

        spsList = new List<Staged_Prospective_Student__c> { spsWithMatch, spsNoMatch };

        ExplodingLeadsContactMatcher matcher;
        List<Staged_Prospective_Student__c> res;

        Test.startTest();

        //when
        matcher = new ExplodingLeadsContactMatcher(spsList);
        matcher.run();
        res = matcher.getSpsRecords();

        Test.stopTest();

        //then

        System.assert(res != null, 'Unable to get SPS matching results');
        System.assert(!res.isEmpty(), 'Unable to get SPS matching results');
        for(Staged_Prospective_Student__c iSps : res) {
            if(iSps.First_Name__c.equalsIgnoreCase('NO MATCH')) {
                System.assert(iSps.Exploded_Target__c != con.Id, 'Duplicate matching mismatched!');
                System.assert(iSps.Exploded_Target__c != null, 'Unable to create new Contact record for SPS');
            } else {
                System.assert(iSps.Exploded_Target__c != null, 'Unable to match existing Contact record for SPS');
                System.assertEquals(con.Id, iSps.Exploded_Target__c, 'Duplicate matching mismatched!');
            }
        }
    }
}