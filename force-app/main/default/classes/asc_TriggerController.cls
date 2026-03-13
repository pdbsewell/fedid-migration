//Added by UC Innovation to override Out of the Box Review Transaction logic - 2019-09-19

public with sharing class asc_TriggerController {

    

    public static Boolean ReviewTransactionHandlerIsRunning = true;
    public static Boolean HardSoftTriggerIsRunning = false;
    public static Boolean Payment_CreateMatchingGift_WantRun = true;

    
}