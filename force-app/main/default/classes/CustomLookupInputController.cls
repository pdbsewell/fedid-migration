/*******************************************************************************
    * @author       Sethu Venna
    * @date         28/03/2025
    * @description  Controller class for Custom Look up Input component
    * @revision     28/03/2025 - Initial Version
*******************************************************************************/
public class CustomLookupInputController {
    
    /*******************************************************************************
    * @author       Sethu Venna
    * @date         28/03/2025
    * @description  method to search by name
    * @param        searchParam - value to look for
    * @param        objectsToSearch - objects to look for
    * @return       List<List<SObject>> - searched results
    * @revision     28/03/2025 - Initial Version
    *******************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static List<List<SObject>> searchByName(
        String searchParam,
        String objectsToSearch
    ) {
        String searchQuery = 'FIND {' + searchParam + '} IN ALL FIELDS RETURNING ' + objectsToSearch;
        return search.query(searchQuery);
    }   
}