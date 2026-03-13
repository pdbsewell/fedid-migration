/**
 * @description       : Class to generate a permission set to capture all permissions required to merge the particular object(s).
 *                      Call String output = new PermsetFileCreator().generate(Account.getSObjectType());
 * @author            : Stefan Scheit
 * @group             : Helper
 * @last modified on  : 2022-01-18
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author             Modification
 * 1.1   2022-01-18   Inderpal Dhanoa   Build Fix Error (ENGAGEIE-1292)
 * 1.0   2020-11-05   Stefan Scheit     Initial Version
**/
public without sharing class PermsetFileCreator {

    // Exclude certain Sobjects (case sensitive) that need additinal licensing (on top of standard Salesforce), otherwise you see an error like: "The user license doesn't allow the permission: Manage All Product2"
    public static Set<String> excludedSobjectSet {
        get {
            if(excludedSobjectSet==null || excludedSobjectSet.isEmpty()) {
                excludedSobjectSet = new Set<String>();
                List<String> strSobjList = Label.PermsetFileCreator_excludeSobjects.split(',');
                for(String strSobj : strSobjList) {
                    if(String.isNotBlank(strSobj)) {
                        excludedSobjectSet.add(strSobj.trim());
                    }
                }
            }
            return excludedSobjectSet;
            /*
            public static final Set<String> excludedSobjectSet = new Set<String>{
                Product2.getSObjectType().getDescribe().getName(),
                Pricebook2.getSObjectType().getDescribe().getName(),
                Idea.getSObjectType().getDescribe().getName(),
                PushTopic.getSObjectType().getDescribe().getName()
            };*/
        }
        private set;
    }
    
    // Exclude certain managed package namespaces (case sensitive), e.g. due to licensing dependencies etc.
    public static Set<String> excludedNamespacePrefixSet {
        get {
            if(excludedNamespacePrefixSet==null || excludedNamespacePrefixSet.isEmpty()) {
                excludedNamespacePrefixSet = new Set<String>();
                List<String> namespaces = Label.PermsetFileCreator_excludeNamespaces.split(',');
                for(String namespace : namespaces) {
                    if(String.isNotBlank(namespace)) {
                        excludedNamespacePrefixSet.add(namespace.trim());
                    }
                }
            }
            return excludedNamespacePrefixSet;
        }
        private set;
    }
    
    /**
     * Set of Sobjects for which permissions can be captured (in profiles and permission sets)
     */
    public static Set<String> permissionableSobjectSet {
        get {
            if(permissionableSobjectSet==null || permissionableSobjectSet.isEmpty()) {
                permissionableSobjectSet = new Set<String>();
                String sobjName;
                for(ObjectPermissions objPerm : [SELECT SobjectType FROM ObjectPermissions LIMIT 50000]) {
                    sobjName = String.valueOf(objPerm.SobjectType);
                    permissionableSobjectSet.add(sobjName);
                }
            }
            return permissionableSobjectSet;
        }
        private set;
    }

    // Permission set value object
    private PermSetFile permsetFile;

    /**
     * Default constructor
     */
    public PermsetFileCreator() {
        this.permsetFile = new PermSetFile();
    }

    /**
     * Method to run logic in a standalone (anonymous apex) context, see PermsetFileCreator.generate() method to pass you own mergeable type. 
     */
    public static void run() {
        PermsetFileCreator permsetCreator = new PermsetFileCreator();
        String outputXml = permsetCreator.generate(Account.getSObjectType());
        //String outputXml = permsetCreator.generate(new List<SobjectType>{Account.getSObjectType(), Contact.getSObjectType(), Case.getSObjectType()});
        // System.debug(LoggingLevel.DEBUG, outputXml);
    }

    /**
     * Method returns a permission set as String for the particular SObject.
     * @param SobjectType
     * @return String representing the permission set file (as XML)
     */
    public String generate(SobjectType sobj) {
        // delegate to method which handles the list input
        return this.generate(new List<SObjectType>{sobj});
    }
    
    /**
     * Method to wrap up logic of evaluation of the SObjects and generation of the output file.
     * @param List of SobjectType
     * @return String representing the permission set file (as XML)
     */
    public String generate(List<SobjectType> sobjList) {
        
        // evaluate each SobjectType
        for(SobjectType sobjType : sobjList) {
            evaluateObject(sobjType);
        }
        
        // generate XML output (as String)
        String strObjectList = sobjList.toString().replaceAll('[()]', ''); // replace all ( and ) characters
        String label = 'Merge '+strObjectList+' Permission Set';
        String description = 'Generated permission set (by '+String.valueOf(PermsetFileCreator.class)+ ') for merging ' +strObjectList+ ' records.';
        return this.permsetFile.createXml(label, description);
    }

    /**
     * Evaluate the Sobject for child objects and parent objects.
     */
    private void evaluateObject(SObjectType sobjType) {

        DescribeSObjectResult sobjResult = sobjType.getDescribe();

        // add Sobject itself
        this.permsetFile.objectPermissions.add(sobjResult.getName());
        // TODO: assign tab access (only possible for profiles...)
        
        // add all fields of the Sobject
        for(SObjectField field : sobjResult.fields.getMap().values()) {
            // add field by object.field notation (required field cannot be added)
            if(field.getDescribe().isPermissionable() && field.getDescribe().getCompoundFieldName() == null) {
                this.permsetFile.fieldPermissions.add(sobjResult.getName() + '.' + field);
            }
        }
        
        // handle child objects
        DescribeSObjectResult childObjDescribeResult = null;
        for(ChildRelationship relation : sobjResult.getChildRelationships()) {
            SObjectType childType = relation.getChildSObject();
            
            // the above value is the token for the lookup field on the child object
            SObjectField lookupField = relation.getField();
            // the above value is what you would use in a SOQL sub-query, e.g. SELECT Id, (SELECT Id FROM Children) FROM MyObject
            String relationshipName = relation.getRelationshipName();
            //System.debug('Object: '+childType+', Field: '+childType+'.'+lookupField+', Relationship Name: '+relationshipName);

            childObjDescribeResult = childType.getDescribe();
            
            // only add whitelisted object types
            if(isIncluded(childType)) {

                // capture object's field (unless it's required and not part of a compound field)
                if(lookupField.getDescribe().isPermissionable() && lookupField.getDescribe().getCompoundFieldName() == null) {
                    // add field by object.field notation (as required in profiles/permissionsets)
                    this.permsetFile.fieldPermissions.add(childObjDescribeResult.getName() + '.' + lookupField);
                }

                // capture child Sobject (if permissions can be assigned), deduped by the Set
                if(permissionableSobjectSet.contains(childObjDescribeResult.getName())) {
                    this.permsetFile.objectPermissions.add(String.valueOf(childType));
                }

                // evaluate parent object(s) of the child object
                this.evaluateParentObjects(childType);
            }
        }
    }

    /**
     * Evaluate parent object
     */
    private void evaluateParentObjects(SObjectType sobjType) {
        DescribeSObjectResult sobjDescibeResult = sobjType.getDescribe();

        // stop evaluation if parent object is not whitelisted
        if(!isIncluded(sobjType)) {
            return;
        }

        // add sobjType to list of object permissions (if permissions can be assigend
        String sobjName = sobjType.getDescribe().getName();
        if(permissionableSobjectSet.contains(sobjName)) {
            this.permsetFile.objectPermissions.add(sobjName);
        }

        // evaluate any reference object (master or lookup) and add them
        Map<String, Schema.SObjectField> fields = sobjDescibeResult.fields.getMap();
        DescribeFieldResult dfr;
        for(SObjectField field : fields.values()) {
            dfr = field.getDescribe();
            // reference fields only
            for(SObjectType parentObject : dfr.getReferenceTo()) {
                // master-detail relationship OR 
                // parent-child lookup is between standard Sobjects (some have permission dependencies, e.g. AuthorizationFormConsent needs AuthorizationFormText permissions in place)
                if(dfr.relationshipOrder!=null || (!parentObject.getDescribe().isCustom() && !sobjDescibeResult.isCustom())) {
                    // evaluate parent object (if it was not already done) && permissions can be assigned
                    String parentObjName = parentObject.getDescribe().getName();
                    if(!this.permsetFile.objectPermissions.contains(parentObjName) && permissionableSobjectSet.contains(parentObjName)) {
                        this.evaluateParentObjects(parentObject);
                    }
                }                            
            }
        }
    }

    /**
     * Helper method to define whitelisted / allowed Sobject types.
     */
    private boolean isIncluded(SObjectType sobjType) {
        // default, the SObject is included to be evaluated
        boolean bIncluded = true;
                
        // check for excluded SObjectType
        if(excludedSobjectSet.contains(sobjType.getDescribe().getName())) {
            return false;
        }

        // check for excluded managed package namespace (ie. due to licensing)
        boolean isManagedObject = (sobjType.getDescribe().getName().countMatches('__')<2) ? false : true;
        if(isManagedObject) {
            String namespacePrefix = sobjType.getDescribe().getName().substringBefore('__');
            if(excludedNamespacePrefixSet.contains(namespacePrefix)) {
                bIncluded = false;
            }
        }
        return bIncluded;
    }

    /**
     * Inner class representing the PermissionSet file fragments and logic.
     * The API name of the permission set is defined by the file name, i.e. <name>.permissionset
     */
    public class PermSetFile {

        // Permission Set file XML fragments
        public final String PERMSET_PREFIX = 
        '<?xml version="1.0" encoding="UTF-8"?>\r\n'+
        '<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">\r\n'+
        '    <description>{0}</description>\r\n';

        public final String PERMSET_SUFFIX = 
        '</PermissionSet>';

        public final String PERMSET_LABEL = 
        '    <hasActivationRequired>false</hasActivationRequired>\r\n'+
        '    <label>{0}</label>\r\n';
        
        public final String PERMSET_FIELD_PERMISSIONS = 
        '    <fieldPermissions>\r\n'+
        '        <editable>true</editable>\r\n'+
        '        <field>{0}</field>\r\n'+
        '        <readable>true</readable>\r\n'+
        '    </fieldPermissions>\r\n';
        
        public final String PERMSET_OBJECT_PERMISSIONS = 
        '    <objectPermissions>\r\n'+
        '        <allowCreate>true</allowCreate>\r\n'+
        '        <allowDelete>true</allowDelete>\r\n'+
        '        <allowEdit>true</allowEdit>\r\n'+
        '        <allowRead>true</allowRead>\r\n'+
        '        <modifyAllRecords>true</modifyAllRecords>\r\n'+
        '        <object>{0}</object>\r\n'+
        '        <viewAllRecords>true</viewAllRecords>\r\n'+
        '    </objectPermissions>\r\n';

        // Set to capture all object permissions
        public Set<String> objectPermissions = new Set<String>();
        
        // Set to capture all field permissions
        public Set<String> fieldPermissions = new Set<String>();

        /**
         * Method to assemble the Permission set file.
         * @param label - The label to be set in the permission set file.
         * @param description - The description to be set in the permission set file.
         * @return String representation of the *.permissionset file.
         * //TODO: add any system permissions?
         */
        public String createXml(String label, String description) {
            String strPermSetFile;
            // 1. append prefix, description is max 255 characters
            strPermSetFile += String.format(PERMSET_PREFIX, new List<String>{description.left(255)});
            // 2. append field permissions
            for(String fieldName : this.fieldPermissions) {
                strPermSetFile += String.format(PERMSET_FIELD_PERMISSIONS, new List<String>{fieldName});
            }
            // 3. append label, label is max 80 characters
            strPermSetFile += String.format(PERMSET_LABEL, new List<String>{label.left(80)});
            // 4. append object permissions
            for(String objectName : this.objectPermissions) {
                strPermSetFile += String.format(PERMSET_OBJECT_PERMISSIONS, new List<String>{objectName});
            }
            // 5. append suffix
            strPermSetFile += PERMSET_SUFFIX;
            return strPermSetFile;
        }
    }
}