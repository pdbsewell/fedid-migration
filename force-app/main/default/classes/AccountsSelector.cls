/**
 * @author      Kristian Vegerano
 * @description Selector class for account object processes
 * @group       Selectors
 * @revision    17/05/2019 - Kristian Vegerano - Created
 */
public inherited sharing class AccountsSelector extends BaseSelector {
    /**
     * Constructors
     */
	public AccountsSelector() {
	    super(false);
	}
	
    public AccountsSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      Kristian Vegerano
     * @description Returns the object type
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
	public Schema.SObjectType getSObjectType() {
		return Account.sObjectType;
	}
    
	/**
     * @author      Kristian Vegerano
     * @description Query accounts by ids
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public List<Account> selectById(Set<Id> idSet) {
		return (List<Account>) selectSObjectsById(idSet);
	}
}