/**
* @author Martin Cadman
* @date 28.03.2019
*
* @group Assessment
*
* @description 
* IbdEncumbrance__e test class.<br/>
*
* @revision
* 28.03.2019 Martin Cadman - Initial version<br/>
* 07.09.2019 Martin Cadman - Reviewed for code coverage, added retry exception test.<br/>
* 01-06-2025 Martin Cadman : Moved to Assert class
*
*/
@isTest(isParallel=true)
public class IbdEncumbranceServices_Test {
    private static final Integer NUMBER_OF_CONTACTS = 5;
    
    private static List<Contact> contactList = new List<Contact>();
    private static List<Course_Attempt__c> courseAttList = new List<Course_Attempt__c>();
    
    @testSetup
    static void testSetup() {
        Course__c aCourse = new Course__c(Name = 'A9999',Type__c = 'Course-All',course_code__c = 'A9999', version__c = '1');
        insert aCourse; 
        
        Course_Group__c aGroup = new Course_Group__c(Name = 'GroupA', course_group__c = 'GroupA', is_active__c = true, type__c = 'GOVT-RET');
		insert aGroup;
        
        // Disable some of the automation that occurs when contacts are created
        triggerCommon.disableTrigger('Contact');
        ucinn_ascendv2__Trigger_Handler__c disableEngageTrig = new ucinn_ascendv2__Trigger_Handler__c(ucinn_ascendv2__Object__c ='Contact',ucinn_ascendv2__Is_Active__c=False,ucinn_ascendv2__class__c='ascend_TRIG_Contact');
        insert disableEngageTrig;

        for (Integer i=0; i<NUMBER_OF_CONTACTS; i++) {
            contactList.add(new Contact(Person_Id_unique__c = 'ID-'+i, LastName = 'Lastname-'+i, FirstName = 'Firstname-'+i, SAP_Staff_Id__c = 'NoDupRules'+i));
        }
        insert contactList;

        for (Integer i=0; i<NUMBER_OF_CONTACTS; i++) {
            courseAttList.add(new Course_Attempt__c(Callista_External_Id__c = contactList[i].Person_Id_unique__c + '_' + aCourse.Course_Code__c, person_id__c = contactList[i].Person_Id_unique__c, Course__c = aCourse.id, contact__c = contactList[i].id));
        }
        insert courseAttList;
    }
    
