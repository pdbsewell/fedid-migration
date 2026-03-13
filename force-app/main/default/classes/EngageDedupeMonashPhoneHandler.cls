/**
 * @author          Mark Johnson: UC Innovation
 * @description     Processes creation of phones from processing of an Interim object.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

public class EngageDedupeMonashPhoneHandler {

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Constructs list of phones from the interim record for insertion into the system.
    *******************************************************************************/
    public void createPhoneListToUpdateAndInsert(Map<String, Object> params) {
        // Processing Phone for current interim-contact pair
        ucinn_ascendv2__Interim__c currentInterim = (ucinn_ascendv2__Interim__c)params.get('currentInterim');
        Integer preferredPhoneIndex = 0;


        if (currentInterim.ucinn_ascendv2__Preferred_Phone__c != null) {

            //Format for picklist value here is Phone_(#)__c
            List<String> splitString = currentInterim.ucinn_ascendv2__Preferred_Phone__c.split(' ');

            if (splitString.size() > 1 && splitString[1].isNumeric()) {
                preferredPhoneIndex = Integer.valueOf(splitString[1]);
            }
        }

        Set<String> supportedPhoneType = EngageDedupeUtils.getPicklistValues(Phone__c.Type__c.getDescribe().getPicklistValues());

        Map<Integer, EngageDedupeWrapper.InterimPhoneWrapper> interimPhoneWrapperMap = new Map<Integer, EngageDedupeWrapper.InterimPhoneWrapper>();

        EngageDedupeUtils.EngageInterimFields interimFields = new EngageDedupeUtils.EngageInterimFields(currentInterim);


        for (Integer phoneIndex = 0; phoneIndex < interimFields.phoneList.size(); phoneIndex++) {
            String phone = interimFields.phoneList[phoneIndex];
            String phoneType = interimFields.phoneTypeList[phoneIndex];
            String phoneImportId = interimFields.phoneImportIdList[phoneIndex];
            Date phoneLastChanged = interimFields.phoneLastChangedList[phoneIndex];
            String classification;
            Integer phoneNum;
            String phoneSource = currentInterim.ucinn_ascendv2__Source_File__c;

            phoneNum = phoneIndex + 1;

            //3rd and 5th fields on interim are Business and Assistant.
            if (phoneNum == 2 || phoneNum == 4) {
                classification = 'Business';
            } else {
                classification = 'Private';
            }

            if (!String.isBlank(phone)) {
                Boolean isValid = validatePhone(phone);
                Boolean isPreferred = ((preferredPhoneIndex == phoneNum) && isValid);

                if (!isValid) {
                    appendManuallyReviewReason(currentInterim, 'Invalid Phone ' + phoneNum);
                } else if (String.isBlank(phoneType) || !supportedPhoneType.contains(phoneType)) {
                    appendManuallyReviewReason(currentInterim, 'Invalid Phone ' + phoneNum + ' Type');
                } else {
                    EngageDedupeWrapper.InterimPhoneWrapper interimPhoneWrapper = new EngageDedupeWrapper.InterimPhoneWrapper(phoneType,
                                                                                                                phone,
                                                                                                                false,
                                                                                                                isPreferred,
                                                                                                                isValid,
                                                                                                                phoneImportId,
                                                                                                                phoneLastChanged,
                                                                                                                classification,
                                                                                                                phoneSource);

                    interimPhoneWrapperMap.put(phoneIndex, interimPhoneWrapper);
                }
            }
        }

        params.put('interimPhoneWrapperMap', interimPhoneWrapperMap);

        updatePhoneNumbers(params);
    }


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Construct lists of phones to perform DML on.
    *******************************************************************************/
    public virtual void updatePhoneNumbers(Map<String, Object> params) {
        Map<Integer, EngageDedupeWrapper.InterimPhoneWrapper> interimPhoneWrapperMap = (Map<Integer, EngageDedupeWrapper.InterimPhoneWrapper>)params.get('interimPhoneWrapperMap');
        List<Phone__c> phonesToInsertStaging = new List<Phone__c>();

        ucinn_ascendv2__Interim__c currentInterim = (ucinn_ascendv2__Interim__c)params.get('currentInterim');
        Contact currentContact = (Contact)params.get('currentContact');
        String recordSource = (String)params.get('recordSource');

        List<Phone__c> phonesToInsert = (List<Phone__c>)params.get('phonesToInsert');
        List<Phone__c> phonesToUpdate = (List<Phone__c>)params.get('phonesToUpdate');

        for (Integer phoneIndex : interimPhoneWrapperMap.keySet()) {
            EngageDedupeWrapper.InterimPhoneWrapper interimPhoneWrapper = interimPhoneWrapperMap.get(phoneIndex);

            for (Phone__c curPhone : currentContact.Phones__r) {
                if (interimPhoneWrapper.phoneFound != true) {
                    interimPhoneWrapper.phoneFound = comparePhone(interimPhoneWrapper.phone, curPhone.Name);
                }
                if(interimPhoneWrapper.phoneFound == true && curPhone.Is_Active__c==false){
                	curPhone.End_Date__c= null;
                    phonesToUpdate.add(curPhone);
                }
            }

            if (interimPhoneWrapper.phoneFound != true) {
                Phone__c phoneToInsert = setupPhoneList(interimPhoneWrapper.phone,
                                                        interimPhoneWrapper.phoneType,
                                                        currentContact.Id,
                                                        interimPhoneWrapper.phonePreferred,
                                                        recordSource,
                                                        interimPhoneWrapper.phoneImportId,
                                                        interimPhoneWrapper.phoneLastChanged,
                                                        interimPhoneWrapper.classification,
                                                        interimPhoneWrapper.phoneSource);
                phonesToInsertStaging.add(phoneToInsert);
            }
        }

        if (String.isBlank(currentInterim.ucinn_ascendv2__Manual_Review_Reason__c)) {
            phonesToInsert.addAll(phonesToInsertStaging);
        }
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Where phone validation can occur.
    *******************************************************************************/
    public static Boolean validatePhone(String phone) {
        Boolean phoneValid = false;

        //Basic regex to check proper phone format.
        //Remove special characters, and check for extension.
        String modPhone = phone.replaceAll('[^A-Za-z0-9]', '');
        List<String> phoneRegex= new List<String>{'[0-9]+',
                                                '[0-9]+[xX][0-9]+',
                                                '[0-9]+ext{1}[0-9]+'};
        for(String s : phoneRegex){
            Pattern phonePattern = Pattern.compile(s);
            Matcher phoneMatcher = phonePattern.matcher(modPhone);
            if (phoneMatcher.matches()) {
                phoneValid = true;
                break;
            }
        }
        return phoneValid;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Basic comparison to find exact duplicates previously loaded.
    *******************************************************************************/
    public static Boolean comparePhone(String interimPhone,  String contactPhone) {
        String modInterimPhone = interimPhone.replaceAll('[^A-Za-z0-9]', '');
        String modContactPhone = contactPhone.replaceAll('[^A-Za-z0-9]', '');

        if (modInterimPhone == modContactPhone) {
            return true;
        } else {
            return false;
        }
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Construct lists of phones to perform DML on.
    *******************************************************************************/
    public static Phone__c setupPhoneList(String phoneAdd, String phoneType, Id conId, Boolean prefFlag, String recSource, String phoneImportId, Date phoneLastChanged, String classification, String phoneSource) {
        Phone__c newPhone = new Phone__c();

        newPhone.Name = phoneAdd;
        newPhone.Type__c = phoneType;
        newPhone.Contact__c = conId;
        newPhone.Is_Primary__c = prefFlag;
        newPhone.Is_Active__c = true;
        newPhone.External_System_ID__c = phoneImportId;
        newPhone.LastModifiedDate = phoneLastChanged;
        newPhone.CreatedDate = phoneLastChanged;
        newPhone.Classification__c = classification;

        if (!String.isEmpty(phoneSource)) {
            newPhone.Source__c = phoneSource;
        } else {
            newPhone.Source__c = 'Internal';
        }

        EngageDedupeUtils.fixCreationDate(newPhone);

        return newPhone;
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


}