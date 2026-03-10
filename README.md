# Grocery Hands Free (MVP)

## Local device testing (iPhone)
1. Open `GroceryHandsFree.xcodeproj` in Xcode 16+.
2. In **Signing & Capabilities**, select your Apple Team and let Xcode manage signing.
3. Confirm bundle identifier is `com.groceryhandsfree.ios` (or use your personal suffix if needed).
4. Connect your iPhone, trust the computer/device pairing, and select your iPhone as the run destination.
5. Build and run with `⌘R` using the **GroceryHandsFree** scheme.
6. On first launch, verify you can:
   - Create a shopping list
   - Add and check off items
   - Enter shopping mode and hear spoken guidance

## Release-friendly archive check
1. In Xcode, choose **Any iOS Device (arm64)**.
2. Use **Product → Archive**.
3. Validate the archive in Organizer before TestFlight upload.
