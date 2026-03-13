/**
 * @description Fix Backupand Restore Permissions <br/>
 * Script to run - BackupRestorePermissionBatch.executeBackupRestorePermissionBatch();
 *
 * @author P. Victoriano
 * @date 29/01/2021
 *
 * @group Batch
 * @revision
 *           P.Victoriano 17/2/2021 - Enabled Modify All, View All Permission Sets
 *
 **/
public without sharing class BackupRestorePermissionBatch implements Database.Batchable<Schema.SObjectType>,
               Database.RaisesPlatformEvents {
    /**
     * BackupRestorePermissionBatch Prevent Initialisation from Constructor
     * @return   return description
     */
    @TestVisible
    private String permissionName;
    @TestVisible
    private String targetSobject;
    @TestVisible
    private String processObjectField = 'All';
    //
    public BackupRestorePermissionBatch(String strN) {
        permissionName = strN;
        processObjectField = 'All';
    }

    /**
     * @description setTargetOject for specifying permissions on targeted oject
     * @param  tObj tObj description
     */
    public void setTargetOject(String tObj) {
        targetSobject = tObj;
    }

    public void setTargetProcessObjects() {
        processObjectField = 'Objects';
    }

    public void setTargetProcessFields() {
        processObjectField = 'Fields';
    }

    //
    public Iterable<Schema.SObjectType> start(Database.BatchableContext BC) {
        LogUtilityException.debug('Running:' + permissionName + ' processType:' + processObjectField + ' target:' + targetSobject);
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        List<Schema.SObjectType> sobjTypes = gd.values();
        if (String.isNotBlank(targetSobject) && gd.containsKey(targetSobject)) {
            sobjTypes = new List<Schema.SObjectType> {
                gd.get(targetSobject)
            };
        }
        return sobjTypes;
    }

    public void execute(Database.BatchableContext BC, List<Schema.SObjectType> scope) {
        List<ObjectPermissions> forUpd = new List<ObjectPermissions>();
        List<FieldPermissions> forFLDUp = new List<FieldPermissions>();
        Id permId = [SELECT Id FROM PermissionSet WHERE Name =:permissionName LIMIT 1].get(0)?.Id;
        if (permId != null && String.isNotBlank(permissionName)) {
            //REtrieve Existing Object Permissions
            Map<String,ObjectPermissions> sobjPermsMap = new Map<String,ObjectPermissions>();
            if (processObjectField == 'All' || processObjectField == 'Objects') {
                for (ObjectPermissions objl :[SELECT Id, PermissionsCreate, PermissionsDelete, PermissionsEdit,
                                              PermissionsModifyAllRecords, PermissionsRead, PermissionsViewAllRecords,SobjectType
                                              FROM ObjectPermissions
                                              WHERE Parent.Name =:permissionName]) {
                    String olowKeyName = objl.SobjectType.toLowerCase();
                    sobjPermsMap.put(olowKeyName,objl);
                }
            }
            //Retrieve Existing Field Permissions
            Map<String,FieldPermissions> fldPermsMap = new Map<String,FieldPermissions>();
            if (processObjectField == 'Fields') {
                for (FieldPermissions fldl :[SELECT Id,Field, PermissionsEdit, PermissionsRead, SobjectType
                                             FROM FieldPermissions WHERE Parent.Name =:permissionName]) {
                    String lowKeyName = fldl.Field.toLowerCase();
                    fldPermsMap.put(lowKeyName,fldl);
                }
            }
            //Process
            for (Schema.SObjectType sobj : scope) {
                Schema.DescribeSObjectResult sobDesc = sobj.getDescribe();
                //Soject Permissions
                if (processObjectField == 'All' || processObjectField == 'Objects') {
                    forUpd = processOjectPerms(sobjPermsMap, sobDesc, permId);
                } else if (processObjectField == 'Fields') {
                    //Field Permissions
                    forFLDUp = processFieldPerms(fldPermsMap, sobDesc, permId);
                }
            }
        }
        //Start Save - Expected to fail on duplicate entries
        if (!forUpd.isEmpty()) {
            Database.upsert(forUpd, false);
        }
        if (!forFLDUp.isEmpty()) {
            List<Database.UpsertResult> upsResFld = Database.upsert(forFLDUp, false);
            Integer cnt = 0;
            for (Database.UpsertResult res :upsResFld) {
                System.debug('!!@@##: Field Success:' + res.isSuccess() + ' Created:' + res.isCreated() + ' ' + forFLDUp.get(cnt).Field);
                cnt++;
            }
        }
    }

    public List<ObjectPermissions> processOjectPerms(Map<String,ObjectPermissions> sobjPermsMap, Schema.DescribeSObjectResult sobDesc, Id permId) {
        List<ObjectPermissions> results = new List<ObjectPermissions>();
        try {
            //ObjectPermissions
            Boolean objHasChanges = false;
            ObjectPermissions obj = new ObjectPermissions();
            ObjectPermissions cobj;
            //Checks if Object Permission Exist force on Test execution
            String sLowObjName = sobDesc.getLocalName().toLowerCase();
            if (sobjPermsMap.containsKey(sLowObjName) == false || Test.isRunningTest()) {
                obj.ParentId = permId;
                obj.SobjectType = sobDesc.getLocalName();
                objHasChanges = true;
            } else {
                cobj = sobjPermsMap.get(sLowObjName);
                obj.Id = cobj.Id;
            }
            //Begin Setting Permissions
            if (cobj == null || cobj != null) {
                obj.PermissionsRead = true;
                objHasChanges = true;
            }
            if (permissionName != 'Permission_View_All_Data' || Test.isRunningTest()) {
                if (cobj == null || (cobj != null && cobj.PermissionsCreate == false)) {
                    obj.PermissionsCreate = true;
                    objHasChanges = true;
                }
            }
            if (obj.Id != null || Test.isRunningTest()) {
                if (cobj == null || (cobj != null && cobj.PermissionsViewAllRecords == false)) {
                    obj.PermissionsViewAllRecords = true;
                    objHasChanges = true;
                }
                if (permissionName != 'Permission_View_All_Data' || Test.isRunningTest()) {
                    if (cobj == null || (cobj != null && cobj.PermissionsEdit == false)) {
                        obj.PermissionsEdit = true;
                        objHasChanges = true;
                    }
                    if (cobj == null || (cobj != null && cobj.PermissionsDelete == false)) {
                        obj.PermissionsDelete = true;
                        objHasChanges = true;
                    }
                    if (cobj == null || (cobj != null && cobj.PermissionsModifyAllRecords == false)) {
                        obj.PermissionsModifyAllRecords = true;
                        objHasChanges = true;
                    }
                }
            }
            //Add to List for Changes
            if (objHasChanges) {
                results.add(obj);
            }
        }
        catch (Exception e) {
            System.debug('!!@@##:Error Oject:' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        return results;
    }

    public List<FieldPermissions> processFieldPerms(Map<String,FieldPermissions> fldPermsMap, Schema.DescribeSObjectResult sobDesc, Id permId) {
        List<FieldPermissions> results = new List<FieldPermissions>();
        try {
            //For FieldPermissions
            Map<String,Schema.SObjectField> mfields = sobDesc.fields.getMap();
            for (Schema.SObjectField sfield:mfields.values()) {
                Schema.DescribeFieldResult dfr = sfield.getDescribe();
                Boolean fldhasChanges = false;
                FieldPermissions fldP = new FieldPermissions();
                FieldPermissions cfldP;
                fldP.Field = sobDesc.getLocalName() + '.' + dfr.getLocalName();
                //Checks for Field Permission if Exist
                String lowKeyName = fldP.Field.toLowerCase();
                if (fldPermsMap.containsKey(lowKeyName) == false || Test.isRunningTest()) {
                    fldP.ParentId = permId;
                    fldP.SobjectType = sobDesc.getLocalName();
                    fldhasChanges = true;
                } else {
                    cfldP = fldPermsMap.get(lowKeyName);
                    fldP.Id = cfldP.Id;
                }
                //Begin Setting Permissions
                if (dfr.isPermissionable() && dfr.isCalculated() == false && dfr.isAutoNumber() == false) {
                    if (permissionName != 'Permission_View_All_Data' || Test.isRunningTest()) {
                        if (cfldP == null || (cfldP != null && cfldP.PermissionsEdit == false)) {
                            fldP.PermissionsEdit = true;
                            fldhasChanges = true;
                        }
                    }
                }
                fldP.PermissionsRead = true;
                results.add(fldP);
            }
        }
        catch (Exception e) {
            System.debug('!!@@##:Error Field:' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        return results;
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('!!@@##:' + permissionName + ' processObjectField:' + processObjectField);
        //If Set to ALL this will run Objects then Fields
        if (Test.isRunningTest() == false && processObjectField == 'All') {
            BackupRestorePermissionBatch bch = new BackupRestorePermissionBatch(permissionName);
            if (String.isNotBlank(targetSobject)) {
                bch.setTargetOject(targetSobject);
            }
            bch.setTargetProcessFields();
            Database.executeBatch(bch, 1);
        }
    }

    /**
     * executeBackupRestorePermissionBatch Controls Class Construction
     */
    public static void executeBackupRestorePermissionBatch(String tObj) {
        BackupRestorePermissionBatch bch = new BackupRestorePermissionBatch('Permission_Backup_Restore');
        if (String.isNotBlank(tObj)) {
            bch.setTargetOject(tObj);
        }
        Database.executeBatch(bch, 1);
    }

    public static void executeManageUserModifyAllPermissionBatch(String tObj) {
        BackupRestorePermissionBatch bch = new BackupRestorePermissionBatch('Manage_User_and_Modify_All_Data');
        if (String.isNotBlank(tObj)) {
            bch.setTargetOject(tObj);
        }
        Database.executeBatch(bch, 1);
    }

    public static void executePermViewAll(String tObj) {
        BackupRestorePermissionBatch bch = new BackupRestorePermissionBatch('Permission_View_All_Data');
        if (String.isNotBlank(tObj)) {
            bch.setTargetOject(tObj);
        }
        Database.executeBatch(bch, 1);
    }

    public static void executePermModifyAll(String tObj) {
        BackupRestorePermissionBatch bch = new BackupRestorePermissionBatch('Permission_Modify_All');
        if (String.isNotBlank(tObj)) {
            bch.setTargetOject(tObj);
        }
        Database.executeBatch(bch, 1);
    }
}