/**
 * @Class              : CourseOffering_AS_Populate_COUID_FT.cls
 * @Description        : Test class  for CourseOffering_AS_Populate_COUID  flow 
 * @Author             : SMendu
 * @Group              : Admissions
 * @Revision           : 
 * 2024-06-21       Created 
 */
@isTest(isParallel=true)
private  class CourseOffering_AS_Populate_COUID_FT {
   
     /*
    * @description: Verifies that  Course_Offering_UID__c ExternalId gets populated on Course_Offering__c insert
    */
    @isTest 
    private static void shouldPopulateCourseOfferingUID() {
    
            // GIVEN - A course is created by the running user
            Course__c  course =  AgentPortalTestDataFactory.createCourse();
            insert course;
            // WHEN- Course_Offering__c is inserted 
            Test.startTest();
                Course_Offering__c  co = AgentPortalTestDataBuilder.factory.createCourseOffering([select id,Course_Code__c from Course__c]);   
                co.Mix_Unique_Id__c = 'MIXMIX';
            insert co;        
            Test.stopTest();

            //THEN - Course_Offering_UID__c should be populated on the Course_Offering__c record 
            Assert.isTrue(([select Course_Offering_UID__c from Course_Offering__c where id=:co.Id].Course_Offering_UID__c!=null), 'Course_Offering_UID__c must be populated');

        
    }


}