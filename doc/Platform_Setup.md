# **🧭 Platform Setup Guide**

Before using ConnectKit, you must configure native entitlements and permissions on both iOS (HealthKit) and Android (Health Connect) platforms.

## **1\. ⚙️ iOS Setup (HealthKit)**

To access health data on iOS, you need to enable the HealthKit capability and define usage strings in your Info.plist file.

### **A. Enable HealthKit Capability**

1. Open your project in **Xcode**.  
2. Select your project in the Project Navigator, then choose the **Target** for your app (e.g., Runner).  
3. Go to the **"Signing & Capabilities"** tab.  
4. Click the **\+ Capability** button.  
5. Search for and select **"HealthKit"**.  
6. Ensure the HealthKit checkbox is checked.

### **B. Configure Info.plist Permissions**

Apple requires specific strings explaining *why* your app needs to read and write health data. These strings are displayed to the user when permissions are requested.

Open ios/Runner/Info.plist and add the following keys:

| Key | Description |
| :---- | :---- |
| Privacy \- Health Share Usage Description (NSHealthShareUsageDescription) | Required for **reading** health data. |
| Privacy \- Health Update Usage Description (NSHealthUpdateUsageDescription) | Required for **writing** health data. |

**Example Info.plist Snippet (source view):**

\<key\>NSHealthShareUsageDescription\</key\>  
\<string\>We need access to your health data (e.g., steps, heart rate) to provide personalized insights and sync data across platforms.\</string\>  
\<key\>NSHealthUpdateUsageDescription\</key\>  
\<string\>We need permission to write data (e.g., workouts, weight) to HealthKit to keep your records consistent across all your devices.\</string\>

## **2\. ⚙️ Android Setup (Health Connect)**

Health Connect requires setting specific permissions and ensuring your app can query the Health Connect app package on the device.

### **A. Add Permissions to AndroidManifest.xml**

Open android/app/src/main/AndroidManifest.xml and add the necessary Health Connect permissions inside the \<manifest\> tag.

You must declare the specific permissions for the data types you intend to use. For example:

\<uses-permission android:name="android.permission.health.READ\_STEPS" /\>  
\<uses-permission android:name="android.permission.health.WRITE\_STEPS" /\>  
\<uses-permission android:name="android.permission.health.READ\_HEART\_RATE" /\>  
\<\!-- Add other permissions as required by your app's data usage \--\>

### **B. Configure Package Visibility (for Health Connect App)**

To allow the app to open the Health Connect settings (e.g., if it's not pre-installed or needs updates), you must add a \<queries\> block to your AndroidManifest.xml inside the \<manifest\> tag:

\<queries\>  
    \<\!-- Health Connect is packaged as an external app that is downloaded from the store \--\>  
    \<package android:name="com.google.android.apps.healthdata" /\>  
\</queries\>

### **C. Health Connect Activity Setup (If applicable)**

If you intend to launch Health Connect directly from your app (e.g., for setting permissions), you may need an Activity entry configured to handle the Health Connect action. This will be covered in future implementation phases.