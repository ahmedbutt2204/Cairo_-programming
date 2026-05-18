// ============================================================
// zk_commitment.cairo
// Core ZK Commitment Logic using Poseidon Hash
//
// KEY IDEA:
//   - User has a secret: age (u64)
//   - We NEVER expose age directly
//   - Instead we expose: commitment = Poseidon_hash(age)
//   - Verifier recomputes hash(age) and compares it
//   - Then checks age >= 18 AND score >= 50
// ============================================================

use core::poseidon::poseidon_hash_span;

// ------------------------------------------------------------
// generate_commitment(age) -> felt252
// Creates a Poseidon hash of the age value.
// This is the "commitment" - it hides the real age.
// ------------------------------------------------------------
pub fn generate_commitment(age: u64) -> felt252 {
    // convert age to felt252 so it can be hashed
    let age_felt: felt252 = age.into();

    // poseidon_hash_span is a ZK-friendly hash function
    // it takes a span of felt252 values and returns one felt252
    poseidon_hash_span(array![age_felt].span())
}

// ------------------------------------------------------------
// verify_age_constraint(age) -> bool
// Returns true if age >= 18 (old enough).
// ------------------------------------------------------------
pub fn verify_age_constraint(age: u64) -> bool {
    // check age condition
    age >= 18
}

// ------------------------------------------------------------
// verify_score_constraint(score) -> bool
// Returns true if score >= 50 (passing score).
// ------------------------------------------------------------
pub fn verify_score_constraint(score: u64) -> bool {
    // check score condition
    score >= 50
}

// ------------------------------------------------------------
// verify_commitment(commitment, age, score) -> bool
//
// Full ZK verification in 4 steps:
//   1. Recompute hash(age)
//   2. Compare with stored commitment -> if mismatch return false
//   3. Check age >= 18            -> if fails return false
//   4. Check score >= 50          -> if fails return false
//   5. Return true (all checks passed)
// ------------------------------------------------------------
pub fn verify_commitment(commitment: felt252, age: u64, score: u64) -> bool {
    // Step 1: recompute the hash from the given age
    let recomputed = generate_commitment(age);

    // Step 2: compare recomputed hash with the provided commitment
    // if they don't match, the data was tampered or incorrect
    if recomputed != commitment {
        return false;
    }

    // Step 3: check age constraint (must be >= 18)
    if !verify_age_constraint(age) {
        return false;
    }

    // Step 4: check score constraint (must be >= 50)
    if !verify_score_constraint(score) {
        return false;
    }

    // all checks passed - user is valid
    true
}
