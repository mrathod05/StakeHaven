module admin::HavenCoin {

    //============= Helper ============ //
    //================================ //

    use std::signer::address_of;
    use std::string::utf8;
    use aptos_framework::coin;
    use aptos_framework::managed_coin;
    use admin::EmitEvents;

    use admin::Accounts::{asset_is_admin};

    //============= Friend Module ============ //
    friend admin::StakingMechanism;

    #[test_only]
    friend admin::TestHavenCoin;
    //======================================== //

    //============= Errors ============ //
        const E_INSUFFICIENT_BAL: u64 = 2;
        const E_COIN_ALREADY_INITIALIZED: u64 = 4;
    //================================ //

    struct HVC has store{}

    fun init_module(admin: &signer){
        let admin_addr = address_of(admin);
        asset_is_admin(admin_addr);

        let coin_name = b"Haven Coin";

        managed_coin::initialize<HVC>(
            admin,
            coin_name,
            b"HVC",
            9,
            true
        );

        register_user(admin);
        managed_coin::mint<HVC>(admin, admin_addr, 100000);
        EmitEvents::init_coin_event( address_of(admin), utf8(coin_name));
    }

    public fun mint_coin(admin: &signer,addr: address, amount: u64){
        let admin_addr = address_of(admin);
        asset_is_admin(admin_addr);
        managed_coin::mint<HVC>(admin, addr, amount);
        EmitEvents::init_mint_event(admin_addr, addr, amount);
    }

   public fun transfer_coin(user: &signer, receiver_addr: address, amount: u64){
        let user_addr = address_of(user);
        assert_is_sufficient_balance(user_addr, amount);
        coin::transfer<HVC>(user, receiver_addr, amount);
    }

    public fun register_user(user: &signer){
        if (!coin::is_account_registered<HVC>(address_of(user))) {
            coin::register<HVC>(user);
        };
    }

    //============= Helper ============ //
    #[view]
    public fun get_balance(addr: address): u64{
        coin::balance<HVC>(addr)
    }
    //================================ //

    //============= Helper ============ //

    public fun assert_is_sufficient_balance(addr: address, amount: u64){
        assert!(get_balance(addr) >= amount, E_INSUFFICIENT_BAL);
    }

    public fun assert_is_coin_already_init(){
        assert!(coin::is_coin_initialized<HVC>(), E_COIN_ALREADY_INITIALIZED);
    }
    //================================ //

    //============= Test ============ //
    #[test_only]
    public(friend) fun init_haven_coin(admin: &signer){
        init_module(admin);
    }
    //================================ //

}