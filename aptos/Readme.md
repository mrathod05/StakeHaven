# 🏦 StakeHaven: Aptos Move Staking Protocol 🚀

## 📜 Overview

StakeHaven is a complete staking solution built on the Aptos blockchain using Move language. It allows users to stake custom tokens (HavenCoin/HVC), earn rewards over time, and withdraw their stakes with configurable conditions.

## 🌟 Features

- ✅ Custom token (HavenCoin/HVC) implementation
- ✅ Staking mechanism with time-based rewards
- ✅ Minimum stake duration with early withdrawal penalties
- ✅ Airdrops functionality
- ✅ Event emission for all operations
- ✅ Admin controls for ecosystem management
- ✅ Comprehensive test suite

## 🏗️ Architecture

StakeHaven consists of four primary modules:

1. **Accounts**: Manages resource accounts for the staking pool
2. **EmitEvents**: Handles event emissions for tracking and auditing
3. **HavenCoin**: Implements the custom HVC token
4. **StakingMechanism**: Core staking logic and reward calculation

## 📋 Technical Specifications

- **Token Name**: Haven Coin (HVC)
- **Decimals**: 9
- **Reward Rate**: Configurable rewards per second
- **Staking Duration**: Configurable minimum staking period
- **Early Withdrawal Penalty**: Configurable percentage fee

## 🔧 Installation

### Prerequisites

- Aptos CLI
- Move compiler
- Aptos account with sufficient funds

### Setup

1. Clone the repository:

```bash
git clone https://github.com/wdcs-meetrathod/StakeHaven.git
cd StakeHaven
```

2. Compile the Move modules:

```bash
aptos move compile
```

3. Test the modules:

```bash
aptos move test
```

4. Publish to your account:

```bash
aptos move publish --named-addresses admin=YOUR_ADDRESS
```

## 🚀 Usage

### Initialize HavenCoin and Staking Mechanism

Only the admin account can initialize the protocol:

```bash
aptos move run --function-id YOUR_ADDRESS::StakingMechanism::init_module
```

### Register a User

Users need to register to interact with the token:

```bash
aptos move run --function-id YOUR_ADDRESS::HavenCoin::register_user
```

### Mint Tokens (Admin only)

```bash
aptos move run --function-id YOUR_ADDRESS::HavenCoin::mint_coin \
  --args address:USER_ADDRESS u64:AMOUNT
```

### Airdrop Tokens (Admin only)

```bash
aptos move run --function-id YOUR_ADDRESS::HavenCoin::airdrop_coin \
  --args address:USER_ADDRESS u64:AMOUNT
```

### Stake Tokens

```bash
aptos move run --function-id YOUR_ADDRESS::StakingMechanism::stack \
  --args u64:AMOUNT
```

### Claim Rewards

```bash
aptos move run --function-id YOUR_ADDRESS::StakingMechanism::claim_rewards
```

### Withdraw Stake

```bash
aptos move run --function-id YOUR_ADDRESS::StakingMechanism::withdraw_stack \
  --args u64:AMOUNT
```

### Add Rewards (Admin only)

```bash
aptos move run --function-id YOUR_ADDRESS::StakingMechanism::add_rewards \
  --args u64:AMOUNT
```

## 📊 View Functions

### Check User Balance

```bash
aptos move view --function-id YOUR_ADDRESS::HavenCoin::get_balance \
  --args address:USER_ADDRESS
```

### Check User Stake Info

```bash
aptos move view --function-id YOUR_ADDRESS::StakingMechanism::get_stake_info \
  --args address:USER_ADDRESS
```

### Check Pending Rewards

```bash
aptos move view --function-id YOUR_ADDRESS::StakingMechanism::calculate_reward \
  --args address:USER_ADDRESS
```

### Check Staking Pool Info

```bash
aptos move view --function-id YOUR_ADDRESS::StakingMechanism::get_stakepool_info \
  --args address:ADMIN_ADDRESS
```

## 📝 Events

StakeHaven emits events for all operations:

- CoinInitEvent
- CoinMintEvent
- StakeMechanismInitEvent
- AddStakeEvent
- ClaimStakeEvent
- WithdrawStakePenaltyEvent
- WithdrawStakeEvent
- AdminAddStakeEvent
- AirDropEvent

## 🧪 Testing

The protocol includes comprehensive tests in `test_haven_coin.move`:

- Token initialization tests
- Staking tests
- Reward calculation tests
- Withdrawal tests (normal and early)
- Admin operations tests

Run tests with:

```bash
aptos move test
```

## ⚠️ Important Notes

1. Only the admin account can mint tokens and initialize the staking mechanism
2. Early withdrawals (before minimum staking duration) incur a penalty
3. Rewards accrue per second based on the staking amount

## 🔒 Security

- Resource account pattern for secure fund management
- Proper validation and access control for all operations
- Comprehensive error handling