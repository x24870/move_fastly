module MoonCoinOwner::mooncoin {
    use std::error;
    use std::string;
    use std::signer;
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};

    /// Address of the owner of this module
    const MODULE_OWNER: address = @MoonCoinOwner;

    //
    // Errors
    //

    /// Account has no capabilities (burn/mint).
    const ENO_CAPABILITIES: u64 = 1;
    const ENOT_OWNER:       u64 = 2;
    const ENOT_AUTHORIZED:  u64 = 3;

    //
    // Data structures
    //

    struct MoonCoin {}

    /// MooncoinCapabilities resource storing mint/burn/freeze capabilities.
    /// The resource is stored on the account that initialized Mooncoin.
    struct MooncoinCapabilities has key {
        burn_cap: BurnCapability<MoonCoin>,
        freeze_cap: FreezeCapability<MoonCoin>,
        mint_cap: MintCapability<MoonCoin>,
    }

    // Authorized addresses able to mint/burn moon coins
    struct AuthorizedAddresses has key {
        address_map: SimpleMap<address, bool>,
    }

    //
    // Private functions
    //
    fun init_module(owner: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MoonCoin>(
            owner,
            string::utf8(b"Moon coin"),
            string::utf8(b"MOON"),
            6,
            true,
        );

        move_to(owner, MooncoinCapabilities{
            burn_cap,
            freeze_cap,
            mint_cap,
        });

        move_to(owner, AuthorizedAddresses{
            address_map: simple_map::create<address, bool>(),
        });
    }

    fun is_authorized(acct_addr: &address): bool acquires AuthorizedAddresses {
        let addr_map = &borrow_global<AuthorizedAddresses>(MODULE_OWNER).address_map;
        // if key not exists, simple map will abort it
        *simple_map::borrow<address, bool>(addr_map, acct_addr)
    }

    //
    // Public functions
    //
    public entry fun add_authorized_address(
        owner: &signer, addr: address) acquires AuthorizedAddresses {
        let onwer_addr = signer::address_of(owner);
        assert!(signer::address_of(owner) == MODULE_OWNER, ENOT_OWNER);

        let addr_map = &mut borrow_global_mut<AuthorizedAddresses>(onwer_addr).address_map;
        // if key already exists, simple map will abort it
        simple_map::add<address, bool>(addr_map, addr, true);
    }

    public entry fun enable_unauthorized_address(
        owner: &signer, addr: address) acquires AuthorizedAddresses {
        let onwer_addr = signer::address_of(owner);
        assert!(signer::address_of(owner) == MODULE_OWNER, ENOT_OWNER);

        let addr_map = &mut borrow_global_mut<AuthorizedAddresses>(onwer_addr).address_map;
        // if key not exists, simple map will abort it
        *simple_map::borrow_mut<address, bool>(addr_map, &addr) = true;
    }

    public entry fun disable_authorized_address(
        owner: &signer, addr: address)acquires AuthorizedAddresses {
        let onwer_addr = signer::address_of(owner);
        assert!(signer::address_of(owner) == MODULE_OWNER, ENOT_OWNER);

        let addr_map = &mut borrow_global_mut<AuthorizedAddresses>(onwer_addr).address_map;
        // if key not exists, simple map will abort it
        *simple_map::borrow_mut<address, bool>(addr_map, &addr) = false;
    }

    /// Withdraw an `amount` of coin `CoinType` from `account` and burn it.
    public entry fun burn(
        account: &signer,
        amount: u64,
    ) acquires MooncoinCapabilities {
        let account_addr = signer::address_of(account);

        assert!(
            exists<MooncoinCapabilities>(account_addr),
            error::not_found(ENO_CAPABILITIES),
        );

        let capabilities = borrow_global<MooncoinCapabilities>(account_addr);

        let to_burn = coin::withdraw<MoonCoin>(account, amount);
        coin::burn(to_burn, &capabilities.burn_cap);
    }

    // Withdraw coins from an account and burn it
    public fun proxy_burn(
        account: &signer,
        amount: u64,
        ) acquires MooncoinCapabilities {
        let caps = borrow_global<MooncoinCapabilities>(MODULE_OWNER);
        let to_burn = coin::withdraw<MoonCoin>(account, amount);
        coin::burn(to_burn, &caps.burn_cap);
    }

    /// Create new MOON coins and deposit them into dst_addr's account.
    public entry fun mint(
        owner: &signer,
        dst_addr: address,
        amount: u64,
    ) acquires MooncoinCapabilities {
        let owner_addr = signer::address_of(owner);

        assert!(
            exists<MooncoinCapabilities>(owner_addr),
            error::not_found(ENO_CAPABILITIES),
        );

        let capabilities = borrow_global<MooncoinCapabilities>(owner_addr);
        let coins_minted = coin::mint(amount, &capabilities.mint_cap);
        coin::deposit(dst_addr, coins_minted);
    }

    // Create new coins with provided mint capability and deposit them into dst_addr's account.
    public entry fun mint_with_cap(
        dst_addr: address,
        amount: u64,
        mint_cap: &MintCapability<MoonCoin>,
    ) {
        let coins_minted = coin::mint(amount, mint_cap);
        coin::deposit(dst_addr, coins_minted);
    }

    // Create new coins and deposit them into dst_addr's account
    // Only authorized address can call it.
    public fun proxy_mint(
        account: &signer,
        dst_addr: address,
        amount: u64,
    ) acquires MooncoinCapabilities, AuthorizedAddresses {
        let acct_addr = signer::address_of(account);
        assert!(is_authorized(&acct_addr), ENOT_AUTHORIZED);

        let caps = borrow_global<MooncoinCapabilities>(MODULE_OWNER);
        let coins_minted = coin::mint(amount, &caps.mint_cap);
        coin::deposit(dst_addr, coins_minted);
    }

    /// Creating a resource that stores balance of coin on user's account, withdraw and deposit event handlers.
    /// Required if user wants to start accepting deposits of coin in his account.
    public entry fun register(owner: &signer) {
        coin::register<MoonCoin>(owner);
    }

    //
    // Tests
    //

    #[test_only]
    use std::option;

    #[test_only]
    public fun initialize_for_test(owner: &signer) {
        init_module(owner);
    }

    #[test_only]
    public fun add_authorized_addr_for_test(
        addr: address) acquires AuthorizedAddresses {
        let addr_map = &mut borrow_global_mut<AuthorizedAddresses>(MODULE_OWNER).address_map;
        // if key already exists, simple map will abort it
        simple_map::add<address, bool>(addr_map, addr, true);
    }

    #[test_only]
    public fun disable_authorized_addr_for_test(
        addr: address) acquires AuthorizedAddresses {
        let addr_map = &mut borrow_global_mut<AuthorizedAddresses>(MODULE_OWNER).address_map;
        // if key not exists, simple map will abort it
        *simple_map::borrow_mut<address, bool>(addr_map, &addr) = false;
    }

    #[test(source = @0xa11ce, destination = @0xb0b, mod_account = @MoonCoinOwner)]
    public entry fun test_end_to_end(
        source: signer,
        destination: signer,
        mod_account: signer
    ) acquires MooncoinCapabilities {
        let source_addr = signer::address_of(&source);
        let destination_addr = signer::address_of(&destination);
        aptos_framework::account::create_account_for_test(source_addr);
        aptos_framework::account::create_account_for_test(destination_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&mod_account));
        init_module(&mod_account);
        assert!(coin::is_coin_initialized<MoonCoin>(), 0);

        coin::register<MoonCoin>(&mod_account);
        register(&source);
        register(&destination);

        mint(&mod_account, source_addr, 50);
        mint(&mod_account, destination_addr, 10);
        assert!(coin::balance<MoonCoin>(source_addr) == 50, 1);
        assert!(coin::balance<MoonCoin>(destination_addr) == 10, 2);

        let supply = coin::supply<MoonCoin>();
        assert!(option::is_some(&supply), 1);
        assert!(option::extract(&mut supply) == 60, 2);

        coin::transfer<MoonCoin>(&source, destination_addr, 10);
        assert!(coin::balance<MoonCoin>(source_addr) == 40, 3);
        assert!(coin::balance<MoonCoin>(destination_addr) == 20, 4);

        coin::transfer<MoonCoin>(&source, signer::address_of(&mod_account), 40);
        burn(&mod_account, 40);

        assert!(coin::balance<MoonCoin>(source_addr) == 0, 1);

        let new_supply = coin::supply<MoonCoin>();
        assert!(option::extract(&mut new_supply) == 20, 2);
    }

    #[test(source = @0xa11ce, destination = @0xb0b, mod_account = @MoonCoinOwner)]
    #[expected_failure(abort_code = 0x60001)]
    public entry fun fail_mint(
        source: signer,
        destination: signer,
        mod_account: signer,
    ) acquires MooncoinCapabilities {
        let source_addr = signer::address_of(&source);

        aptos_framework::account::create_account_for_test(source_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&destination));
        aptos_framework::account::create_account_for_test(signer::address_of(&mod_account));

        init_module(&mod_account);
        coin::register<MoonCoin>(&mod_account);
        register(&source);
        register(&destination);

        mint(&destination, source_addr, 100);
    }

    #[test(source = @0xa11ce, destination = @0xb0b, mod_account = @MoonCoinOwner)]
    #[expected_failure(abort_code = 0x60001)]
    public entry fun fail_burn(
        source: signer,
        destination: signer,
        mod_account: signer,
    ) acquires MooncoinCapabilities {
        let source_addr = signer::address_of(&source);

        aptos_framework::account::create_account_for_test(source_addr);
        aptos_framework::account::create_account_for_test(signer::address_of(&destination));
        aptos_framework::account::create_account_for_test(signer::address_of(&mod_account));

        init_module(&mod_account);
        coin::register<MoonCoin>(&mod_account);
        register(&source);
        register(&destination);

        mint(&mod_account, source_addr, 100);
        burn(&destination, 10);
    }
}
