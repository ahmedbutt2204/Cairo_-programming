// ============================================================
// demo.cairo
// Live Execution Simulation of ZK Commitment System
//
// demo_run(age, score) prints a step-by-step log showing:
//   - the input values
//   - generated commitment hash
//   - hash verification result
//   - age constraint check
//   - score constraint check
//   - final PASS or FAIL decision
// ============================================================

// import functions from sibling module zk_commitment
use super::zk_commitment::{
    generate_commitment, verify_commitment, verify_age_constraint, verify_score_constraint,
};

// ------------------------------------------------------------
// demo_run(age, score)
// Simulates a live ZK verification session step by step.
// This is used both for the executable demo and for logging.
// ------------------------------------------------------------
pub fn demo_run(age: u64, score: u64) {
    println!("==========================================");
    println!("   ZK Commitment & Verification Demo");
    println!("==========================================");
    println!("");

    // show the input values
    println!("[INPUT]");
    println!("  age   = {}", age);
    println!("  score = {}", score);
    println!("");

    // generate the commitment hash (prover sends this, NOT the raw age)
    let commitment = generate_commitment(age);
    println!("[COMMITMENT GENERATED]");
    println!("  hash(age) = {}", commitment);
    println!("  (The verifier only sees this hash, never the real age)");
    println!("");

    println!("[VERIFICATION STEPS]");

    // Step 1: Hash Verification
    // verifier re-hashes the age and checks it matches the commitment
    let recomputed = generate_commitment(age);
    let hash_ok = recomputed == commitment;
    if hash_ok {
        println!("  Step 1 - Hash Verification : PASS");
    } else {
        println!("  Step 1 - Hash Verification : FAIL  (commitment mismatch!)");
    }

    // Step 2: Age Constraint Check
    // verifier checks age >= 18
    let age_ok = verify_age_constraint(age);
    if age_ok {
        println!("  Step 2 - Age Check (>= 18) : PASS");
    } else {
        println!("  Step 2 - Age Check (>= 18) : FAIL  (age is below 18)");
    }

    // Step 3: Score Constraint Check
    // verifier checks score >= 50
    let score_ok = verify_score_constraint(score);
    if score_ok {
        println!("  Step 3 - Score Check(>= 50): PASS");
    } else {
        println!("  Step 3 - Score Check(>= 50): FAIL  (score is below 50)");
    }

    println!("");

    // Final Decision - uses full verify_commitment which repeats all steps internally
    let result = verify_commitment(commitment, age, score);
    if result {
        println!("[FINAL DECISION] --> PASS");
        println!("  User is verified: age and score meet requirements.");
    } else {
        println!("[FINAL DECISION] --> FAIL");
        println!("  User failed one or more verification checks.");
    }

    println!("");
    println!("==========================================");
}
