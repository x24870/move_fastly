module BridgeOwner::bridge {
    use std::signer;
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_std::event::{Self, EventHandle};
    use MoonCoinOwner::mooncoin::{Self, MoonCoin};
    use aptos_framework::coin::{Self};
    use aptos_framework::account;

    /// Address of the owner of this module
    const MODULE_OWNER: address = @BridgeOwner;

    /// Error codes
    const ENOT_MODULE_OWNER:           u64 = 0;
    const ENOT_BRIDGE_ADMIN:         u64 = 1;
    const ENO_CAPABILITIES:            u64 = 2;
    const ECOIN_NOT_INIT:              u64 = 3;
    const ENOT_ENOUGH_AMOUNT:          u64 = 4;
    const ETX_HAS_OUT:                 u64 = 5;
    const ETX_NOT_EXIST:               u64 = 6;
    const ETX_NOT_UNLOCK:              u64 = 7;
    const EACCOUNT_NOT_REGISTER_COIN:  u64 = 7;
    const EMINT_FAIL:                  u64 = 8;
    const ESUPPLY_ERR:                 u64 = 9;
    const EBRIDGE_ADMIN_ALLOWED_ERR: u64 = 10;
    const EBRIDGE_IS_FROZEN:         u64 = 11;

    // Administrator able to create new BridgeAdmin, freeze/unfreeze the bridge
    struct Administrator has key {
        is_frozen: bool,
    }

    // BridgeAdmin able to mint, burn and freeze 
    struct BridgeAdmin has key {
        allowed_amount: u64,
        freezed: bool,
        unlocked: SimpleMap<vector<u8>, bool>,
        bridge_out_events: EventHandle<BridgeOutEvent>,
        bridge_in_events: EventHandle<BridgeInEvent>,
    }

    // initialzation when module published
    fun init_module(owner: &signer) {
        create_administrator(owner);
    }

    /// Event emitted when some amount of a coin is send into the bridge.
    struct BridgeOutEvent has drop, store {
        eth_addr: vector<u8>,
        amount: u64,
    }

    /// Event emitted when some amount of a coin is send out from the bridge.
    struct BridgeInEvent has drop, store {
        eth_addr: vector<u8>,
        amount: u64,
    }

    fun is_administrator(account_addr: address): bool {
        exists<Administrator>(account_addr)
    }

    fun is_bridge_admin(account_addr: address): bool {
        exists<BridgeAdmin>(account_addr)
    }

    fun is_frozen(): bool acquires Administrator {
        borrow_global<Administrator>(MODULE_OWNER).is_frozen
    }

    fun destory_bridge_admin_resource(bridge_admin: BridgeAdmin) {
        let BridgeAdmin {
            allowed_amount: _,
            freezed: _,
            unlocked: _,
            bridge_out_events: bridge_out_events_,
            bridge_in_events: bridge_in_events_,
        } = bridge_admin;

        aptos_std::event::destroy_handle(bridge_out_events_);
        aptos_std::event::destroy_handle(bridge_in_events_);
    }

    /// This is only called during Genesis, which is where Administrator can be created.
    /// Beyond genesis, no one can create Administrator.
    fun create_administrator(owner: &signer) {
        assert!(signer::address_of(owner) == MODULE_OWNER, ENOT_MODULE_OWNER);

        let administrator = Administrator{is_frozen: false};
        move_to(owner, administrator);
    }

    // Administrator freeze the bridge
    public entry fun freeze_bridge(owner: &signer) acquires Administrator {
        let owner_addr = signer::address_of(owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);

        borrow_global_mut<Administrator>(owner_addr).is_frozen = true;
    }

    // Administrator unfreeze the bridge
    public entry fun unfreeze_bridge(owner: &signer) acquires Administrator {
        let owner_addr = signer::address_of(owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);

        borrow_global_mut<Administrator>(owner_addr).is_frozen = false;
    }

    // Administrator destroy the bridge admin resource
    public entry fun destroy_bridge_admin(
        owner: &signer,
        admin_addr: address,
    ) acquires BridgeAdmin {
        let owner_addr = signer::address_of(owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);
        assert!(is_bridge_admin(admin_addr), ENOT_BRIDGE_ADMIN);

        // get bridge admin resource
        let bridge_admin = move_from<BridgeAdmin>(admin_addr);
        destory_bridge_admin_resource(bridge_admin);
    }

    // Administrator creates bridge admin resource
    public entry fun create_bridge_admin(
        owner: &signer, 
        destination: &signer,
        allowed_amount: u64,
        ) {
        let owner_addr = signer::address_of(owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);

        let bridge_admin = BridgeAdmin{
            allowed_amount: allowed_amount,
            freezed: false,
            unlocked: simple_map::create<vector<u8>, bool>(),
            bridge_out_events: account::new_event_handle<BridgeOutEvent>(destination),
            bridge_in_events: account::new_event_handle<BridgeInEvent>(destination),
        };

        move_to(destination, bridge_admin);
    }

    // Send coins to the bridge means these coins will be burn
    public entry fun bridge_in( 
        account: &signer, 
        admin_addr: address,
        amount: u64,
        eth_addr: vector<u8>
        ) acquires BridgeAdmin, Administrator {
        // check bridge is not frozen
        assert!(!is_frozen(), EBRIDGE_IS_FROZEN);

        let acct_addr = signer::address_of(account);
        // check if account has enough coins
        if (coin::balance<MoonCoin>(acct_addr) < amount) abort ENOT_ENOUGH_AMOUNT;

        // check admin address is correct
        assert!(is_bridge_admin(admin_addr), ENOT_BRIDGE_ADMIN);
        let bridge_admin = borrow_global_mut<BridgeAdmin>(admin_addr);

        // burn amount of coins
        mooncoin::proxy_burn(account, amount);

        // emit bridge in event
        event::emit_event<BridgeInEvent>(
            &mut bridge_admin.bridge_in_events,
            BridgeInEvent { 
                eth_addr: eth_addr,
                amount: amount
            },
        );
    }

    // Mint new token then send out from the bridge
    public entry fun bridge_out(
        admin: &signer, 
        amount: u64, 
        dst_addr: address, 
        eth_tx_hash: vector<u8>,
        eth_addr: vector<u8>
        ) acquires BridgeAdmin, Administrator {
        // check bridge is not frozen
        assert!(!is_frozen(), EBRIDGE_IS_FROZEN);

        // check caller is bridge admin
        let admin_addr = signer::address_of(admin);
        assert!(is_bridge_admin(admin_addr), ENOT_MODULE_OWNER);

        // check allowed amount is enough
        let bridge_admin = borrow_global_mut<BridgeAdmin>(admin_addr);
        if (bridge_admin.allowed_amount < amount) abort ENOT_ENOUGH_AMOUNT;

        // minus allowed amount
        bridge_admin.allowed_amount = bridge_admin.allowed_amount - amount;

        // checking has tx hash unlocked // TODO: Check if default false is valid?
        // let unlocked = table::borrow_mut<vector<u8>, bool>(
        //     &mut bridge_admin.unlocked, eth_tx_hash);
        assert!(simple_map::contains_key<vector<u8>, bool>(
            &bridge_admin.unlocked, &eth_tx_hash) == false, ETX_HAS_OUT);

        simple_map::add<vector<u8>, bool>(&mut bridge_admin.unlocked, eth_tx_hash, false);

        let is_unlocked = simple_map::borrow_mut<vector<u8>, bool>(&mut bridge_admin.unlocked, &eth_tx_hash);
        if (*is_unlocked == true) abort ETX_HAS_OUT;
        *is_unlocked = true;

        // check account has registered the coin
        assert!(coin::is_account_registered<MoonCoin>(dst_addr), EACCOUNT_NOT_REGISTER_COIN);

        // mint coins to dst_addr's account
        mooncoin::proxy_mint(admin, dst_addr, amount);

        // emit bridge out event
        event::emit_event<BridgeOutEvent>(
            &mut bridge_admin.bridge_out_events,
            BridgeOutEvent { 
                eth_addr: eth_addr,
                amount: amount
            },
        );
    }


    #[test_only]
    use std::error;
    use std::option;

    #[test_only]
    fun initialize_mooncoin(owner: &signer) {
        mooncoin::initialize_for_test(owner);
    }

    #[test_only]
    fun initialize_bridge_admin(
        owner: &signer,
        admin: &signer,
    ) {
        create_bridge_admin(
            owner,
            admin,
            100, // allowed amount
            );
    }

    #[test(owner = @BridgeOwner)]
    public fun test_create_administrator(owner: signer) {
        let owner_addr = signer::address_of(&owner);

        create_administrator(&owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);
    }

    #[test(owner = @BridgeOwner, destination = @0xa11ce)]
    public fun test_create_bridge_admin(
        owner: signer, destination: signer) {
        let mod_addr = signer::address_of(&owner);
        let dst_addr = signer::address_of(&destination);
        aptos_framework::account::create_account_for_test(dst_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&owner));

        // init the coin
        initialize_mooncoin(&owner);
        assert!(coin::is_coin_initialized<MoonCoin>(), 0);

        // init this bridge module
        init_module(&owner);
        assert!(is_administrator(mod_addr), ENOT_MODULE_OWNER);

        // init a bridge admin resource to the destination account
        initialize_bridge_admin(&owner, &destination);
        assert!(is_bridge_admin(dst_addr), ENOT_BRIDGE_ADMIN);

        // mock adding dst_addr to mooncoin authorized addresses
        mooncoin::add_authorized_addr_for_test(dst_addr);

        // check bridge admin is able to mint
        mooncoin::register(&destination);
        mooncoin::proxy_mint(&destination, dst_addr, 100);

        assert!(coin::balance<MoonCoin>(dst_addr) == 100, EMINT_FAIL);
    }

    #[test(owner = @BridgeOwner, admin = @0xa11ce, user = @0xb0b)]
    public fun test_bridge_in_out (
        owner: signer, admin: signer, user: signer) 
        acquires BridgeAdmin, Administrator {
        let mod_addr = signer::address_of(&owner);
        let admin_addr = signer::address_of(&admin);
        let user_addr = signer::address_of(&user);
        aptos_framework::account::create_account_for_test(admin_addr);
        aptos_framework::account::create_account_for_test(user_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&owner));

        // init the coin
        initialize_mooncoin(&owner);
        assert!(coin::is_coin_initialized<MoonCoin>(), ECOIN_NOT_INIT);

        // init this bridge module
        init_module(&owner);
        assert!(is_administrator(mod_addr), ENOT_MODULE_OWNER);

        // init a bridge admin resource to the destination account
        initialize_bridge_admin(&owner, &admin);
        assert!(is_bridge_admin(admin_addr), ENOT_MODULE_OWNER);
        
        // mock adding admin_addr to mooncoin authorized addresses
        mooncoin::add_authorized_addr_for_test(admin_addr);

        // user register mooncoin
        mooncoin::register(&user);

        // bridge admin calls bridge_out
        let txhash = b"0xf103"; 
        let eth_addr = b"0x00000000000000000000000000000000000c11ff";
        bridge_out(&admin, 100, user_addr, txhash, eth_addr);

        // check user has received the minted coins
        assert!(coin::balance<MoonCoin>(user_addr) == 100, EMINT_FAIL);

        // check bridge admin's allowed amount has decreased
        let bridge_admin = borrow_global<BridgeAdmin>(admin_addr);
        assert!(bridge_admin.allowed_amount == 0, EBRIDGE_ADMIN_ALLOWED_ERR);
        
        // check the tx hash been marked as unlocked
        let is_unlocked = simple_map::borrow<vector<u8>, bool>(&bridge_admin.unlocked, &txhash);
        assert!(*is_unlocked == true, ETX_NOT_UNLOCK);

        // check supply increased
        assert!(*option::borrow(&coin::supply<MoonCoin>()) == 100, ESUPPLY_ERR);

        // user calls bridge_in
        bridge_in(&user, admin_addr, 50, eth_addr);

        // check amount of coins has been withdraw from user account
        assert!(coin::balance<MoonCoin>(user_addr) == 50, EMINT_FAIL);

        // check supply decreased
        assert!(*option::borrow(&coin::supply<MoonCoin>()) == 50, ESUPPLY_ERR);

        // destroy bridge admin resource
        destroy_bridge_admin(&owner, admin_addr);

        // check this account is not admin anymore
        assert!(is_bridge_admin(admin_addr) == false, error::invalid_state(0));
    }

    #[test(owner = @BridgeOwner, admin = @0xa11ce)]
    public fun test_freeze_unfreeze(
        owner: signer, admin: signer
        ) acquires Administrator {
        let mod_addr = signer::address_of(&owner);
        let admin_addr = signer::address_of(&admin);
        aptos_framework::account::create_account_for_test(admin_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&owner));

        // init the coin
        initialize_mooncoin(&owner);
        assert!(coin::is_coin_initialized<MoonCoin>(), 0);

        // init this bridge module
        init_module(&owner);
        assert!(is_administrator(mod_addr), ENOT_MODULE_OWNER);

        // init a bridge admin resource to the destination account
        initialize_bridge_admin(&owner, &admin);
        assert!(is_bridge_admin(admin_addr), ENOT_BRIDGE_ADMIN);

        // mock adding admin_addr to mooncoin authorized addresses
        mooncoin::add_authorized_addr_for_test(admin_addr);

        // check bridge admin is able to mint
        mooncoin::register(&admin);
        mooncoin::proxy_mint(&admin, admin_addr, 100);

        assert!(coin::balance<MoonCoin>(admin_addr) == 100, EMINT_FAIL);

        // freeze the bridge
        freeze_bridge(&owner);
        assert!(is_frozen(), error::invalid_state(0));

        unfreeze_bridge(&owner);
        assert!(!is_frozen(), error::invalid_state(0));
    }

    #[test(owner = @BridgeOwner, admin = @0xa11ce, user = @0xb0b)]
    #[expected_failure(abort_code = 11)]
    public fun fail_mint_cuz_frozen(
        owner: signer, admin: signer, user: signer) 
        acquires BridgeAdmin, Administrator {
        let mod_addr = signer::address_of(&owner);
        let admin_addr = signer::address_of(&admin);
        let user_addr = signer::address_of(&user);
        aptos_framework::account::create_account_for_test(admin_addr);
        aptos_framework::account::create_account_for_test(user_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&owner));

        // init the coin
        initialize_mooncoin(&owner);
        assert!(coin::is_coin_initialized<MoonCoin>(), ECOIN_NOT_INIT);

        // init this bridge module
        init_module(&owner);
        assert!(is_administrator(mod_addr), ENOT_MODULE_OWNER);

        // init a bridge admin resource to the destination account
        initialize_bridge_admin(&owner, &admin);
        assert!(is_bridge_admin(admin_addr), ENOT_MODULE_OWNER);
        
        // mock adding admin_addr to mooncoin authorized addresses
        mooncoin::add_authorized_addr_for_test(admin_addr);

        // user register mooncoin
        mooncoin::register(&user);

        // freeze the bridge
        freeze_bridge(&owner);
        assert!(is_frozen(), error::invalid_state(0));

        // bridge admin calls bridge_out
        let txhash = b"0xf103";
        let eth_addr = b"0x00000000000000000000000000000000000c11ff"; 
        bridge_out(&admin, 100, user_addr, txhash, eth_addr);
    }

    #[test(owner = @BridgeOwner, admin = @0xa11ce, user = @0xb0b)]
    #[expected_failure(abort_code = 3)]
    public fun fail_mint_cuz_admin_disabled(
        owner: signer, admin: signer, user: signer) 
        acquires BridgeAdmin, Administrator {
        let mod_addr = signer::address_of(&owner);
        let admin_addr = signer::address_of(&admin);
        let user_addr = signer::address_of(&user);
        aptos_framework::account::create_account_for_test(admin_addr);
        aptos_framework::account::create_account_for_test(user_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&owner));

        // init the coin
        initialize_mooncoin(&owner);
        assert!(coin::is_coin_initialized<MoonCoin>(), ECOIN_NOT_INIT);

        // init this bridge module
        init_module(&owner);
        assert!(is_administrator(mod_addr), ENOT_MODULE_OWNER);

        // init a bridge admin resource to the destination account
        initialize_bridge_admin(&owner, &admin);
        assert!(is_bridge_admin(admin_addr), ENOT_MODULE_OWNER);
        
        // mock adding admin_addr to mooncoin authorized addresses
        mooncoin::add_authorized_addr_for_test(admin_addr);

        // mooncoin module owner disable this authorized address
        mooncoin::disable_authorized_addr_for_test(admin_addr);

        // user register mooncoin
        mooncoin::register(&user);

        // bridge admin calls bridge_out
        let txhash = b"0xf103";
        let eth_addr = b"f103000000add355";
        bridge_out(&admin, 100, user_addr, txhash, eth_addr);
    }
}