use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use dao_voting::IDAOVotingDispatcher;
use dao_voting::IDAOVotingDispatcherTrait;
use starknet::ContractAddress;
use starknet::contract_address_const;

// Deploy and return dispatcher + owner address
fn deploy() -> (IDAOVotingDispatcher, ContractAddress) {
    let owner: ContractAddress = contract_address_const::<0x1>();
    let contract = declare("DAOVoting").unwrap().contract_class();
    let (address, _) = contract.deploy(@array![owner.into()]).unwrap();
    (IDAOVotingDispatcher { contract_address: address }, owner)
}

// TEST 1: Owner is set correctly and is a member
#[test]
fn test_owner_is_member() {
    let (dao, owner) = deploy();
    assert(dao.is_member(owner), 'owner should be member');
}

// TEST 2: Owner can add a member
#[test]
fn test_add_member() {
    let (dao, owner) = deploy();
    let alice: ContractAddress = contract_address_const::<0x2>();
    start_cheat_caller_address(dao.contract_address, owner);
    dao.add_member(alice);
    stop_cheat_caller_address(dao.contract_address);
    assert(dao.is_member(alice), 'alice should be member');
}

// TEST 3: Non-owner cannot add member
#[test]
#[should_panic(expected: ('Only owner allowed',))]
fn test_non_owner_cannot_add_member() {
    let (dao, _) = deploy();
    let alice: ContractAddress = contract_address_const::<0x2>();
    let bob: ContractAddress = contract_address_const::<0x3>();
    start_cheat_caller_address(dao.contract_address, bob);
    dao.add_member(alice);
    stop_cheat_caller_address(dao.contract_address);
}

// TEST 4: Member can create proposal
#[test]
fn test_create_proposal() {
    let (dao, owner) = deploy();
    start_cheat_caller_address(dao.contract_address, owner);
    let id = dao.create_proposal('Fund team', 'Pay developers');
    stop_cheat_caller_address(dao.contract_address);
    assert(id == 0, 'first id should be 0');
    assert(dao.get_proposal_count() == 1, 'count should be 1');
}

// TEST 5: Non-member cannot create proposal
#[test]
#[should_panic(expected: ('Only members allowed',))]
fn test_non_member_cannot_propose() {
    let (dao, _) = deploy();
    let stranger: ContractAddress = contract_address_const::<0x99>();
    start_cheat_caller_address(dao.contract_address, stranger);
    dao.create_proposal('Test', 'Desc');
    stop_cheat_caller_address(dao.contract_address);
}

// TEST 6: Full flow — create, vote, close
#[test]
fn test_full_voting_flow() {
    let (dao, owner) = deploy();
    let alice: ContractAddress = contract_address_const::<0x2>();
    let bob: ContractAddress = contract_address_const::<0x3>();

    // Add members
    start_cheat_caller_address(dao.contract_address, owner);
    dao.add_member(alice);
    dao.add_member(bob);

    // Create proposal
    let id = dao.create_proposal('Hire designer', 'For UI work');
    stop_cheat_caller_address(dao.contract_address);

    // Owner votes YES
    start_cheat_caller_address(dao.contract_address, owner);
    dao.vote(id, true);
    stop_cheat_caller_address(dao.contract_address);

    // Alice votes YES
    start_cheat_caller_address(dao.contract_address, alice);
    dao.vote(id, true);
    stop_cheat_caller_address(dao.contract_address);

    // Bob votes NO
    start_cheat_caller_address(dao.contract_address, bob);
    dao.vote(id, false);
    stop_cheat_caller_address(dao.contract_address);

    // Close proposal
    start_cheat_caller_address(dao.contract_address, owner);
    dao.close_proposal(id);
    stop_cheat_caller_address(dao.contract_address);

    // Check result: 2 YES vs 1 NO → passed
    let (_, _, yes, no, passed) = dao.get_proposal(id);
    assert(yes == 2, 'yes should be 2');
    assert(no == 1, 'no should be 1');
    assert(passed, 'should have passed');
}

// TEST 7: Cannot vote twice
#[test]
#[should_panic(expected: ('You already voted',))]
fn test_no_double_vote() {
    let (dao, owner) = deploy();
    start_cheat_caller_address(dao.contract_address, owner);
    dao.create_proposal('Test', 'Desc');
    dao.vote(0, true);
    dao.vote(0, true);
    stop_cheat_caller_address(dao.contract_address);
}

// TEST 8: Cannot vote on closed proposal
#[test]
#[should_panic(expected: ('Proposal is closed',))]
fn test_cannot_vote_on_closed() {
    let (dao, owner) = deploy();
    start_cheat_caller_address(dao.contract_address, owner);
    dao.create_proposal('Test', 'Desc');
    dao.close_proposal(0);
    dao.vote(0, true);
    stop_cheat_caller_address(dao.contract_address);
}

// TEST 9: Proposal fails when NO wins
#[test]
fn test_proposal_fails() {
    let (dao, owner) = deploy();
    let alice: ContractAddress = contract_address_const::<0x2>();
    start_cheat_caller_address(dao.contract_address, owner);
    dao.add_member(alice);
    dao.create_proposal('Rejected', 'Will fail');
    dao.vote(0, false);
    stop_cheat_caller_address(dao.contract_address);
    start_cheat_caller_address(dao.contract_address, alice);
    dao.vote(0, false);
    stop_cheat_caller_address(dao.contract_address);
    start_cheat_caller_address(dao.contract_address, owner);
    dao.close_proposal(0);
    stop_cheat_caller_address(dao.contract_address);
    let (_, _, _, _, passed) = dao.get_proposal(0);
    assert(!passed, 'should have failed');
}

// TEST 10: has_voted works correctly
#[test]
fn test_has_voted_check() {
    let (dao, owner) = deploy();
    start_cheat_caller_address(dao.contract_address, owner);
    dao.create_proposal('Check', 'Voted?');
    assert(!dao.has_voted(0, owner), 'should not have voted yet');
    dao.vote(0, true);
    assert(dao.has_voted(0, owner), 'should have voted');
    stop_cheat_caller_address(dao.contract_address);
}
