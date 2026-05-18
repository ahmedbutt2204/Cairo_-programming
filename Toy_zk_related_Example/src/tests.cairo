// ============================================================
// tests.cairo
// Full Test Suite - 9 Test Cases
//
// Tests verify correctness of the ZK commitment system:
//   1. Valid user PASS
//   2. Underage user FAIL
//   3. Boundary age = 18 PASS
//   4. Boundary score = 50 PASS
//   5. Score < 50 FAIL
//   6. Commitment consistency (same age -> same hash)
//   7. Commitment uniqueness (different ages -> different hash)
//   8. Tampered commitment detection -> FAIL
//   9. Mixed invalid combination -> FAIL
// ============================================================

// import core functions from the zk_commitment module
use super::zk_commitment::{generate_commitment, verify_commitment};

// ------------------------------------------------------------
// Test 1: Valid user (age=25, score=80) must PASS
// ------------------------------------------------------------
#[test]
fn test_valid_user_passes() {
    let age = 25_u64;
    let score = 80_u64;
    // generate the commitment (as the prover would)
    let commitment = generate_commitment(age);
    // verifier should approve this user
    assert!(verify_commitment(commitment, age, score), "Valid user (25, 80) must PASS");
}

// ------------------------------------------------------------
// Test 2: Underage user (age=16, score=80) must FAIL
// ------------------------------------------------------------
#[test]
fn test_underage_user_fails() {
    let age = 16_u64;
    let score = 80_u64;
    let commitment = generate_commitment(age);
    // age < 18 so verification must fail
    assert!(!verify_commitment(commitment, age, score), "Underage user (16, 80) must FAIL");
}

// ------------------------------------------------------------
// Test 3: Boundary age exactly = 18 must PASS
// ------------------------------------------------------------
#[test]
fn test_boundary_age_18_passes() {
    let age = 18_u64;
    let score = 60_u64;
    let commitment = generate_commitment(age);
    // age = 18 is exactly at the boundary, must PASS
    assert!(verify_commitment(commitment, age, score), "Boundary age 18 must PASS");
}

// ------------------------------------------------------------
// Test 4: Boundary score exactly = 50 must PASS
// ------------------------------------------------------------
#[test]
fn test_boundary_score_50_passes() {
    let age = 20_u64;
    let score = 50_u64;
    let commitment = generate_commitment(age);
    // score = 50 is exactly at the boundary, must PASS
    assert!(verify_commitment(commitment, age, score), "Boundary score 50 must PASS");
}

// ------------------------------------------------------------
// Test 5: Score below 50 (score=49) must FAIL
// ------------------------------------------------------------
#[test]
fn test_low_score_fails() {
    let age = 25_u64;
    let score = 49_u64;
    let commitment = generate_commitment(age);
    // score is 1 below threshold, must FAIL
    assert!(!verify_commitment(commitment, age, score), "Score below 50 (49) must FAIL");
}

// ------------------------------------------------------------
// Test 6: Commitment consistency
// Same age always produces the same hash
// ------------------------------------------------------------
#[test]
fn test_commitment_consistency() {
    let age = 30_u64;
    // hash the same age twice
    let hash1 = generate_commitment(age);
    let hash2 = generate_commitment(age);
    // Poseidon is deterministic - same input must give same output
    assert!(hash1 == hash2, "Same age must always produce same commitment hash");
}

// ------------------------------------------------------------
// Test 7: Commitment uniqueness
// Different ages must produce different hashes
// ------------------------------------------------------------
#[test]
fn test_commitment_uniqueness() {
    let hash_20 = generate_commitment(20_u64);
    let hash_21 = generate_commitment(21_u64);
    // different ages must give different hashes (collision resistance)
    assert!(hash_20 != hash_21, "Different ages must produce different commitment hashes");
}

// ------------------------------------------------------------
// Test 8: Tampered commitment must be detected and FAIL
// ------------------------------------------------------------
#[test]
fn test_tampered_commitment_fails() {
    let real_age = 25_u64;
    let score = 80_u64;
    // attacker uses a commitment from a different age (tampering)
    let tampered_commitment = generate_commitment(99_u64);
    // verifier must detect the mismatch and reject
    assert!(
        !verify_commitment(tampered_commitment, real_age, score),
        "Tampered commitment must be detected and FAIL",
    );
}

// ------------------------------------------------------------
// Test 9: Mixed invalid combination (underage + low score) must FAIL
// ------------------------------------------------------------
#[test]
fn test_mixed_invalid_fails() {
    let age = 15_u64;
    let score = 40_u64;
    let commitment = generate_commitment(age);
    // both age and score fail - overall result must FAIL
    assert!(
        !verify_commitment(commitment, age, score), "Mixed invalid (15, 40) must FAIL",
    );
}
