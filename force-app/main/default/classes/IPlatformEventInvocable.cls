/**
 * @File Name          : IPlatformEventInvocable.cls
 * @Description        : Interface for Platform Event invocable classes
 * @Author             : Nick Guia
 * @Group              : Commons
 **/
public interface IPlatformEventInvocable {

    /**
    * @description execute logic for processing
    * @param param : a class instance of AsyncProcessPayload to cater
    *   for multiple class parameters with dynamic data type
    * @return void
    **/
    void execute(List<AsyncProcessPayload> param);
}