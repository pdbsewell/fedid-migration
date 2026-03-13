/*******************************************************************************
* @author       ???
* @date         ???         
* @description  
* @revision     Stefan Scheit (2018-09-15): Changed class to with sharing
*               Null check added on birthday
*******************************************************************************/
public with sharing class asmAlertsContactCC {
    
    public static String MESSAGE = 'message';
    
    public static String CONTACT_ID = 'contactId';
    public static String IS_UNDER18 = 'isUnder18';
    public static String HAS_ENCUMBRANCES = 'hasEncumbrances';
    public static String HAS_DISABILITIES = 'hasDisabilities';
    public static String HAS_GTE_ALERT = 'hasGTEAlert';
    public static String HAS_CREDIT_APPLICATION = 'hasCreditApplication';
    public static String HAS_CITIZENSHIP_ALERT = 'hasCitizenshipAlert';
    
    @AuraEnabled
    public static Map<String, Object> GetContactAlerts(Id contactId)
    {
        Map<String, Object> mapAlerts = new Map<String, Object>();      
        
        if(contactId == NULL)
        {
            ExLog.add('asmAlertsContactCC', 'N/A', 'GetContactAlerts', 'Contact ID is null'); 
            mapAlerts.put(MESSAGE, 'Error:Contact Id is null');
        }
        else
        {
            List<Contact> conRecords = [SELECT id
                                        , Birthdate
                                        , HasDisabilities__c
                                        , has_academic_enc__c
                                        , has_admin_enc__c
                                        FROM Contact
                                        WHERE id=:contactId];
            
            
            if(conRecords.size() != 1)
            {
                ExLog.add('asmAlertsContactCC', 'N/A', 'GetContactAlerts', 'Could not find Contact with Id ' + contactId); 
            	mapAlerts.put(MESSAGE, 'Error:Contact Id invalid');
            }
            else
            {
                // all good, continue
                Contact conRecord = conRecords[0];
                
                // contact Id for debugging, house keeping
                mapAlerts.put(CONTACT_ID, contactId);
                
                // under 18
                mapAlerts.put(IS_UNDER18, IsAppUnder18(conRecord));        
                
                // encumbrances
                mapAlerts.put(HAS_ENCUMBRANCES, HasAnyEncumbrance(conRecord.id));
                // disability
                mapAlerts.put(HAS_DISABILITIES, HasDisabilities(conRecord));
                // GTE only qualification level 
                //mapAlerts.put(HAS_GTE_ALERT, HasGTEAlert(conRecord.id));                                                
                // Citizenship
                mapAlerts.put(HAS_CITIZENSHIP_ALERT, HasCitizenshipAlert(contactId));                
                
                mapAlerts.put(MESSAGE, 'Alerts for Contact:' + contactId);
            }
        }
        
        return mapAlerts;
    }
    
    public static Boolean IsAppUnder18(Contact applicant)
    {
        Boolean isUnder18 = false;

        if (applicant.Birthdate != null) {
	        Decimal currAge = math.floor(applicant.Birthdate.daysBetween(date.TODAY()) / 365.2425 );
            if(currAge < MyApplicationUtilities.AGE_18){isUnder18 = true;}
        }
        return isUnder18;
    }
    
    public static Boolean HasAnyEncumbrance(Id contactId)
    {
        List<Encumbrance__c> listEncs = MyApplicationUtilities.getEncumbrancesByContact(contactId);
        if(listEncs.size() > 0)
            return true;
        return false;
    }
    
    public static Boolean HasDisabilities(Contact con)
    {
        if(con.HasDisabilities__c == 'Yes')
        {
            return true;
        }
        return false;
    }    
    
    public static Boolean HasCitizenshipAlert(Id contactId)
    {
        String citizenshipType = MyApplicationUtilities.getCitizenshipType(contactId);
        if(citizenshipType == MyApplicationUtilities.INTERNATIONAL)
        {
            return true;
        }        
        return false;
    }
 
}