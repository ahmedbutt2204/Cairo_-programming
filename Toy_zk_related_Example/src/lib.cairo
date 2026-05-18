// ============================================================
// ZK Commitment System - Main Entry Point
// Author: Afsah Ur Rehman
// Description: Toy Zero-Knowledge Commitment & Verification
//              Simulates ZK proofs using Poseidon hashing.
//              Age is NEVER revealed; only its hash is shared.
// ============================================================

// import core logic module
mod zk_commitment;

// import demo runner module
mod demo;

// import tests (only compiled during `scarb test`)
#[cfg(test)]
mod tests;

// Entry point for: scarb execute --executable-name demo
#[executable]
fn main() {
    // run the live demo with age=25, score=80 (a valid user)
    demo::demo_run(25, 80);
}
