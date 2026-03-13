/**
 * @description	: Test class for SkillRoutingServices
 * @author				: Angelo Rivera
 * @group				: Test Class
 * @last modified on  : 2021-05-19
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-05-19 - Angelo Rivera - Initial Creation
 * 2.0   2021-06-01 - Angelo Rivera - Added test coverage
 * 2.1   2021-06-04 - Angelo Rivera - Handle racing condition error
**/

@isTest(isParallel=true)
private class SkillRoutingServices_Test {

	@TestSetup
	static void setup() {
		List<Skill_Attribute__c> lstSkillAttributes = new List<Skill_Attribute__c>();
		lstSkillAttributes.add(new Skill_Attribute__c(Object_Name__c='Case', Field_Name__c='RecordType.Name',Operator__c='==', Value__c= 'Standard Enquiry'));
		lstSkillAttributes.add(new Skill_Attribute__c(Object_Name__c='Case', Field_Name__c='RecordType.Name',Operator__c='!=', Value__c= 'Special Consideration'));
		lstSkillAttributes.add(new Skill_Attribute__c(Object_Name__c='Case', Field_Name__c='Enquiry_Type__c',Operator__c='==', Value__c= 'Course Advice'));
		lstSkillAttributes.add(new Skill_Attribute__c(Object_Name__c='Case', Field_Name__c='Category_Level_1__c',Operator__c='==', Value__c= 'First Year Advice;Course Advice'));
		lstSkillAttributes.add(new Skill_Attribute__c(Object_Name__c='Case', Field_Name__c='Category_Level_1__c',Operator__c='!=', Value__c= 'Exams'));
		lstSkillAttributes.add(new Skill_Attribute__c(Object_Name__c='Case', Field_Name__c='Managing_Faculty__c',Operator__c='==', Value__c= 'Arts'));
		insert lstSkillAttributes;

		String strSkillAttributes ='';
		for(Skill_Attribute__c sa : [SELECT Name FROM Skill_Attribute__c]){
			if(strSkillAttributes==''){
				strSkillAttributes=sa.Name;
			}else{
				strSkillAttributes+=','+ sa.Name;
			}
		}
		System.debug('!@# strSkillAttributes: '+strSkillAttributes);


		Skill_Mapping__c sm = new Skill_Mapping__c(
				Name='Course Advice - Arts',
				Skill__c='Course Advice - Arts',
				Skill_Attribute__c=strSkillAttributes,
				Skill_Level__c=10,
				IsActive__c=true,
				Level__c=1);
		insert sm;

	}

	@IsTest
	static void testSkillBasedRouting() {
		Id queueId = [SELECT Id, Name, DeveloperName FROM Group WHERE Name = 'Monash Connect Course Advice'].Id;
		Id recId2 = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();

		Test.startTest();
		Case c = new Case(
				RecordTypeId = recId2,
				Enquiry_Type__c = 'Course Advice',
				Origin = 'Web - Monash Forms',
				Category_Level_1__c = 'Course Advice',
				Category_Level_2__c = 'General Enquiry',
				Subject = 'Testing Skill-Based Routing - Course Advice',
				Managing_Faculty__c = 'Arts',
				OwnerId = queueId);
		insert c;
		Test.stopTest();

		List<PendingServiceRouting> lstPsr = new List<PendingServiceRouting>();
		lstPsr = [SELECT Id, WorkItemId, RoutingType, IsReadyForRouting FROM PendingServiceRouting];
		if(lstPsr.isEmpty()){
			System.assertNotEquals(null, lstPsr.size());
			System.assertEquals(lstPsr.get(0).WorkItemId, c.Id);
			System.assertEquals(lstPsr.get(0).IsReadyForRouting, true);
		}
	}

	@IsTest
	static void testSkillBasedRoutingUpdate() {
		Id queueId = [SELECT Id, Name, DeveloperName FROM Group WHERE Name = 'Monash Connect Course Advice'].Id;
		Id recId2 = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();

		Test.startTest();
		Case c = new Case(
				RecordTypeId = recId2,
				Enquiry_Type__c = 'Course Advice',
				Origin = 'Web - Monash Forms',
				Category_Level_1__c = 'Course Advice',
				Category_Level_2__c = 'General Enquiry',
				Subject = 'Testing Skill-Based Routing - Course Advice',
				Managing_Faculty__c = 'Arts',
				OwnerId = queueId);
		insert c;
		c.OwnerId = UserInfo.getUserId();
		update c;
		c.OwnerId = queueId;
		update c;
		Test.stopTest();

		List<PendingServiceRouting> lstPsr = new List<PendingServiceRouting>();
		lstPsr = [SELECT Id, WorkItemId, RoutingType, IsReadyForRouting FROM PendingServiceRouting];
		if(lstPsr.isEmpty()){
			System.assertNotEquals(null, lstPsr.size());
			System.assertEquals(lstPsr.get(0).WorkItemId, c.Id);
			System.assertEquals(lstPsr.get(0).IsReadyForRouting, true);
		}
	}
}