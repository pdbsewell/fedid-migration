/**
 * @author      K Liew
 * @description Creates Chargent Order and performs Charge
 * @date        22 Feb 2019
 * @group       Chargent related classes
 * @description Class modelling JSON needed for calling Chargent's ChargeOrder_ClickJSON method
 * @revision Trent De Laney - 29/11/2019 - Renamed function for consistency across outbound messages
 */

public class ObdChargentRequest {

    public ObdChargentRequest() {}

    public String ObjectId {get; set;}
    public String CardSecurity {get; set;}
    public String CardMonth {get; set;}
    public String CardYear {get; set;}
    public String PaymentMethod {get; set;}
    public String CardType {get; set;}

    public String CardNumber {get; set;}
    public Decimal ChargeAmount {get; set;}

}