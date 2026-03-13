/**
 * @description Test class for ContentVersionSelector
 */
 @isTest(isParallel=true)
public class ContentVersionSelector_Test {

    private static final String FILE_1_FILE_NAME = 'ContentVersionSelector_Test file 1';
    private static final String FILE_2_FILE_NAME = 'ContentVersionSelector_Test file 2';
    private static List<Id> contentVersionCreatedIds = new List<Id>();

    @testSetup
    static void createTestData() {
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        ContentVersion file1 = new ContentVersion();
        file1.Title = FILE_1_FILE_NAME;
        file1.PathOnClient = 'package.xml';
        file1.VersionData = Blob.valueOf('PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9InllcyI/Pgo8UGFja2FnZSB4bWxucz0iaHR0cDovL3NvYXAuc2ZvcmNlLmNvbS8yMDA2LzA0L21ldGFkYXRhIj4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz5PZmZlcl9CdWxrX0FjdGlvbl9fYzwvbWVtYmVycz4KICAgICAgICA8bmFtZT5DdXN0b21PYmplY3Q8L25hbWU+CiAgICA8L3R5cGVzPgogICAgPCEtLQogICAgPHR5cGVzPgogICAgICAgIDxtZW1iZXJzPio8L21lbWJlcnM+CiAgICAgICAgPG5hbWU+TGF5b3V0PC9uYW1lPgogICAgPC90eXBlcz4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz5PZmZlckJ1bGtBY3Rpb25zPC9tZW1iZXJzPgogICAgICAgIDxtZW1iZXJzPk9mZmVyQnVsa0FjdGlvbnMvQWxsX09mZmVyX0J1bGtfQWN0aW9uc182aUY8L21lbWJlcnM+CiAgICAgICAgPG5hbWU+UmVwb3J0PC9uYW1lPgogICAgPC90eXBlcz4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz5PZmZlckJ1bGtBY3Rpb25zRGFzaGJvYXJkczwvbWVtYmVycz4KICAgICAgICA8bWVtYmVycz5PZmZlckJ1bGtBY3Rpb25zRGFzaGJvYXJkcy9pbUJKRFl2QUF2a294Vmp0elRzSm9qbmZsUEl5YWE8L21lbWJlcnM+CiAgICAgICAgPG5hbWU+RGFzaGJvYXJkPC9uYW1lPgogICAgPC90eXBlcz4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz4qPC9tZW1iZXJzPgogICAgICAgIDxuYW1lPlJlcG9ydFR5cGU8L25hbWU+CiAgICA8L3R5cGVzPgotLT4KICAgIDx2ZXJzaW9uPjQ3LjA8L3ZlcnNpb24+CjwvUGFja2FnZT4=');
        contentVersions.add(file1);

        ContentVersion file2 = new ContentVersion();
        file2.Title = FILE_2_FILE_NAME;
        file2.PathOnClient = 'package1.xml';
        file2.VersionData = Blob.valueOf('PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9InllcyI/Pgo8UGFja2FnZSB4bWxucz0iaHR0cDovL3NvYXAuc2ZvcmNlLmNvbS8yMDA2LzA0L21ldGFkYXRhIj4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz5PZmZlcl9CdWxrX0FjdGlvbl9fYzwvbWVtYmVycz4KICAgICAgICA8bmFtZT5DdXN0b21PYmplY3Q8L25hbWU+CiAgICA8L3R5cGVzPgogICAgPCEtLQogICAgPHR5cGVzPgogICAgICAgIDxtZW1iZXJzPio8L21lbWJlcnM+CiAgICAgICAgPG5hbWU+TGF5b3V0PC9uYW1lPgogICAgPC90eXBlcz4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz5PZmZlckJ1bGtBY3Rpb25zPC9tZW1iZXJzPgogICAgICAgIDxtZW1iZXJzPk9mZmVyQnVsa0FjdGlvbnMvQWxsX09mZmVyX0J1bGtfQWN0aW9uc182aUY8L21lbWJlcnM+CiAgICAgICAgPG5hbWU+UmVwb3J0PC9uYW1lPgogICAgPC90eXBlcz4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz5PZmZlckJ1bGtBY3Rpb25zRGFzaGJvYXJkczwvbWVtYmVycz4KICAgICAgICA8bWVtYmVycz5PZmZlckJ1bGtBY3Rpb25zRGFzaGJvYXJkcy9pbUJKRFl2QUF2a294Vmp0elRzSm9qbmZsUEl5YWE8L21lbWJlcnM+CiAgICAgICAgPG5hbWU+RGFzaGJvYXJkPC9uYW1lPgogICAgPC90eXBlcz4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz4qPC9tZW1iZXJzPgogICAgICAgIDxuYW1lPlJlcG9ydFR5cGU8L25hbWU+CiAgICA8L3R5cGVzPgotLT4KICAgIDx2ZXJzaW9uPjQ3LjA8L3ZlcnNpb24+CjwvUGFja2FnZT4=');
        contentVersions.add(file2);

        insert contentVersions;
    }

    /**
     * @description Verifes getObjectType returns a value
     */
    @isTest
    static void shouldGetSObjectType() {
        ContentVersionSelector selector = new ContentVersionSelector();
        System.assertNotEquals(null, selector.getSObjectType(), 'Expected an SObjectType to be defined.');
    }

    /**
     * @description Verifies a Query Exception is thrown if null 
     * is passed as a parameter
     */
    @isTest
    static void shouldThrowExceptionOnNullParameter() {
        try {
            ContentVersionSelector selector = new ContentVersionSelector();
            ContentVersion contentVersion = selector.selectContentVersionById(null);
            System.assert(false, 'Expected an exception due to null id value');
        } catch(QueryException e) {
            System.assert(true, 'Expected QueryException due to null id value.');
        } catch(Exception e) {
            System.assert(false, 'Expected QueryException instead of Exception.');
        }
    }

    /**
     * @description Tests that the selector returns a ContentVersion when the
     * Id provided exists in the database
     */
    @isTest
    static void shouldReturnContentVersionOnValidSelect() {
        ContentVersionSelector selector = new ContentVersionSelector();
        ContentVersion contentVersion = selector.selectContentVersionById([SELECT Id FROM ContentVersion WHERE Title = :FILE_2_FILE_NAME].Id);

        System.assertNotEquals(null, contentVersion, 'Expected a ContentVersion record instead of null');
        System.assertNotEquals(null, contentVersion.title, 'Expected a ContentVersion record with title field not equal to null');
    }

}