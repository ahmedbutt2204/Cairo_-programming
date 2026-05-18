# Guide to Events in Cairo

## What are Events?
In Starknet and Cairo, smart contracts cannot easily "talk" directly to the outside world (like a web frontend). **Events** are the solution. They are a way for a smart contract to emit logs or notifications to the blockchain when something important happens. External applications can listen for these events and react to them.

## How to implement Events in Cairo
Based on the `events.cairo` file in this folder, here are the steps to create an event:

1. **The `#[event]` Enum:** You must create an `enum` named `Event` and annotate it with `#[event]` and `#[derive(Drop, starknet::Event)]`. This enum acts as a container for all the different events your contract might emit.

2. **The Event Struct:**
   For every variant in your Event enum, you need a corresponding `struct` that defines the actual data you want to log. In my code, this is the `ValueChanged` struct, which holds a `u32` integer.

3. **Emitting the Event:**
   Inside an implementation function, you trigger the event using the `self.emit()` method. You pass the constructed event variant into this method. 

By logging events, we make smart contracts transparent and easy to track on block explorers.
