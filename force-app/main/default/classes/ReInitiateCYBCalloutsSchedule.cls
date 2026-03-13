/**
 * @description       : Class to invoke ReInitiateFailedCybersourceCallouts
 * @author            : Inderpal Dhanoa
 * @group             : Engage
 * @last modified on  : 2023-01-23
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2023-01-23 - Inderpal Dhanoa - Initial Version
**/
public with sharing class ReInitiateCYBCalloutsSchedule implements Schedulable{

    private String s_failedExternalGatewayAccount, s_dependentExternalGatewayAccount;

    public ReInitiateCYBCalloutsSchedule(String s_failedExternalGatewayAccount, String s_dependentExternalGatewayAccount){
        this.s_failedExternalGatewayAccount = s_failedExternalGatewayAccount;
        this.s_dependentExternalGatewayAccount = s_dependentExternalGatewayAccount;
    }

    public void execute(SchedulableContext sc) {
        ReInitiateFailedCybersourceCallouts obj = new ReInitiateFailedCybersourceCallouts();
        obj.setRetriesOnAutomatedLogs(s_failedExternalGatewayAccount, s_dependentExternalGatewayAccount);
    }
}