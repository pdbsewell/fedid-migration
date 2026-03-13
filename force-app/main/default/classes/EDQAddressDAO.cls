/**
 * @author      Paul Victoriano
 * @description Wrapper class for Address request and response
 * @group       Wrapper
 * @testclass   EDQAddressDAO_Test
 * @revision    2022-06-17 - Paul Victoriano - Created
**/
public with sharing class EDQAddressDAO {
    //Request
    public class AddressRequest {
        @AuraEnabled
        public String country_iso {
            get; set;
        }
        @AuraEnabled
        public Integer max_suggestions {
            get; set;
        }
        @AuraEnabled
        public AddReqComponents components {
            get; set;
        }
        //
        public AddressRequest() {
            components = new AddReqComponents();
        }

        public AddressRequest(String addressStr) {
            components = new AddReqComponents();
            if (String.isNotBlank(addressStr)) {
                components.unspecified.add(addressStr);
            }
        }
    }

    public class AddReqComponents {
        @AuraEnabled
        public List<String> unspecified {
            get;
            set;
        }
        //
        public AddReqComponents() {
            unspecified = new List<String>();
        }
    }

    //Response Search
    public class AddressResponse {
        @AuraEnabled
        public AddrResult result {
            get;

            set;
        }
    }

    public class AddrResult {
        @AuraEnabled
        public boolean more_results_available;

        @AuraEnabled
        public String confidence;
        @AuraEnabled
        public List<AddrSuggestions> suggestions;
        //
        public AddrResult() {
            suggestions = new List<AddrSuggestions>();
        }
    }

    public class AddrSuggestions {
        @AuraEnabled
        public String global_address_key;

        @AuraEnabled
        public String text;
        @AuraEnabled
        public String format;
        @AuraEnabled
        public List<List<Integer>> matched;
        public AddrSuggestions() {
            matched = new List<List<Integer>>();
        }

    }

    //Address Response Format
    public class AddressFormatResponse {
        @AuraEnabled
        public AddFormResult result;
        @AuraEnabled
        public AddFormMetadata metadata;
    }
    public class AddFormResult {
        @AuraEnabled
		public String global_address_key;	
        @AuraEnabled
		public String confidence;	
        @AuraEnabled
		public AddressFormatted address;
        @AuraEnabled
		public AddressComponents components;
	}
	public class AddressFormatted {
        @AuraEnabled
		public String address_line_1;	//U 102  7 Brighton Rd
        @AuraEnabled
		public String address_line_2;	//
        @AuraEnabled
		public String address_line_3;	//
        @AuraEnabled
		public String locality;	//ST KILDA
        @AuraEnabled
		public String region;	//VIC
        @AuraEnabled
		public String postal_code;	//3182
        @AuraEnabled
		public String country;	//AUSTRALIA
	}

    public class AddressComponents {
        @AuraEnabled
		public String language; //en-GB
        @AuraEnabled
		public String country_name; //AUSTRALIA
        @AuraEnabled
		public String country_iso_3; //AUS
        @AuraEnabled
		public String country_iso_2; //AU-VIC
        @AuraEnabled
		public StreetComponent street;
        @AuraEnabled
		public LocalityComponent locality;
	}

    public class StreetComponent {
        @AuraEnabled
		public String full_name; //Brighton Rd
        @AuraEnabled
		public String name; //Brighton
    }

    public class LocalityComponent {
        @AuraEnabled
		public NameComponent region; //Victoria
        @AuraEnabled
		public NameComponent town; //ST KILDA
        @AuraEnabled
		public NameComponent district;
    }

    public class NameComponent {
        @AuraEnabled
		public String name;
    }

    public class AddFormMetadata {
        @AuraEnabled
		public AddressInfo address_info;
	}

    public class AddressInfo {
        @AuraEnabled
		public AddressIdentifier identifier;
	}

    public class AddressIdentifier {
        @AuraEnabled
		public String dpid;
        @AuraEnabled
		public String hin;
	}
}