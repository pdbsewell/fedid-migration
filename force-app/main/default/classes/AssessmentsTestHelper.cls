@isTest
public class AssessmentsTestHelper {
    public static Queue_Routing_Rule__c createRule(String name, Integer order, String queue, Boolean active) {
        return new Queue_Routing_Rule__c(Name = name, Order__c = order, Queue__c = queue, Active__c = active);
    }

    public static void addCondition(
        List<Map<String, String>> conditionsData,
        String field,
        String operator,
        String value
    ) {
        conditionsData.add(
            new Map<String, String>{ 'Field__c' => field, 'Operator__c' => operator, 'Value__c' => value }
        );
    }

    public static void createConditions(
        Id ruleId,
        List<Map<String, String>> conditionsData,
        List<Queue_Routing_Rule_Condition__c> conditions
    ) {
        for (Map<String, String> data : conditionsData) {
            Queue_Routing_Rule_Condition__c condition = new Queue_Routing_Rule_Condition__c(
                Queue_Routing_Rule__c = ruleId,
                Field__c = data.get('Field__c'),
                Operator__c = data.get('Operator__c'),
                Value__c = data.get('Value__c')
            );
            conditions.add(condition);
        }
    }

    public class MockHttpResGenerator implements HttpCalloutMock {
        private String mockResponse;
        private Integer statusCode;

        public MockHttpResGenerator(String mockResponse, Integer statusCode) {
            this.mockResponse = mockResponse;
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setBody(mockResponse);
            response.setStatusCode(statusCode);
            return response;
        }
    }

    public class MultiMockHttpResGenerator implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests = new Map<String, HttpCalloutMock>();

        public HTTPResponse respond(HTTPRequest req) {
            HttpCalloutMock mock = requests.get(req.getEndpoint());
            return mock.respond(req);
        }

        public void addRequestMock(String url, HttpCalloutMock mock) {
            requests.put(url, mock);
        }
    }
}