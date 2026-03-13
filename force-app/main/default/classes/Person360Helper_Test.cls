/**
 * @description       : This is test class for Person360Helper.
 * @author            : Angelo Rivera
 * @group             : Test
 * @last modified on  : 2020-10-07
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-01-21   Angelo Rivera   Created.
 * 1.1   2020-10-07   Stefan Scheit   Removed reference to out-of-date opt out field(s)
**/
@isTest(isParallel=true)
private class Person360Helper_Test {

	@IsTest
	static void testBehavior() {
		// test address formatting
		String strFormattedAddress = Person360Helper.formatAddressName('Spring Street', 'Melbourne', 'Victoria', 'Australia');
		System.assertNotEquals(null, strFormattedAddress);

		// test full name with more than 80 characters formatting
		String strFormattedName1 = Person360Helper.formatName('thisisgonnabealong FirstName', 'thisisgonnabealong MiddleName', 'thisisgonnabealong LastName thisisgonnabealong LastName thisisgonnabealong LastName');
		System.assertNotEquals(null, strFormattedName1);

		// test full name with less than 80 characters formatting
		String strFormattedName2 = Person360Helper.formatName('FirstName', 'MiddleName', 'LastName');
		System.assertNotEquals(null, strFormattedName2);

		// test person 360 key generation
		String strPerson360Key = Person360Helper.generatePerson360Key(new Set<String>{'Test','Test','Test'});
		System.assertNotEquals(null, strPerson360Key);

		// test default date where field != null
		Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact());
		Date dtDefaultDate = Person360Helper.setDefaultDate(Contact.Birthdate, con);
		System.assertNotEquals(null, dtDefaultDate);

		// test default date where field = null
		con.Birthdate = System.today()-10;
		Date dtDefaultDate2 = Person360Helper.setDefaultDate(Contact.Birthdate, con);
		System.assertNotEquals(null, dtDefaultDate);

		// test adding field value
		Contact con1 = new Contact();
		con1 = (Contact)Person360Helper.addFieldValue(con, 'Birthdate', con.Birthdate);
		con1 = (Contact)Person360Helper.addFieldValue(con, 'Person_ID_unique__c', con.Person_ID_unique__c);
		con1 = (Contact)Person360Helper.addFieldValue(con, 'Commercial_Opt_Out__c', con.Commercial_Opt_Out__c);
		con1 = (Contact)Person360Helper.addFieldValue(con, 'Owner', con.get('OwnerId'));
		System.assertNotEquals(null, con1);

		// GIVEN MUM Staff Contact
		Contact staffContact = TestHelper.createStaffContacts(1)[0];
		staffContact.Personnel_Area_Code__c = 'MY01';
		// WHEN it is checked against isMumStaffContact method
		// THEN it returns true
		System.assertEquals(true, Person360Helper.isMUMStaffContact(staffContact));

		// GIVEN non-MUM Staff Contact
		Contact nonStaffContact = TestHelper.createStaffContacts(1)[0];
		// WHEN it is checked against isMumStaffContact method
		// THEN it returns false
		System.assertEquals(false, Person360Helper.isMUMStaffContact(nonStaffContact));
	}

	@isTest
	static void test_setUserOrSystemToPrimarySetBy() {
		Address__c newAddress = new Address__c(Start_Date__c = Date.today());
		Person360Helper.setUserOrSystemToPrimarySetBy(newAddress);
		System.assertEquals('user', newAddress.Primary_set_by__c, '##### Error! Expected value of Address__c.Primary_set_by__c should be user.');
		Email__c newEmail = new Email__c(Start_Date__c = Date.today());
		Person360Helper.setUserOrSystemToPrimarySetBy(newEmail);
		System.assertEquals('user', newEmail.Primary_set_by__c, '##### Error! Expected value of Email__c.Primary_set_by__c should be user.');
		Name__c newName = new Name__c(Start_Date__c = Date.today());
		Person360Helper.setUserOrSystemToPrimarySetBy(newName);
		System.assertEquals('user', newName.Primary_set_by__c, '##### Error! Expected value of Name__c.Primary_set_by__c should be user.');
		Phone__c newPhone = new Phone__c(Start_Date__c = Date.today());
		Person360Helper.setUserOrSystemToPrimarySetBy(newPhone);
		System.assertEquals('user', newPhone.Primary_set_by__c, '##### Error! Expected value of Phone__c.Primary_set_by__c should be user.');
	}

	/**
     * Set read-only CreatedDate field - useful for mocking records without DML
     */
	private static Name__c setCreatedDate(Name__c n, Datetime createdDate) {
		Map<String,Object> objMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(n));
		objMap.put('CreatedDate', createdDate);
		Name__c withDate = (Name__c)JSON.deserialize(JSON.serialize(objMap), Name__c.class);
		return withDate;
	}

	/**
     * Test that sorting is working on rollup rank followed by Start_Date__c
     */
	@IsTest static void testSortable() {
		// Arrange
		Name__c n1 = new Name__c(First_Name__c = 'Bob', Start_Date__c = Date.today().addDays(-4));
		Name__c n2 = new Name__c(First_Name__c = 'Jerry', Start_Date__c = Date.today().addDays(-2));
		Name__c n3 = new Name__c(First_Name__c = 'Mick', Start_Date__c = Date.today());
		Name__c n4 = new Name__c(First_Name__c = 'Larry', Start_Date__c = Date.today().addDays(0));
		Name__c n5 = new Name__c(First_Name__c = 'JerryNewer', Start_Date__c = Date.today().addDays(-2));
		Name__c n6 = new Name__c(First_Name__c = 'JerryNewest', Start_Date__c = Date.today().addDays(-2));
		Name__c n7 = new Name__c(First_Name__c = 'Last', Start_Date__c = null);

		n2 = setCreatedDate(n2, Datetime.now().addDays(-2));
		n5 = setCreatedDate(n5, Datetime.now().addDays(-1));

		Person360Helper.SortableContactPoint[] sortableNames = new Person360Helper.SortableContactPoint[0];
		sortableNames.add(new Person360Helper.SortableContactPoint(n1, 80));
		sortableNames.add(new Person360Helper.SortableContactPoint(n2, 80));
		sortableNames.add(new Person360Helper.SortableContactPoint(n3, 10));
		sortableNames.add(new Person360Helper.SortableContactPoint(n4, 80));
		sortableNames.add(new Person360Helper.SortableContactPoint(n5, 80));
		sortableNames.add(new Person360Helper.SortableContactPoint(n6, 80));
		sortableNames.add(new Person360Helper.SortableContactPoint(n7, 80));

		// Test
		sortableNames.sort();

		// Assert
		System.assertEquals(n3, sortableNames[0].obj, 'lowest roll-up rank should be first');
		System.assertEquals(n4, sortableNames[1].obj, 'most recent start date should be next');
		System.assertEquals(n6, sortableNames[2].obj, 'null created date should be next');
		System.assertEquals(n5, sortableNames[3].obj);
		System.assertEquals(n2, sortableNames[4].obj);
		System.assertEquals(n1, sortableNames[5].obj);
		System.assertEquals(n7, sortableNames[6].obj);
	}
}