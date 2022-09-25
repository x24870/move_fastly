module MoonCoin::bridge {
    use MoonCoin::moon_coin::MoonCoin;
    use aptos_framework::managed_coin::Capabilities;
    use aptos_framework::coin::{Self, BurnCapability, MintCapability};

    // struct CapStore has key {
    //     mint_cap: MintCapability<MoonCoin>,
    //     burn_cap: BurnCapability<MoonCoin>
    // }

    /// MoonCoin capabilities, set during genesis and stored in @CoreResource account.
    /// This allows the Bridge module to mint coins.
    struct MoonCoinCapabilities has key {
        mint_cap: MintCapability<MoonCoin>,
    }

    /// This is only called during Genesis, which is where MintCapability<MoonCoin> can be created.
    /// Beyond genesis, no one can create MoonCoin mint/burn capabilities.
    public(friend) fun store_aptos_coin_mint_cap(sender: &signer, mint_cap: MintCapability<MoonCoin>) {
        // system_addresses::assert_aptos_framework(sender);
        // TODO: check sender is the owner of mooncoin
        move_to(sender, MoonCoinCapabilities { mint_cap })
    }

    fun init_module(sender: &signer) {
    }
}