/**
* @author Angelo Rivera
* @date 09.Jan.2020
* @group Test Class
* @description  Test Class to test the functionality of MIXAPI_StudentPersonNote
* @revision     APRivera, 09.Jan.2020 - Created <br/>
*/

@isTest(isParallel=true)
private class MIXAPI_StudentPersonNote_Test {

	@IsTest
	static void testBehavior() {
		Test.startTest();
		MIXAPI_StudentPersonNote.cls_notes clsNotes = new MIXAPI_StudentPersonNote.cls_notes();
		MIXAPI_StudentPersonNote.clsself clsself = new MIXAPI_StudentPersonNote.clsself();
		clsself.href = 'testHref';
		clsNotes.type = 'test';
		clsNotes.admissionApplicationId = 'test';
		clsNotes.noteType = 'test';
		clsNotes.typeDescription = 'test';
		clsNotes.updateBy = 'test';
		clsNotes.updateOn = 'test';
		clsNotes.text = 'test';
		clsNotes.portalApplicationID = 'test';
		Test.stopTest();
		System.assertNotEquals(null,clsNotes.type);
	}
}