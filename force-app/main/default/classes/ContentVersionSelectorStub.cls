/**
 * @description Stub for ContentVersionSelectorStub
 */
@isTest(isParallel=true)
public class ContentVersionSelectorStub implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
        Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
        List<Object> listOfArgs) {

        if (stubbedMethodName == 'selectContentVersionById') {
            return this.selectContentVersionByIdStub();
        }

        return null;
    }

    private ContentVersion selectContentVersionByIdStub() {
        ContentVersion file = new ContentVersion();
        file.Title = 'file1';
        file.PathOnClient = 'package.xml';
        file.VersionData = Blob.valueOf('PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9InllcyI/Pgo8UGFja2FnZSB4bWxucz0iaHR0cDovL3NvYXAuc2ZvcmNlLmNvbS8yMDA2LzA0L21ldGFkYXRhIj4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz5PZmZlcl9CdWxrX0FjdGlvbl9fYzwvbWVtYmVycz4KICAgICAgICA8bmFtZT5DdXN0b21PYmplY3Q8L25hbWU+CiAgICA8L3R5cGVzPgogICAgPCEtLQogICAgPHR5cGVzPgogICAgICAgIDxtZW1iZXJzPio8L21lbWJlcnM+CiAgICAgICAgPG5hbWU+TGF5b3V0PC9uYW1lPgogICAgPC90eXBlcz4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz5PZmZlckJ1bGtBY3Rpb25zPC9tZW1iZXJzPgogICAgICAgIDxtZW1iZXJzPk9mZmVyQnVsa0FjdGlvbnMvQWxsX09mZmVyX0J1bGtfQWN0aW9uc182aUY8L21lbWJlcnM+CiAgICAgICAgPG5hbWU+UmVwb3J0PC9uYW1lPgogICAgPC90eXBlcz4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz5PZmZlckJ1bGtBY3Rpb25zRGFzaGJvYXJkczwvbWVtYmVycz4KICAgICAgICA8bWVtYmVycz5PZmZlckJ1bGtBY3Rpb25zRGFzaGJvYXJkcy9pbUJKRFl2QUF2a294Vmp0elRzSm9qbmZsUEl5YWE8L21lbWJlcnM+CiAgICAgICAgPG5hbWU+RGFzaGJvYXJkPC9uYW1lPgogICAgPC90eXBlcz4KICAgIDx0eXBlcz4KICAgICAgICA8bWVtYmVycz4qPC9tZW1iZXJzPgogICAgICAgIDxuYW1lPlJlcG9ydFR5cGU8L25hbWU+CiAgICA8L3R5cGVzPgotLT4KICAgIDx2ZXJzaW9uPjQ3LjA8L3ZlcnNpb24+CjwvUGFja2FnZT4=');
        return file;
    }

}