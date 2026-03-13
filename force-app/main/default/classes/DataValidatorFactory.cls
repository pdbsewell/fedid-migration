/*******************************************************************************
* @author       Shalini Mendu
* @date         09.Jul.2019
* @description  Factory class to select the appropriate data validator
*               at run time.
* @revision Trent De Laney - SFTN-463 - 18/11/2019 - Added in curly braces for formatting
*******************************************************************************/
public with sharing class DataValidatorFactory {
    private final static String AGENT_PORTAL_SOURCE = 'AgentPortal';
    private final static String IDP_SOURCE = 'IDP';
    private final static String OES_SOURCE = 'OES';

    /*******************************************************************************
    * @author       Shalini Mendu
    * @date         09.Jul.2019
    * @description  Selects the appropriate data validator depending on the Source_System__c coming in the data
    * @revision Trent De Laney - SFTN-463 - 18/11/2019 - Added in curly braces for formatting
    *******************************************************************************/
    public static IDataValidator getValidator(String source) {
        if (source == AGENT_PORTAL_SOURCE) {
            return new AgentPortalDataValidator();
        }
        else if(source == IDP_SOURCE || source == OES_SOURCE){
            return new IDPDataValidator();
        }
        else {
            return null;
        }
    }
}