/*
 * @description Contains all test for  EncumbranceServices
 *
 **/
@isTest(isParallel=true)
public class EncumbranceServices_Test {
    
    @TestSetup
    static void initData(){
        Contact con = new Contact(lastname='Encumbrance Test',  person_id_unique__c = '88888888');
        insert con;
    
        Encumbrance__c enc = new Encumbrance__c(Name='Encumbrance Test', contact__c = con.id, isActive__c = false, eff_start_date__c = date.today() - 7, person_id__c = '88888888');
        insert enc;
    }
                                                
	@IsTest
    static void runTests() {
        Encumbrance__c[] eList;

        // Initial Conditions
        eList = [Select id, name, deleted_in_source__c, eff_start_date__c, eff_expiry_date__c, isActive__c from Encumbrance__c where person_id__c = '88888888'];
        Assert.areEqual(eList.size(),1,'Check test data setup');
        Assert.isTrue(eList[0].isActive__c,'Null effect expiry date should set the active flag to true');

        // Active flag
		eList[0].eff_expiry_date__c = date.today() + 6;
        update eList;
        eList = [Select id, name, deleted_in_source__c, eff_start_date__c, eff_expiry_date__c, isActive__c from Encumbrance__c where person_id__c = '88888888'];
        Assert.isTrue(eList[0].isActive__c,'Future expiry date should set the active flag to true');
        
        //Delete & undelete - code coverage
        delete eList;
        eList = [Select id, name, deleted_in_source__c, eff_start_date__c, eff_expiry_date__c, isActive__c from Encumbrance__c where person_id__c = '88888888' ALL ROWS];
		undelete eList;
        Assert.isTrue(eList[0].isActive__c,'Undeleted and still active');

		eList[0].eff_expiry_date__c = date.today();
        update eList;
        eList = [Select id, name, deleted_in_source__c, eff_start_date__c, eff_expiry_date__c, isActive__c from Encumbrance__c where person_id__c = '88888888'];
        Assert.isFalse(eList[0].isActive__c,'Setting the expiry date to today should inactivate the Encumbrance');

		// reactivate
        eList[0].eff_expiry_date__c = date.today()+7;
        update eList;
        eList = [Select id, name, deleted_in_source__c, eff_start_date__c, eff_expiry_date__c, isActive__c from Encumbrance__c where person_id__c = '88888888'];
        Assert.isTrue(eList[0].isActive__c,'Changing the effect expiry date to future should activate the Encumbrance');

        eList[0].deleted_in_source__c = true;
        update eList;
        eList = [Select id, name, deleted_in_source__c, eff_start_date__c, eff_expiry_date__c, isActive__c from Encumbrance__c where person_id__c = '88888888'];
        Assert.isFalse(eList[0].isActive__c,'Marking as deleted in source should inactivate the Encumbrance');
        Assert.areEqual(eList[0].eff_expiry_date__c, date.today(),'Marking as deleted in source should set the expiry date to today');
        
        //Code Coverage - unable to create active encumbrances with expiry dates in the past
        EncumbranceServices.validateisActive();
    }
}