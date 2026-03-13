/**
 * @author Tom Gangemi
 * @date Feb.2023
 *
 * @revision
 *     2023-02 - Tom Gangemi - SA-2115 - DoI Owner Mapping
 **/
@IsTest(isParallel=true)
private class DOIServices_Test {

    @IsTest
    static void testGetOwnerForSubjectMatter() {
        final String authcate = 'doiServices_123';
        final String email = 'doi.services.test.6849@monash.edu';

        User u = (User)TestDataFactory.createSObject(new User(
            FederationIdentifier = authcate,
            Username = email, Email = email,
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id
        ));
        System.runAs(new User(Id=UserInfo.getUserId())) {
            insert u;
        }

        DoI_Subject_Owner_Mapping__c[] mappings = new DoI_Subject_Owner_Mapping__c[]{
            new DoI_Subject_Owner_Mapping__c(
                Name = '1', Subject_Matter__c = 'Declarations Officer', Queue_Name__c = 'HR_Declaration_of_Interest'
            ),
            new DoI_Subject_Owner_Mapping__c(
                Name = '2', Subject_Matter__c = 'Research', Staff_Authcate__c = authcate
            ),
            new DoI_Subject_Owner_Mapping__c(
                Name = '3', Subject_Matter__c = 'Stuff', Staff_Authcate__c = authcate
            )
        };
        insert mappings;

        // Act
        Test.startTest();
        DOIServices.Result[] results1 = DOIServices.getOwnerForSubjectMatter(
            new String[]{mappings[0].Subject_Matter__c, mappings[1].Subject_Matter__c}
        );
        DOIServices.Result[] results2 = DOIServices.getOwnerForSubjectMatter(
            new String[]{mappings[2].Subject_Matter__c}
        );
        Test.stopTest();

        // Assert
        Id doiQueue = [SELECT Id FROM Group WHERE DeveloperName = :mappings[0].Queue_Name__c AND Type = 'Queue']?.Id;

        Assert.areEqual(2, results1.size());
        Assert.areEqual(mappings[0].Queue_Name__c, results1[0].ownerName);
        Assert.areEqual(doiQueue, results1[0].ownerId);
        Assert.areEqual(mappings[1].Staff_Authcate__c, results1[1].ownerName);
        Assert.areEqual(u.Id, results1[1].ownerId);

        Assert.areEqual(1, results2.size());
        Assert.areEqual(mappings[2].Staff_Authcate__c, results2[0].ownerName);
        Assert.areEqual(u.Id, results2[0].ownerId);
        Assert.areEqual(u.Email, results2[0].ownerEmail);
    }
}