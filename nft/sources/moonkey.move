module owner::moonkey {
    use aptos_framework::account;
    use aptos_std::ed25519;
    use aptos_std::table;
    use aptos_std::type_info;
    use std::signer;
    use std::string;
    use std::vector;
    use aptos_token::token;

    #[test_only]
    use aptos_std::debug;

    const MAX_SUPPLY: u64 = 10000;

    struct Moonkey {}

    struct MoonkeyMinter has store, key {
        counter: u64,
        mints: table::Table<address, bool>,
        public_key: ed25519::ValidatedPublicKey,
        minting_enabled: bool,
        signer_cap: account::SignerCapability,
    }

    const ENOT_AUTHORIZED:           u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED:      u64 = 3;

    const SEP: vector<u8> = b"::";

    const COLLECTION_NAME: vector<u8> = b"Moonkey";
    const TOKEN_NAME: vector<u8> = b"Moonkey";

    const TOKEN_URI: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmWHpqznqbNx6oixmmg53mnJug2UcjSpXULX7QGMkTSSfk";

    fun init_module(sender: &signer) {
        // init the module once
        if (exists<MoonkeyMinter>(signer::address_of(sender))) {
            return
        };

        // Set up default public key
        let public_key = std::option::extract(&mut ed25519::new_validated_public_key_from_bytes(x"5a4fc3b498f2d816435bc792b460122db0188d61b4f46cb658c8c7dcef8cf721"));

        // Create the resource account, so we can get ourselves as signer later
        let (resource, signer_cap) = account::create_resource_account(sender, vector::empty());

        // Set up NFT collection
        let collection_name = string::utf8(COLLECTION_NAME);
        let description = string::utf8(b"Moonkey is the typo of monkey");
        let collection_uri = string::utf8(b"https://gateway.pinata.cloud/ipfs/QmWHpqznqbNx6oixmmg53mnJug2UcjSpXULX7QGMkTSSfk");
        let maximum_supply = MAX_SUPPLY;
        let mutate_setting = vector<bool>[ false, false, false ];
        token::create_collection(&resource, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        move_to(sender, MoonkeyMinter { counter: 1, mints: table::new(), public_key, minting_enabled: true, signer_cap });
    }

    fun get_resource_signer(): signer acquires MoonkeyMinter {
        account::create_signer_with_capability(&borrow_global<MoonkeyMinter>(@owner).signer_cap)
    }

    public entry fun rotate_key(sign: signer, new_public_key: vector<u8>) acquires MoonkeyMinter {
        let sender = signer::address_of(&sign);
        assert!(sender == @owner, ENOT_AUTHORIZED);
        let public_key = std::option::extract(&mut ed25519::new_validated_public_key_from_bytes(new_public_key));
        let mm = borrow_global_mut<MoonkeyMinter>(sender);
        mm.public_key = public_key;
    }

    public entry fun set_minting_enabled(sign: signer, minting_enabled: bool) acquires MoonkeyMinter {
        let sender = signer::address_of(&sign);
        assert!(sender == @owner, ENOT_AUTHORIZED);
        let mm = borrow_global_mut<MoonkeyMinter>(sender);
        mm.minting_enabled = minting_enabled;
    }

    const HEX_SYMBOLS: vector<u8> = b"0123456789abcdef";

    public entry fun claim_mint(sign: &signer) acquires MoonkeyMinter {
        let mm = borrow_global<MoonkeyMinter>(@owner);
        assert!(mm.minting_enabled, EMINTING_NOT_ENABLED);
        do_mint(sign);
        set_minted(sign);
    }

    fun do_mint(sign: &signer) acquires MoonkeyMinter {
        // Mints 1 NFT to the signer
        let sender = signer::address_of(sign);

        let resource = get_resource_signer();

        let mm = borrow_global_mut<MoonkeyMinter>(@owner);

        let count_str = u64_to_string(mm.counter);

        // Set up the NFT
        let collection_name = string::utf8(COLLECTION_NAME);
        let tokendata_name = string::utf8(TOKEN_NAME);
        string::append_utf8(&mut tokendata_name, b": ");
        string::append(&mut tokendata_name, count_str);
        let nft_maximum: u64 = 1;
        let description = string::utf8(b"Long Live the Testnet!");
        // let token_uri: string::String = string::utf8(TOKEN_URL_PREFIX);
        let token_uri: string::String = string::utf8(TOKEN_URI);
        string::append(&mut token_uri, count_str);
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 0;
        let royalty_points_numerator: u64 = 0;
        let token_mutate_config = token::create_token_mutability_config(&vector<bool>[ false, true, false, false, true ]);
        let property_keys: vector<string::String> = vector::singleton(string::utf8(b"mint_number"));
        let property_values: vector<vector<u8>> = vector::singleton(*string::bytes(&u64_to_hex_string(mm.counter)));
        let property_types: vector<string::String> = vector::singleton(string::utf8(b"number"));

        let token_data_id = token::create_tokendata(
            &resource,
            collection_name,
            tokendata_name,
            description,
            nft_maximum,
            token_uri,
            royalty_payee_address,
            royalty_points_denominator,
            royalty_points_numerator,
            token_mutate_config,
            property_keys,
            property_values,
            property_types
        );

        let token_id = token::mint_token(&resource, token_data_id, 1);

        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        token::transfer(&resource, token_id, sender, 1);
        mm.counter = mm.counter + 1;
    }

    fun set_minted(sign: &signer) acquires MoonkeyMinter {
        let mm = borrow_global_mut<MoonkeyMinter>(@owner);
        let signer_addr = signer::address_of(sign);
        assert!(table::contains(&mm.mints, signer_addr) == false, EHAS_ALREADY_CLAIMED_MINT);
        table::add(&mut mm.mints, signer_addr, true);
    }

    fun u64_to_hex_string(value: u64): string::String {
        if (value == 0) {
            return string::utf8(b"0x00")
        };
        let temp: u64 = value;
        let length: u64 = 0;
        while (temp != 0) {
            length = length + 1;
            temp = temp >> 8;
        };
        to_hex_string_fixed_length(value, length)
    }
    fun to_hex_string_fixed_length(value: u64, length: u64): string::String {
        let buffer = vector::empty<u8>();

        let i: u64 = 0;
        while (i < length * 2) {
            vector::push_back(&mut buffer, *vector::borrow(&mut HEX_SYMBOLS, (value & 0xf as u64)));
            value = value >> 4;
            i = i + 1;
        };
        assert!(value == 0, 1);
        vector::append(&mut buffer, b"x0");
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }

    fun bytes_to_hex_string(bytes: &vector<u8>): string::String {
        let length = vector::length(bytes);
        let buffer = b"0x";

        let i: u64 = 0;
        while (i < length) {
            let byte = *vector::borrow(bytes, i);
            vector::push_back(&mut buffer, *vector::borrow(&mut HEX_SYMBOLS, (byte >> 4 & 0xf as u64)));
            vector::push_back(&mut buffer, *vector::borrow(&mut HEX_SYMBOLS, (byte & 0xf as u64)));
            i = i + 1;
        };
        string::utf8(buffer)
    }

    fun address_to_hex_string(addr: &address): string::String {
        let addr_bytes = std::bcs::to_bytes(addr);
        bytes_to_hex_string(&addr_bytes)
    }

    public entry fun address_to_hex_string_script(addr: &address): string::String {
        let addr_bytes = std::bcs::to_bytes(addr);
        bytes_to_hex_string(&addr_bytes)
    }

    fun full_type_string<T>(): string::String {
        let info = type_info::type_of<T>();
        let full_name = string::utf8(vector::empty());
        let account_address = address_to_hex_string(&type_info::account_address(&info));
        string::append(&mut full_name, account_address);
        string::append_utf8(&mut full_name, SEP);
        string::append_utf8(&mut full_name, type_info::module_name(&info));
        string::append_utf8(&mut full_name, SEP);
        string::append_utf8(&mut full_name, type_info::struct_name(&info));
        full_name
    }

    public entry fun full_type_string_script<T>(): string::String {
        let info = type_info::type_of<T>();
        let full_name = string::utf8(vector::empty());
        let account_address = address_to_hex_string(&type_info::account_address(&info));
        string::append(&mut full_name, account_address);
        string::append_utf8(&mut full_name, SEP);
        string::append_utf8(&mut full_name, type_info::module_name(&info));
        string::append_utf8(&mut full_name, SEP);
        string::append_utf8(&mut full_name, type_info::struct_name(&info));
        full_name
    }

    fun u64_to_string(value: u64): string::String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }

    public entry fun u64_to_string_script(value: u64): string::String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }

    #[test(sign = @0x123ff)]
    public entry fun test_address_to_hex_string(sign: signer) {
        let str = address_to_hex_string(&signer::address_of(&sign));
        debug::print(&str);
        assert!(string::bytes(&str) == &b"0x00000000000000000000000000000000000000000000000000000000000123ff", 100002);
    }

    #[test(owner=@owner)]
    public entry fun test_full_type_string(owner: signer) {
        let str = full_type_string<Moonkey>();
        debug::print(&str);
        let result = address_to_hex_string(&signer::address_of(&owner));
        string::append_utf8(&mut result, b"::moonkey::Moonkey");
        assert!(str == result, 100003);
    }

    #[test_only]
    public fun setup_and_mint(sign: &signer, aptos: &signer) {
        account::create_account_for_test(signer::address_of(sign));
        account::create_account_for_test(signer::address_of(aptos));
        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(aptos);
        aptos_framework::coin::destroy_burn_cap(burn_cap);
        aptos_framework::coin::destroy_mint_cap(mint_cap);
    }

    #[test(sign = @0x123ff, owner = @owner)]
    public entry fun test_set_minted(
        sign: signer, owner: signer
    ) acquires MoonkeyMinter {
        account::create_account_for_test(signer::address_of(&owner));
        init_module(&owner);
        set_minted(&sign);
    }

    #[test(sign = @0x123ff, owner = @owner)]
    #[expected_failure(abort_code = 2)]
    public entry fun test_set_minted_fails(
        sign: signer, owner: signer
    ) acquires MoonkeyMinter {
        account::create_account_for_test(signer::address_of(&owner));
        init_module(&owner);
        set_minted(&sign);
        set_minted(&sign);
    }

    #[test(sign = @0x123ff, owner = @owner, aptos = @0x1)]
    public entry fun test_e2e(
        sign: signer, owner: signer, aptos: signer
    ) acquires MoonkeyMinter {
        setup_and_mint(&sign, &aptos);
        account::create_account_for_test(signer::address_of(&owner));
        init_module(&owner);

        claim_mint(&sign);

        // Ensure the NFT exists
        let resource = get_resource_signer();
        let token_name = string::utf8(TOKEN_NAME);
        string::append_utf8(&mut token_name, b": 1");
        let token_id = token::create_token_id_raw(signer::address_of(&resource), string::utf8(COLLECTION_NAME), token_name, 0);
        let new_token = token::withdraw_token(&sign, token_id, 1);
        // Put it back so test doesn't explode
        token::deposit_token(&sign, new_token);
    }

    #[test]
    public entry fun test_u64_to_hex_string2() {
        let eleven = u64_to_hex_string(18);
        debug::print(&eleven);
        assert!(string::bytes(&eleven) == &b"0x12", 100004);
    }

}