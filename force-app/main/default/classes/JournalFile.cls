/**
 * @description JournalFile represent a value object (with some logic) of a journal to be sent (as a file) to SAP.
 *
 * @author Stefan Scheit
 * @date 2019-12-17
 * @revision 1.1
 * Added formatting of PRAX Id to SL08 parameter.
 * Modifications Log 
 * Ver   Date         Author          	Modification
 * 1.1	 28-11-2022   Inderpal Dhanoa   Updated formatting PENGAGE-2480 
 * 1.0   17-12-2019   Stefan Scheit     Initial Version
 * 
 **/
public class JournalFile {
    // Used to identify a PRAX External Gateway Id
    private static final string PRAX_NUMBER_PREFIX = 'PRAX';
    // properites to be serialised
    public Header header = new Header();
    private List<LineItem> creditLineItemList = new List<LineItem>();
    private List<LineItem> debitLineItemList = new List<LineItem>();
    
    /**
     * Method to add a (debit) line item
     * @param  lineItem The (debit) line item to be added
     */
    public void addDebitLineItem(LineItem lineItem) {
        this.debitLineItemList.add(lineItem);
    }
    /**
     * Method to add a (credit) line item
     * @param  lineItem The (credit) line item to be added
     */
    public void addCreditLineItem(LineItem lineItem) {
        this.creditLineItemList.add(lineItem);
    }

