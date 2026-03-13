/**
 * @author      David Browaeys
 * @description Selector class for product object processes
 * @group       Selectors
 * @revision    28/10/2019 - David Browaeys - Created
 */
public inherited sharing class ProductsSelector extends BaseSelector {
    /**
     * Constructors
     */
	public ProductsSelector() {
	    super(false);
	}
	
    public ProductsSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      David Browaeys
     * @date        28/10/2019
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return Product2.sObjectType;
	}
    public Map<String,Product2> selectProductByExternalId(Set<String> idSet, Schema.SObjectField externIdField) {
		String fieldName = externIdField.getDescribe().getName();
        Product2[] records = Database.query(String.format('SELECT {0} FROM {1} WHERE {3} IN :idSet ORDER BY {2}', new List<String>{
																													getFieldListString(),
		                                                                                                            getSObjectName(),
		                                                                                                            getOrderBy(),
																													fieldName}));
		Map<String,Product2> tmp = new Map<String,Product2>();
		for (Product2 record : (Product2[])records){
			tmp.put(String.valueOf(record.get(externIdField.getDescribe().getName())),record);
		}
		return tmp;
    }
	public static String getStandardPricebook(){
		return Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE isStandard = TRUE LIMIT 1].Id;
	}
}