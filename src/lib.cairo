#[derive(Copy, Drop, Serde, starknet::Store)]
struct Book {
    book_title: felt252,
    book_author: felt252,
    book_price: u256,
    book_qty: u8
}

#[starknet::interface]
pub trait IBookStore<TContractState> {
    fn add_book(
        ref self: TContractState,
        book_id: felt252,
        book_title: felt252,
        book_author: felt252,
        book_price: u256,
        book_qty: u8
    );
    fn update_title(ref self: TContractState, book_id: felt252, updated_title: felt252);
    fn update_book_qty(ref self: TContractState, book_id: felt252, updated_qty: u8);
    fn sell_book(ref self: TContractState, book_id: felt252, qty_sold: u8);
    fn get_book(self: @TContractState, book_id: felt252) -> Book;
}

#[starknet::contract]
pub mod BookStore {
    use starknet::event::EventEmitter;
    use super::{Book, IBookStore};
    use core::starknet::{
        get_caller_address, ContractAddress,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess}
    };

    #[storage]
    struct Storage {
        books: Map<felt252, Book>, // map each book_id to an instance of Book
        storekeeper_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BookAdded: BookAdded,
        BookQtyUpdated: BookQtyUpdated,
        BookTitleUpdated: BookTitleUpdated,
        BookSold: BookSold,
    }

    #[derive(Drop, starknet::Event)]
    struct BookAdded {
        book_title: felt252,
        book_author: felt252,
        book_id: felt252,
        book_qty: u8
    }

    #[derive(Drop, starknet::Event)]
    struct BookQtyUpdated {
        book_title: felt252,
        book_author: felt252,
        book_id: felt252,
        book_qty: u8
    }

    #[derive(Drop, starknet::Event)]
    struct BookTitleUpdated {
        book_title: felt252,
        book_author: felt252,
        book_id: felt252,
        book_qty: u8
    }

    #[derive(Drop, starknet::Event)]
    struct BookSold {
        book_title: felt252,
        book_author: felt252,
        book_id: felt252,
        old_book_qty: u8,
        qty_sold: u8,
        new_book_qty: u8,
    }

    #[constructor]
    fn constructor(ref self: ContractState, storekeeper_address: ContractAddress) {
        self.storekeeper_address.write(storekeeper_address)
    }

    #[abi(embed_v0)]
    impl BookStoreImpl of IBookStore<ContractState> {
        fn add_book(
            ref self: ContractState,
            book_id: felt252,
            book_title: felt252,
            book_author: felt252,
            book_price: u256,
            book_qty: u8
        ) {
            let storekeeper_address = self.storekeeper_address.read();
            assert(get_caller_address() == storekeeper_address, 'Only Storekeeper can add book');
            let book = Book {
                book_title: book_title,
                book_author: book_author,
                book_price: book_price,
                book_qty: book_qty,
            };
            self.books.write(book_id, book);
            self.emit(BookAdded { book_title, book_author, book_id, book_qty });
        }

        fn update_title(ref self: ContractState, book_id: felt252, updated_title: felt252) {
            let storekeeper_address = self.storekeeper_address.read();
            assert(get_caller_address() == storekeeper_address, 'Only Storekeeper can add book');
            let mut book = self.books.read(book_id);
            book.book_title = updated_title;
            self.books.write(book_id, book);
            self
                .emit(
                    BookTitleUpdated {
                        book_title: book.book_title,
                        book_author: book.book_author,
                        book_id,
                        book_qty: book.book_qty
                    }
                );
        }

        fn update_book_qty(ref self: ContractState, book_id: felt252, updated_qty: u8) {
            let storekeeper_address = self.storekeeper_address.read();
            assert(get_caller_address() == storekeeper_address, 'Only Storekeeper can add book');
            let mut book = self.books.read(book_id);
            book.book_qty = updated_qty;
            self.books.write(book_id, book);
            self
                .emit(
                    BookQtyUpdated {
                        book_title: book.book_title,
                        book_author: book.book_author,
                        book_id,
                        book_qty: updated_qty
                    }
                )
        }

        fn sell_book(ref self: ContractState, book_id: felt252, qty_sold: u8) {
            let storekeeper_address = self.storekeeper_address.read();
            assert(get_caller_address() == storekeeper_address, 'Only Storekeeper can add book');
            let mut book = self.books.read(book_id);
            let old_book_qty = book.book_qty;
            assert(qty_sold <= book.book_qty, 'Cannot sell more than stock');
            let new_book_qty = book.book_qty - qty_sold;
            book.book_qty = new_book_qty;
            self.books.write(book_id, book);
            self
                .emit(
                    BookSold {
                        book_title: book.book_title,
                        book_author: book.book_author,
                        book_id,
                        old_book_qty: old_book_qty,
                        qty_sold,
                        new_book_qty
                    }
                );
        }

        fn get_book(self: @ContractState, book_id: felt252) -> Book {
            self.books.read(book_id)
        }
    }
}
// #[starknet::interface]
// pub trait IHelloStarknet<TContractState> {
//     fn increase_balance(ref self: TContractState, amount: felt252);
//     fn get_balance(self: @TContractState) -> felt252;
// }

// #[starknet::contract]
// mod HelloStarknet {
//     #[storage]
//     struct Storage {
//         balance: felt252,
//     }

//     #[abi(embed_v0)]
//     impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
//         fn increase_balance(ref self: ContractState, amount: felt252) {
//             assert(amount != 0, 'Amount cannot be 0');
//             self.balance.write(self.balance.read() + amount);
//         }

//         fn get_balance(self: @ContractState) -> felt252 {
//             self.balance.read()
//         }
//     }
// }

