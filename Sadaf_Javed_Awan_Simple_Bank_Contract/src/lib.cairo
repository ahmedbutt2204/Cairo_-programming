// Simple Bank Contract - Cairo Smart Contract

use starknet::ContractAddress;

#[starknet::interface]
trait IBankContract<TContractState> {
    fn deposit(ref self: TContractState, amount: u256);
    fn withdraw(ref self: TContractState, amount: u256);
    fn get_balance(self: @TContractState, user: ContractAddress) -> u256;
    fn get_total_balance(self: @TContractState) -> u256;
    fn get_owner(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
mod SimpleBankContract {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        StoragePathEntry, Map
    };

    #[storage]
    struct Storage {
        owner: ContractAddress,
        balances: Map<ContractAddress, u256>,
        total_deposits: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deposited: Deposited,
        Withdrawn: Withdrawn,
    }

    #[derive(Drop, starknet::Event)]
    struct Deposited {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdrawn {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self.total_deposits.write(0);
    }

    #[abi(embed_v0)]
    impl BankContractImpl of super::IBankContract<ContractState> {

        fn deposit(ref self: ContractState, amount: u256) {
            assert(amount > 0, 'Amount must be > 0');
            let caller = get_caller_address();
            let current_balance = self.balances.entry(caller).read();
            self.balances.entry(caller).write(current_balance + amount);
            let total = self.total_deposits.read();
            self.total_deposits.write(total + amount);
            self.emit(Deposited { user: caller, amount });
        }

        fn withdraw(ref self: ContractState, amount: u256) {
            assert(amount > 0, 'Amount must be > 0');
            let caller = get_caller_address();
            let current_balance = self.balances.entry(caller).read();
            assert(current_balance >= amount, 'Insufficient balance');
            self.balances.entry(caller).write(current_balance - amount);
            let total = self.total_deposits.read();
            self.total_deposits.write(total - amount);
            self.emit(Withdrawn { user: caller, amount });
        }

        fn get_balance(self: @ContractState, user: ContractAddress) -> u256 {
            self.balances.entry(user).read()
        }

        fn get_total_balance(self: @ContractState) -> u256 {
            self.total_deposits.read()
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
    }
}
