/**
* @author Nick Guia
* @date NOV.13.2017
* @description Test Class for ContentVersionTriggerHandler
* @history
**/
@isTest(isParallel=false)
private class ContentVersionTriggerHandler_Test {

	@testSetup static void setup() {
		/** add current user to public group
			assumption is that this group should always exist.
			Otherwise, test class should fail as COO user's file
			attachments will be exposed publicly.
		**/
	 	Id cooGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'Monash_Board_Management_System_Users' LIMIT 1].Id;

	 	GroupMember gm = new GroupMember(); 
      	gm.GroupId = cooGroupId;
      	gm.UserOrGroupId = UserInfo.getUserId();
      	insert gm;
	}
	
	@isTest static void test_updateSharingPrivacy() {
	 	ContentVersion cv = new ContentVersion(); 
	 	cv.Title ='test cv';
	 	//testContentInsert.ContentURL='<a target="_blank" href="http://www.google.com/';" rel="nofollow">http://www.google.com/';</a> 
	 	cv.ContentURL='www.google.com';
	 	cv.SharingPrivacy = 'N';

	 	Test.startTest();
	 		insert cv;
	 		//check if record was successfully inserted
	 		Assert.isNotNull(cv.Id);
	 		//requery update field values
	 		cv = [SELECT Id, SharingPrivacy FROM ContentVersion WHERE Id = :cv.Id];
	 		//check if sharing privacy was updated to private
	 		Assert.areEqual(cv.SharingPrivacy, 'P');
	 	Test.stopTest(); 
	}
	
	@isTest 
	static void testFeedItemCreation() {
	    Case testCase = new Case(Subject = 'TestSubject');
	    insert testCase;
	    
	 	ContentVersion cv = new ContentVersion(); 
	 	cv.FirstPublishLocationId = testCase.Id;
	 	cv.Title ='test cv';
	 	//testContentInsert.ContentURL='<a target="_blank" href="http://www.google.com/';" rel="nofollow">http://www.google.com/';</a> 
	 	cv.ContentURL='www.google.com';
	 	cv.SharingPrivacy = 'N';

	 	Test.startTest();
	 		insert cv;
	 		//check if record was successfully inserted
	 		Assert.isNotNull(cv.Id);
	 		//requery update field values
	 		cv = [SELECT Id, SharingPrivacy FROM ContentVersion WHERE Id = :cv.Id];
	 		//check if sharing privacy was updated to private
	 		Assert.areEqual(cv.SharingPrivacy, 'P');
	 	Test.stopTest(); 
	}

	@isTest 
	static void testProfilePicture() {
	    Contact testContact = new Contact(LastName = 'Test Contact');
	    insert testContact;
	    
	 	ContentVersion cv = new ContentVersion(); 
	 	cv.Title ='test cv';
	 	//testContentInsert.ContentURL='<a target="_blank" href="http://www.google.com/';" rel="nofollow">http://www.google.com/';</a> 
	 	cv.ContentURL='www.google.com';
	 	cv.SharingPrivacy = 'N';
		cv.isProfilePhoto__c = true;
		cv.Constituent__c = testContact.Id;

	 	Test.startTest();
	 		insert cv;
	 		//check if record was successfully inserted
	 		Assert.isNotNull(cv.Id);
	 		//requery update field values
	 		testContact = [SELECT ID, ucinn_ascendv2__Picture_Record_ID__c FROM Contact WHERE ID =: testContact.Id];
	 		//check if sharing privacy was updated to private
	 		Assert.areEqual(testContact.ucinn_ascendv2__Picture_Record_ID__c, cv.Id);
	 	Test.stopTest(); 
	}
}