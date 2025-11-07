# iOS (App Store) subscription setup for Reconstruct

This app uses the `in_app_purchase` plugin to sell an auto‑renewable subscription through the App Store on iOS and Google Play on Android. Follow this checklist to enable payments on iOS.

## 1) Product you must create in App Store Connect

- Subscription Group: Reconstruct Subscription
- Product Type: Auto‑Renewable Subscription
- Reference Name: annual-pro-plan
- Product ID (must match the app code exactly): `re_599_1yr`
- Duration: 1 year
- Introductory Offer: 7‑day free trial (optional, based on your pricing setup)
- Price: Choose a yearly tier that matches your target price
- Localizations:
  - Name: Annual Pro Plan
  - Description: All-access membership

Code reference for the product ID used by the app:

```dart
// lib/services/subscription_manager.dart
// Subscription product IDs
static const String yearlySubscriptionId = 're_599_1yr';
```

## 2) Agreements, Tax, and Banking

In App Store Connect → Agreements, Tax, and Banking:

- Accept the Paid Apps Agreement
- Add and verify Banking information
- Complete Tax information

Purchases will not work until these are completed.

## 3) Xcode project configuration

- In your iOS target (Runner) → Signing & Capabilities → add capability: In‑App Purchase
- Ensure the app Bundle Identifier matches the App Store Connect app record
- Push a build to TestFlight or for App Store review with the IAP attached (see submission step below)

## 4) Add the IAP to the app version submission

When you create a new app version in App Store Connect:

- On the version page, click “+ In‑App Purchases” and add the subscription (`re_599_1yr`) to the submission
- If the purchase path requires authentication, provide demo credentials in App Review Information
- Upload a screenshot of the purchase screen (paywall) for the In‑App Purchase review

Tip: A good screenshot is the screen built by `PaymentMethodsPage` or `SubscriptionModal` showing the plan and trial.

## 5) Testing on a device (Sandbox)

- Create a Sandbox Tester (Users and Access → Sandbox → Testers)
- On a physical iOS device:
  - Sign out of the App Store in Settings
  - Install your TestFlight build (or run a debug build)
  - Start the purchase in‑app; when prompted, sign in using the Sandbox Apple ID
- The `in_app_purchase` plugin will present the native App Store purchase sheet if your product exists and is approved for test

Optional (advanced local testing): Add a StoreKit Configuration file in Xcode and run the app using that configuration to simulate purchases locally.

## 6) What the app already does

- Uses `in_app_purchase` to query the product with ID `re_599_1yr` and start the purchase
- Handles purchase updates and marks the user premium after a successful transaction
- Shows a platform‑specific “Manage subscription” link that opens the App Store subscription management page on iOS

## 7) Apple Pay note

For auto‑renewable subscriptions, Apple requires App Store billing (not “Apple Pay”). The UI labels in the app show “Apple (App Store)” for iOS to reflect this. If you prefer the label to read “Apple Pay” visually, you can change the label text, but billing will still be processed by the App Store.

## 8) Troubleshooting checklist

- Product not found / purchase sheet doesn’t show:
  - Ensure the product ID is exactly `reconstruct`
  - Ensure the product ID is exactly `re_599_1yr`
  - The subscription is in the “Ready to Submit” or “Approved for Testing” state
  - The app’s Bundle ID matches the App Store Connect app
  - IAP capability is added in Xcode
  - Use a Sandbox tester account (not a real Apple ID)

- Purchase flows but premium not unlocked:
  - Confirm `purchaseDetails.productID` equals `re_599_1yr`
  - Check logs from `SubscriptionManager._listenToPurchaseUpdated`
  - Verify your backend (if any) accepts the conversion and the app saves local premium state

## 9) Minimal Android parity (for reference)

In Google Play Console → Monetize → Products → Subscriptions:

- Create a subscription with Product ID `re_599_1yr`
- Add test license accounts
- The same code path will route to Google Play on Android

---

Once the App Store Connect product (`re_599_1yr`) is created and approved for testing, the iOS purchase flow in this app will work without additional code changes.
