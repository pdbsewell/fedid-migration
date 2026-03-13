/**
 * @author Inderpal Dhanoa
 * @date 9/20/2023
 * @group ERDA
 * @group-content 
 * @description An apex page controller that renders links for the Library Page
 * @last modified on  : 2023-09-22
 * @last modified by  : Sachin Shetty
 * Modifications Log 
 * Ver   Date         Author              Modification  
 * 1.0   2023-03-20 - Inderpal Dhanoa - Initial Version
 * 1.1   2023-09-22 - Sachin Shetty   - Moved the library page links to a custom object
**/
public with sharing class AlumniLibraryController { 
    @AuraEnabled
    public static List<LibLinksWrapper> retrieveLinks(){
        try {
            LibLinksWrapper wrapperlink;
            List<LibLinksWrapper> relLinks = new List<LibLinksWrapper>();
            for(Alumni_Library_Links__c link : [SELECT Header_Banner__c, Header_Description__c, Header_URL__c, Image_Link__c, Image_URL__c, Category__c, Order__c FROM Alumni_Library_Links__c ORDER BY Order__c ASC]){
                wrapperlink = new LibLinksWrapper();
                wrapperlink.headerBanner = link.Header_Banner__c;
                wrapperlink.headerDescription = link.Header_Description__c;
                wrapperlink.headerURL = link.Header_URL__c;
                wrapperlink.imageLink = link.Image_Link__c;
                wrapperlink.imageURL = link.Image_URL__c;
                wrapperlink.category = link.Category__c;
                relLinks.add(wrapperlink);
            }
            return relLinks;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class LibLinksWrapper{
        @AuraEnabled
        public String headerBanner;
        @AuraEnabled
        public String headerDescription;
        @AuraEnabled
        public String headerURL;
        @AuraEnabled
        public String imageLink;
        @AuraEnabled
        public String imageURL;
        @AuraEnabled
        public String category;
    } 
}