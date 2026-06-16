# ResQNet Web Automated Testing Suite

This directory contains the automated test runner and verification suite for the ResQNet Web application.

## Prerequisites

1. **Python 3.x**: Ensure Python and `pip` are installed on your system.
2. **Google Chrome**: The test suite uses the Chrome browser.
3. **Running Application**:
   - Spring Boot backend running on `http://localhost:8080`
   - React frontend running on `http://localhost:5173`

## Installation

Install the required Python dependencies:
```bash
pip install -r requirements.txt
```

## Running the Tests

To run the full suite of 100+ tests and generate the report:
```bash
python test_runner.py
```

The script will launch a Chrome browser, interactively execute all UX, functional, and API validations, and generate a comprehensive `test_report.xlsx` inside this folder with separate sheets representing each test category.
