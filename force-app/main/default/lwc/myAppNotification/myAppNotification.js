import { api, LightningElement } from 'lwc';
/**
 * A notification component that displays a message with an icon.
 */
export default class MyAppNotification extends LightningElement {
	@api message; // Notification message
	@api variant; // Variant type (can be passed as null)
	_iconName; // Default icon is warning
	// Getter for iconName
	get iconName() {
		switch (this.variant) {
			// case 'error':
			//     this._iconName = 'utility:error';
			//     break;
			case 'warning':
				this._iconName = 'utility:warning';
				break;
			// case 'success':
			//     this._iconName = 'utility:success';
			//     break;
			// case 'info':
			//     this._iconName = 'utility:info';
			//     break;
			default:
				this._iconName = 'utility:info';
		}
		// Return the variant if it exists, otherwise return the default (_iconName)
		return this._iconName;
	}
	// Setter for iconName
	set iconName(value) {
		this._iconName = value || 'utility:info'; // If value is not set, fallback to default
	}
}