/**
 * @Class              : KnowledgeTriggerHandler.cls
 * @Description        : Trigger class for handling Knowledge Articles 
 * @Author             : Inderpal Dhanoa
 * @Group              : Monash COnnect
 * @Revision           : 2024-05-14     Inderpal Dhanoa   Created 
 */
public without sharing class KnowledgeTriggerHandler {
    /**
     * @description Create a linked data Category upon Article creation
     */
    public class MapDataCategories extends TriggerAbstract {

        public final String MAPPING_NAME = 'Knowledge_Data_Category_Mapping';
        List<Knowledge_Article__kav> records = new List<Knowledge_Article__kav>();

        public override void process(SObject sobj) {
            Knowledge_Article__kav newRecord = (Knowledge_Article__kav) sobj;
            records.add(newRecord);
        }

        public override void execute() {
            // Check if a mapping exists for the RecordType Name vs data Category Name in the Custom MetaData
            System_Settings__mdt recdTypeDataCatg = [SELECT Value__c FROM System_Settings__mdt WHERE DeveloperName = :MAPPING_NAME LIMIT 1];
            Map<String, String> m_recdTypeNameToDataCatg = (Map<String, String>)JSON.deserialize(recdTypeDataCatg.Value__c.toString(), Map<String, String>.class);
            List<Knowledge_Article__DataCategorySelection> l_articleDataCatgMapping = new List<Knowledge_Article__DataCategorySelection>();
            for(Knowledge_Article__kav newRecd : records){
                if(m_recdTypeNameToDataCatg.containsKey(newRecd.Record_Type__c)){
                    l_articleDataCatgMapping.add(new Knowledge_Article__DataCategorySelection(ParentId=newRecd.Id, 
                                                DataCategoryGroupName='What', DataCategoryName=m_recdTypeNameToDataCatg.get(newRecd.Record_Type__c)));
                }
            }
            try{
                insert l_articleDataCatgMapping;
            }catch(Exception ex){
                Nebula.Logger.error(ex.getMessage(), ex);
                Nebula.Logger.saveLog();
            }
        }
    }
}