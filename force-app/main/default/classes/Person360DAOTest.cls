@isTest
private class Person360DAOTest {

    /**
     * Test Contact Record
     */
    static testMethod void sObjectTest() {

        Person360DAO dao = new Person360DAO();
        //
        dao.initialize('Contact', 'Group1');
        System.assertEquals(Contact.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
        //
        dao.addFieldValue('LastName', 'TestLastName');
        Contact con = (Contact)dao.getSObject().clone();
        dao.clearCache();
        System.assertEquals(null, dao.getSObject(), 'Contact Failed Cache');
        dao.setSObject(con);
        System.assertEquals('TestLastName', dao.getSObject().get('LastName'), 'Contact Failed');
        //
        dao.clearCache();
        dao.initialize('Name__c', 'Group2');
        System.assertEquals(Name__c.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
        //
        dao.clearCache();
        dao.initialize('Email__c', 'Group3');
        System.assertEquals(Email__c.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
        //
        dao.clearCache();
        dao.initialize('Phone__c', 'Group4');
        System.assertEquals(Phone__c.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
        //
        dao.clearCache();
        dao.initialize('Address__c', 'Group5');
        System.assertEquals(Address__c.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
        //
        dao.clearCache();
        dao.initialize('Social__c', 'Group6');
        System.assertEquals(Social__c.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
        //Double the Grouping Test
        dao.clearCache();
        dao.initialize('Email__c', 'Group3');
        System.assertEquals(Email__c.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
        //
        dao.clearCache();
        dao.initialize('Phone__c', 'Group4');
        System.assertEquals(Phone__c.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
        //
        dao.clearCache();
        dao.initialize('Address__c', 'Group5');
        System.assertEquals(Address__c.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
        //
        dao.clearCache();
        dao.initialize('Social__c', 'Group6');
        System.assertEquals(Social__c.sObjectType, dao.getSObject().getSObjectType(), 'Object Type Error');
    }

}