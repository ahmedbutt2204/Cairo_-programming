// ============================================================
// Authentication Logic Contract
// Author: Zainab Iftikhar
// Topic: Authentication Logic in Cairo Smart Contracts
// Description: This contract demonstrates role-based access
//              control with owner management and address
//              whitelisting on Starknet.
// ============================================================

#[starknet::interface]
trait IAuthContract<TContractState> {
    fn get_owner(self: @TContractState) -> starknet::ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: starknet::ContractAddress);
    fn add_to_whitelist(ref self: TContractState, address: starknet::ContractAddress);
    fn remove_from_whitelist(ref self: TContractState, address: starknet::ContractAddress);
    fn is_whitelisted(self: @TContractState, address: starknet::ContractAddress) -> bool;
    fn grant_admin_role(ref self: TContractState, address: starknet::ContractAddress);
    fn revoke_admin_role(ref self: TContractState, address: starknet::ContractAddress);
    fn is_admin(self: @TContractState, address: starknet::ContractAddress) -> bool;
    fn owner_only_action(ref self: TContractState) -> felt252;
    fn whitelist_only_action(ref self: TContractState) -> felt252;
    fn admin_only_action(ref self: TContractState) -> felt252;
}

#[starknet::contract]
mod AuthContract {
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        whitelist: LegacyMap<ContractAddress, bool>,
        admins: LegacyMap<ContractAddress, bool>,
        whitelist_count: u32,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnershipTransferred: OwnershipTransferred,
        AddressWhitelisted: AddressWhitelisted,
        AddressRemovedFromWhitelist: AddressRemovedFromWhitelist,
        AdminGranted: AdminGranted,
        AdminRevoked: AdminRevoked,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        #[key]
        previous_owner: ContractAddress,
        #[key]
        new_owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct AddressWhitelisted {
        #[key]
        address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct AddressRemovedFromWhitelist {
        #[key]
        address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct AdminGranted {
        #[key]
        address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct AdminRevoked {
        #[key]
        address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let deployer = get_caller_address();
        self.owner.write(deployer);
        self.admins.write(deployer, true);
        self.whitelist.write(deployer, true);
        self.whitelist_count.write(1);
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn assert_only_owner(self: @ContractState) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Caller is not the owner');
        }

        fn assert_only_whitelisted(self: @ContractState) {
            let caller = get_caller_address();
            let is_whitelisted = self.whitelist.read(caller);
            assert(is_whitelisted, 'Caller is not whitelisted');
        }

        fn assert_only_admin(self: @ContractState) {
            let caller = get_caller_address();
            let is_admin = self.admins.read(caller);
            assert(is_admin, 'Caller is not an admin');
        }
    }

    #[abi(embed_v0)]
    impl AuthContractImpl of super::IAuthContract<ContractState> {

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            self.assert_only_owner();
            let previous_owner = self.owner.read();
            self.owner.write(new_owner);
            self.admins.write(new_owner, true);
            self.emit(OwnershipTransferred { previous_owner, new_owner });
        }

        fn add_to_whitelist(ref self: ContractState, address: ContractAddress) {
            self.assert_only_admin();
            let already_whitelisted = self.whitelist.read(address);
            if !already_whitelisted {
                self.whitelist.write(address, true);
                let count = self.whitelist_count.read();
                self.whitelist_count.write(count + 1);
                self.emit(AddressWhitelisted { address });
            }
        }

        fn remove_from_whitelist(ref self: ContractState, address: ContractAddress) {
            self.assert_only_admin();
            let owner = self.owner.read();
            assert(address != owner, 'Cannot remove owner');
            let was_whitelisted = self.whitelist.read(address);
            if was_whitelisted {
                self.whitelist.write(address, false);
                let count = self.whitelist_count.read();
                self.whitelist_count.write(count - 1);
                self.emit(AddressRemovedFromWhitelist { address });
            }
        }

        fn is_whitelisted(self: @ContractState, address: ContractAddress) -> bool {
            self.whitelist.read(address)
        }

        fn grant_admin_role(ref self: ContractState, address: ContractAddress) {
            self.assert_only_owner();
            self.admins.write(address, true);
            self.emit(AdminGranted { address });
        }

        fn revoke_admin_role(ref self: ContractState, address: ContractAddress) {
            self.assert_only_owner();
            let owner = self.owner.read();
            assert(address != owner, 'Cannot revoke owner admin');
            self.admins.write(address, false);
            self.emit(AdminRevoked { address });
        }

        fn is_admin(self: @ContractState, address: ContractAddress) -> bool {
            self.admins.read(address)
        }

        fn owner_only_action(ref self: ContractState) -> felt252 {
            self.assert_only_owner();
            42
        }

        fn whitelist_only_action(ref self: ContractState) -> felt252 {
            self.assert_only_whitelisted();
            1
        }

        fn admin_only_action(ref self: ContractState) -> felt252 {
            self.assert_only_admin();
            99
        }
    }
}