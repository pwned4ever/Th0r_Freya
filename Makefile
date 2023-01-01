all::
	xcodebuild clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER="team.p4e.freya" -sdk iphoneos -configuration Debug -quiet
	ln -sf build/Debug-iphoneos Payload
	zip -r9q Freya.ipa Payload/freya.app/
	rm -rf clean build Payload
	
clean::
	rm -rf clean build Payload Freya.ipa

