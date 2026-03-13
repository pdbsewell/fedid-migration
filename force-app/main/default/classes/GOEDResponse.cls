/****************************************************************************
@Name: GOEDResponse
@Author: Kevin Evasco (GrowthOps)
********************************************************************************/
public class GOEDResponse {
    public static final String SUCCESS = 'SUCCESS';
    public static final String ERROR = 'ERROR';

    public String status = SUCCESS;
    public String msg = '';
    public Object data;
}