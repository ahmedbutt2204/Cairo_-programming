#[starknet::contract]
mod WhitelistChecker {

    use starknet::ContractAddress;
    use starknet::get_caller_address;

    use starknet::storage::{
        Map,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };

    #[storage]
    struct Storage {
        whitelist: Map<ContractAddress, bool>,
        owner: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    fn assert_only_owner(self: @ContractState) {
        let caller = get_caller_address();
        let owner = self.owner.read();

        assert(caller == owner, 'Only owner can call');
    }

    #[external(v0)]
    fn add_to_whitelist(
        ref self: ContractState,
        address: ContractAddress
    ) {
        assert_only_owner(@self);

        self.whitelist.write(address, true);
    }

    #[external(v0)]
    fn is_whitelisted(
        self: @ContractState,
        address: ContractAddress
    ) -> bool {
        self.whitelist.read(address)
    }

    #[external(v0)]
    fn get_owner(
        self: @ContractState
    ) -> ContractAddress {
        self.owner.read()
    }
}