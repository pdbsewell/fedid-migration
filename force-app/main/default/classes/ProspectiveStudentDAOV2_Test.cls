/**
 * @description       : test class for ProspectiveStudentDAOV2 
 * @author            : Nick Guia
 * @date              : 06-10-2020
 * @group             : Lead Management
 * @last modified on  : 05-07-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class ProspectiveStudentDAOV2_Test {
    
    /**
     * @description run a test build of Person360 using the dao class
     */
    @isTest
    static void shouldBuildPerson360() {
        //given
        Contact con = new Contact(
            FirstName = 'ProspectiveStudentDAOV2_Test',
            LastName = 'test',
            Email = 'test@test.org'
        );
        ProspectiveStudentDAOV2 dao;

        Test.startTest();

        //when
        dao = new ProspectiveStudentDAOV2(con);
        dao.buildPerson360();

        Test.stopTest();

        //then
        System.assert(dao.p360 != null, 'Unable to build Person360 for DAO class');
    }
}