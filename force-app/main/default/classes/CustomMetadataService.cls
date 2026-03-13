/**
* @author David Browaeys
* @date 05/11/2019
* @description This service class allow to manipulate custom metadata type. 
*/
public inherited sharing class CustomMetadataService{
    /**
    * @description Return custom metadata type data set record for the specified set developer name. 
    * @author David Browaeys
    * @param mdt object type of the custom metadata type
    * @param mdt value of the developer name to search
    * @return SObject
    * Org_Unit_Bundle_Mapping__mdt  ex2 = (Org_Unit_Bundle_Mapping__mdt) CustomMetadataService.getInstance(Org_Unit_Bundle_Mapping__mdt.sObjectType,'FACULTY_OF_ARTS');
    * @example 
    */
    public static SObject getInstance(Schema.SObjectType mdt, String value){
        return getInstance(mdt, mdt.getDescribe().fields.getMap().get('DeveloperName'), value);
    }
    /**
    * @description Return custom metadata type data set record for the specified set developer name. 
    * @author David Browaeys
    * @param mdt object type of the custom metadata type
    * @param mdt value of the developer name to search
    * @return SObject
    * @example 
    * Org_Unit_Bundle_Mapping__mdt  ex3 = (Org_Unit_Bundle_Mapping__mdt) CustomMetadataService.getInstance(Org_Unit_Bundle_Mapping__mdt.sObjectType,Org_Unit_Bundle_Mapping__mdt.Org_Unit_Code__c,'50000561');
    */
    public static SObject getInstance(Schema.SObjectType mdt, Schema.SObjectField field, String value){
        SObject[] tmp = query(mdt, field, value);
        return tmp != null && tmp.isEmpty() == false ? tmp[0] : null; 
    }
    /**
    * @description Returns a map of the data sets defined for the custom metadata type.
    * @author David Browaeys
    * @param mdt object type of the custom metadata type
    * @return Map<String, SObject>
    * @example 
    * Map<String,Org_Unit_Bundle_Mapping__mdt>  ex1 = (Map<String,Org_Unit_Bundle_Mapping__mdt>) CustomMetadataService.getAll(Org_Unit_Bundle_Mapping__mdt.sObjectType);
    */
    public static Map<String, SObject> getAll(Schema.SObjectType mdt){
        return getAll(mdt, mdt.getDescribe().fields.getMap().get('DeveloperName'));
    }
    /**
    * @description Returns a map of the data sets defined for the custom metadata type.
    * @author David Browaeys
    * @param mdt object type of the custom metadata type
    * @param field key of the map
    * @return Map<String, SObject>
    * @example 
    * Map<String,Org_Unit_Bundle_Mapping__mdt>  ex4 = (Map<String,Org_Unit_Bundle_Mapping__mdt>) CustomMetadataService.getAll(Org_Unit_Bundle_Mapping__mdt.sObjectType, Org_Unit_Bundle_Mapping__mdt.Org_Unit_Code__c);
    */
    public static Map<String, SObject> getAll(Schema.SObjectType mdt, Schema.SObjectField field){
        Type t= Type.forName('Map<String,'+mdt.getDescribe().getName()+'>');  
        Map<String,SObject> tmp = (Map<String,Sobject>)t.newInstance();
        for (SObject s : query(mdt, field, null)){
            tmp.put(String.valueOf(s.get(field.getDescribe().getName())), s);                                                                        
        }
        return tmp;
    }

    /**
     * @description Returns a map of the data sets defined for the 
     * custom metadata type based on the value filtered and key
     * @param mdt object type of the custom metadata type
     * @param field key of the map
     * @param value value to filter by
     * @return Map<String, SObject>
     */
    public static Map<String, SObject> getAll(Schema.SObjectType mdt, String whereField, String whereFieldValue, Schema.SObjectField mapKey) {
        Type t= Type.forName('Map<String,'+mdt.getDescribe().getName()+'>');  
        Map<String,SObject> tmp = (Map<String,Sobject>)t.newInstance();
        for (SObject s : query(mdt, whereField, whereFieldValue)){
            tmp.put(String.valueOf(s.get(mapKey.getDescribe().getName())), s);                                                                        
        }
        return tmp; 
    }

    /**
    * @description Perform soql query to retrieve data set of custom metadata
    * @author David Browaeys
    * @param mdt object type of the custom metadata type
    * @param field field name to filter by
    * @param value value to filter by
    * @return List<SObject>
    */
    public static List<SObject> query(Schema.SObjectType mdt, Schema.SObjectField field, String value){
        return query(mdt, field.getDescribe().getName(), value);
    }

    /**
    * @description Perform soql query to retrieve data set of custom metadata
    * @param mdt object type of the custom metadata type
    * @param field field name to filter by as a string
    * @param value value to filter by
    * @return List<SObject>
    */
    public static List<SObject> query(Schema.SObjectType mdt, String field, String value){
        String fields = String.join(new List<String>(mdt.getDescribe().fields.getMap().keySet()),',');
        String whereClause = '';
        if (String.isBlank(value) == false){
            String fieldName = field;
            whereClause = String.format('WHERE {0} = :value', new String[]{fieldName});
        }
        String soql = String.format('SELECT {0} FROM {1} {2}', 
                    new String[]{fields,
                    mdt.getDescribe().getName(),
                    whereClause});
        System.debug(soql);
        return Database.query(soql);
    }

    /**
    * @description Query Docusign Envelop Setting 
    * @param feature feature name from System Setting
    * @param key Key for System Setting
    * @return SystemSettingWrapper.DocusignEnvelopSetting
    */
    public static SystemSettingWrapper.DocusignEnvelopSetting getDocusignEnvelopSettings(String feature, String key){
        SystemSettingWrapper.DocusignEnvelopSetting envelopSetting;
        // query Docusign Envelop Settings from SystemSetting Metadata
        System_Settings__mdt systemSetting = SystemSettingsUtil.getinstance().getByKeyFeature(feature, key);
        if(systemSetting != null){
            envelopSetting = (SystemSettingWrapper.DocusignEnvelopSetting)SystemSettingWrapper.parse(systemSetting, SystemSettingWrapper.DocusignEnvelopSetting.class);
        }
        return envelopSetting;
    }
    /**
    * @description Perform soql query to retrieve data set of custom metadata
    * @param feature feature name from System Setting
    * @return Map<String,SystemSettingWrapper.DocusignTab>
    */
    public static Map<String,SystemSettingWrapper.DocusignTab> getDocusignTabs(String feature){
        Map<String,SystemSettingWrapper.DocusignTab> returnMap = new Map<String,SystemSettingWrapper.DocusignTab>();
        SystemSettingWrapper.DocusignTab tabSettings;
        // query Docusign Envelop Settings from SystemSetting Metadata
        List<System_Settings__mdt> systemSettings = SystemSettingsUtil.getinstance().getByFeature(feature);
        if(!systemSettings.isEmpty()){
            for(System_Settings__mdt objSettings : systemSettings){
                tabSettings = (SystemSettingWrapper.DocusignTab)SystemSettingWrapper.parse(objSettings, SystemSettingWrapper.DocusignTab.class);
                returnMap.put(tabSettings.key, tabSettings);
            }
        }
        return returnMap;
    }
    private void CustomMetadataService(){}

}