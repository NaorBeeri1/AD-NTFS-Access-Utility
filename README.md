\# Active Directory NTFS Access Provisioning Utility



An enterprise-grade, GUI-driven PowerShell automation tool designed to streamline security access workflows across Active Directory environments. This utility eliminates human error in high-volume provisioning by allowing system administrators to batch-modify or remove NTFS Access Control Lists (ACLs) on file servers via an intuitive, state-driven user interface.



\## 🌟 Key Technical Engineering Highlights



\* \*\*State-Driven Workflow Stack:\*\* Implements a native tracking framework utilizing a `\[System.Collections.Stack]` object. This enables complex multi-screen UI navigation, allowing administrators to seamlessly move backward and forward (`< Back`) through input panels while preserving user-defined script states.

\* \*\*Multi-Forest Identity Resolution:\*\* Dynamically discovers and traverses all domains within an Active Directory forest utilizing advanced filtering. It safely maps input strings (SAM account names, corporate emails, or display names) to exact security identifiers (SIDs) for both users and groups.

\* \*\*Deterministic Input Cleansing:\*\* Uses robust regex patterns to clean, trim, and normalize paths dragged or pasted from different environments, ensuring zero trailing slashes or formatting artifacts disrupt file system operations.

\* \*\*Atomic NTFS ACL Security Modification:\*\* Directly interacts with security descriptors using `Get-Acl` and `Set-Acl` APIs, enforcing strict inheritance structures (`ContainerInherit, ObjectInherit`) for deterministic permission propagation.



\---



\## 🛠️ Technology Core



\* \*\*Automation Engine:\*\* PowerShell 5.1 / Core

\* \*\*Core Modules:\*\* Microsoft.ActiveDirectory.Management

\* \*\*UI Architecture:\*\* Windows Forms (`System.Windows.Forms`), GDI+ Graphics UI Layout Engines (`System.Drawing`)

\* \*\*State Collections:\*\* System.Collections.Stack



\---



\## 📐 Operation \& Input Pipeline



1\. \*\*Action Matrix selection:\*\* Selection of access intent (Add Permissions vs. Remove Permissions).

2\. \*\*Access Rights Definition:\*\* Granular permission level assignment matching canonical NTFS definitions (`FullControl`, `Modify`, `ReadAndExecute`).

3\. \*\*Identity Batch Ingestion:\*\* A multi-line entry panel accepting varied string profiles (usernames, display names, emails), which are dynamically validated across the global directory catalog.

4\. \*\*Target Path Mapping:\*\* Bulk directory resolution containing full structural confirmation blocks to double-check targeted file paths before execution.

5\. \*\*Telemetry Summary:\*\* Returns a granular final window showcasing success/failure metrics alongside individual atomic object status markers.



\---



\## 🚀 Deployment \& Usage



\### Prerequisites

\* PowerShell console initialized with Elevated Administrator access privileges.

\* Active Directory Domain Services or Remote Server Administration Tools (RSAT) installed on the local workstation.



\### Local Execution

1\. Open an elevated PowerShell terminal and run:

```powershell

&#x20;  \& .\\AclProvisioner.ps1

