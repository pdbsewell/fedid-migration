/**
* @author          Ajitabh
* @description     This class contains unit tests for validating the behavior of ContactRelationshipServices methods.
* @revision 
*/
@isTest(isParallel=true)
private class ContactRelationshipServices_Test{
    
    @testSetup
    static void setup() {
        
        // create four contacts - two pairs
        List<Contact> testContacts = TestHelper.createOrphanContactRecords(4);
        testContacts[0].Person_Id_unique__c = 'Man Partnered';
        testContacts[1].Person_Id_unique__c = 'Woman Partnered';
        testContacts[2].Person_Id_unique__c = 'Man unPartnered';
        testContacts[3].Person_Id_unique__c = 'Woman unPartnered';
        insert testContacts;
        // Create name entries
        List<Name__c> testNames = new List<Name__c>();
        testNames.add(new Name__c(Contact__c = testContacts[0].id, First_Name__c = 'Man', Last_Name__c ='Partnered'));
        testNames.add(new Name__c(Contact__c = testContacts[1].id,First_Name__c = 'Woman', Last_Name__c ='Partnered'));
        testNames.add(new Name__c(Contact__c = testContacts[2].id,First_Name__c = 'Man', Last_Name__c ='unPartnered'));
        testNames.add(new Name__c(Contact__c = testContacts[3].id,First_Name__c = 'Woman', Last_Name__c ='unPartnered'));
        insert testNames;
		// Create relationships  
		List<Contact_Relationship__c> relationships = new List<Contact_Relationship__c>();      
		// Partnered relationship
        relationships.add (new Contact_Relationship__c(
        	Contact__c=testContacts[0].Id,
        	Related_Contact__c=testContacts[1].Id,
      		Start_Date__c = System.today().addDays(-45),
        	Type__c ='Spouse'));

        // unpartnered relationship
        relationships.add(new Contact_Relationship__c(
        Contact__c=testContacts[2].Id,
        Related_Contact__c=testContacts[3].Id,
        Start_Date__c = System.today().addDays(-45),
        Type__c ='Friend'));
        // Insert
        insert relationships;
    }
    
    @isTest
    static void testCreateReciprocalRelationship() {
        // Given
        Contact originalContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Man Partnered'];
        Contact_Relationship__c originalContactRelationship = [SELECT Id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:originalContact.Id AND Type__c ='Spouse'];
        Contact_Relationship__c reciprocalRelationship = [SELECT Id, Start_Date__c, Type__c, Reciprocal_Relationship__c, Contact__c
                                                          FROM Contact_Relationship__c
                                                          WHERE Reciprocal_Relationship__c = :originalContactRelationship.Id
                                                          LIMIT 1];
        // Then
        System.assertEquals('Spouse',reciprocalRelationship.Type__c ,'Recipical relationship of type Spouse exists');
    }
    
    @isTest
    static void testUpdateReciprocalRelationship() {

        Contact originalContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Man Partnered'];
        Contact_Relationship__c originalContactRelationship = [SELECT Id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:originalContact.Id AND Type__c ='Spouse'];

        originalContactRelationship.Type__c = 'Friend';
        originalContactRelationship.Start_Date__c = System.today();
        originalContactRelationship.End_Date__c = System.today().addDays(1);
        Test.startTest();
        update originalContactRelationship;
        Contact_Relationship__c reciprocalRelationship = [SELECT Id, Start_Date__c,End_Date__c, Type__c, Reciprocal_Relationship__c, Contact__c
                                                          FROM Contact_Relationship__c
                                                          WHERE Reciprocal_Relationship__c =:originalContactRelationship.Id
                                                          LIMIT 1];
        Test.stopTest();
        System.assertEquals('Friend', reciprocalRelationship.Type__c,'Reciprocal Relationship Type should reflect the Relationship Type ');	
        System.assertEquals(originalContactRelationship.Start_Date__c, reciprocalRelationship.Start_Date__c,'Start Date should be the same as the Relationship Type');
        System.assertEquals(originalContactRelationship.End_Date__c, reciprocalRelationship.End_Date__c,'End Date should be the same as the Relationship Type');
    }
    
