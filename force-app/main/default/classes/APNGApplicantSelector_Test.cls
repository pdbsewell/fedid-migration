/**
 * @description       : Test class forAPNGApplicantSelector
 * @author            : Ben Greenland
 * @group             :
 * @last modified on  : 2024-10-21
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-08-20   Ben Greenland   Initial Version
 **/
@isTest(isParallel=true)
private class APNGApplicantSelector_Test {
  /**
   * @description test AgentPortalServices.searchApplicantsCount
   * @author Ben Greenland | 2024-08-20
   **/
  @isTest
  static void testSearchApplicantsCount() {
    AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser()
      .build();
    User u = portalUser.testUser;
    Test.startTest();
    System.runAs(u) {
      Contact con = new Contact(
        FirstName = 'John',
        First_Name__c = 'John',
        LastName = 'Test Last',
        Last_Name__c = 'Test Last',
        Personal_email__c = 'testzzzzzzz123@getnad.com',
        BirthDate = Date.valueOf('2003-02-01')
      );

      con = AgentPortalServices.createApplicant(con, u.id);
      Integer count = APNGApplicantSelector.searchApplicantsCountForPagination('John');
      Integer notFound = APNGApplicantSelector.searchApplicantsCountForPagination('ZZZZZZZ');
      System.assertEquals(
        1,
        count,
        'Count should match the number of returned records expected 1'
      );
      System.assertEquals(
        0,
        notFound,
        'Count should match the number of returned records expected 0'
      );
    }
    Test.stopTest();
  }
}