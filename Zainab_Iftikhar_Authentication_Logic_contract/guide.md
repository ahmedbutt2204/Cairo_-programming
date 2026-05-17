# Authentication Logic in Cairo Smart Contracts

**Author:** Zainab Iftikhar  
**Topic:** Authentication Logic Contract  
**Language:** Cairo (Starknet)  
**Tool:** Scarb

---

## What is Cairo?

Cairo is a programming language designed specifically for writing smart contracts on the Starknet blockchain. It was created by StarkWare. Its syntax is inspired by Rust. It compiles to Sierra first, then to Cairo Assembly (CASM). It is used for building secure, scalable decentralized applications.

---

## What is Starknet?

Starknet is a Layer 2 blockchain built on top of Ethereum. It is a ZK-Rollup which means transactions are processed off-chain (cheaper and faster) and a cryptographic STARK proof is submitted to Ethereum to verify correctness. Smart contracts on Starknet are written in Cairo. Scarb is the build tool used to compile Cairo projects.

---

## What is Authentication Logic?

Authentication Logic in smart contracts refers to the mechanism that controls who can call which functions. Just like a website has a login system to verify users, a smart contract needs to verify who is calling a function and whether they are allowed to perform that action. Without authentication, anyone could call any function including sensitive ones like withdrawing funds or changing critical settings.

---

## Real World Analogy

| Real World | Smart Contract |
|---|---|
| Building security guard | assert_only_owner() check |
| VIP member list | Whitelist mapping |
| Manager role | Admin role mapping |
| Staff badge scan | get_caller_address() |

---

## Why Authentication Matters

Smart contracts are public. Anyone on the internet can call their functions. This means no authentication equals anyone can do anything which is catastrophic for financial contracts. Wrong authentication means the contract is exploitable. Many famous hacks happened due to missing access checks. Proper authentication means only the right people can do sensitive things.

---

## Key Concepts Used in This Contract

### 1. get_caller_address()
This is a system call provided by Starknet that returns the wallet address of whoever is currently calling the contract function. This is the foundation of all authentication.

### 2. ContractAddress
A type in Cairo representing a wallet or contract address on Starknet. Used to identify users uniquely.

### 3. LegacyMap
A storage mapping like a dictionary stored permanently on-chain. Used here to map addresses to their permissions such as whitelist and admin status.

### 4. assert()
Cairo's way of enforcing rules. If the condition is false, the transaction reverts and undoes all changes with the given error message.

### 5. Storage
The Storage struct defines all variables that persist on-chain between function calls. Reading from storage uses .read() and writing uses .write().

### 6. Events
Events are logs emitted to the blockchain. They allow front-end apps and explorers to track what happened. Used here to log ownership transfers, whitelist changes, and role changes.

### 7. Constructor
The constructor function runs only once when the contract is deployed. Used here to set the initial owner.

### 8. Interface
Defines the public functions of the contract. This is what external callers interact with.

---

## Contract Structure

The contract has the following storage variables:
- owner: the single address that is the boss of the contract
- whitelist: a map of address to bool for the approved list
- admins: a map of address to bool for the manager list
- whitelist_count: tracks how many addresses are whitelisted

The contract has the following permission levels:
- Owner: can do everything, can grant and revoke admin roles
- Admin: can add and remove addresses from the whitelist
- Whitelisted User: can access whitelisted-only functions
- Regular Address: can only call view functions

---

## Function Reference

| Function | Access | Description |
|---|---|---|
| get_owner() | Anyone | Returns the current owner address |
| transfer_ownership() | Owner only | Transfers ownership to a new address |
| add_to_whitelist() | Admin only | Adds an address to the whitelist |
| remove_from_whitelist() | Admin only | Removes an address from the whitelist |
| is_whitelisted() | Anyone | Returns true if address is whitelisted |
| grant_admin_role() | Owner only | Grants admin privileges to an address |
| revoke_admin_role() | Owner only | Removes admin privileges from an address |
| is_admin() | Anyone | Returns true if address has admin role |
| owner_only_action() | Owner only | Demo function gated to owner |
| whitelist_only_action() | Whitelisted only | Demo function gated to whitelist |
| admin_only_action() | Admin only | Demo function gated to admins |

---

## How to Run

1. Install Scarb from https://docs.swmansion.com/scarb/download.html
2. Run scarb new authentication_logic
3. Replace Scarb.toml with the provided configuration
4. Replace src/lib.cairo with the contract code
5. Run scarb build
6. If you see Finished then the contract compiled successfully

---

## What I Learned

Through this assignment I learned how Cairo smart contracts are structured with interfaces, storage, events, and implementations. I learned the role of get_caller_address() as the fundamental building block of authentication. I learned how to implement a three-tier permission system using maps. I learned how assert() acts as a guard to revert unauthorized transactions. I learned how events make contract activity transparent and trackable on-chain. Authentication logic is one of the most critical security layers in any smart contract.