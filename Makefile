all::
	xcodebuild clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER="team.ziyou.ziyou" -sdk iphoneos -configuration Debug -quiet
	ln -sf build/Debug-iphoneos Payload
	zip -r9q Ziyou.ipa Payload/Ziyou.app/
	rm -rf clean build Payload
	
clean::
	rm -rf clean build Payload Ziyou.ipa

