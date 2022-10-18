script {
    fun claim_mint(account: &signer) {
        owner::moonkey::claim_mint(account);
    }
}