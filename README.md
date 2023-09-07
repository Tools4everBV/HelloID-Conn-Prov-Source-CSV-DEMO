# HelloID-Conn-Prov-Source-CSV-DEMO
<br />
<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/csv-logo.png">
</p>


## This is a work in progress

The _'HelloID-Conn-Prov-Source-CSV-DEMO'_ connector needs to be executed 'on-premises'. Make sure you have a local 'HelloID provisioning agent' running, and the 'Execute on-premises' switch is toggled on.

## Table of contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Mappings](#mappings)
* [Setup the PowerShell source connector](#setup-the-powershell-source-connector)

## Introduction

This CSV DEMO system is intended for training/demo purposes only, or can be used as a starting point for building your own CSV source system.

## Prerequisites

- A local running version of the 'HelloID provisioning agent'.

- A local directory on the server running the 'HelloID provisioning agent' containing the DEMO data from the 'CSV source data' folder.

- The 'Execute on-premises' switch on the 'System' tab is toggled.

![image](https://github.com/Tools4everBV/HelloID-Conn-Prov-Source-CSV-DEMO/raw/main/assets/hid.png)

## Mappings

A basic person and contract mapping is provided. Make sure to further customize these accordingly.

## Setup the PowerShell source connector

1. Make sure your service account running the 'HelloID provisioning agent' service can access the local directory containing the CSV DEMO data.

2. Add a new 'Source System' to HelloID and make sure to import all the necessary files.

    - [ ] configuration.json
    - [ ] personMapping.json
    - [ ] contractMapping.json
    - [ ] persons.ps1
    - [ ] departments.ps1

3. Fill in the required fields on the connectors 'Configuration' tab.

![image](https://github.com/Tools4everBV/HelloID-Conn-Prov-Source-CSV-DEMO/raw/main/assets/config.png)

# HelloID Docs
The official HelloID documentation can be found at: https://docs.helloid.com/
