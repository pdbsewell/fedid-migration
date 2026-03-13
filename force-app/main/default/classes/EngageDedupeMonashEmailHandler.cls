/**
 * @author          Mark Johnson: UC Innovation
 * @description     Processes creation of emails from processing of an Interim object.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

public class EngageDedupeMonashEmailHandler {

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Constructs list of emails from the interim record for insertion into the system.
    *******************************************************************************/
    public void createEmailListToUpdateAndInsert(Map<String, Object> params) {

        // Processing Email for current interim-contact pair
        ucinn_ascendv2__Interim__c currentInterim = (ucinn_ascendv2__Interim__c)params.get('currentInterim');
        Integer preferredEmailNumber = 0;

        if (currentInterim.ucinn_ascendv2__Preferred_Email__c != null) {
            List<String> splitString = currentInterim.ucinn_ascendv2__Preferred_Email__c.split(' ');

            if (splitString.size() > 1 && splitString[1].isNumeric()) {
                preferredEmailNumber = Integer.valueOf(splitString[1]);
            }
        }

        Map<Integer, EngageDedupeWrapper.InterimEmailWrapper> interimEmailWrapperMap = new Map<Integer, EngageDedupeWrapper.InterimEmailWrapper>();

        EngageDedupeUtils.EngageInterimFields interimFields = new EngageDedupeUtils.EngageInterimFields(currentInterim);

        Set<String> supportedEmailType = EngageDedupeUtils.getPicklistValues(Email__c.Classification__c.getDescribe().getPicklistValues());


        for (Integer emailIndex = 0; emailIndex < interimFields.emailList.size(); emailIndex++) {
            String email = interimFields.emailList[emailIndex];
            String emailType = interimFields.emailTypeList[emailIndex];
            String emailImportId = interimFields.emailImportIdList[emailIndex];
            Date emailLastChanged = interimFields.emailLastChangedList[emailIndex];
            String emailSource = currentInterim.ucinn_ascendv2__Source_File__c;

            Integer emailNumber = emailIndex + 1;

            if (!String.isBlank(email)) {
                Boolean isValid = validateEmail(email);
                Boolean isPreferred = ((preferredEmailNumber == emailNumber) && isValid);

                if (!isValid) {
                    appendManuallyReviewReason(currentInterim, 'Invalid Email ' + emailNumber);
                } else if (String.isBlank(emailType) || !supportedEmailType.contains(emailType)) {
                    appendManuallyReviewReason(currentInterim, 'Invalid Email ' + emailNumber + ' Type');
                } else {
                    EngageDedupeWrapper.InterimEmailWrapper interimEmailWrapper = new EngageDedupeWrapper.InterimEmailWrapper(emailType,
                                                                                                                email,
                                                                                                                false,
                                                                                                                isPreferred,
                                                                                                                isValid,
                                                                                                                emailImportId,
                                                                                                                emailLastChanged,
                                                                                                                emailSource);

                    interimEmailWrapperMap.put(emailNumber, interimEmailWrapper);
                }
            }
        }

        params.put('interimEmailWrapperMap', interimEmailWrapperMap);

        updateEmailAddresses(params);
    }


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Construct lists of emails to perform DML on.
    *******************************************************************************/
    public virtual void updateEmailAddresses(Map<String, Object> params) {
        Map<Integer, EngageDedupeWrapper.InterimEmailWrapper> interimEmailWrapperMap = (Map<Integer, EngageDedupeWrapper.InterimEmailWrapper>)params.get('interimEmailWrapperMap');

        List<Email__c> emailsToInsertStaging = new List<Email__c>();

        ucinn_ascendv2__Interim__c currentInterim = (ucinn_ascendv2__Interim__c)params.get('currentInterim');
        Contact currentContact = (Contact)params.get('currentContact');
        String recordSource = (String)params.get('recordSource');

        List<Email__c> emailsToInsert = (List<Email__c>)params.get('emailsToInsert');
        List<Email__c> emailsToUpdate = (List<Email__c>)params.get('emailsToUpdate');

        for (Integer emailNumber : interimEmailWrapperMap.keySet()) {
            EngageDedupeWrapper.InterimEmailWrapper interimEmailWrapper = interimEmailWrapperMap.get(emailNumber);

            for (Email__c curEmail : currentContact.Emails__r) {
                if (interimEmailWrapper.emailFound != true) {
                    interimEmailWrapper.emailFound = compareEmail(interimEmailWrapper.emailAddress, curEmail.Name);
                }
                if(interimEmailWrapper.emailFound == true && curEmail.Is_Active__c==false){
                	curEmail.End_Date__c= null;
                    emailsToUpdate.add(curEmail);
                }
            }

            if (interimEmailWrapper.emailFound != true) {
                Email__c emailToInsert = setupEmailList(interimEmailWrapper.emailAddress,
                                                        interimEmailWrapper.emailType,
                                                        currentContact.Id,
                                                        interimEmailWrapper.emailPreferred,
                                                        recordSource,
                                                        interimEmailWrapper.emailImportId,
                                                        interimEmailWrapper.emailLastChanged,
                                                        interimEmailWrapper.emailSource);

                emailsToInsertStaging.add(emailToInsert);
            }
        }

        if (String.isBlank(currentInterim.ucinn_ascendv2__Manual_Review_Reason__c)) {
            emailsToInsert.addAll(emailsToInsertStaging);
        }
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Where email validation can occur.
    *******************************************************************************/
    public static Boolean validateEmail(String email) {
        //No current email validation.
        return true;
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Basic comparison to find exact duplicates previously loaded.
    *******************************************************************************/
    public static Boolean compareEmail(String interimEmail, String contactEmail) {
        if (interimEmail != null) interimEmail = interimEmail.toLowerCase();
        if (contactEmail != null) contactEmail = contactEmail.toLowerCase();

        if(interimEmail == contactEmail) {
            return true;
        } else {
            return false;
        }
    }


    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019
    * @description  Construct lists of emails to perform DML on.
    *******************************************************************************/
    public static Email__c setupEmailList(String emailAdd, String emailType, Id conId, Boolean prefFlag, String recSource, String emailImportId, Date emailLastChanged, String emailSource) {
        Email__c newEmail = new Email__c();

        newEmail.Name = emailAdd;
        newEmail.Classification__c = emailType;
        newEmail.Contact__c = conId;
        newEmail.Is_Primary__c = prefFlag;
        newEmail.Is_Active__c = true;
        newEmail.External_System_ID__c = emailImportId;
        newEmail.LastModifiedDate = emailLastChanged;
        newEmail.CreatedDate = emailLastChanged;

        if (!String.isEmpty(emailSource)) {
            newEmail.Source__c = emailSource;
        } else {
            newEmail.Source__c = 'Internal';
        }

        EngageDedupeUtils.fixCreationDate(newEmail);

        return newEmail;
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