    @isTest
    static void testUpdateRelationshipWithEndDate() {

        Contact originalContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Man Partnered'];
        Contact_Relationship__c originalContactRelationship = [SELECT Id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:originalContact.Id LIMIT 1];
		
        originalContactRelationship.End_Date__c = System.today();
        Test.startTest();
        update originalContactRelationship;
        Test.stopTest();
        Contact_Relationship__c reciprocalRelationship = [SELECT Id, Start_Date__c, End_Date__c, Type__c, Reciprocal_Relationship__c, Contact__c
                                                          FROM Contact_Relationship__c
                                                          WHERE Reciprocal_Relationship__c =:originalContactRelationship.Id
                                                          LIMIT 1];
        System.assertEquals(originalContactRelationship.End_Date__c, reciprocalRelationship.End_Date__c,'End Date should be the same as the Relationship Type');
        
        List<ucinn_ascendv2__Salutation__c> jointSalutations = 
            [SELECT id 
            FROM ucinn_ascendv2__Salutation__c
            WHERE ucinn_ascendv2__Salutation_Record_Type_Formula__c = 'Joint'
            And ucinn_ascendv2__Contact__c = :originalContact.id];
        
        System.assertEquals(0, jointSalutations.size(),'Joint salutation should be removed after end date is updated');
        
    }
    
    @isTest
    static void testUpdateRelationshipTypeSpouse() {
        Contact originalContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Man unPartnered'];
        Contact_Relationship__c originalContactRelationship = [SELECT Id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:originalContact.Id AND Type__c ='Friend'];
        originalContactRelationship.Type__c = 'Spouse';
        Test.startTest();
        update originalContactRelationship;
        Test.stopTest();
        System.assertEquals(originalContactRelationship.Type__c, 'Spouse' ,'Relation Type changed to Spouse.');
    }
    
    @isTest
    static void testUpdateRelationshipTypePartner() {
   		Contact originalContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Man Partnered'];



        Contact_Relationship__c originalContactRelationship = [SELECT id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:originalContact.Id AND Type__c ='Spouse'];

        originalContactRelationship.Type__c = 'Partner';
        Test.startTest();
        update originalContactRelationship;
        Test.stopTest();
        System.assertEquals(originalContactRelationship.Type__c, 'Partner' ,'Relation Type changed to Partner.');
        
                List<ucinn_ascendv2__Salutation__c> jointSalutations = 
            [SELECT id,ucinn_ascendv2__Contact__c ,ucinn_ascendv2__Contact_2__c 
             FROM ucinn_ascendv2__Salutation__c
             WHERE ucinn_ascendv2__Salutation_Record_Type_Formula__c = 'Joint'
             And ucinn_ascendv2__Contact__c = :originalContact.id];
        
        System.assertEquals(2, jointSalutations.size(),'Joint Sal should be maintained when changing from Spouse to Partner');

    }
    
    @isTest
    static void testUpdateRelationshipTypeWidow() {

        Contact originalContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Woman Partnered'];
        Contact_Relationship__c originalContactRelationship = [SELECT id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:originalContact.Id AND Type__c ='Spouse'];

        originalContactRelationship.Type__c = 'Widow';
        Test.startTest();
        update originalContactRelationship;
        Test.stopTest();
        System.assertEquals(originalContactRelationship.Type__c, 'Widow' ,'Relation Type changed to Widow.');
        
        List<ucinn_ascendv2__Salutation__c> jointSalutations = 
            [SELECT id 
            FROM ucinn_ascendv2__Salutation__c
            WHERE ucinn_ascendv2__Salutation_Record_Type_Formula__c = 'Joint'
            And ucinn_ascendv2__Contact__c = :originalContact.id];
        
        System.assertEquals(0, jointSalutations.size(),'Joint salutation should be removed after partner is widowed');
        
        
        
    }
    
