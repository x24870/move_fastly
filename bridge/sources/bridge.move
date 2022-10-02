module MoonCoin::bridge {
    use std::signer;
    use std::option::{Self};
    use aptos_std::table::{Self, Table};
    use aptos_std::event::{Self, EventHandle};
    use MoonCoin::moon_coin::MoonCoin;
    use aptos_framework::coin::{Self, Coin, BurnCapability, MintCapability};
    use aptos_framework::managed_coin;
    use aptos_framework::account;

    /// Address of the owner of this module
    const MODULE_OWNER: address = @MoonCoin;

    /// Error codes
    const ENOT_MODULE_OWNER:          u64 = 0;
    const ENOT_BRIDGE_ADMIN:          u64 = 1;
    const ENO_CAPABILITIES:           u64 = 2;
    const ECOIN_NOT_INIT:             u64 = 3;
    const ENOT_ENOUGH_AMOUNT:         u64 = 4;
    const ETX_HAS_OUT:                u64 = 5;
    const ETX_NOT_EXIST:              u64 = 6;
    const ETX_NOT_UNLOCK:             u64 = 7;
    const EACCOUNT_NOT_REGISTER_COIN: u64 = 7;
    const EMINT_FAIL:                 u64 = 8;
    const ESUPPLY_ERR:                u64 = 9;
    const EBRIDGE_ADMIN_ALLOWED_ERR:  u64 = 10;
    const EBRIDGE_IS_FROZEN:          u64 = 11;

    /// MoonCoin capabilities, set during genesis and stored in @CoreResource account.
    /// This allows the Bridge module to mint coins.
    struct MoonCoinCapabilities has store {
        mint_cap: MintCapability<MoonCoin>,
        burn_cap: BurnCapability<MoonCoin>,
    }

    // Administrator able to create new BridgeAdmin, freeze/unfreeze the bridge vault
    struct Administrator has key {
        is_frozen: bool,
    }

    // BridgeAdmin able to mint, burn and freeze 
    struct BridgeAdmin has key {
        allowed_amount: u64,
        vault: Coin<MoonCoin>,
        mooncoin_caps: MoonCoinCapabilities,
        freezed: bool,
        unlocked: Table<vector<u8>, bool>,
        bridge_out_events: EventHandle<BridgeOutEvent>,
        bridge_in_events: EventHandle<BridgeInEvent>,
    }

    // initialzation when module published
    fun init_module(module_owner: &signer) {
        create_administrator(module_owner);
    }

    /// Event emitted when some amount of a coin is send into the bridge.
    struct BridgeOutEvent has drop, store {
        amount: u64,
    }

    /// Event emitted when some amount of a coin is send out from the bridge.
    struct BridgeInEvent has drop, store {
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

    /// This is only called during Genesis, which is where Administrator can be created.
    /// Beyond genesis, no one can create Administrator.
    fun create_administrator(module_owner: &signer) {
        assert!(signer::address_of(module_owner) == MODULE_OWNER, ENOT_MODULE_OWNER);

        let administrator = Administrator{is_frozen: false};
        move_to(module_owner, administrator);
    }

    // Administrator freeze the bridge
    public entry fun freeze_bridge(module_owner: &signer) acquires Administrator {
        let owner_addr = signer::address_of(module_owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);

        borrow_global_mut<Administrator>(owner_addr).is_frozen = true;
    }

    // Administrator unfreeze the bridge
    public entry fun unfreeze_bridge(module_owner: &signer) acquires Administrator {
        let owner_addr = signer::address_of(module_owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);

        borrow_global_mut<Administrator>(owner_addr).is_frozen = false;
    }

    // Administrator creates bridge admin resource
    public entry fun create_bridge_admin(
        module_owner: &signer, 
        destination: &signer,
        allowed_amount: u64,
        mint_cap: MintCapability<MoonCoin>,
        burn_cap: BurnCapability<MoonCoin>
        ) {
        let owner_addr = signer::address_of(module_owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);

        let mooncoin_caps = MoonCoinCapabilities {
            mint_cap, burn_cap
        };

        let bridge_admin = BridgeAdmin{
            allowed_amount: allowed_amount,
            vault: coin::zero<MoonCoin>(),
            mooncoin_caps: mooncoin_caps,
            freezed: false,
            unlocked: table::new<vector<u8>, bool>(),
            bridge_out_events: account::new_event_handle<BridgeOutEvent>(destination),
            bridge_in_events: account::new_event_handle<BridgeInEvent>(destination),
        };

        move_to(destination, bridge_admin);
    }

    // Send coins to the bridge means these coins will be burn
    public entry fun bridge_in( 
        account: &signer, 
        admin_addr: address,
        amount: u64
        ) acquires BridgeAdmin, Administrator {
        // check bridge is not frozen
        assert!(!is_frozen(), EBRIDGE_IS_FROZEN);

        let acct_addr = signer::address_of(account);
        // check if account has enough coins
        if (coin::balance<MoonCoin>(acct_addr) < amount) abort ENOT_ENOUGH_AMOUNT;

        // check admin address is correct
        assert!(is_bridge_admin(admin_addr), ENOT_BRIDGE_ADMIN);

        // burn amount of coins
        let burn_cap = &borrow_global<BridgeAdmin>(admin_addr).mooncoin_caps.burn_cap;
        let to_burn = coin::withdraw<MoonCoin>(account, amount);
        coin::burn(to_burn, burn_cap);
    }

    // Mint new token then send out from the bridge
    public entry fun bridge_out(
        admin: &signer, amount: u64, dst_addr: address, flow_tx_hash: vector<u8>)
        acquires BridgeAdmin, Administrator {
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
        //     &mut bridge_admin.unlocked, flow_tx_hash);
        let unlocked = table::borrow_mut_with_default<vector<u8>, bool>(
            &mut bridge_admin.unlocked, flow_tx_hash, false);

        if (*unlocked == true) abort ETX_HAS_OUT;
        *unlocked = true;

        // check account has registered the coin
        assert!(coin::is_account_registered<MoonCoin>(dst_addr), EACCOUNT_NOT_REGISTER_COIN);

        // mint
        managed_coin::mint_with_cap<MoonCoin>(
            dst_addr, amount, &bridge_admin.mooncoin_caps.mint_cap);

        // emit teleport out event
        event::emit_event<BridgeOutEvent>(
            &mut bridge_admin.bridge_out_events,
            BridgeOutEvent { amount: amount },
        );
    }


    #[test_only]
    use std::error;

    #[test_only]
    fun initialize_mooncoin(
        module_owner: &signer,
        decimals: u8,
        monitor_supply: bool,
    ) {
        managed_coin::initialize<MoonCoin>(
            module_owner,
            b"Moon Coin",
            b"MOON",
            decimals,
            monitor_supply
        );
    }

    #[test_only]
    fun initialize_bridge_admin(
        module_owner: &signer,
        admin: &signer,
    ) {
        let mint_cap = managed_coin::get_mint_cap<MoonCoin>(module_owner);
        let burn_cap = managed_coin::get_burn_cap<MoonCoin>(module_owner);

        create_bridge_admin(
            module_owner,
            admin,
            100, // allowed amount
            mint_cap,
            burn_cap);
    }

    #[test(module_owner = @MoonCoin)]
    public fun test_create_administrator(module_owner: signer) {
        let owner_addr = signer::address_of(&module_owner);

        create_administrator(&module_owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);
    }

    #[test(module_owner = @MoonCoin, destination = @0xa11ce)]
    public fun test_create_bridge_admin(
        module_owner: signer, destination: signer) acquires BridgeAdmin {
        let mod_addr = signer::address_of(&module_owner);
        let dest_addr = signer::address_of(&destination);
        aptos_framework::account::create_account_for_test(dest_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&module_owner));

        // init the coin
        initialize_mooncoin(&module_owner, 6, true);
        assert!(coin::is_coin_initialized<MoonCoin>(), 0);

        // init this bridge module
        init_module(&module_owner);
        assert!(is_administrator(mod_addr), ENOT_MODULE_OWNER);

        // init a bridge admin resource to the destination account
        initialize_bridge_admin(&module_owner, &destination);
        assert!(is_bridge_admin(dest_addr), ENOT_BRIDGE_ADMIN);

        // check bridge admin is able to mint
        let bridge_admin = borrow_global<BridgeAdmin>(dest_addr);
        managed_coin::register<MoonCoin>(&destination);
        managed_coin::mint_with_cap<MoonCoin>(
        dest_addr, 100, &bridge_admin.mooncoin_caps.mint_cap);

        assert!(coin::balance<MoonCoin>(dest_addr) == 100, EMINT_FAIL);
    }

    #[test(module_owner = @MoonCoin, admin = @0xa11ce, user = @0xb0b)]
    public fun test_bridge_in_out (
        module_owner: signer, admin: signer, user: signer) 
        acquires BridgeAdmin, Administrator {
        let mod_addr = signer::address_of(&module_owner);
        let admin_addr = signer::address_of(&admin);
        let user_addr = signer::address_of(&user);
        aptos_framework::account::create_account_for_test(admin_addr);
        aptos_framework::account::create_account_for_test(user_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&module_owner));

        // init the coin
        initialize_mooncoin(&module_owner, 6, true);
        assert!(coin::is_coin_initialized<MoonCoin>(), ECOIN_NOT_INIT);

        // init this bridge module
        init_module(&module_owner);
        assert!(is_administrator(mod_addr), ENOT_MODULE_OWNER);

        // init a bridge admin resource to the destination account
        initialize_bridge_admin(&module_owner, &admin);
        assert!(is_bridge_admin(admin_addr), ENOT_MODULE_OWNER);
        
        // user register mooncoin
        managed_coin::register<MoonCoin>(&user);

        // bridge admin calls bridge_out
        let txhash = b"0xf103"; 
        bridge_out(&admin, 100, user_addr, txhash);

        // check user has received the minted coins
        assert!(coin::balance<MoonCoin>(user_addr) == 100, EMINT_FAIL);

        // check bridge admin's allowed amount has decreased
        let bridge_admin = borrow_global<BridgeAdmin>(admin_addr);
        assert!(bridge_admin.allowed_amount == 0, EBRIDGE_ADMIN_ALLOWED_ERR);
        
        // check the tx hash been marked as unlocked
        let is_unlocked = table::borrow<vector<u8>, bool>(&bridge_admin.unlocked, txhash);
        assert!(*is_unlocked == true, ETX_NOT_UNLOCK);

        // check supply increased
        assert!(*option::borrow(&coin::supply<MoonCoin>()) == 100, ESUPPLY_ERR);

        // user calls bridge_in
        bridge_in(&user, admin_addr, 50);

        // check amount of coins has been withdraw from user account
        assert!(coin::balance<MoonCoin>(user_addr) == 50, EMINT_FAIL);

        // check supply decreased
        assert!(*option::borrow(&coin::supply<MoonCoin>()) == 50, ESUPPLY_ERR);
    }

    #[test(module_owner = @MoonCoin, admin = @0xa11ce)]
    public fun test_freeze_unfreeze(
        module_owner: signer, admin: signer
        ) acquires BridgeAdmin, Administrator {
        let mod_addr = signer::address_of(&module_owner);
        let admin_addr = signer::address_of(&admin);
        aptos_framework::account::create_account_for_test(admin_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&module_owner));

        // init the coin
        initialize_mooncoin(&module_owner, 6, true);
        assert!(coin::is_coin_initialized<MoonCoin>(), 0);

        // init this bridge module
        init_module(&module_owner);
        assert!(is_administrator(mod_addr), ENOT_MODULE_OWNER);

        // init a bridge admin resource to the destination account
        initialize_bridge_admin(&module_owner, &admin);
        assert!(is_bridge_admin(admin_addr), ENOT_BRIDGE_ADMIN);

        // check bridge admin is able to mint
        let bridge_admin = borrow_global<BridgeAdmin>(admin_addr);
        managed_coin::register<MoonCoin>(&admin);
        managed_coin::mint_with_cap<MoonCoin>(
        admin_addr, 100, &bridge_admin.mooncoin_caps.mint_cap);

        assert!(coin::balance<MoonCoin>(admin_addr) == 100, EMINT_FAIL);

        // freeze the bridge
        freeze_bridge(&module_owner);
        assert!(is_frozen(), error::invalid_state(0));

        unfreeze_bridge(&module_owner);
        assert!(!is_frozen(), error::invalid_state(0));
    }

    #[test(module_owner = @MoonCoin, admin = @0xa11ce, user = @0xb0b)]
    #[expected_failure(abort_code = 11)]
    public fun fail_mint_cuz_frozen(
        module_owner: signer, admin: signer, user: signer) 
        acquires BridgeAdmin, Administrator {
        let mod_addr = signer::address_of(&module_owner);
        let admin_addr = signer::address_of(&admin);
        let user_addr = signer::address_of(&user);
        aptos_framework::account::create_account_for_test(admin_addr);
        aptos_framework::account::create_account_for_test(user_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&module_owner));

        // init the coin
        initialize_mooncoin(&module_owner, 6, true);
        assert!(coin::is_coin_initialized<MoonCoin>(), ECOIN_NOT_INIT);

        // init this bridge module
        init_module(&module_owner);
        assert!(is_administrator(mod_addr), ENOT_MODULE_OWNER);

        // init a bridge admin resource to the destination account
        initialize_bridge_admin(&module_owner, &admin);
        assert!(is_bridge_admin(admin_addr), ENOT_MODULE_OWNER);
        
        // user register mooncoin
        managed_coin::register<MoonCoin>(&user);

        // freeze the bridge
        freeze_bridge(&module_owner);
        assert!(is_frozen(), error::invalid_state(0));

        // bridge admin calls bridge_out
        let txhash = b"0xf103";
        bridge_out(&admin, 100, user_addr, txhash);
    }
}