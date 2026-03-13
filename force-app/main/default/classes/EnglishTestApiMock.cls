/**
 * @author      APRivera
 * @description HttpCalloutMock for EnglishTestApiService
 * @group       Admissions - English Test
 * @revision   15/12/2024 - APRivera - Created
 */

@IsTest
global class EnglishTestApiMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        // Simulate the response based on the request
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (request.getEndpoint().contains('testType=IELTS')) {
            // Mock valid response
            response.setBody('{"provider":"IELTS","testType":"IELTS Online (Academic)","testDate":"2024-01-01","testNumber":"123","lastName":"Doe","firstName":"John","dateOfBirth":"1995-01-01","listeningScore":9.0,"readingScore":8.5,"speakingScore":8.0,"writingScore":7.5,"overallScore":8.5,"validationResult":true,"photoBase64":"base64encodedphoto","photoMediaType":"image/jpeg","pdfBase64":"base64encodedpdf"}');
            response.setStatusCode(200);
            response.setStatus('HTTP/1.1 200 OK');
        } else if (request.getEndpoint().contains('testNumber=999&provider=Invalid')) {
            // New mock response with invalid JSON
            response.setBody('{"invalidField":"invalidValue"}'); // Invalid JSON for the expected payload
        } else {
            // Mock an error response
            response.setStatusCode(404);
            response.setBody('{"error":"Not Found"}');
        }
        return response;
    }

    /**
     * Inner class to simulate an invalid JSON response for parsing failure.
     */
    global class InvalidResponse implements HttpCalloutMock {
        /**
         * Respond with an invalid JSON body to simulate a failure in response parsing.
         * @param request The HTTP request sent by the code under test.
         * @return HttpResponse with invalid JSON content.
         */
        global HttpResponse respond(HttpRequest request) {
            // Create a new HTTP response
            HttpResponse response = new HttpResponse();

            // Set status code to 200 (to simulate a valid HTTP response)
            response.setStatusCode(200);
            response.setStatus('HTTP/1.1 200 OK');

            // Set the response body to an invalid JSON string
            response.setBody('{invalidJsonResponseHere: "missing_quotes_and_braces"}');

            return response;
        }
    }

    /**
     * Inner class to simulate an failure response.
     */
    global class Failure implements HttpCalloutMock {
        /**
         * Respond with an error status to simulate an API failure.
         * @param request The HTTP request sent by the code under test.
         * @return HttpResponse with a 404 error status code.
         */
        global HttpResponse respond(HttpRequest request) {
            // Create a new HTTP response
            HttpResponse response = new HttpResponse();

            // Set failure status code and message
            response.setStatusCode(404);
            response.setStatus('HTTP/1.1 404 NOT FOUND');
            response.setBody('{"error": "Resource not found", "error_description": "The requested test report could not be located."}');

            return response;
        }
    }
}