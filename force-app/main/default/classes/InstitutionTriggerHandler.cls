/*
 * @author       Martin Cadman
 * @date         28.Apr.2023
 * @description  Service class for Institution creation
 * @revision     28.Apr.2023    Martin - Initial version
 *
 */
public class InstitutionTriggerHandler {

   	// Use the text country field (supplied by Callista) to link the instituion to the country attribute record
    public class countryLookup extends TriggerAbstract {

        // Insert
        public override void process(SObject newRecord) {
            Institution__c ni = (Institution__c)newRecord;
            
			// Only operate if a country is specified
            if (String.isNotEmpty(ni.country__c)) {
	            records.add(newRecord);
            }
        }
        
        // Update
        public override void process(SObject newRecord, SObject oldRecord) {
            Institution__c ni = (Institution__c)newRecord;
            Institution__c oi = (Institution__c)oldRecord;

			// Only operate if a country is specified and has changed
            if (String.isNotEmpty(ni.country__c) 
             && CommonUtilities.fieldHasChanged('Country__c', ni, oi)) {
            	records.add(newRecord);
            }
        }

        // Introduce or clear the Lookup to the country attribute
        public override void execute() {
            try {
                if (!records.isEmpty()) {
                    Set<Institution__c> instList = new Set <Institution__c>((List<Institution__c>)records);
    
                    for (Institution__c i : instList) {
                        Country_Attribute__c c = countryServices.getCountry(i.country__c); 
                        If (c != null) {
                            i.Institution_country__c = c.id;
                        } else {
                            i.Institution_country__c = null;
                        }
                    }
                }
            } catch (Exception ex) {
                logUtilityException.logException(ex,'InstitutionTriggerHandler.countryLookup()');
            }
        }
    }
}