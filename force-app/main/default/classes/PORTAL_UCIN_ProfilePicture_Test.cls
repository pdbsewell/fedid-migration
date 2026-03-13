/**
 * @author Charlie Park, UC Innovation
 * @date 10/16/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for profile picture
 */
@isTest(isParallel=true)
public class PORTAL_UCIN_ProfilePicture_Test {     
    @testSetup
    static void setupData() {
        Contentversion cv = new ContentVersion(Title = 'Test',
                                               PathOnClient = 'Test.jpg',
                                               VersionData = blob.valueOf('Test CV data'),
                                               IsMajorVersion = true);
        insert cv;
        
        Contact con = new Contact(LastName = 'TestContact',
                                  Portal_Picture_ID__c = String.valueOf(cv.Id));
        insert con;
        
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = con.Id;
        contentLink.ShareType = 'V';
        contentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion Where Id =: cv.Id].ContentDocumentId;
        insert contentLink;    
    }

    @isTest
    public static void testGetProfilePictureFromConNoPic() {
        Contact cont = new Contact(LastName = 'TestContact',
                           Portal_Picture_ID__c = null);
        insert cont;

        test.startTest();
        system.assertEquals(PORTAL_UCIN_ProfilePicture.getProfilePictureInfoFromConstituentOrOrganization(cont.Id), null);
        test.stopTest();
    }

    @isTest
    public static void testGetProfilePictureFromConWithPic() {
        Contact con = [SELECT ID FROM Contact LIMIT 1];
        ContentVersion cv = [SELECT ID FROM ContentVersion LIMIT 1];

        test.startTest();
        Map<String, Object> returnMap = PORTAL_UCIN_ProfilePicture.getProfilePictureInfoFromConstituentOrOrganization(con.Id);
        test.stopTest();

        system.assertEquals(returnMap.get('profilePictureId'), cv.Id);
    }
}