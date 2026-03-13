/**
 * @author          Tom Gangemi
 * @description     Controller for the ApexRelatedList component
 * @revision        2023-07-19 - Tom Gangemi - Initial version
 */

global with sharing class ApexRelatedListController extends VisualEditor.DynamicPickList {

    global override VisualEditor.DataRow getDefaultValue(){
        return new VisualEditor.DataRow('(none)', '');
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        for(ApexTypeImplementor impl :[
            SELECT ClassName FROM ApexTypeImplementor
            WHERE InterfaceName = :ApexRelatedListController.DataProvider.class.getName() AND IsConcrete = TRUE
        ]) {
            values.addRow(new VisualEditor.DataRow(impl.ClassName, impl.ClassName));
        }
        return values;
    }

    // implement this interface and the class will appear as an option in the Data Provider picklist
    public interface DataProvider {
        List<Record> getRecords(String ref);
    }

    public class Record {
        @AuraEnabled public Id id;
        @AuraEnabled public String title;
        @AuraEnabled public List<RecordValue> values;
        public Record(Id id, String title, List<RecordValue> values) {
            this.id = id;
            this.title = title;
            this.values = values;
        }
    }

    public class RecordValue {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public RecordValue(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Record> getRecords(String ref, String dataProviderClass) {
        Type classType = Type.forName(dataProviderClass);
        ApexRelatedListController.DataProvider dp = (ApexRelatedListController.DataProvider)classType.newInstance();
        return dp.getRecords(ref);
    }

}