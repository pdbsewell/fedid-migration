/*******************************************************************************
* @author       Ant Custodio
* @date         10.Jul.2017        
* @description  test class for Marketing Cloud Trigger "Trig_Lead"
* @revision     
*******************************************************************************/
@isTest(isParallel=true)
public class Trig_Lead_Test {
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         10.Jul.2017        
    * @description  insert Lead
    * @revision     
    *******************************************************************************/
    static testMethod void test_InsertLead() {
        Lead leadRec = new Lead();
        leadRec.FirstName = 'Lead1';
        leadRec.LastName = 'Test';
        leadRec.Company = 'Company1';
        
        Test.startTest();
        //insert Lead
        insert leadRec;
        system.assertNotEquals(null, leadRec.Id);
        Test.stopTest();
    }
}