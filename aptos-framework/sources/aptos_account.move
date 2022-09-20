module aptos_framework::aptos_account {
    use aptos_framework::account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;

    friend aptos_framework::genesis;
    friend aptos_framework::resource_account;

    ///////////////////////////////////////////////////////////////////////////
    /// Basic account creation methods.
    ///////////////////////////////////////////////////////////////////////////

    public entry fun create_account(auth_key: address) {
        let signer = account::create_account(auth_key);
        coin::register<AptosCoin>(&signer);
    }

    public entry fun transfer(source: &signer, to: address, amount: u64) {
        if(!account::exists_at(to)) {
            create_account(to)
        };
        coin::transfer<AptosCoin>(source, to, amount)
    }

    #[test(alice = @0xa11ce, core = @0x1)]
    public fun test_transfer(alice: signer, core: signer) {
        use std::signer;
        use aptos_std::from_bcs;

        let bob = from_bcs::to_address(x"0000000000000000000000000000000000000000000000000000000000000b0b");
        let carol = from_bcs::to_address(x"00000000000000000000000000000000000000000000000000000000000ca501");

        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(&core);
        create_account(signer::address_of(&alice));
        coin::deposit(signer::address_of(&alice), coin::mint(10000, &mint_cap));
        transfer(&alice, bob, 500);
        assert!(coin::balance<AptosCoin>(bob) == 500, 0);
        transfer(&alice, carol, 500);
        assert!(coin::balance<AptosCoin>(carol) == 500, 1);
        transfer(&alice, carol, 1500);
        assert!(coin::balance<AptosCoin>(carol) == 2000, 2);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
        let _bob = bob;
    }
}
