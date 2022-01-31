// THIS CONTRACT WAS WRITTEN BEFORE THE LATEST RELEASES. THEREFORE, IT HAS TO BE CORRECTED WITH THE NEW FUNCTIONS (ITOA, ATOI, MAPSTORE etc.)

Function Initialize() Uint64
10  STORE("type", "MARKETPLACE_1.0.0")
20  STORE("title", "Marketplace title goes here")
30  STORE("description", "Marketplace description goes here.")
40  STORE("registrationsOpen", 1) // bool
50  STORE("registrationFee", 50000) // 0.5 DERO to register as a vendor. Tunable. To avoid spamming.
60  STORE("reviewFee", 1000) // 0.01 DERO to leave a review. Tunable. To avoid spamming. Also, only one review for each vendor is allowed by the same customer.
70  STORE("vendorsCount", 0)
80  STORE("owner", SIGNER())
90  STORE("balance", 0)
100  RETURN 0
End Function

// Internal utility functions

// Fixed version of ADDRESS_RAW. Avoids panics when trying to convert an adddress which is already in raw form. Instead, returns the raw address itself. Still panics if the address is actually invalid.
Function addressRaw(address String) String
10  IF IS_ADDRESS_VALID(address) THEN GOTO 20
11  RETURN ADDRESS_RAW(address)

20  RETURN address
End Function

// Version of SEND_DERO_TO_ADDRESS that keeps 0.00001 DERO from the transaction. Needed because the contract won't work without at least 0.00001 DERO inside.
// In a future where SC TXs on mainnet will require the payment of a fee, this function can be updated to subtract the cost of the fee as well.
Function sendDeroToAddress(address String, amount Uint64) Uint64
10  DIM actualAmount as Uint64
11  LET actualAmount = 0

20  IF amount <= 1 THEN GOTO 50

30  LET actualAmount = amount - 1
40  SEND_DERO_TO_ADDRESS(addressRaw(address), actualAmount)
50  RETURN actualAmount
End Function

Function isOwner() Uint64
10  IF LOAD("owner") == SIGNER() THEN GOTO 20
11  RETURN 0

20  RETURN 1
End Function

// Boilerplate functions

Function TransferOwnership(newOwner String) Uint64 
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  STORE("tmpOwner", addressRaw(newOwner))
30  RETURN 0
End Function

Function ClaimOwnership() Uint64 
10  IF EXISTS("tmpOwner") THEN GOTO 20
11  RETURN 1

20  IF LOAD("tmpOwner") == SIGNER() THEN GOTO 30
21  RETURN 2

30  STORE("owner", SIGNER())
40  RETURN 0
End Function

Function UpdateCode(code String) Uint64 
10  IF isOwner() THEN GOTO 20 
11  RETURN 1

20  UPDATE_SC_CODE(code)
30  RETURN 0
End Function

// Owner functions

Function Withdraw(amount Uint64) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  IF LOAD("balance") >= amount THEN GOTO 30
21  RETURN 2

30  DIM actualAmount as Uint64
40  LET actualAmount = sendDeroToAddress(SIGNER(), amount)
50  STORE("balance", LOAD("balance") - actualAmount)
60  RETURN 0
End Function

// Ignores the stored "balance" variable.
// Felt the need to add this functions because SCs can (perhaps mistakenly) receive coins through functions that don't update the value of "balance".
// Note to self: for this reason, this function could replace the standard Withdraw function altogether and the "balance" variable could be gotten rid of completely since there are ways to get the balance of a SC from outside without it.
// User will just have to be careful with the amount typed to avoid panics.
Function ForceWithdraw(amount Uint64) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

30  DIM actualAmount as Uint64
40  LET actualAmount = sendDeroToAddress(SIGNER(), amount)
50  STORE("balance", LOAD("balance") - actualAmount)
60  RETURN 0
End Function

Function EditMarketplaceInfo(title String, description String) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  IF title == "" THEN GOTO 30
21  STORE("title", title)

30  IF description == "" THEN GOTO 40
31  STORE("description", description)

40  RETURN 0
End Function

Function SetRegistrationsOpen(open Uint64) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  IF open <= 1 THEN GOTO 30 // open is a boolean.
21  RETURN 1

