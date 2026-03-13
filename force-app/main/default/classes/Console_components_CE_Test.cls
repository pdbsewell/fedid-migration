/** test coverage for Console_components_CE custom controller extension 
 * @author PwC
 */
@isTest(isParallel=true)
private class Console_components_CE_Test {

    @testSetup 
    static void setupTestData(){
    	// if test data required, establish here	
    	TestHelper.calabrioSetUp();
        List<contact> contacts = TestHelper.createOrphanContactRecords(10);
        integer offset = 1;
        for(contact c : contacts) { 
            c.birthdate = date.newInstance(1975,1,1);
            c.Person_Id_unique__c = String.valueOf(12345+offset);
        	offset++;
        }
        insert contacts;
        
        system.assertNotEquals(null, contacts[0].id,'contacts didnt insert as expected');
        
        // add some person notes
        List<Person_Note__c> notes = new List<Person_note__c>();
        for(contact c : contacts) notes.add(new Person_note__c(contact__c = c.id, type__c = 'type', important__c = true, notes__c = 'test note'));
        insert notes;
        
        system.assertNotEquals(null, notes[0].id,'notes didnt insert as expected');
        
        List<Case> cases = TestHelper.webToCaseForms(1);
        cases[0].contactId = contacts[0].id;
        cases[0].Enquiry_Type__c = CaseServices.CURRENT_COURSE;
    	insert cases;
        
        system.assertNotEquals(null, cases[0].id,'cases didnt insert as expected');
        
        // append some enquiry interests
        List<course__c> courses = TestHelper.createCourses(2);
        insert courses;
        
        system.assertNotEquals(null, courses[0].id,'courses didnt insert as expected');
        
        List<Enquiry_Interest__c> interests = new List<Enquiry_Interest__c>();
        for(contact c : contacts){
            for(course__c course : courses){
                for(case cse : cases)
                    interests.add(new Enquiry_Interest__c(course__c = course.id, person__c = c.id, case__c = cse.id));
            }
        }
        insert interests;
        
        system.assertNotEquals(null, interests[0].id,'interests didnt insert as expected');
    }
    
    
    static testMethod void populateListsTest(){
        
        PageReference pg = Page.Console_tabbedLists_v2;
        Test.setCurrentPage(pg);
        
        Case cse = [select id from case limit 1];
        system.assertNotEquals(null, cse.id,'case didnt exist as expected');
        
        ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
        
        Console_components_CE con = new Console_components_CE(stdCase);
        
		string fdt = con.formattedDateTime;
        con.refreshLists();
        
        system.assert(!con.personNotes.isEmpty());
        
    }
    
    
    static testMethod void otherTests(){
        
        PageReference pg = Page.Console_tabbedLists_v2;
        Test.setCurrentPage(pg);
        
        Case cse = [select id, contactId, Enquiry_Type__c from case limit 1];
        ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
        
        Console_components_CE con = new Console_components_CE(stdCase);
        
		Test.startTest();
        	con.tab = '';
        	con.refreshLists();
        	system.assertEquals('1', con.tab,'tab not set to what it should be');
        	
        	List<SelectOption> options = con.casetypes;
        	system.assertEquals(false, options.isEmpty(),'options should not be empty');
        
        	
        Test.stopTest();
    }
    
    
}