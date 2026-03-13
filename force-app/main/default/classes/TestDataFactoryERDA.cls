/**
 * @description       : 
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 03-05-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest
public with sharing class TestDataFactoryERDA {
   
    /***** Contact Object [Contact] *****/

    /**
    * @description Create Non Studen Contact.
    *R ecord Type Label = Not known to Monash systems
    * Record Type Name	= Non_Student
    * @author rajesh.punjabi@monash.edu | 03-05-2022 
    * @param bInsert 
    * @return Contact 
    **/
    public static Contact createNonStudenContact(Boolean bInsert){
        Contact oContact = new Contact(
            FirstName='Sample'+ CommonUtilityERDA.generateRandomString(5),
            LastName='John'+ CommonUtilityERDA.generateRandomString(5),
            Email = CommonUtilityERDA.generateRandomString(5) + 'test@mutesting.edu',
            Deceased_Date__c = null,
            Deceased__c = false
        );

        if (bInsert){
            insert oContact;
        }

        return oContact;
    }

   /***** Contact Relationship Object [Contact_Relationship__c] *****/

   /**
   * @description Create Contact Relationship Record With Type.
   * @author rajesh.punjabi@monash.edu | 03-05-2022 
   * @param strRelationType 
   * @param bInsert 
   **/
   public static Contact_Relationship__c createContactRelationship (String strRelationType, Boolean bInsert){
        Contact_Relationship__c oContactRelation = new Contact_Relationship__c();
        oContactRelation.Contact__c = createNonStudenContact(true).Id;
        oContactRelation.Related_Contact__c = createNonStudenContact(true).Id;
        oContactRelation.Start_Date__c = System.today().addDays(-45);
        oContactRelation.End_Date__c = null;
        oContactRelation.Type__c = strRelationType;
        if(bInsert){
            insert oContactRelation;
        }
        return oContactRelation;
   }
}