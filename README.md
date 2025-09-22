# AlcoholAuth

AlcoholAuth is a comprehensive supply chain tracking smart contract for alcoholic beverage authentication and age verification built on the Stacks blockchain using Clarity.

## Overview

This smart contract enables end-to-end tracking of alcoholic beverages through the supply chain, from production to retail consumption. It provides robust authentication mechanisms, age verification compliance, and complete traceability for regulatory compliance and consumer safety.

## Features

- **Supply Chain Tracking**: Complete traceability from producer to consumer
- **Location Management**: Register and verify producers, distributors, and retailers
- **Batch Management**: Create and track alcoholic beverage batches with detailed metadata
- **Age Verification**: Built-in legal drinking age compliance (21+ years)
- **Product Authentication**: Verification codes to prevent counterfeiting
- **Movement Tracking**: Record all batch movements between supply chain locations
- **Consumption Recording**: Track end-consumer purchases and consumption
- **Batch Deactivation**: Support for product recalls and safety measures

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Epoch**: 2.5
- **Minimum Drinking Age**: 21 years
- **Age Calculation**: Approximates 52,560 blocks per year (10-minute block time)

## Project Structure

```
AlcoholAuth_contract/
├── contracts/
│   └── AlcoholAuth.clar          # Main smart contract
├── settings/
│   ├── Devnet.toml              # Development network configuration
│   ├── Testnet.toml             # Test network configuration
│   └── Mainnet.toml             # Main network configuration
├── Clarinet.toml                # Project configuration
├── package.json                 # Node.js dependencies
└── tsconfig.json               # TypeScript configuration
```

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- Node.js (for testing and development tools)

### Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd AlcoholAuth
   ```

2. Install Clarinet following the [official installation guide](https://docs.hiro.so/clarinet/getting-started)

3. Install Node.js dependencies:
   ```bash
   cd AlcoholAuth_contract
   npm install
   ```

4. Verify installation:
   ```bash
   clarinet check
   ```

## Usage Examples

### 1. Register a Producer Location

```clarity
(contract-call? .AlcoholAuth register-location
  "ABC Distillery"
  "producer"
  "LIC-001-PRODUCER")
```

### 2. Verify a Location (Contract Owner Only)

```clarity
(contract-call? .AlcoholAuth verify-location u1)
```

### 3. Create a Batch

```clarity
(contract-call? .AlcoholAuth create-batch
  "Premium Whiskey"
  u4000  ;; 40% alcohol content (in basis points)
  u525600  ;; Expiry date (block height)
  u1000  ;; Quantity
  "AUTH-CODE-123456"
  u1)  ;; Location ID
```

### 4. Verify Age

```clarity
(contract-call? .AlcoholAuth verify-age u1051200)  ;; Birth date in block height
```

### 5. Consumer Purchase

```clarity
(contract-call? .AlcoholAuth consume-product
  u1  ;; Batch ID
  u5  ;; Quantity
  "AUTH-CODE-123456"  ;; Verification code
  u3)  ;; Retailer location ID
```

## Contract Functions

### Public Functions

#### Location Management
- `register-location(name, location-type, license-number)` - Register a supply chain location
- `verify-location(location-id)` - Verify a location (owner only)

#### Batch Management
- `create-batch(product-name, alcohol-content, expiry-date, quantity, verification-code, location-id)` - Create a new batch
- `move-batch(batch-id, to-location-id, quantity)` - Move batch between locations
- `deactivate-batch(batch-id)` - Deactivate a batch (producer only)

#### Age Verification & Consumption
- `verify-age(birth-date)` - Verify user's legal drinking age
- `consume-product(batch-id, quantity, verification-code, location-id)` - Record product consumption

### Read-Only Functions

#### Data Retrieval
- `get-batch(batch-id)` - Get batch information
- `get-location(location-id)` - Get location details
- `get-batch-movement(batch-id, movement-id)` - Get movement record
- `get-batch-movement-count(batch-id)` - Get total movements for batch
- `get-age-verification(user)` - Get age verification status
- `get-consumption-record(batch-id, consumer)` - Get consumption record

#### Verification Functions
- `is-of-legal-age(user)` - Check if user meets drinking age requirement
- `verify-product(batch-id, verification-code)` - Verify product authenticity
- `get-next-batch-id()` - Get next available batch ID
- `get-next-location-id()` - Get next available location ID

## Data Structures

### Batch Information
```clarity
{
  producer: principal,
  product-name: (string-ascii 100),
  alcohol-content: uint,           ;; In basis points (1250 = 12.5%)
  production-date: uint,           ;; Block height
  expiry-date: uint,              ;; Block height
  quantity: uint,
  remaining-quantity: uint,
  verification-code: (string-ascii 32),
  is-active: bool
}
```

### Location Information
```clarity
{
  owner: principal,
  name: (string-ascii 100),
  location-type: (string-ascii 20),  ;; "producer", "distributor", "retailer"
  license-number: (string-ascii 50),
  is-verified: bool
}
```

## Error Codes

- `u400` - Invalid batch
- `u401` - Unauthorized access
- `u402` - Invalid location
- `u403` - Invalid age (under 21)
- `u404` - Resource not found
- `u409` - Resource already exists
- `u410` - Product already consumed
- `u411` - Invalid verification code

## Deployment

### Development Network

1. Start local development environment:
   ```bash
   clarinet console
   ```

2. Deploy contract:
   ```clarity
   ::deploy_contracts
   ```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
   ```bash
   clarinet publish --testnet
   ```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
   ```bash
   clarinet publish --mainnet
   ```

## Security Considerations

### Access Control
- Only the contract owner can register and verify locations
- Only verified producers can create batches
- Only batch producers can deactivate their batches
- Age verification is self-attested but recorded on-chain

### Data Integrity
- All supply chain movements are immutably recorded
- Verification codes prevent counterfeiting
- Batch quantities are tracked to prevent overselling
- Expiry dates are enforced through smart contract logic

### Privacy Notes
- Age verification requires users to submit birth dates on-chain
- All transactions and movements are publicly visible on the blockchain
- Consider privacy implications for sensitive supply chain data

## Testing

Run contract tests:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or contributions, please open an issue on the project repository.