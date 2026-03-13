/**
 * @author      Kristian Vegerano
 * @description Base class to be extended by selectors per objects
 * @revision    17/05/2019 - Kristian Vegerano - Created
 */
public abstract class BaseSelector {
    /**
     * Constructors
     */
	public BaseSelector() {
	    overrideObjectPermissions = false;
	}
	
    public BaseSelector(Boolean newOverrideObjectPermissions) {
        overrideObjectPermissions = newOverrideObjectPermissions;
    }
    
    /**
     * Public properties
     */
    public Boolean overrideObjectPermissions {get; set;}
    
	/**
     * Abstract properties
     */
	abstract Schema.SObjectType getSObjectType();
	
	/**
     * @author      Kristian Vegerano
     * @description Initializes list of fields to be queried by the selector - default is selecting all fields - may be overriden to only specify required field
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
	public virtual List<Schema.SObjectField> getSObjectFieldList() {
		return getSObjectType().getDescribe().fields.getMap().values();
	}

	/**
     * @author      Kristian Vegerano
     * @description Checks if the context user has access to the object being retrieved
	 * @revision    17/05/2019 - Kristian Vegerano - Created
     */
	public void assertIsAccessible(){
	    //If not instructed to override object permissions
	    if(!overrideObjectPermissions){
	        //If context user does not have access to the object then throw an error
        	if(!getSObjectType().getDescribe().isAccessible()){
    	        throw new SelectorException('Permission to access ' + getSObjectType().getDescribe().getName() + ' denied.');
        	}
	    }
	}
	
	/**
     * @author      Kristian Vegerano
     * @description Checks if the context user has access to the object being retrieved
	 * @revision    17/05/2019 - Kristian Vegerano - Created
     */
	public List<SObject> selectSObjectsById(Set<Id> idSet) {
		assertIsAccessible();
		return Database.query(String.format('SELECT {0} FROM {1} WHERE id in :idSet ORDER BY {2}', new List<String>{getFieldListString(),
		                                                                                                            getSObjectName(),
		                                                                                                            getOrderBy()}));
	}
	
	/**
     * @author      Kristian Vegerano
     * @description Returns the list of api names for the fields
	 * @revision    17/05/2019 - Kristian Vegerano - Created
	 * @revision    31/10/2019 - David Browaeys - Simplified and Optimized method by removing for loop
     */
	public String getFieldListString() {
		return String.join(new List<String>(getSObjectType().getDescribe().fields.getMap().keySet()),',');
	}
	
	/**
     * @author      Kristian Vegerano
     * @description Returns the api name of the object
	 * @revision    17/05/2019 - Kristian Vegerano - Created
     */
	public String getSObjectName() {
		return getSObjectType().getDescribe().getName();
	}
	
	/**
     * @author      Kristian Vegerano
     * @description Return ORDER BY clause for the query
	 * @revision    17/05/2019 - Kristian Vegerano - Created
     */
	public virtual String getOrderBy() {
	    return 'Name';
	}
	
	/**
     * @author      Kristian Vegerano
     * @description Returns the list of api names for the fields plus the relationship field from a child record looking up to this object
	 * @revision    17/05/2019 - Kristian Vegerano - Created
     */
	public String getRelatedFieldListString(String relation){
	    List<String> fieldApiNames = new List<String>();
	    for(Schema.SObjectField field : getSObjectFieldList()){
	        fieldApiNames.add(relation + '.' + field.getDescribe().getName());
	    }
		return String.join(fieldApiNames, ',');
	}
	
	/**
     * @author      Kristian Vegerano
     * @description Custom exception for selector errors
	 * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public class SelectorException extends Exception {
        
    }
}