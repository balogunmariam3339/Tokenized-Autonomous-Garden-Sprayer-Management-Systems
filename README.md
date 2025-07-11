# Tokenized Autonomous Garden Sprayer Management System

A blockchain-based system for managing autonomous garden sprayers through smart contracts, ensuring proper chemical handling, calibration, cleaning, safety compliance, and maintenance scheduling.

## System Overview

This system consists of five independent smart contracts that manage different aspects of autonomous garden sprayer operations:

### Core Contracts

1. **Chemical Compatibility Contract** (`chemical-compatibility.clar`)
    - Manages approved chemical combinations
    - Tracks chemical compatibility matrices
    - Prevents dangerous chemical mixing
    - Maintains treatment history

2. **Calibration Service Contract** (`calibration-service.clar`)
    - Manages spray pattern and volume calibration
    - Tracks calibration history and schedules
    - Validates calibration parameters
    - Issues calibration certificates

3. **Cleaning Protocol Contract** (`cleaning-protocol.clar`)
    - Manages sprayer sanitation procedures
    - Tracks cleaning cycles between applications
    - Validates cleaning completion
    - Maintains cleaning audit trail

4. **Safety Compliance Contract** (`safety-compliance.clar`)
    - Manages protective equipment requirements
    - Tracks safety protocol compliance
    - Validates operator certifications
    - Maintains safety incident records

5. **Maintenance Scheduling Contract** (`maintenance-scheduling.clar`)
    - Coordinates nozzle cleaning schedules
    - Manages pump servicing intervals
    - Tracks maintenance history
    - Issues maintenance alerts

## Features

- **Tokenized Access Control**: Each sprayer has unique tokens for access management
- **Audit Trail**: Complete blockchain-based record keeping
- **Compliance Tracking**: Automated safety and regulatory compliance
- **Preventive Maintenance**: Scheduled maintenance and calibration reminders
- **Chemical Safety**: Prevents incompatible chemical combinations

## Contract Architecture

Each contract operates independently without cross-contract calls, ensuring:
- Reduced complexity and gas costs
- Better security isolation
- Easier testing and maintenance
- Modular system design

## Getting Started

### Prerequisites
- Clarity development environment
- Stacks blockchain testnet access

### Installation

1. Clone the repository
2. Deploy contracts to Stacks testnet
3. Initialize system parameters
4. Register sprayer units

### Usage

Each contract provides specific functionality for sprayer management:

\`\`\`clarity
;; Example: Register a new sprayer
(contract-call? .chemical-compatibility register-sprayer u1 "Sprayer-001")
\`\`\`

## Testing

Tests are written using Vitest and cover:
- Contract deployment
- Function execution
- Error handling
- Edge cases
- Integration scenarios

Run tests with:
\`\`\`bash
npm test
\`\`\`

## Security Considerations

- All contracts include proper access controls
- Input validation on all public functions
- Error handling for edge cases
- Audit trail for all operations

## License

MIT License - See LICENSE file for details
