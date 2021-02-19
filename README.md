# HelloID-Conn-Prov-Source-CSV-DEMO
 CSV DEMO HRM by Tools4ever

## This is a work in progress

The _'HelloID-Conn-Prov-Source-CSV-DEMO'_ connector needs to be executed 'on-premises'. Make sure you have a local 'HelloID provisioning agent' running, and the 'Execute on-premises' switch is toggled on.

## Table of contents

- Introduction
- Prerequisites
- Mappings
- Setup the PowerShell connector

## Introduction

This CSV DEMO system is intended for training purposes only, or can be used as a starting point for your own CSV source system.

## Prerequisites

- A local running version of the 'HelloID provisioning agent'.

- A local directory on the server running the 'HelloID provisioning agent' containing the DEMO data from the 'CSV source data' folder.

- The 'Execute on-premises' switch on the 'System' tab is toggled.

![image](./assets/hid.png)

## Mappings

A basic person and contract mapping is provided. Make sure to further customize these accordingly.

## Setup the PowerShell connector

1. Make sure your service account running the 'HelloID provisioning agent' service can access the local directory containing the CSV DEMO data.

2. Add a new 'Source System' to HelloID and make sure to import all the necessary files.

    - [ ] configuration.json
    - [ ] personMapping.json
    - [ ] contractMapping.json
    - [ ] persons.ps1
    - [ ] departments.ps1

3. Fill in the required fields on the connectors 'Configuration' tab.

![image](./assets/config.png)