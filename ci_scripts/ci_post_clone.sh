#!/bin/sh

#  ci_post_clone.sh
#  Satafood
#
#  Created by hadeer kamel on 05/09/2022.
#  Copyright © 2022 Xicom. All rights reserved.


# Install CocoaPods using Homebrew.
brew install cocoapods

# Install dependencies you manage with CocoaPods.
pod install