   /*
	* Test method to validate the processing of a single course attempt
	*/
    @isTest
    static void testInsertEncumbrance() {
        IbdEncumbrance__e inEvent = new IbdEncumbrance__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = 'ID-1';
        inEvent.financialIndicator__c = true;
        inEvent.encumbranceEffectUniqueKey__c = 'testunique1';
        inEvent.effectCourseCode__c = 'A9999';
        inEvent.ExclusionCourseGroup__c = 'GroupA';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), 'Encumbrance event could not be published. Errors: ' + sr.getErrors());
        List<Encumbrance__c> encList = [SELECT Id
                                          FROM Encumbrance__c
                                         WHERE contact__r.person_id__c = 'ID-1'];
        Assert.areEqual(1, encList.size(), 'Encumbrance record was not inserted as expected');
    }

   /*
	* @description Test method to validate the processing of a single Encumbrance
	*/
    @isTest
    static void testUpdateEncumbrance() {
        IbdEncumbrance__e inEvent = new IbdEncumbrance__e();
        inEvent.Event_Type__c = 'INSERT';
        inEvent.Person_ID__c = 'ID-1';
        inEvent.financialIndicator__c = true;
        inEvent.encumbranceEffectUniqueKey__c = 'testunique1';
		inEvent.effectDescription__c = 'Inserted';
        inEvent.effectCourseCode__c = 'A9999';
        inEvent.ExclusionCourseGroup__c = 'GroupA';

        IbdEncumbrance__e upEvent = new IbdEncumbrance__e();
        upEvent.Event_Type__c = 'UPDATE';
        upEvent.Person_ID__c = 'ID-1';
        upEvent.financialIndicator__c = true;
		upEvent.effectDescription__c = 'Updated';
        upEvent.encumbranceEffectUniqueKey__c = 'testunique1';
        upEvent.effectCourseCode__c = 'A9999';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Assert.isTrue(sr.isSuccess(), 'Encumbrance insert event could not be published. Errors: ' + sr.getErrors());
        sr = EventBus.publish(upEvent);
        Assert.isTrue(sr.isSuccess(), 'Encumbrance update event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();

        List<Encumbrance__c> encList = [SELECT Id
                                          FROM Encumbrance__c
                                         WHERE contact__r.person_id__c = 'ID-1' AND eff_Description__c = 'Updated'];
        Assert.areEqual(1, encList.size(), 'Encumbrance record was not updated as expected (a)' );
        encList = [SELECT Id
                   FROM Encumbrance__c
                   WHERE contact__r.person_id__c = 'ID-1' AND eff_Description__c = 'Inserted'];
        Assert.areEqual(0, encList.size(), 'Encumbrance record was not updated as expected (b)');
    }

   /*
	* @description Test method to validate deleting an existing Encumbrance
	*/
    @isTest
    static void testDeleteExistingEncumbrance() {

        List<Contact> conList = [Select id from contact where person_id__c = 'ID-1'];
		        
        Encumbrance__c encumbrance_A = new Encumbrance__c();
        encumbrance_A.contact__c = conList[0].id;
        encumbrance_A.enceff_key__c = 'testunique2';
        insert encumbrance_A;
        
        IbdEncumbrance__e inEvent = new IbdEncumbrance__e();
        inEvent.Event_Type__c = 'DELETE';
        inEvent.Person_ID__c = 'ID-1';
        inEvent.financialIndicator__c = true;
        inEvent.encumbranceEffectUniqueKey__c = 'testunique2';

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Encumbrance event could not be published. Errors: ' + sr.getErrors());
        List<Encumbrance__c> encList = [SELECT Id, deleted_in_source__c, name
                                                  FROM Encumbrance__c
                                                  WHERE deleted_in_source__c = true];
        Assert.areEqual(1, encList.size(), 'Encumbrance not marked as deleted');
    }
    
   /*
	* @description Test method to validate delete event occuring first
	*/
    @isTest
    static void testDeleteMysteryEncumbrance() {

        IbdEncumbrance__e inEvent = new IbdEncumbrance__e();
        inEvent.Event_Type__c = 'DELETE';
        inEvent.Person_ID__c = 'ID-1';
        inEvent.encumbranceEffectUniqueKey__c = 'ID-1_NO-ARR-INT_2019-03-12-000000_SUS_SRVC_2019-03-12-000000_690552';
        inEvent.effectTypeApplyToCourseInd__c = false;
        inEvent.financialIndicator__c = false;
        inEvent.encumbranceUniqueKey__c = 'ID-1_NO-ARR-INT_2019-03-12-000000';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(inEvent);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Encumbrance event could not be published. Errors: ' + sr.getErrors());
        List<Encumbrance__c> encList = [SELECT Id
                                        FROM Encumbrance__c
                                        WHERE deleted_in_source__c = true];
        
        Assert.areEqual(1, encList.size(), 'Encumbrance should be created as a deleted in source record');
    }
    
   /*
	* @description Test method to validate retry events
	*/
	@isTest
    static void testRetry() {
        Test.startTest();

        IbdEncumbrance__e iEnc = new IbdEncumbrance__e();
        iEnc.Event_Type__c = 'INSERT';
        iEnc.Person_ID__c = 'Nobody';
        iEnc.encumbranceEffectUniqueKey__c = 'ID-X_NO-ARR-INT_2019-03-12-000000_SUS_SRVC_2019-03-12-000000_690552';
        iEnc.effectTypeApplyToCourseInd__c = false;
        iEnc.financialIndicator__c = false;
        iEnc.encumbranceUniqueKey__c = 'ID-X_NO-ARR-INT_2019-03-12-000000';
        
        Database.SaveResult SR = EventBus.publish(iEnc);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
 
        for(Integer i=0;i<2 ;i++) {                          
            // Get info about all subscribers to the event

            EventBusSubscriber[] subscribers = queryBus('IbdEncumbrance__e');
            for (EventBusSubscriber sub : subscribers) { 
				if (sub.Name == 'IbdEncumbranceTrigger') {
	                Assert.areEqual(i+1, sub.Retries);
                }
            }
            // Deliver the retried event
            Test.getEventBus().deliver();
        }

        Test.stopTest();
    }
    
    static List<EventBusSubscriber> queryBus(String ibdObject) {
        List<EventBusSubscriber> bus = new List<EventBusSubscriber>();
        try {
            bus = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic=:ibdObject];
        } catch(Exception e) {
            return new List<EventBusSubscriber>();
        }
        return bus;
    }
}