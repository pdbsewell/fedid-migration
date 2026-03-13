/**
 * @description       : Trigger handler which delegates from Monash's trigger framework(s) to the DLRS (declrarative lookup rollup summaries) implementation. 
 *                      The delegate supports both Triggers.bind() and Triggers.bindExtended()
 * @author            : Stefan Scheit
 * @group             : Trigger Handler
 * @last modified on  : 2020-09-17
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-09-17   Stefan Scheit   Initial Version
**/
public class DlrsDelegateTriggerHandler extends TriggerAbstract implements Triggers.Handler {
    
    // SObjectType for which the DLRS logic should run
    private SObjectType sobjType;
    
    // Public constructor to pass in the SObjectType which is required by DLRS
    public DlrsDelegateTriggerHandler(SObjectType sobjType) {
        this.sobjType = sobjType;
    }
    
    // hide default constructor
    @TestVisible
    private DlrsDelegateTriggerHandler() {
    }
    
    // Implementation for Triggers.bind()
    public void run() {
        this.delegate();
    }
    
    // Implementation/extension for Triggers.bindExtended()
    public override void execute() {
        this.delegate();
    }
    
    // Delegate execution to DLRS rollup service class
    private void delegate() {
        dlrs.RollupService.triggerHandler(this.sobjType);
    }
}