30  STORE("registrationsOpen", open)
40  RETURN 0
End Function

Function TuneMarketplaceFees(registrationFee Uint64, reviewFee Uint64) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  STORE("registrationFee", registrationFee)
30  STORE("reviewFee", reviewFee)
40  RETURN 0
End Function

// If you want to make this an absolutely free market where the owner of the contract cannot ban the vendors, then comment out this function.
Function SetVendorBan(vendorID Uint64, isBanned Uint64, reason String) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  IF isBanned <= 1 THEN GOTO 30 // isBanned is a boolean.
21  RETURN 2

30  IF EXISTS("VENDOR_"+vendorID+"_IsBanned") THEN GOTO 40 // Make sure vendor exists.
31  RETURN 3

40  STORE("VENDOR_"+vendorID+"_IsBanned", isBanned)

50  IF isBanned == 1 THEN GOTO 60
51  STORE("VENDOR_"+vendorID+"_BanReason", "")
52  RETURN 0

60  STORE("VENDOR_"+vendorID+"_BanReason", reason)
70  RETURN 0
End Function

// Vendor functions

Function RegisterAsVendor(address String, name String, description String, inventoryURI String) Uint64
10  IF DEROVALUE() >= LOAD("registrationFee") THEN GOTO 20 // Registration fee must be paid in full.
11  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
12  RETURN 0

20  IF LOAD("registrationsOpen") == 1 THEN GOTO 30
21  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
22  RETURN 0

30  IF ADDRESS_RAW(address) == SIGNER() THEN GOTO 40 // Address can be registered only by its owner.
31  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
32  RETURN 0

40  DIM id as Uint64
41  LET id = getVendorID(SIGNER())

50  IF id == 0 THEN GOTO 80

60  IF isVendorRegistered(id) == 0 THEN GOTO 70 // Make sure user isn't registered already.
61  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
62  RETURN 0

// Vendor had already been registered before but then deregistered. No need to create whole account from scratch.
70  STORE("VENDOR_"+id+"_Name", name)
71  STORE("VENDOR_"+id+"_Description", description)
72  STORE("VENDOR_"+id+"_OffChainJSONInventoryURI", inventoryURI)
73  STORE("VENDOR_"+id+"_IsRegistered", 1)
74  STORE("balance", LOAD("balance") + DEROVALUE())
75  RETURN 0

// Create new vendor.
80  LET id = LOAD("vendorsCount") + 1
81  STORE("vendorsCount", id)
82  STORE("VENDOR_"+id+"_Address", address)
83  STORE("VENDOR_"+id+"_Name", name)
84  STORE("VENDOR_"+id+"_Description", description)
85  STORE("VENDOR_"+id+"_OffChainJSONInventoryURI", inventoryURI)
86  STORE("VENDOR_"+id+"_OnChainJSONInventory", "")
87  STORE("VENDOR_"+id+"_IsRegistered", 1)
88  STORE("VENDOR_"+id+"_IsBanned", 0)
89  STORE("VENDOR_"+id+"_BanReason", "")
90  STORE("VENDOR_"+id+"_RegisteredAtTopoHeight", BLOCK_TOPOHEIGHT())
91  STORE("VENDOR_"+id+"_ProductsCount", 0)
92  STORE("VENDOR_"+id+"_TotalStars", 0)
93  STORE("VENDOR_"+id+"_ReviewsCount", 0)
94  STORE(SIGNER()+"_VendorID", id)
95  STORE("balance", LOAD("balance") + DEROVALUE())
96  RETURN 0
End Function

Function DeregisterAsVendor() Uint64
10  DIM id as Uint64
11  LET id = getVendorID(SIGNER())

20  IF id != 0 THEN GOTO 30
21  RETURN 1

30  IF isVendorRegistered(id) THEN GOTO 40
31  RETURN 2

40  STORE("VENDOR_"+id+"_Name", "")
50  STORE("VENDOR_"+id+"_Description", "")
60  STORE("VENDOR_"+id+"_OffChainJSONInventoryURI", "")
70  STORE("VENDOR_"+id+"_OnChainJSONInventory", "")
80  STORE("VENDOR_"+id+"_IsRegistered", 0)
90  RETURN 0
End Function

