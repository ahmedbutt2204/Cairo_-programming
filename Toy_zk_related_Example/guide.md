# Toy ZK Commitment & Verification System

**Author:** Afsah Ur Rehman  
**Subject:** Blockchain Programming — Cairo 2.x Assignment  
**Topic:** Zero-Knowledge Commitment using Poseidon Hash

---

## What is a Zero-Knowledge Commitment?

A **Zero-Knowledge (ZK) commitment** lets a user *prove* something about their secret data **without revealing the data itself**.

### Real-World Example

Imagine you need to prove you are **18 or older** to enter a website, but you do not want to show your actual birthday.

With a ZK commitment:
1. You **hash** your age using a special math function (Poseidon).
2. You send the **hash** to the verifier — not your real age.
3. The verifier **re-hashes** the value you claim and checks it matches.
4. If it matches, and the age satisfies the rules, you are approved.

The verifier **never sees your actual age** — only the hash. That is the "zero-knowledge" part.

---

## How Hashing Hides the Secret

A **hash function** is a one-way function:

```
hash(age = 25)  -->  some_big_number (commitment)
```

- Given the commitment, you **cannot reverse it** to find age = 25.
- The same input **always produces the same output** (deterministic).
- Different inputs **always produce different outputs** (collision resistant).

So the hash acts as a *locked box*: the verifier can check the box matches, but cannot open it.

---

## Why Age is Never Directly Exposed

In this system:

```
User sends:  commitment = hash(25)       <-- only the hash
User sends:  score = 80                  <-- score is public

Verifier does:
  recompute = hash(claimed_age)
  if recompute != commitment  -->  REJECT (tampered!)
  if age < 18                -->  REJECT (underage)
  if score < 50              -->  REJECT (low score)
  else                       -->  APPROVE
```

The verifier **never directly trusts** the age value — it always verifies the hash first.

---

## Business Rules

| Rule         | Requirement     |
|--------------|-----------------|
| Age check    | `age >= 18`     |
| Score check  | `score >= 50`   |
| Hash check   | `hash(age)` must match stored commitment |

A user is approved only if **all three rules** pass.

---

## Project Structure

```
Afsah_Ur_Rehman_Toy_zk_related_Example/
├── Scarb.toml              # Scarb package config (edition 2024_07)
├── run_demo.ps1            # PowerShell: clears logs + runs demo
├── logs.txt                # Auto-generated demo log (overwritten each run)
├── guide.md                # This file
└── src/
    ├── lib.cairo           # Entry point: declares modules + #[executable] main
    ├── zk_commitment.cairo # Core ZK logic: hash, constraints, verification
    ├── demo.cairo          # Live demo runner: step-by-step output
    └── tests.cairo         # Test suite: 9 test cases
```

---

## Source Files Explained

### `src/zk_commitment.cairo`
Core logic. Contains:
- `generate_commitment(age)` — returns `Poseidon_hash(age)`
- `verify_age_constraint(age)` — returns `true` if `age >= 18`
- `verify_score_constraint(score)` — returns `true` if `score >= 50`
- `verify_commitment(commitment, age, score)` — full 4-step verification

### `src/demo.cairo`
Demo runner. Contains:
- `demo_run(age, score)` — prints step-by-step ZK verification output

### `src/tests.cairo`
Test suite. Contains 9 `#[test]` functions covering all scenarios.

### `src/lib.cairo`
Root module. Wires everything together. Has the `#[executable]` entry point.

---

## Commands

### Build the project
```bash
scarb build
```

### Run all 9 tests
```bash
scarb test
```
Expected output: **9/9 tests pass**

### Run the live demo (prints step-by-step output)
```bash
scarb execute --executable-name demo
```

### Run demo via PowerShell (also saves output to logs.txt)
```powershell
.\run_demo.ps1
```

---

## Expected Demo Output

```
==========================================
   ZK Commitment & Verification Demo
==========================================

[INPUT]
  age   = 25
  score = 80

[COMMITMENT GENERATED]
  hash(age) = <poseidon hash value>
  (The verifier only sees this hash, never the real age)

[VERIFICATION STEPS]
  Step 1 - Hash Verification : PASS
  Step 2 - Age Check (>= 18) : PASS
  Step 3 - Score Check(>= 50): PASS

[FINAL DECISION] --> PASS
  User is verified: age and score meet requirements.

==========================================
```

---

## Test Cases (9/9)

| # | Description                           | Expected |
|---|---------------------------------------|----------|
| 1 | Valid user (age=25, score=80)         | PASS     |
| 2 | Underage user (age=16, score=80)      | FAIL     |
| 3 | Boundary age = 18                     | PASS     |
| 4 | Boundary score = 50                   | PASS     |
| 5 | Score below 50 (score=49)             | FAIL     |
| 6 | Same age → same hash (consistency)   | PASS     |
| 7 | Different ages → different hash       | PASS     |
| 8 | Tampered commitment detected          | FAIL     |
| 9 | Mixed invalid (age=15, score=40)      | FAIL     |

---

## Key Concepts Used

| Concept             | Details                                        |
|---------------------|------------------------------------------------|
| Poseidon Hash       | `core::poseidon::poseidon_hash_span`           |
| ZK Commitment       | `hash(secret)` replaces the secret itself      |
| felt252             | Cairo's native field element type              |
| `#[executable]`     | Marks the entry function for `scarb execute`   |
| `#[test]`           | Marks test functions for `scarb test`          |
| `#[cfg(test)]`      | Includes module only during test compilation   |

---

## How to Read the Logs

After running `.\run_demo.ps1`, open `logs.txt`:

```
=== ZK Commitment Demo Log ===
Run Time : 2026-05-17 14:00:00
================================

--- Demo Output ---
[all demo output here]
=== End of Log ===
```

Logs are **fully overwritten** on every run — no stale output accumulates.
