/**
 * @author Peter Sewell
 * @date 20/09/2021
 * @description Trigger on Break Glass Platform Event to send alert via email and callout
 */
trigger BreakGlassAlertTrigger on BreakGlassAlert__e (after insert) {
    //P.Victoriano - Excemption to use Trigger Pattern as this is scoped and not to be bypassed
    BreakGlassAlert.handleAlertEvent(Trigger.new);
}