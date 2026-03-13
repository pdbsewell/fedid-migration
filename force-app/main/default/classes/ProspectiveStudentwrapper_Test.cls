/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
public class ProspectiveStudentwrapper_Test {
    @testSetup
    static void setup() {
        // Lead
        List<Lead> leads = new List<Lead>();
        
        Lead leadOne = new Lead();
        leadOne.Company = 'Company';
        leadOne.LastName = 'LastName';
        leads.add(leadOne);
        
        insert leads;
        
        // Course_Master__c
        List<Course_Master__c> courseMasters = new List<Course_Master__c>();
        
        Course_Master__c courseMasterOne = new Course_Master__c();
        courseMasterOne.Course_Code__c = 'Course_Code__c';
        courseMasters.add(courseMasterOne);
        
        insert courseMasters;
        
        // Lead_Course_Association__c
        List<Lead_Course_Association__c> leadCourseAssociations = new List<Lead_Course_Association__c>();
        
        Lead_Course_Association__c leadCourseAssociationOne = new Lead_Course_Association__c();
        leadCourseAssociationOne.Course_Master__c = courseMasterOne.Id;
        leadCourseAssociationOne.Lead__c = leadOne.Id;
        leadCourseAssociations.add(leadCourseAssociationOne);
        
        insert leadCourseAssociations;
        
        // Contact
        List<Contact> contacts = new List<Contact>();
        
        Contact contactOne = new Contact();
        contactOne.LastName = 'LastName';
        contacts.add(contactOne);
        
        insert contacts;
        
        // Contact_Qualification__c
        List<Contact_Qualification__c> contactQualifications = new List<Contact_Qualification__c>();
        
        Contact_Qualification__c contactQualificationOne = new Contact_Qualification__c();
        contactQualificationOne.Contact__c = contactOne.Id;
        contactQualificationOne.Other_Qualification__c = 'Other_Qualification__c';
        contactQualificationOne.Institution_Name__c = 'Institution_Name__c';
        contactQualifications.add(contactQualificationOne);
        
        insert contactQualifications;
    }
    
	static testMethod void testAddLeadCourseAssociation() {
        Lead l = [SELECT Id FROM Lead];
        Lead_Course_Association__c lca = [SELECT Id, Lead__c FROM Lead_Course_Association__c];
        
        Test.startTest();
        
        ProspectiveStudentwrapper instance = new ProspectiveStudentwrapper();
        instance.addLeadCourseAssociation(l.Id, lca);
        
        Test.stopTest();
	}
    
    static testMethod void testAddContactQualificationByKey() {
        Contact_Qualification__c cq = [SELECT
                                       Id,
                                       Contact__c,
                                       Other_Qualification__c,
                                       Institution_Name__c
                                       FROM Contact_Qualification__c];
        
        Test.startTest();
        
        ProspectiveStudentwrapper instance = new ProspectiveStudentwrapper();
        instance.addContactQualificationByKey(cq);
        
        Test.stopTest();
	}
    
    static testMethod void testSPSRecords() {
        Test.startTest();
        
        ProspectiveStudentwrapper.SPSRecords instance = new ProspectiveStudentwrapper.SPSRecords();
        System.debug(instance.spsByDNOMap);
        System.debug(instance.mergedAllSPS);
        System.debug(instance.mergedDNOSps);
        System.debug(instance.mergedOverwriteSps);
        
        Test.stopTest();
	}
}