/**
 * @author                      Kristian Vegerano
 * @created                     February 02, 2018
 * @description                 Rest Service that retrieves FAQ Articles tagged as Customer and Public
 */
@RestResource(urlMapping='/FAQDataService')
global without sharing class FAQDataService {

    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Method that runs when a GET request has been sent to FAQDataService
     * @return                      returns customer and public articles in JSON format attached to the response body
     */
    @HttpGet
    global static void doGet() {
        //Set return type to JSON
        RestContext.response.addHeader('Content-Type', 'application/json');

        //Return FAQ data
        String responseJSON = FAQData.generateArticleJSONContent(FAQData.retrievePublishedFAQArticles());
        
        //Set return type to JSON
        RestContext.response.responseBody = Blob.valueOf(responseJSON);
    }
}