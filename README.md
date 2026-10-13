# Powernet IT Service Dashboard

A simple Node.js application demonstrating DevOps practices for Powernet Pvt Ltd.

## Features
- Displays the application running status.
- Shows the IT and Network Support service.
- Displays the current application environment.

## Technologies
- Node.js
- Docker
- Git and GitHub
- Jenkins CI

## Run locally
Open PowerShell in the project folder and run:
`cd app`
`node app.js`

Then open http://localhost:3000 in a browser.

## Automated tests
Start the application server first. Then, in another terminal, go to the app folder and run:
`npm.cmd test`

In Jenkins/Linux, use:
`npm test`

## Docker
Run these commands from the project root:
`docker build -t powernet-dashboard:1.0 .\app`
`docker run -d --name powernet-dashboard-container -p 3000:3000 powernet-dashboard:1.0`
