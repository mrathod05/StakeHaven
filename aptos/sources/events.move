module admin::EmitEvents {
    use std::string::String;
    use aptos_framework::event;
    use aptos_framework::timestamp;

    //============= Friend ============ //
    friend admin::HavenCoin;
    friend admin::StakingMechanism;
    //================================ //

    #[event]
    struct CoinInitEvent has drop, store {
        name: String,
        owner_addr: address,
    }

    #[event]
    struct CoinMintEvent has drop, store {
        owner_addr: address,
        receiver_addr: address,
        amount: u64,
    }

    #[event]
    struct StakeMechanismInitEvent has drop, store {
        owner_addr: address,
        stack_addr: address,
    }

    #[event]
    struct AddStakeEvent has drop, store {
        user_addr: address,
        amount: u64,
        total_stack: u64,
        created_at: u64
    }

    #[event]
    struct ClaimStakeEvent has drop, store {
        user_addr: address,
        amount: u64,
        created_at: u64
    }

    #[event]
    struct WithdrawStakePenaltyEvent has drop, store {
        user_addr: address,
        amount: u64,
        penalty:u64,
        percentage: u64,
        before_time: u64,
        created_at: u64
    }

    #[event]
    struct WithdrawStakeEvent has drop, store {
        user_addr: address,
        amount: u64,
        total_stack: u64,
        created_at: u64
    }

    #[event]
    struct AdminAddStakeEvent has drop, store {
        admin_addr: address,
        amount: u64,
        current_balance: u64,
        created_at: u64
    }

    public(friend) fun init_coin_event(owner_addr: address, name: String, ){
         event::emit(CoinInitEvent{
             name,
             owner_addr,
         });
    }

    public(friend) fun init_mint_event(owner_addr: address, receiver_addr: address, amount: u64){
        event::emit(CoinMintEvent{
            owner_addr,
            receiver_addr,
            amount,
        });
    }

    public(friend) fun init_stake_mechanism(owner_addr: address, stack_addr: address){
        event::emit(StakeMechanismInitEvent{
            owner_addr,
            stack_addr,
        });
    }

    public(friend) fun add_stake(user_addr: address, amount: u64, total_stack: u64){
        event::emit(AddStakeEvent{
            user_addr,
            amount,
            total_stack,
            created_at: timestamp::now_seconds()
        });
    }

    public(friend) fun claim_stake(user_addr: address, amount: u64){
        event::emit(ClaimStakeEvent{
            user_addr,
            amount,
            created_at: timestamp::now_seconds()
        });
    }

    public(friend) fun withdraw_stake_penalty(
        user_addr: address,
        amount: u64,
        penalty:u64,
        percentage: u64,
        before_time: u64,
    ){
        event::emit(WithdrawStakePenaltyEvent{
            user_addr,
            amount,
            penalty,
            percentage,
            before_time,
            created_at: timestamp::now_seconds()
        });
    }

    public(friend) fun withdraw_stake(user_addr: address, amount: u64, total_stack: u64){
        event::emit(WithdrawStakeEvent{
            user_addr,
            amount,
            total_stack,
            created_at: timestamp::now_seconds()
        });
    }

    public(friend) fun admin_add_stake(
        admin_addr: address,
        amount: u64,
        current_balance: u64,
    ){
        event::emit(AdminAddStakeEvent{
            admin_addr,
            amount,
            current_balance,
            created_at: timestamp::now_seconds()
        });
    }
}