module admin::Accounts {
    use aptos_framework::account::{create_resource_account, SignerCapability, create_resource_address};

    //============= Constants ============ //
    const RESOURCE_ACCOUNT_SEED: vector<u8> = b"RESOURCE_ACCOUNT_SEED";
    //=================================== //

    //============= Errors ============ //
    /// Is not admin
    const E_NOT_AN_ADMIN: u64 = 0;
    //=================================== //

    public fun create_stake_resource_account(multisig: &signer): (signer, SignerCapability) {
        create_resource_account(multisig, RESOURCE_ACCOUNT_SEED)
    }

    //============= view ============ //
    #[view]
    public fun get_resource_address(): address {
        let res_addr = create_resource_address(&@admin, RESOURCE_ACCOUNT_SEED);
        res_addr
    }
    //================================ //

    //============= Helper ============ //
    public fun asset_is_admin(addr :address){
        assert!(addr == @admin , E_NOT_AN_ADMIN);
    }


    //================================ //
}