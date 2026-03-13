/**
* @author David Browaeys
* @date 18/10/2019
* @group SF Offer
* @description CPQ API Service layer
*/
global inherited sharing class CPQ_APIService {
    public class CPQException extends Exception{}
    /** CPQ API METHODS */
    public static final String PRODUCT_LOADER = 'SBQQ.ProductAPI.ProductLoader';
    public static final String QUOTE_READER = 'SBQQ.QuoteAPI.QuoteReader';
    public static final String QUOTE_PRODUCT_ADDER = 'SBQQ.QuoteAPI.QuoteProductAdder';
    public static final String QUOTE_CALCULATOR = 'SBQQ.QuoteAPI.QuoteCalculator';
    public static final String QUOTE_SAVER = 'SBQQ.QuoteAPI.QuoteSaver';
    public static final String QUOTE_VALIDATOR = 'SBQQ.QuoteAPI.QuoteValidator';

    public static CPQ_ApiDataModels.QuoteModel getQuote(String uid) {
        String quoteJSON = SBQQ.ServiceRouter.read(QUOTE_READER, uid);
        return (CPQ_ApiDataModels.QuoteModel) JSON.deserialize(quoteJSON, CPQ_ApiDataModels.QuoteModel.class);
    }
    //load
    public static String load(String name, String uid, Object payload) {
        return load(name, uid, JSON.serialize(payload));
    }
    public static String load(String name, String uid, String payloadJson) {
        return SBQQ.ServiceRouter.load(name, uid, payloadJson);
    }
    //get product
    public static CPQ_ApiDataModels.ProductModel loadProduct(String productId, String pricebookId, String currencyCode) {
        String productJson = load(PRODUCT_LOADER, productId,'{"pricebookId" : "'+pricebookId+'", "currencyCode" : "'+currencyCode+'"}');
        return (CPQ_ApiDataModels.ProductModel) JSON.deserialize(productJson, CPQ_ApiDataModels.ProductModel.class);
    }
    //add products
    public static CPQ_ApiDataModels.QuoteModel addProducts(CPQ_ApiDataModels.QuoteModel quote, List<CPQ_ApiDataModels.ProductModel> products) {
        String quoteJSON = '{"quote" : ' + JSON.serialize(quote) + ', "products" : ' + JSON.serialize(products) + ', "ignoreCalculate" : true}';
        quoteJSON = load(QUOTE_PRODUCT_ADDER, null, quoteJSON);
        return (CPQ_ApiDataModels.QuoteModel) JSON.deserialize(quoteJSON, CPQ_ApiDataModels.QuoteModel.class);
    }
    //update quote
    public static CPQ_ApiDataModels.QuoteModel save(String quote) {
        String quoteJSON = SBQQ.ServiceRouter.save(QUOTE_SAVER, quote);
        return (CPQ_ApiDataModels.QuoteModel) JSON.deserialize(quoteJSON, CPQ_ApiDataModels.QuoteModel.class);
    }
    public static CPQ_ApiDataModels.QuoteModel save(CPQ_ApiDataModels.QuoteModel quote) {
        return save(JSON.serialize(quote));
    }
    //validate quote
    public static List<String> validate(CPQ_ApiDataModels.QuoteModel quote) {
      String res = load(QUOTE_VALIDATOR, null, quote);
      System.debug(res);
      return res != null ? (List<String>) JSON.deserialize(res, List<String>.class) : null;
    }
    //re-calculate
    public static void calculate(CPQ_ApiDataModels.QuoteModel quote, String callback){
        CPQ_ApiDataModels.CalculatorContext ctx = new CPQ_ApiDataModels.CalculatorContext(quote, callback);
        if (Test.isRunningTest() == false) load (QUOTE_CALCULATOR, null, JSON.serialize(ctx));
    }
}