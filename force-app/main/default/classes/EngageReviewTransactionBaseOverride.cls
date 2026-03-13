/**
 * @author          UC Innovation
 * @description    	This override class is to provide initialization of review transaction fields.
 * @revision        10/09/2021 - Initial version
 */

global without sharing class EngageReviewTransactionBaseOverride extends ucinn_ascendv2.ascend_GIFT_ReviewTransactionBasev2  {
    global override void initReviewTransaction(List<ucinn_ascendv2__Review_Transaction_v2__c> reviewTransList){
        
        
        reviewTransactionDataMap.clear();

        List<ucinn_ascendv2__Gift_Processing_Tender_Type__mdt> customMetadataTypeListTenderType = [SELECT MasterLabel,
                                                                                          DeveloperName,
                                                                                          ucinn_ascendv2__Tender_Type_Category__c
                                                                                   FROM ucinn_ascendv2__Gift_Processing_Tender_Type__mdt];

        for (ucinn_ascendv2__Gift_Processing_Tender_Type__mdt customMetadatType : customMetadataTypeListTenderType) {
            tenderTypeToCategoryMap.put(customMetadatType.MasterLabel, customMetadatType.ucinn_ascendv2__Tender_Type_Category__c);
        }

        recordTypePrefixToRecordTypeIdMap = getRecordTypesFromReviewTransactionPrefixesCustomSetting();

        for (ucinn_ascendv2__Review_Transaction_v2__c reviewTrans : reviewTransList) {
            // Create the review transaction data map so that we can track things specific to a particular review transaction record.
            if (!reviewTransactionDataMap.containsKey(reviewTrans.ucinn_ascendv2__External_System_ID__c)) {
                reviewTransactionDataMap.put(reviewTrans.ucinn_ascendv2__External_System_ID__c, new ReviewTransactionData());
            }

            ReviewTransactionData reviewTransData = reviewTransactionDataMap.get(reviewTrans.ucinn_ascendv2__External_System_ID__c);

            reviewTransData.initCustomSetting(reviewTrans, recordTypePrefixToReviewTransPrefixesMap);
        }

        initializeIndexedFieldsOverride();

    }
    
    global void initializeIndexedFieldsOverride(){
        Map<String, Schema.SObjectField> fieldMap = reviewTransFieldMap;

        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();

            String fieldApiNameWithoutNamespace = dfr.getName().replace('ucinn_ascendv2__', '');

            Integer numOrder = getIndexFieldNumberOrder(fieldApiNameWithoutNamespace);

            if (fieldApiNameWithoutNamespace.startsWith(DESIGNATION_EXTERNAL_ID_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToDesignationExternalIdApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(DESIGNATION_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToDesignationApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(CAMPAIGN_EXTERNAL_ID_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToCampaignExternalIdApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(CAMPAIGN_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToCampaignApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(TENDER_TYPE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToTenderTypeApiNameMap);
            }

            else if (fieldApiNameWithoutNamespace.startsWith(PAYMENT_AMOUNT_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToPaymentAmountApiNameMap);
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToPaymentAmountIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(PAYMENT_DATE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToPaymentDateApiNameMap);
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToPaymentDateIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(NON_GIFT_AMOUNT_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToNonGiftAmountApiNameMap);
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToNonGiftAmountIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(FACE_VALUE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToFaceValueApiNameMap);
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToFaceValueIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(AUTHORIZATION_CODE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToAuthorizationCodeApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(CREDIT_CARD_NUMBER_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToCreditCardNumberApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(CREDIT_CARD_EXPIRATION_DATE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToCreditCardExpirationDateApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(CHECK_NUMBER_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToCheckNumberApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(CHECK_DATE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToCheckDateApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(BANK_REFERENCE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToBankReferenceApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(TRANSACTION_NUMBER_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToTransactionNumberApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(TICKER_SYMBOL_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToTickerSymbolIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(NUMBER_OF_SHARES_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToNumberOfSharesIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(LOW_VALUE_ON_DATE_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToLowValueOnDateIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(HIGH_VALUE_ON_DATE_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToHighValueOnDateIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(RECEIVED_DATE_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToReceivedDateIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(AVERAGE_VALUE_ON_DATE_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToAverageValueOnDateIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(TOTAL_STOCK_AMOUNT_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToTotalStockAmountIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(SURCHARGE_AMOUNT_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToSurchargeAmountApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(INSTALLMENT_AMOUNT_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToInstallmentAmountApiNameMap);
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToInstallmentAmountIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(INSTALLMENT_DATE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToInstallmentDateApiNameMap);
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToInstallmentDateIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(NUMBER_OF_INSTALLMENTS_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToNumberOfInstallmentsApiNameMap);
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToNumberOfInstallmentsIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(INSTALLMENT_FREQUENCY_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToInstallmentFrequencyApiNameMap);
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToInstallmentFrequencyIndexApiNameMap);
            }

            else if (fieldApiNameWithoutNamespace.startsWith(TRIBUTE_TYPE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToTributeTypeApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(TRIBUTEE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToTributeeApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(NOTIFY_ADDRESS_1_PREFIX)) {
                // Need to do it this way instead of using setSingleIndexedFields since it has a number at the end of the field name.
                orderToNotifyAddress1ApiNameMap.put(numOrder, dfr.getName());
            }
            else if (fieldApiNameWithoutNamespace.startsWith(NOTIFY_ADDRESS_2_PREFIX)) {
                // Need to do it this way instead of using setSingleIndexedFields since it has a number at the end of the field name.
                orderToNotifyAddress2ApiNameMap.put(numOrder, dfr.getName());
            }
            else if (fieldApiNameWithoutNamespace.startsWith(NOTIFY_CITY_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToNotifyCityApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_COMMENTS_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToInMemoryHonorCommentsApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_CONTACT_EXTERNAL_ID_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToInMemoryHonorContactExternalIdApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_CONTACT_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToInMemoryHonorContactApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_FIRST_NAME_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToInMemoryHonorFirstNameApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_LAST_NAME_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToInMemoryHonorLastNameApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_ORGANIZATION_NAME_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToInMemoryHonorOrganizationNameApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(NOTIFY_POSTAL_CODE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToNotifyPostalCodeApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(NOTIFY_STATE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToNotifyHonorStateApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_NOTIFY_CONTACT_EXTERNAL_ID_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToNotifyContactExternalIdApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_NOTIFY_CONTACT_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToNotifyContactApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_NOTIFY_FIRST_NAME_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToNotifyFirstNameApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(IN_MEMORY_HONOR_NOTIFY_LAST_NAME_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToNotifyLastNameApiNameMap);
            }

            else if (fieldApiNameWithoutNamespace.startsWith(HARD_SOFT_CREDIT_AMOUNT_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToHardSoftCreditAmountIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(HARD_SOFT_CREDIT_CONSTITUENT_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToHardSoftCreditConstituentIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(HARD_SOFT_CREDIT_ORGANIZATION_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToHardSoftCreditOrganizationIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(HARD_SOFT_CREDIT_TYPE_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToHardSoftCreditTypeIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(HARD_SOFT_CREDIT_CONSTITUENT_EXTERNAL_ID_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToHardSoftCreditConstituentExternalIdIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(HARD_SOFT_CREDIT_ORGANIZATION_EXTERNAL_ID_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToHardSoftCreditOrganizationExternalIdIndexApiNameMap);
            }

            else if (fieldApiNameWithoutNamespace.startsWith(ADJUSTED_PAYMENT_EXTERNAL_ID_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToAdjustedPaymentExternalIdIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(ADJUSTED_PAYMENT_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToAdjustedPaymentIndexApiNameMap);
            }

            else if (fieldApiNameWithoutNamespace.startsWith(PAYMENT_CUSTOM_EXTERNAL_ID_PREFIX)) {
                setTwoIndicesFields(fieldApiNameWithoutNamespace, dfr.getName(), indexToPaymentCustomExternalIdIndexApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(PAYMENT_CUSTOM_GROUP_ID_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToPaymentCustomPaymentGroupApiNameMap);
            }

            else if (fieldApiNameWithoutNamespace.startsWith(OPPORTUNITY_EXTERNAL_ID_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToOpportunityExternalIdApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(OPPORTUNITY_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToOpportunityApiNameMap);

                // Need to do this.  Otherwise, it 0th index would have been 'Opportunity_Type__c'.
                orderToOpportunityApiNameMap.put(0, 'Opportunity__c');
            }
            else if (fieldApiNameWithoutNamespace.startsWith(MEMBERSHIP_ANNIVERSARY_DATE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToMembershipAnniversaryDateApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(MEMBERSHIP_EXPIRATION_DATE_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToMembershipExpirationDateApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(MEMBERSHIP_LEVEL_EXTERNAL_ID_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToMembershipLevelExternalIdApiNameMap);
            }
            else if (fieldApiNameWithoutNamespace.startsWith(MEMBERSHIP_LEVEL_PREFIX)) {
                setSingleIndexedFields(fieldApiNameWithoutNamespace, dfr.getName(), orderToMembershipLevelApiNameMap);
            }

        }

        orderedDesignationIndexList = new List<Integer>(orderToDesignationExternalIdApiNameMap.keySet());
        orderedDesignationIndexList.sort();

    }
}