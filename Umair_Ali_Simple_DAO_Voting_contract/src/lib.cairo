// =====================================================
// Simple DAO Voting Contract
// Author: Umair Ali
// Description: Members can create proposals and vote.
//              Owner manages membership.
//              Tracks YES/NO votes and proposal status.
// =====================================================

use starknet::ContractAddress;

// ---------------------------------------------------
// INTERFACE — defines all public functions
// ---------------------------------------------------
#[starknet::interface]
pub trait IDAOVoting<TContractState> {
    // Owner only: add a new member
    fn add_member(ref self: TContractState, member: ContractAddress);

    // Any member: create a proposal
    fn create_proposal(ref self: TContractState, title: felt252, description: felt252) -> u64;

    // Any member: vote YES=true or NO=false
    fn vote(ref self: TContractState, proposal_id: u64, support: bool);

    // Anyone: close voting and record result
    fn close_proposal(ref self: TContractState, proposal_id: u64);

    // Read functions
    fn get_proposal(self: @TContractState, proposal_id: u64) -> (felt252, felt252, u64, u64, bool);
    fn get_proposal_count(self: @TContractState) -> u64;
    fn is_member(self: @TContractState, addr: ContractAddress) -> bool;
    fn has_voted(self: @TContractState, proposal_id: u64, voter: ContractAddress) -> bool;
}

// ---------------------------------------------------
// CONTRACT MODULE
// ---------------------------------------------------
#[starknet::contract]
pub mod DAOVoting {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::Map;
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::StorageMapReadAccess;
    use starknet::storage::StorageMapWriteAccess;

    // ---------------------------------------------------
    // STORAGE — all on-chain data stored here
    // ---------------------------------------------------
    #[storage]
    struct Storage {
        // Admin who deployed the contract
        owner: ContractAddress,

        // Total proposals created
        proposal_count: u64,

        // Proposal data — each field stored separately
        proposal_title: Map<u64, felt252>,
        proposal_description: Map<u64, felt252>,
        proposal_yes: Map<u64, u64>,
        proposal_no: Map<u64, u64>,
        proposal_closed: Map<u64, bool>,
        proposal_passed: Map<u64, bool>,

        // Track who has voted on which proposal
        voted: Map<(u64, ContractAddress), bool>,

        // DAO members whitelist
        members: Map<ContractAddress, bool>,
    }

    // ---------------------------------------------------
    // EVENTS — logged permanently on blockchain
    // ---------------------------------------------------
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        MemberAdded: MemberAdded,
        ProposalCreated: ProposalCreated,
        VoteCast: VoteCast,
        ProposalClosed: ProposalClosed,
    }

    #[derive(Drop, starknet::Event)]
    pub struct MemberAdded {
        #[key]
        pub member: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ProposalCreated {
        #[key]
        pub proposal_id: u64,
        pub title: felt252,
        pub creator: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct VoteCast {
        #[key]
        pub proposal_id: u64,
        pub voter: ContractAddress,
        pub support: bool,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ProposalClosed {
        #[key]
        pub proposal_id: u64,
        pub passed: bool,
        pub yes_votes: u64,
        pub no_votes: u64,
    }

    // ---------------------------------------------------
    // CONSTRUCTOR — runs once when deployed
    // ---------------------------------------------------
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // Save owner
        self.owner.write(owner);
        // Owner is automatically a member
        self.members.write(owner, true);
        // Start proposal counter at zero
        self.proposal_count.write(0);
    }

    // ---------------------------------------------------
    // INTERNAL HELPERS — private checks
    // ---------------------------------------------------
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn only_owner(self: @ContractState) {
            assert(get_caller_address() == self.owner.read(), 'Only owner allowed');
        }

        fn only_member(self: @ContractState) {
            assert(self.members.read(get_caller_address()), 'Only members allowed');
        }

        fn proposal_exists(self: @ContractState, id: u64) {
            assert(id < self.proposal_count.read(), 'Proposal not found');
        }
    }

    // ---------------------------------------------------
    // PUBLIC FUNCTIONS — callable by users
    // ---------------------------------------------------
    #[abi(embed_v0)]
    impl DAOVotingImpl of super::IDAOVoting<ContractState> {

        // Add a new DAO member (owner only)
        fn add_member(ref self: ContractState, member: ContractAddress) {
            self.only_owner();
            assert(!self.members.read(member), 'Already a member');
            self.members.write(member, true);
            self.emit(MemberAdded { member });
        }

        // Create a new proposal (members only)
        fn create_proposal(ref self: ContractState, title: felt252, description: felt252) -> u64 {
            self.only_member();

            // Get next available id
            let id = self.proposal_count.read();

            // Save proposal details
            self.proposal_title.write(id, title);
            self.proposal_description.write(id, description);
            self.proposal_yes.write(id, 0);
            self.proposal_no.write(id, 0);
            self.proposal_closed.write(id, false);
            self.proposal_passed.write(id, false);

            // Increment counter
            self.proposal_count.write(id + 1);

            // Emit event
            self.emit(ProposalCreated { proposal_id: id, title, creator: get_caller_address() });

            id
        }

        // Cast a vote (members only, once per proposal)
        fn vote(ref self: ContractState, proposal_id: u64, support: bool) {
            self.only_member();
            self.proposal_exists(proposal_id);

            let caller = get_caller_address();

            // Check not already voted
            assert(!self.voted.read((proposal_id, caller)), 'You already voted');

            // Check proposal is still open
            assert(!self.proposal_closed.read(proposal_id), 'Proposal is closed');

            // Record vote
            self.voted.write((proposal_id, caller), true);

            // Tally the vote
            if support {
                let yes = self.proposal_yes.read(proposal_id);
                self.proposal_yes.write(proposal_id, yes + 1);
            } else {
                let no = self.proposal_no.read(proposal_id);
                self.proposal_no.write(proposal_id, no + 1);
            }

            self.emit(VoteCast { proposal_id, voter: caller, support });
        }

        // Close a proposal and record result (anyone can call)
        fn close_proposal(ref self: ContractState, proposal_id: u64) {
            self.proposal_exists(proposal_id);

            // Cannot close twice
            assert(!self.proposal_closed.read(proposal_id), 'Already closed');

            let yes = self.proposal_yes.read(proposal_id);
            let no = self.proposal_no.read(proposal_id);

            // Passed if YES votes are more than NO votes
            let passed = yes > no;

            self.proposal_closed.write(proposal_id, true);
            self.proposal_passed.write(proposal_id, passed);

            self.emit(ProposalClosed { proposal_id, passed, yes_votes: yes, no_votes: no });
        }

        // Read proposal details
        // Returns: (title, description, yes_votes, no_votes, passed)
        fn get_proposal(self: @ContractState, proposal_id: u64) -> (felt252, felt252, u64, u64, bool) {
            self.proposal_exists(proposal_id);
            (
                self.proposal_title.read(proposal_id),
                self.proposal_description.read(proposal_id),
                self.proposal_yes.read(proposal_id),
                self.proposal_no.read(proposal_id),
                self.proposal_passed.read(proposal_id),
            )
        }

        // Total proposals created
        fn get_proposal_count(self: @ContractState) -> u64 {
            self.proposal_count.read()
        }

        // Check if address is a member
        fn is_member(self: @ContractState, addr: ContractAddress) -> bool {
            self.members.read(addr)
        }

        // Check if someone already voted on a proposal
        fn has_voted(self: @ContractState, proposal_id: u64, voter: ContractAddress) -> bool {
            self.voted.read((proposal_id, voter))
        }
    }
}
