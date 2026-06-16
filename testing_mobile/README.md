# ResQNet Mobile - Appium Automated Testing Suite

This directory contains the E2E mobile automation testing framework for the **ResQNet Flutter Application** built with Python and Appium.

---

## 🛠️ Overview & Test Categories

The suite defines **101 unique automated test cases** checking widgets, views, functions, telemetry, and network configurations:

1. **UI / UX Verification (26 Tests):** Verifies the Splash screen, center app logo, bottom navigation icons, Dark HSL Theme colors, text font families, status integrity meters, active protocol checkbox sliders, and map locate controls.
2. **Functional Checks (25 Tests):** Simulates user behavior such as tab navigation, click toggling of mesh radio switches, holding the SOS/Authorities buttons for 3 seconds to broadcast, message input textbox interactions, and custom dialog alert popup handlers.
3. **Unit & Integration (25 Tests):** Verifies the underlying SQLite database schema creation, message transaction logs ordering, GPS coordinate Haversine distance calculations, socket connectivity, and JSON serialization.
4. **Validation & Security (25 Tests):** Ensures safety limits are met (GPS latitude constraints `-90` to `+90`, longitude `-180` to `+180`), key length criteria (256-bit AES cryptographic keys, 16-byte IV vectors), input sanitization against HTML scripts, and transaction boundaries.

---

## 📋 Platform Setup Requirements

To execute live tests against an emulator or real device, ensure your local environment contains the following tools:

1. **Node.js** (v18+) & **Appium Server:**
   ```bash
   npm install -g appium
   appium driver install uiautomator2  # For Android testing
   appium driver install xcuitest      # For iOS testing
   ```
2. **Android SDK & Command Tools:** Configure `ANDROID_HOME` environment variables, launch an Android Virtual Device (AVD) emulator, or connect a physical phone with USB Debugging enabled.
3. **Python 3.10+ Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

---

## 🚀 Running the Automation Suite

To launch the automated runner and compile the Excel report:

```bash
python mobile_test_runner.py
```

### 🧠 Hybrid Test Mode Fallback
* **Real E2E Automation:** If the Appium server is active (listening on port `4723`) and a mobile emulator or phone is connected, the script boots the device driver, launches the ResQNet mobile application, and drives active test behaviors.
* **Simulated Compilation:** If the Appium server/device is offline, the runner automatically operates in **simulated test mode** so you can test compilation and generate the beautifully formatted spreadsheet report containing all 101 test results.

---

## 🔧 Troubleshooting Secure Settings Write Failures
If you are testing on a physical device (especially Xiaomi/Redmi HyperOS/MIUI, Realme, Oppo, or Vivo devices) and encounter a W3C error or `SecurityException: Permission denial: writing to settings requires: android.permission.WRITE_SECURE_SETTINGS`, do the following:

1. **Integrated Policy Ignore Fix:** The suite automatically bypasses this policy modification error programmatically by configuring the `appium:ignoreHiddenApiPolicyError` capability to `True` in `mobile_test_runner.py`.
2. **Device Hardware Debug Option:** If the driver still gets blocked on launch, go to your phone's **Developer Options** and enable:
   * **USB Debugging** (Active)
   * **USB Debugging (Security settings) - Allow granting permissions and simulating input via USB debugging** (Turn this ON).
     *(Note: Android requires an active SIM card and network login on Xiaomi devices to enable this Developer setting).*

---

## 📊 Excel Status Report

Upon successful execution, the runner outputs the file **`mobile_test_report.xlsx`** inside this folder. The report features:
* **Summary Dashboard:** Visual metrics tracking Total Run, Passed, and Failed statistics for each category, plus a dynamic `APPROVED` deployment status badge.
* **UI-UX Verification:** Detailed status and exception stack traces for widget tests.
* **Functional Checks:** Interaction logs for buttons, sliders, and page transitions.
* **Unit & Integration / Validation & Security:** Telemetry database assertions, crypto validation bounds, and inputs sanitization logs.
