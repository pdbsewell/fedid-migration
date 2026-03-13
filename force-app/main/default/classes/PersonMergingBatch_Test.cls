@isTest(isParallel=true)
private class PersonMergingBatch_Test {
	static Contact masterCon {get; set;}
	static Contact childCon {get; set;}
	static Contact childCon2 {get; set;}
	static List<DuplicateRecordSet> dupRecordSet {get; set;}

	@testSetup static void setupDataCS() {
		//Set up Custom Setting
		Environment_Settings__c cs = new Environment_Settings__c();
		cs.Contact_Merge_Max_Rerun__c = 1;
		cs.Contact_Merge_Max_Records__c = 200;
		cs.Contact_Merge_Job_Name__c = 'Contact Perfect%';
		cs.SetupOwnerId = UserInfo.getOrganizationId();
		insert cs;
	}

	static testMethod void batchTest() {
		//Given - Set up Duplicate Contacts
		setupDataManual();
		//When - Duplicate Contacts Created, create duplicate Record set items
		saveConDups();
		Test.startTest();
		//Run batch to initiate contact merge process
		retrieveDups();
		PersonMergingBatch.runNow(0, new Set<Id>(), false);
		//Then - Check if duplicates are merged
		Test.stopTest();
		System.assertEquals(3, [SELECT count() FROM Contact], 'Contact Merge Failed:');
	}

	/**
	 * Set up data manually
	 */
	private static void setupDataManual() {

		Contact con = new Contact();
		con.Person_ID_unique__c = '12345';
		con.Birthdate = Date.today().addYears(-20);
		con.Citizenship__c = 'INTERNATIONAL';
		con.Citizenship_Code__c = '4';
		con.Residency_Status__c = 'Australian Permanent Resident';
		con.Email = 'test@test.com';
		con.Monash_Email_Address__c = 'test@test.com';
		con.FirstName = 'testFirstName';
		con.LastName = 'testLastName';
		con.Gender__c = 'None';
		con.MobilePhone = '0412345678';
		//Set Master Contact
		masterCon = con;
		//Set Child Contact and clear Callista Id
		childCon = con.clone(false, true);
		childCon.Person_ID_unique__c = '';
		childCon2 = con.clone(false, true);
		childCon2.Person_ID_unique__c = '';
	}
	/**
	 * Retrieve DupRecordSet
	 */
	private static void retrieveDups() {

		dupRecordSet = [SELECT Id, DuplicateRuleId,
		                ParentId,
		                RecordCount,
		                DuplicateRule.DeveloperName,
		                DuplicateRule.SobjectType,
		                (SELECT Id, RecordId, DuplicateRecordSetId FROM DuplicateRecordItems)
		                FROM DuplicateRecordSet
		                WHERE DuplicateRule.SobjectType = 'Contact'
		                        AND RecordCount > 1
		                        ORDER BY DuplicateRuleId];
		System.debug(LoggingLevel.DEBUG, '!!@@##: ' + JSON.serializePretty(dupRecordSet));
		System.assertNotEquals(null, dupRecordSet, 'No Duplicate Record Set Created');
	}
	/**
	 * Save contacts
	 */
	private static void saveConDups() {
		List<Contact> contacts = new List<Contact> {masterCon, childCon, childCon2};
		//
		Database.DMLOptions insertDML = new Database.DMLOptions();
		insertDML.DuplicateRuleHeader.AllowSave = true;
		Database.SaveResult[] srs = Database.insert(contacts, insertDML);
		for (Database.SaveResult sr : srs) {
			System.assert(sr.isSuccess(), 'Failed saving Contacts:' + JSON.serializePretty(sr.getErrors()));
		}
		DuplicateRule dR = [SELECT Id FROM DuplicateRule WHERE MasterLabel LIKE 'Contact Perfect%' LIMIT 1];
		DuplicateRecordSet dupRS = new DuplicateRecordSet(DuplicateRuleId = dR.Id);
		insert dupRS;
		DuplicateRecordItem[] dupitems = new List<DuplicateRecordItem> {
			new DuplicateRecordItem(DuplicateRecordSetId = dupRS.Id, RecordId = masterCon.Id),
			new DuplicateRecordItem(DuplicateRecordSetId = dupRS.Id, RecordId = childCon.Id),
			new DuplicateRecordItem(DuplicateRecordSetId = dupRS.Id, RecordId = childCon2.Id)
		};
		insert dupitems;
		System.assertNotEquals(null, dupRS.Id, 'Failed Creating Duplicate Record Set');

	}
}