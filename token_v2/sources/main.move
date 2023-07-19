module owner::blocto_venture {
    use std::signer;
    use std::string;
    use aptos_framework::account;
    use aptos_framework::object::{Self, Object};
    use aptos_token_objects::aptos_token::{Self, AptosToken};

    public fun init(creator: &signer) {
        let collection_name = string::utf8(b"blocto venture");
        let token_name = string::utf8(b"sword");
        let flag = true;

        aptos_token::create_collection(
            creator,
            string::utf8(b"collection description"),
            1,
            collection_name,
            string::utf8(b"collection uri"),
            flag,
            flag,
            flag,
            flag,
            flag,
            flag,
            flag,
            flag,
            flag,
            1,
            100,
        );

        // aptos_token::collection_object(creator, &collection_name);
    }


    public entry fun mint(creator: &signer) {
        let collection_name = string::utf8(b"blocto venture");
        let token_name = string::utf8(b"sword");

        aptos_token::mint(
            creator,
            collection_name,
            string::utf8(b"description"),
            token_name,
            string::utf8(b"uri"),
            vector[string::utf8(b"bool")],
            vector[string::utf8(b"bool")],
            vector[vector[0x01]],
        );

        let creator_addr = signer::address_of(creator);
        let token_creation_num = account::get_guid_next_creation_num(creator_addr);
        let token = object::address_to_object<AptosToken>(object::create_guid_object_address(creator_addr, token_creation_num));
        object::transfer(creator, token, @0x345);
    }
}