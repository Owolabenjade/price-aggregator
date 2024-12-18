# DePo (Decentralized Price Oracle) Aggregator

The DePo Aggregator is a Stacks blockchain smart contract designed to provide a decentralized and secure price oracle mechanism. It allows multiple providers to submit price data, which is then aggregated and validated to ensure reliable and accurate price information.

## Key Features

- **Decentralized Price Aggregation**: Collects price submissions from multiple authorized providers
- **Price Validation**: Implements multiple checks to ensure price data integrity
- **Configurable Provider Management**: Allows adding and removing price providers
- **Stale Price Protection**: Prevents use of outdated price information

## Contract Constants

- **Price Precision**: 8 decimal places
- **Max Price Age**: 15 minutes (900 blocks)
- **Provider Limits**: 
  - Minimum Providers: 3
  - Maximum Providers: 10
- **Price Deviation Limit**: 20%
- **Price Range**: 
  - Minimum: 1.00
  - Maximum: 10,000,000.00

## Main Functions

### Provider Management
- `add-price-provider`: Adds a new authorized price provider
- `remove-price-provider`: Removes an existing price provider
- `get-price-provider-count`: Retrieves the current number of active providers

### Price Submission and Retrieval
- `submit-price`: Allows authorized providers to submit price data
- `get-current-price`: Retrieves the most recent validated price

## Error Handling

The contract includes comprehensive error handling with specific error codes:
- `ERR_NOT_AUTHORIZED`: Unauthorized action attempt
- `ERR_STALE_PRICE`: Price data is too old
- `ERR_INSUFFICIENT_PROVIDERS`: Not enough price providers
- `ERR_PRICE_TOO_LOW`: Submitted price below minimum threshold
- `ERR_PRICE_TOO_HIGH`: Submitted price above maximum threshold

## Security Considerations

- Only the contract owner can manage price providers
- Prices must be submitted by authorized providers
- Multiple validation checks prevent manipulation
- Price must be from at least 3 providers
- Prices must be within a predefined range

## Usage Example

1. Contract owner adds price providers
2. Providers submit their price observations
3. Contract aggregates and validates prices
4. Users can retrieve the current validated price

## Deployment Notes

- Deployed on the Stacks blockchain
- Requires careful initial configuration of providers
- Regular monitoring recommended