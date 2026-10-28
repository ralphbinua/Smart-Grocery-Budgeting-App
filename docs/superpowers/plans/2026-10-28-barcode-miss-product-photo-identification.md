# Barcode Miss Product Photo Identification Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task in the v1 checkout.

**Goal:** When a scanned barcode is missing from the local `Product` model, use a package photo and Groq vision AI to identify a name, then match that name against `Product` before adding a database-backed item.

**Architecture:** Keep the existing barcode scan and local `GET /api/products/:barcode` lookup. On a 404, prompt for a package photo, then send the image and barcode to a vision-capable Groq model for a product name, brand, and size. Query MongoDB's `Product` model with that identity; when a product matches, show its canonical database name and price for confirmation and add it. When it does not match, offer one photo retry; if the second identification still has no `Product` match, fall back to manual name/price entry. A barcode value alone is not enough for the current text model to identify a product, and visual recognition must be confirmed because it can misread packaging.

**Tech Stack:** Flutter/Dart, Provider, existing `mobile_scanner`, Flutter `camera` plugin (`^0.12.0+2`, compatible with repo Dart 3.11.5), Groq Chat Completions vision input, `qwen/qwen3.8-27b`.

**Spec:** User clarified that after the barcode scanner misses in the database, the app should ask the user to scan/photograph the product itself so AI can identify its exact name.

**Implementation Ruling:** Reuse the existing `GET /api/products` endpoint and match its `Product` records in the Flutter lookup service instead of adding `POST /api/products/match-name` — the Flutter app currently calls the hosted backend, so a new endpoint would require a separate backend deployment before this flow could work — the cost if wrong is downloading the full product catalog to the client for each photo match.

## Global Constraints

- Implement in `Smart-Grocery-Budgeting-App` (v1).
- Only ask for the package photo after local barcode lookup returns 404; do not invoke package recognition for a local database match.
- Send both the previously scanned barcode and package photo as context to vision AI.
- Require a match against MongoDB's `Product` model before adding a database-backed result; show the canonical name and `latestPrice` from that matched record.
- Offer exactly one additional package photo when the first AI identification does not match a `Product`; after the retry, fall back to manual entry if there is still no match.
- Preserve the original barcode on the grocery input item.
- Do not use an AI-invented name or price as if it came from `Product`; only a matched record supplies the canonical database name and price.
- Use Groq's documented vision-capable model `qwen/qwen3.8-27b`; current `openai/gpt-oss-20b` analysis remains text-only.
- Keep manual name and optional price entry available after one unsuccessful photo retry, cancellation, camera failure, or AI request failure.

## Review Focus

- Local barcode hit continues to add the matched `Product` name and price without asking for a photo.
- Barcode miss prompts for package photo and retains the scanned barcode.
- AI-recognized identity is looked up against MongoDB `Product`; only the matched record is added as a database match.
- A first no-match offers one retake; a second no-match falls back to manual entry.
- Permission denial, unsupported platform, network failure, invalid AI output, and user cancellation preserve the manual-entry path.

---

### Task 1: Add image capture for product packaging

**Files:** Modify `pubspec.yaml`, `pubspec.lock`, `ios/Runner/Info.plist`, and `lib/screens/dashboard_screen.dart`.

**Interface:** Add a package-photo capture flow that returns image bytes (`Uint8List?`) or null if the user cancels. Use a camera preview with a capture button; request the front label clearly and limit capture resolution/file size for the AI request.

- [x] Add `camera: ^0.12.0+2` and configure the iOS camera usage description; retain existing Android camera permission. This package version supports Android, iOS, and Web and has a minimum Dart SDK below the repo's 3.11.5 floor.
- [x] Implement the package-photo capture route, preview/capture/cancel controls, and lifecycle disposal.
- [x] Handle Windows as unsupported and keep the manual input route available; web builds remain supported.

### Task 2: Identify product from photo using Groq vision

**Files:** Create `lib/services/product_vision_service.dart`; modify `lib/services/openai_service.dart` only if shared API-key access needs a focused refactor.

**Interface:** `ProductVisionService.identifyProduct({required Uint8List imageBytes, required String barcode})` returns `Future<ProductIdentification?>`, where `ProductIdentification` contains `name`, optional `brand`, and optional `quantity`. This result is a search candidate, not a confirmed catalog item.

- [x] Encode captured image as a JPEG data URL and send it with the barcode to Groq's Chat Completions API using `qwen/qwen3.8-27b`.
- [x] Prompt the model to read only visible package identity (product name, brand, size), return structured JSON, and report uncertainty instead of guessing.
- [x] Parse and validate response fields; return a recoverable failure for missing/invalid names, API errors, oversized images, or malformed responses.

### Task 3: Match AI identity against MongoDB Product and handle retry

**Files:** Create `lib/services/product_lookup_service.dart`; modify `lib/screens/dashboard_screen.dart`, `lib/models/grocery_input_item.dart`, and `lib/providers/cart_provider.dart`.

**Interface:** `ProductLookupService.matchProductName({required String name, String? brand, String? quantity})` reads existing `GET /api/products` records (backed by MongoDB's `Product` model) and returns a record only when exactly one candidate matches; ambiguous or absent matches return null.

- [x] Match candidate `name`, `brand`, and `quantity` against MongoDB `Product` fields from the existing products endpoint; prefer normalized full-name matches and reject ambiguous partial matches.
- [x] When the existing barcode endpoint returns 404, ask the user to photograph the package or enter its name manually.
- [x] On a photo capture, call `ProductVisionService.identifyProduct` with the image and scanned barcode, then pass its candidate to `ProductLookupService.matchProductName`.
- [x] If a `Product` match is found, show the record's canonical name and `latestPrice` for confirmation, then add it with the original scanned barcode.
- [x] If no match is found after the first photo, offer one retake; after a second no-match, open manual name/optional-price entry with the barcode preserved.
- [x] On cancellation, permission denial, network failure, or invalid AI output, preserve a manual-entry action.

### Task 4: Acceptance checks

- [ ] Existing local barcode result adds normally with database name and price.
- [ ] Unknown barcode opens package-photo prompt; image and code are sent to vision AI.
- [ ] AI candidate matching a `Product` adds the record's canonical name and `latestPrice` after confirmation.
- [ ] First AI candidate with no `Product` match offers one retake; second no-match leads to manual entry.
- [ ] Cancel, unclear image, API error, and unavailable camera allow manual entry without losing the scanned barcode.
- [x] Format changed Dart files and review the full diff.
- [ ] Exercise the live barcode, photo, database-match, retry, and manual-fallback flow on a device or browser.
