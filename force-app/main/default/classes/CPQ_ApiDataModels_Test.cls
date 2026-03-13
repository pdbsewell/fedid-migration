@isTest
public with sharing class CPQ_ApiDataModels_Test {
    @isTest public static void test_CPQ_ApiDataModels(){
        CPQ_ApiDataModels.QuoteModel quoteModel = new CPQ_ApiDataModels.QuoteModel();
        CPQ_ApiDataModels.ProductModel productModel = new CPQ_ApiDataModels.ProductModel();
        CPQ_ApiDataModels.CalculatorContext calculatorContext = new CPQ_ApiDataModels.CalculatorContext(null,TestCallback.class.toString());
    }

    public class TestCallback implements SBQQ.CalculateCallback{
        private CPQ_ApiDataModels.QuoteModel quoteModel;
        public void callback(String quoteJSON){
            System.debug(quoteJSON);
        }
    }
}