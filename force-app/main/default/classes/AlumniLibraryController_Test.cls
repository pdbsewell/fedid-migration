/**
 * @author Inderpal Dhanoa
 * @date 20 Mar 2023
 * @group Test Class
 * @description Test class to cover the AP validation library
 * @revision:
 *               2023-09-22 - Sachin Shetty - Added comments.
 */
@isTest(isParallel=true)
public with sharing class AlumniLibraryController_Test {

    @isTest
    public static void retrieveLinksTest(){ 
        // GIVEN: 
        // Insert test Alumni Library Links records
        List<Alumni_Library_Links__c> alumniLibraryLinks = new List<Alumni_Library_Links__c>{
            new Alumni_Library_Links__c(
                Header_Banner__c = 'Test Banner1',
                Header_Description__c = 'Test Description1',
                Header_URL__c = 'Test Header1',
                Image_Link__c = 'Test Image1',
                Image_URL__c = 'Test Image1',
                Category__c = 'Test Category1'
            ),
            new Alumni_Library_Links__c(
                Header_Banner__c = 'Test Banner2',
                Header_Description__c = 'Test Description2',
                Header_URL__c = 'Test Header2',
                Image_Link__c = 'Test Image2',
                Image_URL__c = 'Test Image2',
                Category__c = 'Test Category2'
            ),
            new Alumni_Library_Links__c(
                Header_Banner__c = 'Test Banner3',
                Header_Description__c = 'Test Description3',
                Header_URL__c = 'Test Header3',
                Image_Link__c = 'Test Image3',
                Image_URL__c = 'Test Image3',
                Category__c = 'Test Category3'
            )
        };
        insert alumniLibraryLinks;

        // WHEN
        Test.startTest();
            // Method to retrieve all the records from Alumni Library Links is invoked
            List<AlumniLibraryController.LibLinksWrapper> reLinks = AlumniLibraryController.retrieveLinks();
        Test.stopTest();

        // THEN: All the Alumni Library Links records must be returned
        Assert.areEqual(3, reLinks.size(), 'Unable to find Alumni Library Link records');
        
    }
}