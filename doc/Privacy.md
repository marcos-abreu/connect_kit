# **Data Privacy and Logging Policy for ConnectKit Plugin**

This document serves as a policy guide for developers integrating and contributing to the ConnectKit plugin, focusing on the handling of sensitive user data.

## **1\. Data Retention Policy**

The ConnectKit plugin operates strictly on the principle of **data minimization and non-retention**.

* **No Data Storage:** The plugin does **not** persist or store any user-specific data, including Health Data or Personally Identifiable Information (PII), to disk or local storage.
* **Transit Only:** All data processed by the plugin is intended for transit between the platform APIs (e.g., Health Kit, Google Fit) and the consuming host application.
* **Host Application Responsibility:** The consuming application is entirely responsible for securing, processing, storing, and obtaining user consent for any data retrieved via ConnectKit.

## **2\. Logging Policy**

The built-in CKLogger is designed for technical debugging and performance analysis only. **Logging of sensitive data is strictly prohibited** to prevent accidental exposure via application logs.

**All debug logs are stripped in release builds** – no runtime overhead or data leakage

**Developers must ensure that the following categories of data are NEVER included in any log message at any level:**

* **Health and Medical Data:** Any information pertaining to a user's physical or mental health, medical history, fitness metrics, or biometrics.

* **Personally Identifiable Information (PII):** User names, email addresses, phone numbers, unique identifiers (if they map to PII), and other demographic details.