Function EditVendorInfo(name String, description String, inventoryURI String) Uint64
10  DIM id as Uint64
11  LET id = getVendorID(SIGNER())

20  IF id != 0 THEN GOTO 30
21  RETURN 1

30  IF isVendorRegistered(id) THEN GOTO 40
31  RETURN 2

40  IF name == "" THEN GOTO 50
41  STORE("VENDOR_"+id+"_Name", name)

50  IF description == "" THEN GOTO 60
51  STORE("VENDOR_"+id+"_Description", description)

60  IF inventoryURI == "" THEN GOTO 70
61  STORE("VENDOR_"+id+"_OffChainJSONInventoryURI", inventoryURI)

70  RETURN 0
End Function

Function SetOnChainJSONInventory(content String) Uint64
10  DIM id as Uint64
11  LET id = getVendorID(SIGNER())

20  IF id != 0 THEN GOTO 30
21  RETURN 1

30  IF isVendorRegistered(id) THEN GOTO 40
31  RETURN 2

40  STORE("VENDOR_"+id+"_OnChainJSONInventory", content)
50  RETURN 0
End Function

Function AddProduct(name String, description String, price Uint64, isAvailable Uint64, imageURI String) Uint64
10  IF isAvailable <= 1 THEN GOTO 20 // isAvailable is a boolean.
11  RETURN 1

20  DIM vendorID as Uint64
21  LET vendorID = getVendorID(SIGNER())

30  IF vendorID != 0 THEN GOTO 40
31  RETURN 2

40  IF isVendorBanned(vendorID) == 0 THEN GOTO 50 // Banned vendors cannot add new products.
41  RETURN 3

50  DIM productID as Uint64
51  LET productID = LOAD("VENDOR_"+vendorID+"_ProductsCount") + 1
60  STORE("VENDOR_"+vendorID+"_ProductsCount", productID)
70  setProductValues(vendorID, productID, name, description, price, isAvailable, imageURI, 0)
80  RETURN 0
End Function

Function EditProduct(productID Uint64, name String, description String, price Uint64, isAvailable Uint64, imageURI String, isRemoved Uint64) Uint64
10  IF isAvailable <= 1 THEN GOTO 20 // isAvailable is a boolean.
11  RETURN 1

20  IF isRemoved <= 1 THEN GOTO 30 // isRemoved is a boolean.
21  RETURN 2

30  DIM vendorID as Uint64
31  LET vendorID = getVendorID(SIGNER())

40  IF EXISTS("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_Name") THEN GOTO 50 // Make sure product exists.
41  RETURN 3

50  setProductValues(vendorID, productID, name, description, price, isAvailable, imageURI, isRemoved)
60  RETURN 0
End Function

// Shorthand for EditProduct that does not requrie all the other parameters.
Function SetProductAvailability(productID Uint64, isAvailable Uint64) Uint64
10  IF isAvailable <= 1 THEN GOTO 20 // isAvailable is a boolean.
11  RETURN 1

20  DIM vendorID as Uint64
21  LET vendorID = getVendorID(SIGNER())

30  IF EXISTS("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_IsAvailable") THEN GOTO 40 // Make sure product exists.
31  RETURN 2

40  STORE("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_IsAvailable", isAvailable)
50  RETURN 0
End Function

// Shorthand for EditProduct that does not requrie all the other parameters.
Function SetProductRemoval(productID Uint64, isRemoved Uint64) Uint64
10  IF isRemoved <= 1 THEN GOTO 20 // isRemoved is a boolean.
11  RETURN 1

20  DIM vendorID as Uint64
21  LET vendorID = getVendorID(SIGNER())

30  IF EXISTS("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_IsRemoved") THEN GOTO 40 // Make sure product exists.
31  RETURN 2

40  STORE("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_IsRemoved", isRemoved)
50  RETURN 0
End Function

Function ResetCatalog() Uint64
10  DIM vendorID as Uint64
11  LET vendorID = getVendorID(SIGNER())

20  IF vendorID != 0 THEN GOTO 30
21  RETURN 1

30  STORE("VENDOR_"+vendorID+"_ProductsCount", 0)
40  RETURN 0
End Function

Function ReplyToReview(reviewID Uint64, reply String) Uint64
10  DIM vendorID as Uint64
11  LET vendorID = getVendorID(SIGNER())

