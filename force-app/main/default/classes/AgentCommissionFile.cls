/**
 * @description AgentCommissionFile represent a value object (with some logic) of a journal to be sent (as a file) to SAP.
 *
 * @author Vinothraja
 * @date 2021-07-30
 * @revision 1.0
 **/
public class AgentCommissionFile {

    // properites to be serialised
    public List<Record> recordsList = new List<Record>();

    /**
     * Method to add a line item
     * @param  lineItem The (credit) line item to be added
     */
    public void addRecord(Record record) {
        this.recordsList.add(record);
    }

    /**
     * toStringFixedLength Method to obtain a fixed-length text represenation of the AgentCommission file
     * @return   fixed length text as String incl. line breaks etc.
     */
    public String toStringFixedLength() {
        String strOutput = '';
        // add records
        for (Record record : this.recordsList) {
            strOutput += record.toStringFixedLength();
        }
        return strOutput;
    }

    /**
    * @description AgentCommissionFile.Header represent the header row of a Payment Request (file)
    *
    * @author Vinothraja
    * @date 2021-07-30
    * @revision 1.0
    **/
    public class Header {
        // header fields
        public String sh01 {
            get { return '1'; }
            private set; // always ignored
        }
        public String sh02 {
            get { return 'FB01'; }
            private set; // always ignored
        }
        public String sh03 {
            get {
                return String.isBlank(sh03) ? '' : sh03;
            }
            set {
                if (value.length()>2) {
                    sh03 = value.left(2);
                    //throw new FormatException('Field SH03 cannot be longer than 2 characters');
                } else {
                    sh03 = value;
                }
            }
        }
        public String sh04 {
            get { return ''; }
            private set; // always ignored
        }
        public String sh05 {
            get { return '1000'; }
            private set; // always ignored
        }
        public String sh06 {
            get { return ''; }
            private set; // always ignored
        }
        public String sh07 {
            get {
                return String.isBlank(sh07) ? '' : sh07;
            }
            set {
                if (value.length()>16) {
                    sh07 = value.left(16);
                    //throw new FormatException('Field SH07 cannot be longer than 16 characters');
                } else {
                    sh07 = value;
                }
            }
        }
        public String sh08 {
            get { return ''; }
            private set; // always ignored
        }
        public String sh09 {
            get { 
                return String.isBlank(sh09) ? '' : sh09;
            }
            set {
                sh09 = value;
            } 
        }
        public String sh10 {
            get { return ''; }
            private set; // always ignored
        }
        public String sh11 {
            get { return 'AgentComm'; }
            private set; // always ignored
        }
        public String sh12 {
            get { return 'AUD'; }
            private set; // always ignored
        }
        public String sh13 {
            get { return ''; }
            private set; // always ignored
        }
        public String sh14 {
             get { 
                return String.isBlank(sh14) ? '' : sh14;
            }
            set {
                if (value.length()>15) {
                    sh14 = value.left(15);
                    //throw new FormatException('Field SH14 cannot be longer than 15 characters');
                } else {
                    sh14 = value;
                }
            }
        }
        public String sh15 {
            get { 
                return String.isBlank(sh15) ? '' : sh15;
            }
            set {
                if (value.length()>16) {
                    sh15 = value.left(16);
                    //throw new FormatException('Field SH15 cannot be longer than 16 characters');
                } else {
                    sh15 = value;
                }
            }
        }
        public String sh16 {
            get { 
                return String.isBlank(sh16) ? '' : sh16;
            }
            set {
                if (value.length()>50) {
                    sh16 = value.left(50);
                    //throw new FormatException('Field SH16 cannot be longer than 50 characters');
                } else {
                    sh16 = value;
                }
            }
        }
        public String sh17 {
            get { return ''; }
            private set; // always ignored
        }
        public String toStringFixedLength() {
            String returnStr = '';
            returnStr += this.sh01;
            returnStr += this.sh02.rightPad(20); // pad to length of 20
            returnStr += this.sh03;
            returnStr += this.sh04.rightPad(8);
            returnStr += this.sh05;
            returnStr += this.sh06.rightPad(2);
            returnStr += this.sh07.rightPad(16);
            returnStr += this.sh08.rightPad(2);
            returnStr += this.sh09;
            returnStr += this.sh10.rightPad(1);
            returnStr += this.sh11.rightPad(25);
            returnStr += this.sh12.rightPad(5);
            returnStr += this.sh13.rightPad(11);
            returnStr += this.sh14.rightPad(15);
            returnStr += this.sh15.leftPad(16);
            returnStr += this.sh16.rightPad(50);
            returnStr += this.sh17.rightPad(4);
            return returnStr;
        }
    }
    /**
    * @description AgentCommissionFile.LineItem represent the line item rows of a journal file
    *
    * @author Vinothraja
    * @date 2021-07-30
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
                if (value.length()>16) {
                    sl02 = value.left(16);
                    //throw new FormatException('Field SL02 cannot be longer than 16 characters');
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
                if (value.length()>16) {
                    sl03 = value.left(16);
                    //throw new FormatException('Field SL03 cannot be longer than 16 characters');
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
                    //throw new FormatException('Field SL07 cannot be longer than 50 characters');
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
                if (value.length()>20) {
                    sl08 = value.left(20);
                    //throw new FormatException('Field SL08 cannot be longer than 20 characters');
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
                if (value.length()>10) {
                    sl13 = value.left(10);
                    //throw new FormatException('Field SL13 cannot be longer than 10 characters');
                } else {
                    sl13 = value;
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
            returnStr += this.sl02.leftPad(16); // leftpad with ' ' to total length of 16 (9 digits + "." + 2 digits for cents)
            returnStr += this.sl03.leftPad(16); // leftpad with ' ' to total lenght of 16 (9 digits + "." + 2 digits for cents)
            returnStr += this.sl04.rightPad(7); // rightpad with ' ' to total length of 7
            returnStr += this.sl05.rightPad(6);
            returnStr += this.sl06.rightPad(6);
            returnStr += this.sl07.rightPad(50);
            returnStr += this.sl08.rightPad(20);
            returnStr += this.sl09.rightPad(6);
            returnStr += this.sl10.rightPad(4);
            returnStr += this.sl11.rightPad(2);
            returnStr += this.sl12.leftPad(16);
            returnStr += this.sl13.leftPad(10); // leftpad with ' ' to total length of 10 (7 digits + "." + 2 digits for cents)
            return returnStr;
        }
    }

    /**
    * @description AgentCommissionFile.Record represent the combination of Header and associated line-item rows
    *
    * @author Vinothraja
    * @date 2021-07-29
    * @revision 1.0
    **/
    public class Record {
        public Header header = new Header();
        public List<LineItem> lineItemList = new List<LineItem> ();

        public void addHeader(Header header) {
            this.header = header;
        }

        public void addLineItem(LineItem lineitem) {
            this.lineItemList.add(lineitem);
        }
        /**
         * toStringFixedLength Method to obtain a fixed-length text represenation of the journal file
         * @return   fixed length text as String incl. line breaks etc.
         */
        public String toStringFixedLength() {
            String strOutput = '';
            // add header values (first line of file)
            strOutput += header.toStringFixedLength();
            // add line items
            for (LineItem lineItem : this.lineItemList) {
                strOutput += lineItem.toStringFixedLength();
            }
            strOutput += '\n'; // line break
            return strOutput;
        }
    }
    /**
    * @description Exception class for invalid values passed into a header or line item of a journal (file)
    * @author Vinothraja
    * @date 2021-07-30
    * @revision 1.0
    **/
    private virtual class FormatException extends Exception {
    }
}