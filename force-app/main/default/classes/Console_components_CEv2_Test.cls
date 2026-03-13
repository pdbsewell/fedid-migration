/**
 * Created by ariv0002 on 22/10/2018.
 */

@isTest(isParallel=true)
private class Console_components_CEv2_Test {

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

        // add some person notes adn encumbrances
        List<Person_Note__c> notes = new List<Person_Note__c>();
        List<Encumbrance__c> lstEncumbrances = new List<Encumbrance__c>();

        for(contact c : contacts){
            notes.add(new Person_Note__c(Contact__c = c.Id, Type__c = 'type', Important__c = true, Notes__c = 'test note'));
            lstEncumbrances.add(new Encumbrance__c(Contact__c = c.Id, enc_category__c = 'ACADEMIC', enc_comments__c='Test Encumbrance'));
        }
        insert notes;
        insert lstEncumbrances;

        system.assertNotEquals(null, notes[0].id,'notes didnt insert as expected');

        List<Case> cases = TestHelper.webToCaseForms(1);
        cases[0].contactId = contacts[0].id;
        cases[0].Enquiry_Type__c = CaseServices.CURRENT_COURSE;
        insert cases;

        system.assertNotEquals(null, cases[0].id,'cases didnt insert as expected');
    }


    @IsTest
    static void testBehavior() {
        Console_components_CEv2.ThisWrapperClass tw = new Console_components_CEv2.ThisWrapperClass();
        Id cseId = [Select Id from case].Id;
        tw = Console_components_CEv2.init(cseId, 'CRM');
        tw = Console_components_CEv2.init(cseId, 'Callista');
        Console_components_CEv2.insertCaseComments(cseId, true);
        Console_components_CEv2.insertCaseComments(cseId, false);
        System.assert(tw.contactId != null);
    }
}