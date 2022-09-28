module MoonCoin::bridge {
    use std::signer;
    use MoonCoin::moon_coin::MoonCoin;
    use aptos_framework::coin::{Self, Coin, BurnCapability, MintCapability};
    use aptos_framework::managed_coin;

    /// Address of the owner of this module
    const MODULE_OWNER: address = @MoonCoin;

    /// Error codes
    const ENOT_MODULE_OWNER: u64 = 0;
    const ENOT_BRIDGE_OWNER: u64 = 1;
    const ENO_CAPABILITIES: u64 = 2;

    /// MoonCoin capabilities, set during genesis and stored in @CoreResource account.
    /// This allows the Bridge module to mint coins.
    struct MoonCoinCapabilities has key, store {
        mint_cap: MintCapability<MoonCoin>,
        burn_cap: BurnCapability<MoonCoin>,
    }

    // Administrator able to create new BridgeAdmin, freeze/unfreeze the bridge vault
    struct Administrator has key {}

    // BridgeAdmin able to set lock/unlock fee, collect fee, 
    struct BridgeAdmin has key {
        lock_fee: u64,
        unlock_fee: u64,
        allowed_amount: u64,
        vault: Coin<MoonCoin>,
        fee_collector: Coin<MoonCoin>,
        mooncoin_caps: MoonCoinCapabilities,
    }

    // initialzation when module published
    fun init_module(module_owner: &signer) {
        create_administrator(module_owner);
    }

    public fun is_administrator(account_addr: address): bool {
        exists<Administrator>(account_addr)
    }

    public fun is_bridge_admin(account_addr: address): bool {
        exists<BridgeAdmin>(account_addr)
    }


    /// This is only called during Genesis, which is where Administrator can be created.
    /// Beyond genesis, no one can create Administrator.
    fun create_administrator(module_owner: &signer) {
        assert!(signer::address_of(module_owner) == MODULE_OWNER, ENOT_MODULE_OWNER);

        let administrator = Administrator{};
        move_to(module_owner, administrator);
    }

    public entry fun create_bridge_admin(
        module_owner: &signer, 
        destination: &signer,
        lock_fee: u64,
        unlock_fee: u64,
        allowed_amount: u64,
        mint_cap: MintCapability<MoonCoin>,
        burn_cap: BurnCapability<MoonCoin>
        ) {
        let owner_addr = signer::address_of(module_owner);
        assert!(owner_addr == MODULE_OWNER, ENOT_MODULE_OWNER);

        let mooncoin_caps = MoonCoinCapabilities {
            mint_cap, burn_cap
        };

        let bridge_admin = BridgeAdmin{
            lock_fee: lock_fee,
            unlock_fee: unlock_fee,
            allowed_amount: allowed_amount,
            vault: coin::zero<MoonCoin>(),
            fee_collector: coin::zero<MoonCoin>(),
            mooncoin_caps: mooncoin_caps,
        };

        move_to(destination, bridge_admin);
    }



    #[test(module_owner = @MoonCoin)]
    public entry fun test_create_administrator(module_owner: signer) {
        let owner_addr = signer::address_of(&module_owner);

        create_administrator(&module_owner);
        assert!(is_administrator(owner_addr), ENOT_MODULE_OWNER);
    }

    #[test(module_owner = @MoonCoin, destination = @0xa11ce)]
    public entry fun test_create_bridge_admin(
        module_owner: signer, destination: signer) {

        managed_coin::initialize<MoonCoin>(
            &module_owner,
            b"Moon Coin",
            b"MOON",
            6,
            true
        );

        assert!(coin::is_coin_initialized<MoonCoin>(), 0);

        let mint_cap = managed_coin::get_mint_cap<MoonCoin>(&module_owner);
        let burn_cap = managed_coin::get_burn_cap<MoonCoin>(&module_owner);

        create_bridge_admin(
            &module_owner,
            &destination,
            0,
            0,
            100,
            mint_cap,
            burn_cap);

        let dest_addr = signer::address_of(&destination);
        assert!(is_bridge_admin(dest_addr), ENOT_MODULE_OWNER);
    }
}