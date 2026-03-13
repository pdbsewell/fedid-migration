/**
 * @author          PVictoriano
 * @description     Test class to update field and object permissions for Backup and Restore  
 * @revision
 */
@isTest(isParallel=true)
private class BackupRestorePermissionBatch_Test {
    @isTest
    static void testexecuteManageUserModifyAllPermissionBatch() {
        Exception exceptionObj = null;
        try {
            BackupRestorePermissionBatch.executeManageUserModifyAllPermissionBatch('User');
        } catch (Exception e) {
            exceptionObj = e;
        }
        //Assert Error Message
        System.assertEquals(null, exceptionObj, 'Exception occured. ');
    }
    @isTest
    static void testExecute() {
        Exception exceptionObj = null;
        try {
            BackupRestorePermissionBatch.executeBackupRestorePermissionBatch('User');
        } catch (Exception e) {
            exceptionObj = e;
        }
        //Assert Error Message
        System.assertEquals(null, exceptionObj, 'Exception occured. ');
    }
    @isTest
    static void testPermViewAll() {
        Exception exceptionObj = null;
        try {
            BackupRestorePermissionBatch.executePermViewAll('User');
        } catch (Exception e) {
            exceptionObj = e;
        }
        //Assert Error Message
        System.assertEquals(null, exceptionObj, 'Exception occured. ');
    }
    @isTest
    static void testPermModifyAll() {
        Exception exceptionObj = null;
        try {
            BackupRestorePermissionBatch.executePermModifyAll('User');
        } catch (Exception e) {
            exceptionObj = e;
        }
        //Assert Error Message
        System.assertEquals(null, exceptionObj, 'Exception occured. ');
    }
    @isTest
    static void testExecuteManual() {
        Exception exceptionObj = null;
        Iterable<Schema.SObjectType> stIndex;
        try {
            BackupRestorePermissionBatch bch = new BackupRestorePermissionBatch('Permission_Backup_Restore');
            bch.setTargetProcessObjects();
            stIndex = bch.start(null);
            //
            List<Schema.SObjectType> recs = new List<Schema.SObjectType> {User.getSObjectType()};
            bch.setTargetProcessFields();
            bch.execute(null, recs);
            //
            bch.finish(null);
            //
        } catch (Exception e) {
            exceptionObj = e;
        }
        //Assert Error Message
        System.assertEquals(null, exceptionObj, 'Exception occured. ');
        //Assert Iterable
        System.assertNotEquals(null, stIndex, 'Exception occured. No records returned on start');
    }
}