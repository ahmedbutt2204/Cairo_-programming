// Assignment: Tuples in Cairo
// Name: Hamza Qamar Ansari
// Roll No: BSCS22023

#[executable]
fn main() {
    // Declare a tuple with three elements: felt, bool, felt
    let tup: (felt, bool, felt) = (7, true, 15);

    // Print the whole tuple and each element individually
    println!("Tuple: {:?}", tup);
    println!("First: {}", tup.0);
    println!("Second: {}", tup.1);
    println!("Third: {}", tup.2);
}
