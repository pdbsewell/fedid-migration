/*
 * Copyright (c) 2019, UC Innovation, Inc.  All Rights Reserved.
 *                     http://www.ucinnovation.com
 *
 * This source code is licensed, not sold, and is subject to a written
 * license agreement.  Among other things, no portion of this source
 * code may be copied, transmitted, disclosed, displayed, distributed,
 * translated, used as the basis for a derivative work, or used, in
 * whole or in part, for any program or purpose other than its intended
 * use in compliance with the license agreement as part of UC Innovation's
 * software.  This source code and certain of the algorithms contained
 * within it are confidential trade secrets of UC Innovation, Inc.
 * and may not be used as the basis for any other
 * software, hardware, product or service.
 */
 
 public class PORTAL_TRIG_Transaction {
    public static void run(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete, List<SObject> triggerNewList, List<SObject> triggerOldList) {
        if (isBefore) {
            if (isInsert) {
                // Before Insert
            }
            else if (isUpdate) {
                // Before Update

                // To check is gift processor is assigned, then update the status
                List<Transaction__c> transactionRecList = (List<Transaction__c>) triggerNewList;
                for (Transaction__c transactionRec : transactionRecList) {
                    if (transactionRec.Assigned_Gift_Processor__c != null && transactionRec.Status__c == 'Unassigned') {
                        transactionRec.Status__c = 'In Progress';
                    }
                }
            }
            else if (isDelete) {
                // Before Delete
            }
            else if (isUnDelete) {
                // Before undelete
            }
        }
        if (isAfter) {
            if (isInsert) {
                // After Insert

                // To update record name if auto number on transaction is enabled
                List<Transaction__c> transactionRecList = [SELECT Id, Name, Transaction_Name_Auto_Number__c FROM Transaction__c WHERE Id in: triggerNewList];
                for (Transaction__c transactionRec : transactionRecList) {
                    if (transactionRec.Transaction_Name_Auto_Number__c != null) {
                        transactionRec.Name = transactionRec.Transaction_Name_Auto_Number__c;
                    }
                }

                update transactionRecList;
            }
            else if (isUpdate) {
                // After Update
            }
            else if (isDelete) {
                // After Delete
            }
            else if (isUnDelete) {
                // After Undelete
            }
        }
    }
}