@isTest(isParallel=true)
public with sharing class SalutationDuplicateCheck_Test {
    /**
     * @description : test the removal of duplicate salutations by passing a set of contact Id. 
    */ 
    @isTest
    static void test_RemoveDuplicateSalutationsIdSet() {

        ucinn_ascendv2__Trigger_Handler__c ascTrigHandler = new ucinn_ascendv2__Trigger_Handler__c(Name = 'SalutationHandler', ucinn_ascendv2__Class__c = 'SalutationHandler', 
                                                                                                   ucinn_ascendv2__Object__c = 'ucinn_ascendv2__Salutation__c', ucinn_ascendv2__Load_Order__c = 1.00, ucinn_ascendv2__Is_Active__c = true,
                                                                                                   ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete');
        
        insert ascTrigHandler;
        List<Contact> conList = new List<Contact>();
        // Create test data
        TriggerCommon.disableTrigger('Contact');
        Contact contact1 = new Contact(LastName = 'Test', Email = 'testdev@gmail.com', Preferred_Name__c='Sky');
        Contact contact2 = new Contact(LastName = 'Test', Email = 'testdev@gmail.com', Preferred_Name__c='Sky');
        conList.add(contact1);
        conList.add(contact2);
        insert conList;
        TriggerCommon.enableTrigger('Contact');

        List<ucinn_ascendv2__Salutation__c> salutationList1 = new List<ucinn_ascendv2__Salutation__c>();
        List<ucinn_ascendv2__Salutation__c> salutationList2 = new List<ucinn_ascendv2__Salutation__c>();

        //Create salutation JSON record
        String salJASON = '{"attributes":{"type":"ucinn_ascendv2__Salutation__c","url":"/services/data/v25.0/sobjects/ucinn_ascendv2__Salutation__c"},"CreatedDate":"2023-08-01T07:54:26.000+0000", "LastModifiedDate":"2023-08-01T07:54:26.000+0000"}'; 
        ucinn_ascendv2__Salutation__c sal = (ucinn_ascendv2__Salutation__c) JSON.deserialize(salJASON, ucinn_ascendv2__Salutation__c.class); 
        
        //Create salutation record
        ucinn_ascendv2__Salutation__c salutation = sal;  
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);      
        salutation.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation.ucinn_ascendv2__Contact__c = contact1.Id;
        salutation.ucinn_ascendv2__Salutation_Type__c = 'Formal';
        salutation.ucinn_ascendv2__Inside_Salutation__c = 'Sky';
        salutation.ucinn_ascendv2__Addressee_Line_1__c = 'Sky Test';
        salutation.ucinn_ascendv2__Salutation_Author__c = 'Standard';
        salutation.Name = 'null';        
        salutationList1.add(salutation);

        String salJASON2 = '{"attributes":{"type":"ucinn_ascendv2__Salutation__c","url":"/services/data/v25.0/sobjects/ucinn_ascendv2__Salutation__c"},"CreatedDate":"2023-08-01T07:54:26.000+0000", "LastModifiedDate":"2023-08-01T07:54:26.000+0000"}'; 
        ucinn_ascendv2__Salutation__c sal2 = (ucinn_ascendv2__Salutation__c) JSON.deserialize(salJASON2, ucinn_ascendv2__Salutation__c.class); 
        //Create salutation record
        ucinn_ascendv2__Salutation__c salutation2 = sal2;  
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);      
        salutation2.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation2.ucinn_ascendv2__Contact__c = contact1.Id;
        salutation2.ucinn_ascendv2__Salutation_Type__c = 'Informal';
        salutation2.ucinn_ascendv2__Inside_Salutation__c = 'Sky';
        salutation2.ucinn_ascendv2__Salutation_Author__c = 'Standard';
        salutation2.Name = 'null';        
        salutationList1.add(salutation2);
        
        insert salutationList1;

        //Create salutation record for contact 2
        ucinn_ascendv2__Salutation__c salutation3 = new ucinn_ascendv2__Salutation__c(); 
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);       
        salutation3.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation3.ucinn_ascendv2__Contact__c = contact2.Id;
        salutation3.ucinn_ascendv2__Salutation_Type__c = 'Formal';
        salutation3.ucinn_ascendv2__Inside_Salutation__c = 'Sky';
        salutation3.ucinn_ascendv2__Addressee_Line_1__c = 'Sky Test';
        salutation3.ucinn_ascendv2__Salutation_Author__c = 'Standard';
        salutation3.Name = 'null';        
        salutationList2.add(salutation3);

        //Create salutation record contact 2
        ucinn_ascendv2__Salutation__c salutation4 = new ucinn_ascendv2__Salutation__c();  
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);      
        salutation4.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation4.ucinn_ascendv2__Contact__c = contact2.Id;
        salutation4.ucinn_ascendv2__Salutation_Type__c = 'Informal';
        salutation4.ucinn_ascendv2__Inside_Salutation__c = 'Sky';
        salutation4.ucinn_ascendv2__Salutation_Author__c = 'Standard';
        salutation4.Name = 'null';        
        salutationList2.add(salutation4);

        insert salutationList2;
        
        //Merge two records. This will reparent salutations 3 and 4 
        merge contact1 contact2;
        
         // Test method
        SalutationDuplicateCheck deduplication = new SalutationDuplicateCheck();
        Test.startTest();
        deduplication.removeDuplicateSalutations(new Set<Id>{contact1.Id});
        Test.stopTest();
         // Verify
        List<ucinn_ascendv2__Salutation__c> salutations = [SELECT LastModifiedDate, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Salutation_Type__c FROM ucinn_ascendv2__Salutation__c WHERE ucinn_ascendv2__Contact__c = :contact1.Id];
        System.assertEquals(2, salutations.size(), 'Should only have two salutations left after deduplication');
    }

    /**
     * @description : test the removal of duplicate salutations by passing a contact Id. 
    */ 
    @isTest
    static void test_RemoveDuplicateSalutationsRecordId() {
        ucinn_ascendv2__Trigger_Handler__c ascTrigHandler = new ucinn_ascendv2__Trigger_Handler__c(Name = 'SalutationHandler', ucinn_ascendv2__Class__c = 'SalutationHandler', 
            ucinn_ascendv2__Object__c = 'ucinn_ascendv2__Salutation__c', ucinn_ascendv2__Load_Order__c = 1.00, ucinn_ascendv2__Is_Active__c = true,
            ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete');

        insert ascTrigHandler;
        List<Contact> conList = new List<Contact>();
        // Create test data
        TriggerCommon.disableTrigger('Contact');
        Contact contact1 = new Contact(LastName = 'Walker', Email = 'testContact@gmail.com', Preferred_Name__c='Sky');
        Contact contact2 = new Contact(LastName = 'Walker', Email = 'testContact@gmail.com', Preferred_Name__c='Sky');
        conList.add(contact1);
        conList.add(contact2);
        insert conList;
        TriggerCommon.enableTrigger('Contact');        

        List<ucinn_ascendv2__Salutation__c> salutationList1 = new List<ucinn_ascendv2__Salutation__c>();
        List<ucinn_ascendv2__Salutation__c> salutationList2 = new List<ucinn_ascendv2__Salutation__c>();

        //Create salutation JSON record
        String salJASON = '{"attributes":{"type":"ucinn_ascendv2__Salutation__c","url":"/services/data/v25.0/sobjects/ucinn_ascendv2__Salutation__c"},"CreatedDate":"2023-08-01T07:54:26.000+0000", "LastModifiedDate":"2023-08-01T07:54:26.000+0000"}'; 
        ucinn_ascendv2__Salutation__c sal = (ucinn_ascendv2__Salutation__c) JSON.deserialize(salJASON, ucinn_ascendv2__Salutation__c.class); 

        //Create salutation record
        ucinn_ascendv2__Salutation__c salutation = sal;  
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);      
        salutation.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation.ucinn_ascendv2__Contact__c = contact1.Id;
        salutation.ucinn_ascendv2__Salutation_Type__c = 'Formal';
        salutation.ucinn_ascendv2__Inside_Salutation__c = 'Sky';
        salutation.ucinn_ascendv2__Addressee_Line_1__c = 'Sky Walker';
        salutation.ucinn_ascendv2__Salutation_Author__c = 'Standard';
        salutation.Name = 'null';        
        salutationList1.add(salutation);

        String salJASON2 = '{"attributes":{"type":"ucinn_ascendv2__Salutation__c","url":"/services/data/v25.0/sobjects/ucinn_ascendv2__Salutation__c"},"CreatedDate":"2023-08-01T07:54:26.000+0000", "LastModifiedDate":"2023-08-01T07:54:26.000+0000"}'; 
        ucinn_ascendv2__Salutation__c sal2 = (ucinn_ascendv2__Salutation__c) JSON.deserialize(salJASON2, ucinn_ascendv2__Salutation__c.class); 
        //Create salutation record
        ucinn_ascendv2__Salutation__c salutation2 = sal2;  
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);      
        salutation2.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation2.ucinn_ascendv2__Contact__c = contact1.Id;
        salutation2.ucinn_ascendv2__Salutation_Type__c = 'Informal';
        salutation2.ucinn_ascendv2__Inside_Salutation__c = 'Sky';
        salutation2.ucinn_ascendv2__Salutation_Author__c = 'Standard';
        salutation2.Name = 'null';        
        salutationList1.add(salutation2);
        
        insert salutationList1;

        //Create salutation record for contact 2
        ucinn_ascendv2__Salutation__c salutation3 = new ucinn_ascendv2__Salutation__c(); 
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);       
        salutation3.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation3.ucinn_ascendv2__Contact__c = contact2.Id;
        salutation3.ucinn_ascendv2__Salutation_Type__c = 'Formal';
        salutation3.ucinn_ascendv2__Inside_Salutation__c = 'Sky';
        salutation3.ucinn_ascendv2__Addressee_Line_1__c = 'Sky Walker';
        salutation3.ucinn_ascendv2__Salutation_Author__c = 'Standard';
        salutation3.Name = 'null';        
        salutationList2.add(salutation3);

        //Create salutation record contact 2
        ucinn_ascendv2__Salutation__c salutation4 = new ucinn_ascendv2__Salutation__c();  
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);      
        salutation4.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation4.ucinn_ascendv2__Contact__c = contact2.Id;
        salutation4.ucinn_ascendv2__Salutation_Type__c = 'Informal';
        salutation4.ucinn_ascendv2__Inside_Salutation__c = 'Sky';
        salutation4.ucinn_ascendv2__Salutation_Author__c = 'Standard';
        salutation4.Name = 'null';        
        salutationList2.add(salutation4);

        insert salutationList2;        

        //Merge two records. This will reparent salutations 3 and 4 
        merge contact1 contact2;
        
         // Test method
        SalutationDuplicateCheck deduplication = new SalutationDuplicateCheck();
        Test.startTest();
        deduplication.removeDuplicateSalutations(contact1.Id);
        Test.stopTest();
         // Verify
        List<ucinn_ascendv2__Salutation__c> salutations = [SELECT LastModifiedDate, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Salutation_Type__c FROM ucinn_ascendv2__Salutation__c WHERE ucinn_ascendv2__Contact__c = :contact1.Id];
        System.assertEquals(2, salutations.size(), 'Should only have two salutations left after deduplication');
    }

    @isTest
    static void test_RemoveDuplicateSalutations_NoDuplicates() {
        // Create test data
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < 2; i++) {
            Contact contact = new Contact(LastName = 'Test' + i, Email = 'testdev' + i + '@gmail.com', Preferred_Name__c='Sky' + i);
            contacts.add(contact);
        }
       insert contacts;

        List<ucinn_ascendv2__Salutation__c> salutationList = new List<ucinn_ascendv2__Salutation__c>();
        //Create salutation record
        ucinn_ascendv2__Salutation__c salutation1 = new ucinn_ascendv2__Salutation__c();        
        salutation1.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation1.ucinn_ascendv2__Contact__c = contacts[0].Id;
        salutation1.ucinn_ascendv2__Salutation_Type__c = 'Formal';
        salutation1.ucinn_ascendv2__Inside_Salutation__c = 'Salutation';
        salutation1.ucinn_ascendv2__Addressee_Line_1__c = 'Salutation';
        salutation1.ucinn_ascendv2__Addressee_Line_2__c = 'Default';        
        salutation1.ucinn_ascendv2__Salutation_Author__c = 'Honor Roll';
        salutation1.Name = '[Default Name]';        


        //Create salutation record
        ucinn_ascendv2__Salutation__c salutation2 = new ucinn_ascendv2__Salutation__c();        
        salutation2.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation2.ucinn_ascendv2__Contact__c = contacts[1].Id;
        salutation2.ucinn_ascendv2__Salutation_Type__c = 'Formal';
        salutation2.ucinn_ascendv2__Inside_Salutation__c = 'Salutation';
        salutation2.ucinn_ascendv2__Addressee_Line_1__c = 'Salutation';
        salutation2.ucinn_ascendv2__Addressee_Line_2__c = 'Test';
        salutation2.ucinn_ascendv2__Salutation_Author__c = 'Honor Roll';
        salutation2.Name = '[Default Name]';        

        salutationList.add(salutation1);
        salutationList.add(salutation2);

        insert salutationList;

         
         // Test method with no duplicate salutations
        SalutationDuplicateCheck salutationDuplicateCheck = new SalutationDuplicateCheck();
        salutationDuplicateCheck.removeDuplicateSalutations(new Set<Id>{contacts[0].Id});
         // Verify that both salutation records remain
        List<ucinn_ascendv2__Salutation__c> remainingSalutations = [SELECT Id FROM ucinn_ascendv2__Salutation__c WHERE ucinn_ascendv2__Contact__c = :contacts[0].Id];
        System.assertEquals(1, remainingSalutations.size());
    }
}