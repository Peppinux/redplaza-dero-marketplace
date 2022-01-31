// THIS CONTRACT WAS WRITTEN BEFORE THE LATEST RELEASES. THEREFORE, IT HAS TO BE CORRECTED WITH THE NEW FUNCTIONS (ITOA, ATOI, MAPSTORE etc.)

Function Initialize() Uint64
10  STORE("type", "PERSONALSTORE_1.0.0")
20  STORE("title", "Store title goes here")
30  STORE("description", "Store description goes here.")
40  STORE("ownerAddress", "OWNER_ADDRESS_GOES_HERE") // Different from the "owner" variable as this will hold the human-readable address. Make sure to write it correctly as this is going to be the address shown to customers.
50  STORE("offChainJSONInventoryURI", "") // Set the URI of the off-chain inventory here or leave it blank and use EditStoreInfo at a later time.
60  STORE("onChainJSONInventory", "") // Set the on-chain inventory here or leave it blank and use SetOnChainJSONInventory at a later time.
70  STORE("reviewFee", 1000) // 0.01 DERO to leave a review. Tunable. To avoid spamming. Also, only one review is allowed by the same customer.
80  STORE("productsCount", 0)
90  STORE("totalStars", 0)
100  STORE("reviewsCount", 0)
110  STORE("owner", SIGNER())
120  STORE("balance", 0)
130  RETURN 0
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

// Owner/Store functions

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

Function TuneReviewFee(reviewFee Uint64) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  STORE("reviewFee", reviewFee)
30  RETURN 0
End Function

Function EditStoreInfo(title String, description String, inventoryURI String) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  IF title == "" THEN GOTO 30
21  STORE("title", title)

30  IF description == "" THEN GOTO 40
31  STORE("description", description)

40  IF inventoryURI == "" THEN GOTO 50
41  STORE("offChainJSONInventoryURI", inventoryURI)

50  RETURN 0
End Function

Function SetOnChainJSONInventory(content String) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

40  STORE("onChainJSONInventory", content)
50  RETURN 0
End Function

Function AddProduct(name String, description String, price Uint64, isAvailable Uint64, imageURI String) Uint64
10  IF isAvailable <= 1 THEN GOTO 20 // isAvailable is a boolean.
11  RETURN 1

20  IF isOwner() THEN GOTO 30
21  RETURN 2

30  DIM productID as Uint64
31  LET productID = LOAD("productsCount") + 1
40  STORE("productsCount", productID)
50  setProductValues(productID, name, description, price, isAvailable, imageURI, 0)
60  RETURN 0
End Function

Function EditProduct(productID Uint64, name String, description String, price Uint64, isAvailable Uint64, imageURI String, isRemoved Uint64) Uint64
10  IF isAvailable <= 1 THEN GOTO 20 // isAvailable is a boolean.
11  RETURN 1

20  IF isRemoved <= 1 THEN GOTO 30 // isRemoved is a boolean.
21  RETURN 2

30  IF isOwner() THEN GOTO 40
31  RETURN 3

40  IF EXISTS("PRODUCT_"+productID+"_Name") THEN GOTO 50 // Make sure product exists.
41  RETURN 4

50  setProductValues(productID, name, description, price, isAvailable, imageURI, isRemoved)
60  RETURN 0
End Function

// Shorthand for EditProduct that does not requrie all the other parameters.
Function SetProductAvailability(productID Uint64, isAvailable Uint64) Uint64
10  IF isAvailable <= 1 THEN GOTO 20 // isAvailable is a boolean.
11  RETURN 1

20  IF isOwner() THEN GOTO 30
21  RETURN 2

30  IF EXISTS("PRODUCT_"+productID+"_IsAvailable") THEN GOTO 40 // Make sure product exists.
31  RETURN 3

40  STORE("PRODUCT_"+productID+"_IsAvailable", isAvailable)
50  RETURN 0
End Function

// Shorthand for EditProduct that does not requrie all the other parameters.
Function SetProductRemoval(productID Uint64, isRemoved Uint64) Uint64
10  IF isRemoved <= 1 THEN GOTO 20 // isRemoved is a boolean.
11  RETURN 1

