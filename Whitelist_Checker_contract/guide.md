# Whitelist Checker Assignment Report

## How to run it
You need Windows PowerShell, Scarb, Starkli, an internet connection, and a funded Sepolia account. You also need the project files `Scarb.toml`, `src/whitelist_checker.cairo`, `src/lib.cairo`, and the wallet files `starkli-wallet/account.json` and `starkli-wallet/keystore.json`. I could not use WSL, so everything below is the native Windows path.

Before anything works, check the tool versions:

```powershell
scarb --version
starkli --version
```

For this project I used `scarb 2.11.4` and `starkli 0.4.2`.

## What the contract does
The contract is a simple whitelist checker. It stores one owner address and a map of whitelisted addresses. Only the owner can call `add_to_whitelist`. Anyone can call `get_owner` and `is_whitelisted`.

## Project files
The source file is `src/whitelist_checker.cairo`. The module file is `src/lib.cairo`. The build config is `Scarb.toml`. The wallet files are inside `starkli-wallet`. The important build output is `target/dev/assignment_4_WhitelistChecker.contract_class.json`.

## Commands I ran first
I started by checking the tool versions:

```powershell
scarb --version
starkli --version
```

Then I checked the project layout:

```powershell
tree /F
```

I also checked what was inside `target/dev`:

```powershell
dir .\target\dev\
```

That showed these two files:

- `assignment_4.starknet_artifacts.json`
- `assignment_4_WhitelistChecker.contract_class.json`

## Build step
I rebuilt many times while testing fixes:

```powershell
scarb clean
scarb build
```

That was the correct rebuild step every time I changed the build state or removed old files.

## Main constraint
My main constraint was that I could not use WSL. That blocked the suggested `sncast` path, because it was not installed on native Windows here and I did not want a Linux setup. So I stayed on PowerShell and Starkli.

## First big error
The first major error was a compiled class hash mismatch during declaration. The command I tried was:

```powershell
starkli declare .\target\dev\assignment_4_WhitelistChecker.contract_class.json --account .\starkli-wallet\account.json --keystore .\starkli-wallet\keystore.json --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg
```

The error said the compiled class hash did not match the expected one. Starkli printed one hash as the actual CASM hash and a different one as the expected hash.

The key values were:

- Actual CASM hash: `0x042b9e4176d2d8a6cbcf0080f2923d06560a92c06cb0eb2897419c7e7e5c25ea`
- Expected hash: `0x6c06135812ef70fc3229e9992c91d10c3ad2bb21fb2588b7139c88d73afa1b8`

This told me the Cairo code was not the problem. The artifact and the network expected hash were not matching.

## Things I tried that failed
I tried `--compiler-version 2.11.4`:

```powershell
starkli declare .\target\dev\assignment_4_WhitelistChecker.contract_class.json --account .\starkli-wallet\account.json --keystore .\starkli-wallet\keystore.json --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg --compiler-version 2.11.4
```

That flag was ignored and Starkli warned me about it.

I tried `--casm-hash` with the wrong value first:

```powershell
starkli declare .\target\dev\assignment_4_WhitelistChecker.contract_class.json --casm-hash 0x042b9e4176d2d8a6cbcf0080f2923d06560a92c06cb0eb2897419c7e7e5c25ea --account .\starkli-wallet\account.json --keystore .\starkli-wallet\keystore.json --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg
```

That still failed with the mismatch error.

I also tried `class-by-hash` on the same hash:

```powershell
starkli class-by-hash 0x06a0c28e45934c3de7da59f95acf83420815192f3cdf3119cf7f303fba7db98f --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg --parse parsedclass.json
```

That failed with `ClassHashNotFound` because that class was not already on chain.

I also accidentally tried to declare `parsedclass.json` later, which failed because it was not a valid contract artifact:

```powershell
starkli declare parsedclass.json --account .\starkli-wallet\account.json --keystore .\starkli-wallet\keystore.json --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg
```

That gave `failed to parse contract artifact`.

## What finally solved the declare issue
The fix was to use the correct CASM hash that Starkli printed as the expected one. I ran:

```powershell
starkli declare .\target\dev\assignment_4_WhitelistChecker.contract_class.json --casm-hash 0x6c06135812ef70fc3229e9992c91d10c3ad2bb21fb2588b7139c88d73afa1b8 --account $env:STARKNET_ACCOUNT --keystore $env:STARKNET_KEYSTORE --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg
```

That worked. Starkli printed the declaration transaction hash and the class hash as declared.

## Wallet setup
I created the wallet folder first:

```powershell
mkdir starkli-wallet
```

Then I created the keystore:

```powershell
starkli signer keystore new .\starkli-wallet\keystore.json
```

Then I initialized the account config:

```powershell
starkli account oz init .\starkli-wallet\account.json --keystore .\starkli-wallet\keystore.json
```

Then I deployed the account:

```powershell
starkli account deploy .\starkli-wallet\account.json --keystore .\starkli-wallet\keystore.json --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg
```

That command asked me to fund the account address before it could finish.

The first funded account address was:

```text
0x06902a29570ff82eeb4252dd728409e3535cef1d23a7fa7faa0ad06893c093d1
```

