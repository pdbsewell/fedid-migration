/**
 * @author          Mark Johnson: UC Innovation
 * @description     Processes creation of addresses from processing of an Interim object.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

public class EngageDedupeMonashAddressHandler {


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Constructs list of addresses from the interim record for insertion into the system.
    *******************************************************************************/
    public void createAddressListToUpdateAndInsert(Map<String, Object> params) {

        // Processing Address for current interim-contact pair
        ucinn_ascendv2__Interim__c currentInterim = (ucinn_ascendv2__Interim__c)params.get('currentInterim');
        Integer preferredAddressNumber = 0;

        if (currentInterim.ucinn_ascendv2__Preferred_Address__c != null) {
            List<String> splitString = currentInterim.ucinn_ascendv2__Preferred_Address__c.split(' ');

            if (splitString.size() > 1 && splitString[1].isNumeric()) {
                preferredAddressNumber = Integer.valueOf(splitString[1]);
            }
        }

        Set<String> supportedAddressType = EngageDedupeUtils.getPicklistValues(Address__c.Type__c.getDescribe().getPicklistValues());

        List<Map<String, Object>> initialAddressProcessingList = createInitialProcessingWrapper(currentInterim, 3);
        Map<Integer, EngageDedupeWrapper.InterimAddressWrapper> interimAddressWrapperMap = new Map<Integer, EngageDedupeWrapper.InterimAddressWrapper>();

        for (Integer addressIndex = 0; addressIndex < initialAddressProcessingList.size(); addressIndex++) {
            Map<String, Object> addressMap = initialAddressProcessingList[addressIndex];
            String addressType = (String) addressMap.get('type');
            String addressImportId = (String) addressMap.get('addressImportId');
            Date addressDateCreated = (Date) addressMap.get('addressDateCreated');
            Date addressDateFrom = (Date) addressMap.get('addressDateFrom');
            Date addressDateLastChanged = (Date) addressMap.get('addressDateLastChanged');
            Date addressDateTo = (Date) addressMap.get('addressDateTo');
            String addressSource = (String) addressMap.get('addressSource');
            String classification;

            Integer addressNumber = addressIndex + 1;

            //Mappings as specified by Travis (ERDA). Potentially create setting to manipulate this.
            if (addressType == 'Business' || addressType == 'Ministerial' || addressType == 'Electorate' || addressType == 'GovernmentAPH') {
                addressType = null;
                classification = 'Business';
            } else if (addressType == 'Home') {
                addressType = null;
                classification = 'Private';
            } else if (addressType == 'Mailing') {
                addressType = 'Mailing';
                classification = 'Private';
            } else {
                classification = 'Private';
            }

            if (!isEmptyAddress(addressMap)) {
                Boolean isValid = validateAddress(addressMap);
                String addressLines = concatenateAddressLines(addressMap);
                Boolean isPreferred = ((preferredAddressNumber == addressNumber) && isValid);

                if (!isValid) {
                    appendManuallyReviewReason(currentInterim, 'Invalid Address ' + addressNumber);
                } else if (!String.isBlank(addressType) && !supportedAddressType.contains(addressType)) {
                    appendManuallyReviewReason(currentInterim, 'Invalid Address ' + addressNumber + ' Type');
                } else {
                    EngageDedupeWrapper.InterimAddressWrapper interimAddressWrapper = new EngageDedupeWrapper.InterimAddressWrapper(addressType,
                                                                                                                addressLines,
                                                                                                                (String) addressMap.get('city'),
                                                                                                                (String) addressMap.get('state'),
                                                                                                                (String) addressMap.get('post'),
                                                                                                                (String) addressMap.get('country'),
                                                                                                                false,
                                                                                                                isPreferred,
                                                                                                                isValid,
                                                                                                                addressImportId,
                                                                                                                addressDateCreated,
                                                                                                                addressDateFrom,
                                                                                                                addressDateLastChanged,
                                                                                                                addressDateTo,
                                                                                                                addressSource,
                                                                                                                classification);

                    interimAddressWrapperMap.put(addressNumber, interimAddressWrapper);
                }
            }
        }

        params.put('interimAddressWrapperMap', interimAddressWrapperMap);
        updateAddresses(params);
    }



    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Creation of wrapper used to store address.
    *******************************************************************************/
    private List<Map<String, Object>> createInitialProcessingWrapper(ucinn_ascendv2__Interim__c currentInterim, Integer namespacedFieldCount) {
        List<Map<String, Object>> initialAddressProcessingList = new List<Map<String, Object>>();

        for (Integer addressIndex = 1; addressIndex < (namespacedFieldCount + 1); addressIndex++) {
            Map<String, Object> addressWrapper = new Map<String, Object>();

            addressWrapper.put('line1', currentInterim.get('ucinn_ascendv2__Address_' + addressIndex + '_Line_1__c'));
            addressWrapper.put('line2', currentInterim.get('ucinn_ascendv2__Address_' + addressIndex + '_Line_2__c'));
            addressWrapper.put('line3', currentInterim.get('ucinn_ascendv2__Address_' + addressIndex + '_Line_3__c'));
            addressWrapper.put('line4', currentInterim.get('ucinn_ascendv2__Address_' + addressIndex + '_Line_4__c'));

            addressWrapper.put('type', currentInterim.get('ucinn_ascendv2__Address_' + addressIndex + '_Type__c'));
            addressWrapper.put('city', currentInterim.get('ucinn_ascendv2__City_' + addressIndex + '__c'));
            addressWrapper.put('state', currentInterim.get('ucinn_ascendv2__State_' + addressIndex + '__c'));
            addressWrapper.put('post', currentInterim.get('ucinn_ascendv2__Postal_Code_' + addressIndex + '__c'));
            addressWrapper.put('country', currentInterim.get('ucinn_ascendv2__Country_' + addressIndex + '__c'));
            addressWrapper.put('addressImportId', currentInterim.get('Address_' + addressIndex + '_Import_ID__c'));
            addressWrapper.put('addressDateCreated', currentInterim.get('Address_' + addressIndex + '_Date_Created__c'));
            addressWrapper.put('addressDateFrom', currentInterim.get('Address_' + addressIndex + '_Date_From__c'));
            addressWrapper.put('addressDateLastChanged', currentInterim.get('Address_' + addressIndex + '_Date_Last_Changed__c'));
            addressWrapper.put('addressDateTo', currentInterim.get('Address_' + addressIndex + '_Date_To__c'));
            //addressWrapper.put('addressSource', currentInterim.get('Address_' + addressIndex + '_Source__c'));
            addressWrapper.put('addressSource', currentInterim.get('ucinn_ascendv2__Source_File__c'));

            initialAddressProcessingList.add(addressWrapper);
        }

        return initialAddressProcessingList;
    }



    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Construct lists of addresses to perform DML on.
    *******************************************************************************/
    public virtual void updateAddresses(Map<String, Object> params) {
        Map<Integer, EngageDedupeWrapper.InterimAddressWrapper> interimAddressWrapperMap = (Map<Integer, EngageDedupeWrapper.InterimAddressWrapper>)params.get('interimAddressWrapperMap');

        List<Address__c> addressesToInsertStaging = new List<Address__c>();

        ucinn_ascendv2__Interim__c currentInterim = (ucinn_ascendv2__Interim__c)params.get('currentInterim');
        Contact currentContact = (Contact)params.get('currentContact');
        String recordSource = (String)params.get('recordSource');
        List<Address__c> addressesToInsert = (List<Address__c>)params.get('addressesToInsert');
        List<Address__c> addressesToUpdate = (List<Address__c>)params.get('addressesToUpdate');

        for (Integer addressNumber : interimAddressWrapperMap.keySet()) {
            EngageDedupeWrapper.InterimAddressWrapper interimAddressWrapper = interimAddressWrapperMap.get(addressNumber);

            for (Address__c curAddress : currentContact.Addresses__r) {
                if (interimAddressWrapper.addressFound != true) {
                    interimAddressWrapper.addressFound = compareAddress(interimAddressWrapper, curAddress);
                }
                if(interimAddressWrapper.addressFound == true && curAddress.Is_Active__c==false){
                	  curAddress.End_Date__c= null;
                    addressesToUpdate.add(curAddress);
                }
            }

            if (interimAddressWrapper.addressFound != true) {
                Address__c addressToInsert = setupAddressList(interimAddressWrapper, currentContact.Id, recordSource);
                addressesToInsertStaging.add(addressToInsert);
            }
        }

        if (String.isBlank(currentInterim.ucinn_ascendv2__Manual_Review_Reason__c)) {
            addressesToInsert.addAll(addressesToInsertStaging);
        }
    }


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Where address validation can occur.
    *******************************************************************************/
    public static Boolean validateAddress(Map<String, Object> params) {
        //Currrently no specific validation logic for Monash.
        return true;
    }


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Basic comparison to find exact duplicates previously loaded.
    *******************************************************************************/
    public static Boolean compareAddress(EngageDedupeWrapper.InterimAddressWrapper interimAddress, Address__c contactAddress) {

        //Basic comparison to find exact duplicates previously loaded.
        if (interimAddress.addressStreet == contactAddress.Street_Name__c &&
            interimAddress.addressCity == contactAddress.City__c &&
            interimAddress.addressState == contactAddress.State__c &&
            interimAddress.addressPostalCode == contactAddress.Post_Code__c &&
            interimAddress.addressCountry == contactAddress.Country2__c) {
            return true;
        } else {
            return false;
        }
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Creation of map used to replace pre-existing values on interim with mapped values.
    *******************************************************************************/
    public static Address__c setupAddressList(EngageDedupeWrapper.InterimAddressWrapper interimAddress, Id conId, String recSource) {
        Address__c newAddress = new Address__c();

        newAddress.Type__c = interimAddress.addressType;
        newAddress.City__c = interimAddress.addressCity;
        newAddress.State__c = interimAddress.addressState;
        newAddress.Country2__c = interimAddress.addressCountry;
        newAddress.Post_Code__c = interimAddress.addressPostalCode;
        newAddress.Street_Name__c = interimAddress.addressStreet;
        newAddress.Contact__c = conId;
        newAddress.Is_Primary__c = interimAddress.addressPreferred;
        newAddress.Is_Active__c = true;
        newAddress.External_System_ID__c = interimAddress.addressImportId;
        newAddress.CreatedDate = interimAddress.addressDateCreated;
        newAddress.Start_Date__c = interimAddress.addressDateFrom;
        newAddress.End_Date__c = interimAddress.addressDateTo;
        newAddress.LastModifiedDate = interimAddress.addressDateLastChanged;
        newAddress.Classification__c = interimAddress.classification;

        if (!String.isEmpty(interimAddress.addressSource)) {
            newAddress.Source__c = interimAddress.addressSource;
        } else {
            newAddress.Source__c = 'Internal';
        }

        //Must have creation date later than last modified date.
        EngageDedupeUtils.fixCreationDate(newAddress);

        return newAddress;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Appends manual review reason to interim, when issues are found with data.
    *******************************************************************************/
    private void appendManuallyReviewReason(ucinn_ascendv2__Interim__c interimRec, String newReason) {
        interimRec.ucinn_ascendv2__Status__c = 'Manual Review';

        if (interimRec.ucinn_ascendv2__Manual_Review_Reason__c != null) {
            if (!interimRec.ucinn_ascendv2__Manual_Review_Reason__c.contains(newReason)) {
                interimRec.ucinn_ascendv2__Manual_Review_Reason__c = interimRec.ucinn_ascendv2__Manual_Review_Reason__c + ', ' + newReason;
            }
        } else {
            interimRec.ucinn_ascendv2__Manual_Review_Reason__c = newReason;
        }
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Returns true if an address is empty.
    *******************************************************************************/
    private Boolean isEmptyAddress(Map<String, Object> addressMap) {
        if (String.isEmpty((String) addressMap.get('line1')) &&
            String.isEmpty((String) addressMap.get('line2')) &&
            String.isEmpty((String) addressMap.get('line3')) &&
            String.isEmpty((String) addressMap.get('line4')) &&
            String.isEmpty((String) addressMap.get('type')) &&
            String.isEmpty((String) addressMap.get('city')) &&
            String.isEmpty((String) addressMap.get('state')) &&
            String.isEmpty((String) addressMap.get('post')) &&
            String.isEmpty((String) addressMap.get('country'))) {
            return true;
        }

        return false;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Used to concatenate address lines, based on ERDA requirements for RE.
    *******************************************************************************/
    private String concatenateAddressLines(Map<String, Object> addressMap) {
        String addressLines = '';

        List<String> addressLinesToConcatenate = new List<String> { (String) addressMap.get('line1'),
                                                                    (String) addressMap.get('line2'),
                                                                    (String) addressMap.get('line3'),
                                                                    (String) addressMap.get('line4')
                                                                };

        for (String addressLine : addressLinesToConcatenate) {
            if (!String.isEmpty(addressLine)) {
                if (String.isEmpty(addressLines)) {
                    addressLines += addressLine.trim();
                } else {
                    addressLines += (', ' + addressLine.trim());
                }
            }
        }

        return addressLines;
    }


}