    // create JSON payload of the JournalFile
    public String toStringJson() {
        // create a new instance to have a root element for the JSON
        JournalFile jf = new JournalFile();
        jf.header = this.header;
        jf.debitLineItemList = this.debitLineItemList;
        jf.creditLineItemList = this.creditLineItemList;
        return JSON.serializePretty(jf, true);
    }
    /**
     * Method to obtain a CSV represenation of the journal file
     * @return   CSV as String incl. line breaks etc.
     */
    public String toStringCsv() {
        String strOutput = '';
        // return empty string if no credit or debit line items
        if (this.creditLineItemList.isEmpty() || this.debitLineItemList.isEmpty()) {
            return strOutput;
        }
        // add header values (first line of file)
        strOutput += this.header.sh01.escapeCsv() + ',';
        strOutput += this.header.sh02.escapeCsv() + ',';
        strOutput += this.header.sh03.escapeCsv() + ',';
        strOutput += this.header.sh04.escapeCsv() + ',';
        strOutput += this.header.sh05.escapeCsv() + ',';
        strOutput += this.header.sh06.escapeCsv() + ',';
        strOutput += this.header.sh07.escapeCsv() + ',';
        strOutput += this.header.sh08.escapeCsv() + ',';
        strOutput += this.header.sh09.escapeCsv() + ',';
        strOutput += this.header.sh10.escapeCsv() + ',';
        strOutput += this.header.sh11.escapeCsv() + ',';
        strOutput += this.header.sh12.escapeCsv() + ',';
        strOutput += this.header.sh13.escapeCsv() + ',';
        strOutput += this.header.sh14.escapeCsv();
        // add credit line items
        for (LineItem lineItem : this.creditLineItemList) {
            strOutput += '\n'; // line break
            strOutput += lineItem.sl01.escapeCsv() + ',';
            strOutput += lineItem.sl02.escapeCsv() + ',';
            strOutput += lineItem.sl03.escapeCsv() + ',';
            strOutput += lineItem.sl04.escapeCsv() + ',';
            strOutput += lineItem.sl05.escapeCsv() + ',';
            strOutput += lineItem.sl06.escapeCsv() + ',';
            strOutput += lineItem.sl07.escapeCsv() + ',';
            strOutput += lineItem.sl08.escapeCsv() + ',';
            strOutput += lineItem.sl09.escapeCsv() + ',';
            strOutput += lineItem.sl10.escapeCsv() + ',';
            strOutput += lineItem.sl11.escapeCsv() + ',';
            strOutput += lineItem.sl12.escapeCsv() + ',';
            strOutput += lineItem.sl13.escapeCsv() + ',';
            strOutput += lineItem.sl14.escapeCsv();
        }
        // add debit line items
        for (LineItem lineItem : this.debitLineItemList) {
            strOutput += '\n'; // line break
            strOutput += lineItem.sl01.escapeCsv() + ',';
            strOutput += lineItem.sl02.escapeCsv() + ',';
            strOutput += lineItem.sl03.escapeCsv() + ',';
            strOutput += lineItem.sl04.escapeCsv() + ',';
            strOutput += lineItem.sl05.escapeCsv() + ',';
            strOutput += lineItem.sl06.escapeCsv() + ',';
            strOutput += lineItem.sl07.escapeCsv() + ',';
            strOutput += lineItem.sl08.escapeCsv() + ',';
            strOutput += lineItem.sl09.escapeCsv() + ',';
            strOutput += lineItem.sl10.escapeCsv() + ',';
            strOutput += lineItem.sl11.escapeCsv() + ',';
            strOutput += lineItem.sl12.escapeCsv() + ',';
            strOutput += lineItem.sl13.escapeCsv() + ',';
            strOutput += lineItem.sl14.escapeCsv();
        }
        return strOutput;
    }
    /**
     * getCsv Method to obtain a fixed-length text represenation of the journal file
     * @return   fixed length text as String incl. line breaks etc.
     */
    public  String toStringFixedLength() {
        String strOutput = '';
        // return empty string if no credit or debit line items
        if (this.creditLineItemList.isEmpty()) {
            return strOutput;
        }
        // add header values (first line of file)
        strOutput += header.toStringFixedLength();
        // add credit line items
        for (LineItem lineItem : this.creditLineItemList) {
            strOutput += lineItem.toStringFixedLength();
        }
        // add debit line items
        for (LineItem lineItem : this.debitLineItemList) {
            strOutput += lineItem.toStringFixedLength();
        }
        return strOutput;
    }
    /**
    * @description JournalFile.Header represent the header row of a journal (file)
    *
    * @author Stefan Scheit
    * @date 2019-11-13
    * @revision 1.0
    **/
    public class Header {
        // header fields
        String sh01 {
            get { return '1'; }
            private set; // always ignored
        }
        String sh02 {
            get { return 'FB01'; }
            private set; // always ignored
        }
        String sh03 {
            get { return 'SA'; }
            private set; // always ignored
        }
        String sh04 {
            get { return Datetime.now().format('ddMMyyyy'); }
            private set; // always ignored
        }
        String sh05 {
            get { return '1000'; }
            private set; // always ignored
        }
        String sh06 {
            get { return Datetime.now().format('MM'); }
            private set; // always ignored
        }
        String sh07 {
            get { return '371' + Datetime.now().format('ddMMYYHHmmss'); }
            private set; // always ignored
        }
        String sh08 {
            get { return ''; }
            private set; // always ignored
        }
        String sh09 {
            get { return sh04; }
            private set; // always ignored
        }
        String sh10 {
            get { return ''; }
            private set; // always ignored
        }
        String sh11 {
            get { return 'ERDA Help Desk Ext 34809'; }
            private set; // always ignored
        }
        String sh12 {
            get { return 'AUD'; }
            private set; // always ignored
        }
        String sh13 {
            get { return ''; }
            private set; // always ignored
        }
        String sh14 {
            get { return ''; }
            private set; // always ignored
        }
        String sh15 {
            get { return ''; }
            private set; // always ignored
        }
        public String toStringFixedLength() {
            String returnStr = '';
            returnStr += this.sh01;
            returnStr += this.sh02.rightPad(20); // pad to length of 20
            returnStr += this.sh03;
            returnStr += this.sh04;
            returnStr += this.sh05;
            returnStr += this.sh06;
            returnStr += this.sh07.rightPad(16);
            returnStr += this.sh08.rightPad(3);
            returnStr += this.sh09;
            returnStr += this.sh10.rightPad(1);
            returnStr += this.sh11.rightPad(25);
            returnStr += this.sh12.rightPad(5);
            returnStr += this.sh13.rightPad(10);
            returnStr += this.sh14.rightPad(1);
            returnStr += this.sh15.rightPad(1);
            return returnStr;
        }
    }
    /**
    * @description JournalFile.LineItem represent the line item rows of a journal file
    *
    * @author Stefan Scheit
    * @date 2019-11-13
    * @revision 1.0
    **/
    public class LineItem {
        	