20  IF EXISTS("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_Stars") THEN GOTO 30 // Make sure review exists.
21  RETURN 1

30  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_Reply", reply)
40  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_ReplyTopoHeight", BLOCK_TOPOHEIGHT())
50  RETURN 0
End Function

// Internal vendor functions

Function getVendorID(rawAddress String) Uint64
10  IF EXISTS(rawAddress+"_VendorID") THEN GOTO 20
11  RETURN 0

20  RETURN LOAD(rawAddress+"_VendorID")
End Function

Function getVendorAddress(id Uint64) String
10  IF EXISTS("VENDOR_"+id+"_Address") THEN GOTO 20
11  RETURN ""

20  RETURN LOAD("VENDOR_"+id+"_Address")
End Function

Function isVendorRegistered(id Uint64) Uint64
10  RETURN LOAD("VENDOR_"+id+"_IsRegistered")
End Function

Function isVendorBanned(id Uint64) Uint64
10  RETURN LOAD("VENDOR_"+id+"_IsBanned")
End Function

Function setProductValues(vendorID Uint64, productID Uint64, name String, description String, price Uint64, isAvailable Uint64, imageURI String, isRemoved Uint64) Uint64
10  STORE("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_Name", name)
20  STORE("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_Description", description)
30  STORE("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_Price", price)
40  STORE("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_IsAvailable", isAvailable)
50  STORE("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_ImageURI", imageURI)
60  STORE("VENDOR_"+vendorID+"_PRODUCT_"+productID+"_IsRemoved", isRemoved)
70  RETURN 0
End Function

// Customer functions

Function ReviewVendor(vendorID Uint64, stars Uint64, comment String) Uint64
10  IF DEROVALUE() >= LOAD("reviewFee") THEN GOTO 20 // Review fee must be paid in full.
11  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
12  RETURN 0

20  DIM address as String
21  LET address = getVendorAddress(vendorID)

30  IF address != "" THEN GOTO 40 // Make sure vendor exists.
31  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
32  RETURN 0

40  IF ADDRESS_RAW(address) != SIGNER() THEN GOTO 50 // Vendors cannot review themselves.
41  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
42  RETURN 0

50  IF stars >= 1 && stars <= 5 THEN GOTO 60
51  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
52  RETURN 0

60  STORE("balance", LOAD("balance") + DEROVALUE())

70  DIM reviewID as Uint64
71  LET reviewID = getVendorReviewIDByAuthor(vendorID, SIGNER())

80  IF reviewID == 0 THEN GOTO 100

// Edit existing review of the vendor by the author. Customers can leave only one review for each vendor.
90  STORE("VENDOR_"+vendorID+"_TotalStars", LOAD("VENDOR_"+vendorID+"_TotalStars") - LOAD("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_Stars") + stars)
91  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_Stars", stars)
92  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_Comment", comment)
93  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_TopoHeight", BLOCK_TOPOHEIGHT())
94  RETURN 0

// Create new review of the vendor by the author.
100  LET reviewID = LOAD("VENDOR_"+vendorID+"_ReviewsCount") + 1
101  STORE("VENDOR_"+vendorID+"_ReviewsCount", reviewID)
102  STORE("VENDOR_"+vendorID+"_TotalStars", LOAD("VENDOR_"+vendorID+"_TotalStars") + stars)
103  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_Stars", stars)
104  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_Comment", comment)
105  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_TopoHeight", BLOCK_TOPOHEIGHT())
106  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_Author", SIGNER())
107  STORE("VENDOR_"+vendorID+"_ReviewIDByAuthor_"+SIGNER(), reviewID)
108  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_Reply", "")
109  STORE("VENDOR_"+vendorID+"_REVIEW_"+reviewID+"_ReplyTopoHeight", 0)
110  RETURN 0
End Function

// Internal customer functions

Function getVendorReviewIDByAuthor(vendorID Uint64, authorRawAddress String) Uint64
10  IF EXISTS("VENDOR_"+vendorID+"_ReviewIDByAuthor_"+authorRawAddress) THEN GOTO 20
11  RETURN 0

20  RETURN LOAD("VENDOR_"+vendorID+"_ReviewIDByAuthor_"+authorRawAddress)
End Function
