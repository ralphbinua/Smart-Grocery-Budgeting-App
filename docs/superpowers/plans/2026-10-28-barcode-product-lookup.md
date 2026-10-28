# Barcode Product Lookup Implementation Plan

> **For agentic workers:** Use the plan task-by-task in the current v1 checkout.

**Goal:** Let users scan product barcodes, add known products by database name and price, and manually enter products when a barcode is unknown.

**Architecture:** Add `mobile_scanner` to the grocery entry screen and use the existing `GET /api/products/:barcode` endpoint. Extend grocery input data with its barcode and ensure a database price is passed through AI analysis as an explicit estimate when name grounding is unavailable. Unknown scans populate the existing manual name and optional price inputs.

**Tech Stack:** Flutter/Dart, Provider, `mobile_scanner`, existing Express/Mongoose API.

**Spec:** Barcode scanning request and agreed behavior in the conversation.

## Global Constraints

- Work in `Smart-Grocery-Budgeting-App` (v1).
- Reuse the existing backend barcode endpoint and current AI fallback flow.
- Camera scanning is supported on Android, iOS, and Web; Windows is not supported by the selected scanner package.
- A matched product's stored database price is authoritative.

## Review Focus

- Repeated camera detections must not add duplicate items while lookup is in progress.
- Unknown barcode keeps the code visible while allowing manual name and optional price entry.
- API/network failures must give the user a recoverable manual-entry path.
- Product database prices must survive AI analysis even when name grounding doesn't return a match.
- Camera permission denial or unavailable camera must show a useful error and allow dismissal.

---

### Task 1: Preserve barcode and authoritative catalog price

**Files:** Modify `lib/models/grocery_input_item.dart`, `lib/providers/cart_provider.dart`, and `lib/services/openai_service.dart`.

- [x] Add optional barcode to grocery input items and the `addGroceryItem`/`updateGroceryItem` APIs.
- [x] Ensure a supplied catalog price is included in AI input if database name grounding is absent; retain existing `₱50.00` fallback for ordinary unmatched manual items. (Existing AI input already supports this through `estimatedPrice`.)

### Task 2: Add barcode scanner and lookup flow

**Files:** Modify `pubspec.yaml`, `pubspec.lock`, `ios/Runner/Info.plist`, and `lib/screens/dashboard_screen.dart`.

- [x] Add the current compatible `mobile_scanner` package and iOS camera usage text; retain the existing Android camera permission.
- [x] Add a scan button and scanner modal with one-shot detection behavior.
- [x] Request `GET /api/products/:barcode`; on a match add product name, latest price, and barcode to the grocery list.
- [x] For unknown barcodes and lookup failures, offer/manual-fill the existing item-name and price inputs and display the scanned barcode.
- [x] Show recoverable camera permission and lookup errors; Windows shows an unsupported-platform message.

### Task 3: Check changes

- [x] Run `dart format` on modified Dart files.
- [ ] Run `flutter analyze` and address errors introduced by the change.
- [x] Review the diff and report platform/device limitations.