    @isTest
    static void testUpdateRelationshipTypeDeceasedSpouse() {

        Contact originalContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Man Partnered'];
        Contact_Relationship__c originalContactRelationship = [SELECT id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:originalContact.Id AND Type__c ='Spouse'];

        originalContactRelationship.Type__c = 'Deceased Spouse';
        Test.startTest();
        update originalContactRelationship;
        Test.stopTest();
        System.assertEquals(originalContactRelationship.Type__c, 'Deceased Spouse' ,'Relation Type changed to Deceased Spouse.');
        
                List<ucinn_ascendv2__Salutation__c> jointSalutations = 
            [SELECT id 
            FROM ucinn_ascendv2__Salutation__c
            WHERE ucinn_ascendv2__Salutation_Record_Type_Formula__c = 'Joint'
            And ucinn_ascendv2__Contact__c = :originalContact.id];
        
        System.assertEquals(0, jointSalutations.size(),'Joint salutation should be removed after partner is deceased');
    }
    
    @isTest
    static void testMixedUpdateRelationships() {
		// get two different relationship types
        Contact friendContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Man unPartnered'];
        Contact_Relationship__c friendContactRelationship = [SELECT Id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:friendContact.Id AND Type__c ='Friend'];
        Contact partneredContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Man Partnered'];
        Contact_Relationship__c partneredContactRelationship = [SELECT id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:partneredContact.Id AND Type__c ='Spouse'];
		// Add joint salutaiton
          

        
        friendContactRelationship.Type__c = 'Spouse';
        partneredContactRelationship.Type__c = 'Friend';
        
        Test.startTest();
         update new List<Contact_Relationship__c>{friendContactRelationship,partneredContactRelationship};
        Test.stopTest();
        
        List<ucinn_ascendv2__Salutation__c> jointSalutationsNew = 
            [SELECT id,ucinn_ascendv2__Contact__c ,ucinn_ascendv2__Contact_2__c 
            FROM ucinn_ascendv2__Salutation__c
            WHERE ucinn_ascendv2__Salutation_Record_Type_Formula__c = 'Joint'
            And (ucinn_ascendv2__Contact__c = :friendContact.id OR ucinn_ascendv2__Contact__c = :partneredContact.id)
            ORDER BY ucinn_ascendv2__Contact__r.Person_Id_unique__c];
        
        System.assertEquals(2, jointSalutationsNew.size(),'There should be an inner and outer joint salutation for a new relationship and removed for the old relationship');
        System.assertEquals(friendContact.id, jointSalutationsNew[0].ucinn_ascendv2__Contact__c,'Joint salutation should belong to the new relationship');
        System.assertEquals(friendContact.id, jointSalutationsNew[1].ucinn_ascendv2__Contact__c,'Joint salutation should belong to the new relationship');
    }
    
    @isTest
    static void testQueryCustomMetaData(){
        Test.startTest();
        Map<String,String> relationTypeMap = ContactRelationshipServices.getReciprocalRelationshipMap();
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteReciprocalRelationship() {
        Contact originalContact = [SELECT id FROM Contact WHERE Person_Id_unique__c = 'Man Partnered'];
        Contact_Relationship__c originalContactRelationship = [SELECT id, Reciprocal_Relationship__c FROM Contact_Relationship__c WHERE Contact__c =:originalContact.Id AND Type__c ='Spouse'];
        Contact_Relationship__c reciprocalRelationship = [SELECT Id, Start_Date__c, Type__c, Reciprocal_Relationship__c, Contact__c
                                                          FROM Contact_Relationship__c
                                                          WHERE Reciprocal_Relationship__c =:originalContactRelationship.Id
                                                          LIMIT 1];
        Test.startTest();
        delete reciprocalRelationship;
        // System.assert(caRec.Id != null, 'Course could not be inserted.');
        // retrieve result record
        List<Contact_Relationship__c> reciprocalRels = [SELECT Id, Start_Date__c, Type__c, Reciprocal_Relationship__c
                                                        FROM Contact_Relationship__c
                                                        WHERE Reciprocal_Relationship__c =:reciprocalRelationship.Id
                                                        LIMIT 1];
        Test.stopTest();
        System.assertEquals(0, reciprocalRels.size(),'record is deleted');
        
    }
}