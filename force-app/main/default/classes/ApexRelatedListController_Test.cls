/**
 * @author          Tom Gangemi
 * @description     Test class for ApexRelatedListController
 * @revision        2023-07-19 - Tom Gangemi - Initial version
 */

@IsTest
private class ApexRelatedListController_Test {
    @IsTest
    static void testBehavior() {
        ApexRelatedListController arlc = new ApexRelatedListController();
        arlc.getDefaultValue();
        arlc.getValues(); // test class doesn't show up in query

        List<ApexRelatedListController.Record> results = ApexRelatedListController.getRecords('test', 'ApexRelatedListController_Test.TestProvider');
        Assert.areEqual(1, results.size(), 'Expected 1 record');

        ApexRelatedListController.Record record = results[0];
        Assert.areEqual(UserInfo.getUserId(), record.id);
    }

    public class TestProvider implements ApexRelatedListController.DataProvider {
        public List<ApexRelatedListController.Record> getRecords(String ref) {
            ApexRelatedListController.Record[] records = new ApexRelatedListController.Record[0];

            List<ApexRelatedListController.RecordValue> recordValues = new List<ApexRelatedListController.RecordValue>{
                new ApexRelatedListController.RecordValue('Status', 'Active'),
                new ApexRelatedListController.RecordValue('Last Login', '2019-01-01')
            };
            records.add(new ApexRelatedListController.Record(UserInfo.getUserId(), UserInfo.getName(), recordValues));

            return records;
        }
    }
}