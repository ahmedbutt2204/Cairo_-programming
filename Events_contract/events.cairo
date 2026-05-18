// This contract demonstrates how to use Events in Cairo/Starknet.
// Events allow smart contracts to log activity on the blockchain.

#[starknet::interface]
pub trait IEventExample<TContractState> {
    fn emit_custom_event(ref self: TContractState, value: u32);
}

#[starknet::contract]
pub mod EventExample {
    #[storage]
    struct Storage {}

    // 1. Define the Event enum
    // This groups all the different events this contract can emit.
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ValueChanged: ValueChanged,
    }

    // 2. Define the specific event structure
    // This tells the event what data it needs to hold.
    #[derive(Drop, starknet::Event)]
    pub struct ValueChanged {
        pub new_value: u32,
    }

    #[abi(embed_v0)]
    impl EventExampleImpl of super::IEventExample<ContractState> {
        // 3. Function to trigger the event
        fn emit_custom_event(ref self: ContractState, value: u32) {
            
            // Emit the event using self.emit()
            self.emit(Event::ValueChanged(ValueChanged { new_value: value }));
        }
    }
}
