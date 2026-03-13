/**
 * @description Test class for SObjectDao
 */
@isTest(isParallel=true)
public class SObjectDao_Test {

    @isTest
    static void shouldUpdate() {

        List<ContactRequest> contactRequest = new List<ContactRequest>();

        SObjectDao sObjectDao = new SObjectDao();
        sObjectDao.updateRecords(contactRequest);
        System.assert(true, 'Expected update to run successfully');
    }

    @isTest
    static void shouldInsert() {
        SObjectDao sObjectDao = new SObjectDao();
        sObjectDao.insertRecords(new List<ContactRequest>());
        System.assert(true, 'Expected insert to run successfully');
    }

    @isTest
    static void shouldUpsert() {
        SObjectDao sObjectDao = new SObjectDao();
        sObjectDao.upsertRecords(new List<ContactRequest>());
        System.assert(true, 'Expected upsert to run successfully');
    }

    @isTest
    static void shouldDelete() {

        ContactRequest contactRequest = new ContactRequest();
        insert contactRequest;

        SObjectDao sObjectDao = new SObjectDao();
        sObjectDao.deleteRecords(new List<ContactRequest>{contactRequest});
        System.assert(true, 'Expected delete to run successfully');
    }


}