        // line item fields
        public String sl01 {
            get { return '2'; }
            private set; // always ignored
        }
        public String sl02 {
            get {
                return String.isBlank(sl02) ? '' : sl02;
            }
            set {
                if (value.length()>12) {
                    sl02 = value.left(12);
                    //throw new FormatException('Field SL02 cannot be longer than 12 characters');
                } else {
                    sl02 = value;
                }
            }
        }
        public String sl03 {
            get {
                return String.isBlank(sl03) ? '' : sl03;
            }
            set {
                if (value.length()>12) {
                    sl03 = value.left(12);
                    //throw new FormatException('Field SL03 cannot be longer than 12 characters');
                } else {
                    sl03 = value;
                }
            }
        }
        public String sl04 {
            get {
                return String.isBlank(sl04) ? '' : sl04;
            }
            set {
                if (value.length()>7) {
                    sl04 = value.left(7);
                    //throw new FormatException('Field SL04 cannot be longer than 7 characters');
                }
                else{
                    sl04 = value;
                }
            }
        }
        public String sl05 {
            get {
                return String.isBlank(sl05) ? '' : sl05;
            }
            set {
                if (value.length()>6) {
                    sl05 = value.left(6);
                    //throw new FormatException('Field SL05 cannot be longer than 6 characters');
                } else {
                    sl05 = value;
                }
            }
        }
        public String sl06 {
            get {
                return String.isBlank(sl06) ? '' : sl06;
            }
            set {
                if (value.length()>6) {
                    sl06 = value.left(6);
                    //throw new FormatException('Field SL06 cannot be longer than 6 characters');
                } else {
                    sl06 = value;
                }
            }
        }
        public String sl07 {
            get {
                return String.isBlank(sl07) ? '' : sl07;
            }
            set {
                if (value.length()>50) {
                    sl07 = value.left(50);
                    //throw new FormatException('Field SL07 cannot be longer than 20 characters');
                } else {
                    sl07 = value;
                }
            }
        }
        public String sl08 {
            get {
                return String.isBlank(sl08) ? '' : sl08;
            }
            set {
                 //If this field has a PRAX- number (example: PRAX-081821-082411849) then remove initial 3 characters ‘Pra’ and populate field with remaining 18 characters (X-081821-082411849) 
                if (value.left(PRAX_NUMBER_PREFIX.length()) == PRAX_NUMBER_PREFIX) {
                    value = value.right(value.length()-3);
                } else {
                    sl08 = value;
                }
            }
        }
        public String sl09 {
            get {
                return String.isBlank(sl09) ? '' : sl09;
            }
            set {
                if (value.length()>6) {
                    sl09 = value.left(6);
                    //throw new FormatException('Field SL09 cannot be longer than 6 characters');
                } else {
                    sl09 = value;
                }
            }
        }
        public String sl10 {
            get {
                return String.isBlank(sl10) ? '' : sl10;
            }
            set {
                if (value.length()>4) {
                    sl10 = value.left(4);
                    //throw new FormatException('Field SL10 cannot be longer than 4 characters');
                } else {
                    sl10 = value;
                }
            }
        }
        public String sl11 {
            get {
                return String.isBlank(sl11) ? '' : sl11;
            }
            set {
                if (value.length()>2) {
                    sl11 = value.left(2);
                    //throw new FormatException('Field SL11 cannot be longer than 2 characters');
                } else {
                    sl11 = value;
                }
            }
        }
        public String sl12 {
            get {
                return String.isBlank(sl12) ? '' : sl12;
            }
            set {
                if (value.length()>16) {
                    sl12 = value.left(16);
                    //throw new FormatException('Field SL12 cannot be longer than 16 characters');
                } else {
                    sl12 = value;
                }
            }
        }
        public String sl13 {
            get {
                return String.isBlank(sl13) ? '' : sl13;
            }
            set {
                if (value.length()>2) {
                    sl13 = value.left(2);
                    //throw new FormatException('Field SL13 cannot be longer than 2 characters');
                } else {
                    sl13 = value;
                }
            }
        }
        public String sl14 {
            get {
                return String.isBlank(sl14) ? '' : sl14;
            }
            set {
                if (value.length()>11) {
                    sl14 = value.left(11);
                    //throw new FormatException('Field SL14 cannot be longer than 11 characters');
                } else {
                    sl14 = value;
                }
            }
        }
        /**
         * Create a fixed-length text representation of a line item
         * @return   String as fixed-length text representation of a line item
         */
        public String toStringFixedLength() {
            String returnStr = '';
            returnStr += '\n'; // line break
            returnStr += this.sl01; // fixed value
            returnStr += this.sl02.leftPad(12); // leftpad with ' ' to total length of 12 (9 digits + "." + 2 digits for cents)
            returnStr += this.sl03.leftPad(12); // leftpad with ' ' to total lenght of 12 (9 digits + "." + 2 digits for cents)
            returnStr += this.sl04.rightPad(7); // rightpad with ' ' to total length of 7
            returnStr += this.sl05.rightPad(6);
            returnStr += this.sl06.rightPad(6);
            returnStr += this.sl07.rightPad(50);
            returnStr += this.sl08.rightPad(20);
            returnStr += this.sl09.rightPad(6);
            returnStr += this.sl10.rightPad(4);
            returnStr += this.sl11.rightPad(2);
            returnStr += this.sl12.rightPad(16);
            returnStr += this.sl13.rightPad(2);
            returnStr += this.sl14.leftPad(11); // leftpad with ' ' to total length of 11 (8 digits + "." + 2 digits for cents)
            return returnStr;
        }
    }
    /**
    * @description Exception class for invalid values passed into a header or line item of a journal (file)
    * @author Stefan Scheit
    * @date 2019-11-13
    * @revision 1.0
    **/
    private virtual class FormatException extends Exception {
    }
}