20  IF isOwner() THEN GOTO 30
21  RETURN 2

30  IF EXISTS("PRODUCT_"+productID+"_IsRemoved") THEN GOTO 40 // Make sure product exists.
31  RETURN 2

40  STORE("PRODUCT_"+productID+"_IsRemoved", isRemoved)
50  RETURN 0
End Function

Function ResetCatalog() Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  STORE("productsCount", 0)
30  RETURN 0
End Function

Function ReplyToReview(reviewID Uint64, reply String) Uint64
10  IF isOwner() THEN GOTO 20
11  RETURN 1

20  IF EXISTS("REVIEW_"+reviewID+"_Stars") THEN GOTO 30 // Make sure review exists.
21  RETURN 2

30  STORE("REVIEW_"+reviewID+"_Reply", reply)
40  STORE("REVIEW_"+reviewID+"_ReplyTopoHeight", BLOCK_TOPOHEIGHT())
50  RETURN 0
End Function

// Internal store functions

Function setProductValues(productID Uint64, name String, description String, price Uint64, isAvailable Uint64, imageURI String, isRemoved Uint64) Uint64
10  STORE("PRODUCT_"+productID+"_Name", name)
20  STORE("PRODUCT_"+productID+"_Description", description)
30  STORE("PRODUCT_"+productID+"_Price", price)
40  STORE("PRODUCT_"+productID+"_IsAvailable", isAvailable)
50  STORE("PRODUCT_"+productID+"_ImageURI", imageURI)
60  STORE("PRODUCT_"+productID+"_IsRemoved", isRemoved)
70  RETURN 0
End Function

// Customer functions

Function ReviewStore(stars Uint64, comment String) Uint64
10  IF DEROVALUE() >= LOAD("reviewFee") THEN GOTO 20 // Review fee must be paid in full.
11  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
12  RETURN 0

20  IF isOwner == 0 THEN GOTO 30 // Owner cannot review themselves.
21  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
22  RETURN 0

30  IF stars >= 1 && stars <= 5 THEN GOTO 40
31  sendDeroToAddress(SIGNER(), DEROVALUE()) // Refund user.
32  RETURN 0

40  STORE("balance", LOAD("balance") + DEROVALUE())

50  DIM reviewID as Uint64
51  LET reviewID = getReviewIDByAuthor(SIGNER())

60  IF reviewID == 0 THEN GOTO 80

// Edit existing review of the store by the author. Customers can leave one review only.
70  STORE("totalStars", LOAD("totalStars") - LOAD("REVIEW_"+reviewID+"_Stars") + stars)
71  STORE("REVIEW_"+reviewID+"_Stars", stars)
72  STORE("REVIEW_"+reviewID+"_Comment", comment)
73  STORE("REVIEW_"+reviewID+"_TopoHeight", BLOCK_TOPOHEIGHT())
74  RETURN 0

// Create new review of the store by the author.
80  LET reviewID = LOAD("reviewsCount") + 1
81  STORE("reviewsCount", reviewID)
82  STORE("totalStars", LOAD("totalStars") + stars)
83  STORE("REVIEW_"+reviewID+"_Stars", stars)
84  STORE("REVIEW_"+reviewID+"_Comment", comment)
85  STORE("REVIEW_"+reviewID+"_TopoHeight", BLOCK_TOPOHEIGHT())
86  STORE("REVIEW_"+reviewID+"_Author", SIGNER())
87  STORE("reviewIDByAuthor_"+SIGNER(), reviewID)
88  STORE("REVIEW_"+reviewID+"_Reply", "")
89  STORE("REVIEW_"+reviewID+"_ReplyTopoHeight", 0)
90  RETURN 0
End Function

// Internal customer functions

Function getReviewIDByAuthor(authorRawAddress String) Uint64
10  IF EXISTS("reviewIDByAuthor_"+authorRawAddress) THEN GOTO 20
11  RETURN 0

20  RETURN LOAD("reviewIDByAuthor_"+authorRawAddress)
End Function
