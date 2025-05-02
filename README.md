# OSDToolkit
Scripts for managing/automating anything OSDToolkit related.

## Quick Start


### Download of the Toolkit
Get the Toolkit by going here:

https://2pintsoftware.com/products/osd-toolkit

### Build your WinPE 
Build your Media using the WinPEBuilder.ps1

Requires:
- ADK Installed (I'd recommend the latest of 24H2)
- Toolkit Package
- Matching OS WIM file (ex 24H2 Enterprise x64 to match your ADK)
- Optional: Add Drivers (optional because you can do this in CM instead if you like)
- Import into ConfigMgr, and make updates as needed
  - Add Drivers
  - Add Background
  - Enable F8
  - etc
  
