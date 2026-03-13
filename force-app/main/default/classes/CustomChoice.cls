/**
* @description Apex defined variable class used in 'SCR-ACP-Outcome Assistant:Rejected' Flow and 'NextNonRejectedACPController' class
* @author      Sravani Naramsetti
* @date        16/01/2025
* @group       Admissions
*/
public with sharing class CustomChoice {
  @AuraEnabled
  public String label; 

  @AuraEnabled
  public String value;

  public CustomChoice(String label, String value) {
    this.label = label;
    this.value = value;
  }
    
  public CustomChoice() {
      
  }
}