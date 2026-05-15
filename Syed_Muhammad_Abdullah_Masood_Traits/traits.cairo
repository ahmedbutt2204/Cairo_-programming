// Assignment: Traits in Cairo
// Name: Syed Muhammad Abdullah Masood
// Roll No: BSCS22054

trait Describable {
    fn describe(self: @Self);
}

struct Book {
    title: felt,
}

impl Describable of Book {
    fn describe(self: @Book) {
        // TODO: Print the book title
        // Example: println!("Book: Cairo for Beginners");
    }
}

fn main() {
    // TODO: Create a Book instance and call describe
}
