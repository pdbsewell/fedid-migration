/*******************************************************************************
* @author:      K Liew
* @date:        15.Nov.2018
* @description: Wrapper code to expose necessary method in CommonUtilities to be
*               consumable in PBs / Flows.
* @revision:
*               15.Nov.2018 KL > Initial class creation.
*******************************************************************************/

public class AM_Utilities  {

    @InvocableMethod(label='Format Contact Name' description='Common method used to standardise Contact Name formatting')
    public static List<String> formatContactName (List<String> inStrings) {

        List<String> outStrings = new List<String>();
        
        for (String valInLoop : inStrings) {
            outStrings.add(CommonUtilities.correctName(valInLoop));
        }
        
        return outStrings;
    }

}