That was the first account I deployed, but later I learned it was not the account I should use for the final contract flow.

## Account mistake I made
I deployed the first contract with the wrong owner address. Then I tried to call `add_to_whitelist` from a different account config. Because of that mismatch, the contract rejected the call with:

```text
Only owner can call
```

This was the biggest logic mistake in the whole process.

The mistake was not in the contract code. It was in the relationship between three things:

- the deployed account,
- the owner stored in the contract,
- and the account used to sign the invoke.

They must match if the contract checks the owner.

## How I checked the account files
I printed the account file contents with:

```powershell
Get-Content $env:STARKNET_ACCOUNT
```

That showed the deployed account address, public key, and class hash.

The account JSON showed:

```text
address: 0x79d74949338fcc90cf68eb81406077b7744131570185b102550f9679efa15ed
```

I also checked the keystore file with:

```powershell
Get-Content $env:STARKNET_KEYSTORE
```

That confirmed the wallet file existed and was being used.

## Why the first invoke failed
I first deployed the contract with the owner set to `0x06902a...`, but the signer I later used for the invoke was the account from `account.json`, which was `0x79d749...`. The contract owner and the transaction signer were not the same, so the contract rejected the call.

The error trace showed nested contract execution and ended at the contract message:

```text
Only owner can call
```

That was the proof that the owner guard worked.

## The second deployment that fixed it
After I saw the mismatch, I deployed the contract again, but this time I used the same account address as the constructor owner:

```powershell
starkli deploy 0x06a0c28e45934c3de7da59f95acf83420815192f3cdf3119cf7f303fba7db98f 0x79d74949338fcc90cf68eb81406077b7744131570185b102550f9679efa15ed --account $env:STARKNET_ACCOUNT --keystore $env:STARKNET_KEYSTORE --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg
```

That deployment succeeded.

The final working contract address was:

```text
0x03da65ab7060f7bb7fab68c64738f1177e3e317f82b3ddef6cd77228430ec76b
```

## Commands I used to verify the contract
I checked the owner with:

```powershell
starkli call 0x03da65ab7060f7bb7fab68c64738f1177e3e317f82b3ddef6cd77228430ec76b get_owner --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg
```

That returned the correct owner address:

```text
0x079d74949338fcc90cf68eb81406077b7744131570185b102550f9679efa15ed
```

I then invoked the whitelist write function:

```powershell
starkli invoke 0x03da65ab7060f7bb7fab68c64738f1177e3e317f82b3ddef6cd77228430ec76b add_to_whitelist 0x079d74949338fcc90cf68eb81406077b7744131570185b102550f9679efa15ed --account $env:STARKNET_ACCOUNT --keystore $env:STARKNET_KEYSTORE --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg
```

That finally worked and printed an invoke transaction hash.

Then I checked the whitelist status:

```powershell
starkli call 0x03da65ab7060f7bb7fab68c64738f1177e3e317f82b3ddef6cd77228430ec76b is_whitelisted 0x079d74949338fcc90cf68eb81406077b7744131570185b102550f9679efa15ed --rpc https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/m8a0cM5IzRMGmJF9rJIOg
```

That returned:

```text
0x0000000000000000000000000000000000000000000000000000000000000001
```

So the answer was `true`.

## Commands that failed and why
`sncast account create` failed because `sncast` was not installed and I was not using WSL.

`starkliup` failed because that command does not exist.

`Remove-Item .\target -Recurse -Force` and similar cleanup commands failed when I typed them badly with missing backslashes or broken paths.

`starkli invoke ... 0xREALADDRESS ...` failed because `0xREALADDRESS` is not a valid Felt value.

`starkli declare ... --compiled-class-hash ...` failed because that flag does not exist for `declare`.

`starkli declare ...` with the wrong RPC version also failed with JSON-RPC invalid params / invalid block id errors.

## Meaning of the important commands
`scarb clean` removes old build output.

`scarb build` compiles the Cairo project.

`starkli signer keystore new` creates a private-key file protected by a password.

`starkli account oz init` creates the account JSON for an OpenZeppelin-style account.

`starkli account deploy` deploys that account on Sepolia.

`starkli declare` registers the contract class on chain.

`starkli deploy` creates a live contract instance from the declared class.

`starkli call` reads contract data without changing state.

`starkli invoke` sends a transaction that changes contract state.

`class-by-hash` fetches an already declared class from chain.

## What I learned overall
I learned that Starknet work is sensitive to exact file names, exact addresses, and exact account ownership. I learned that a valid build does not guarantee a successful declaration. I also learned that a contract can be correct and still fail if the wrong account sends the transaction.

I learned how to work through errors one by one instead of guessing. I learned how to inspect the generated files, check account data, and compare owner values. I also learned that on Windows, without WSL, I should stay with the toolchain that actually runs natively.

## Final working values
Working account address:

```text
0x79d74949338fcc90cf68eb81406077b7744131570185b102550f9679efa15ed
```

Working contract address:

```text
0x03da65ab7060f7bb7fab68c64738f1177e3e317f82b3ddef6cd77228430ec76b
```

Working whitelist test address:

```text
0x079d74949338fcc90cf68eb81406077b7744131570185b102550f9679efa15ed
```