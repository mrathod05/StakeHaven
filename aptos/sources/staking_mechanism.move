module admin::StakingMechanism {

    use std::signer::address_of;
    use aptos_framework::account::{SignerCapability, create_signer_with_capability};
    use aptos_framework::timestamp;

    use admin::EmitEvents;
    use admin::Accounts::{asset_is_admin, create_stake_resource_account, get_resource_address};
    use admin::HavenCoin::{transfer_coin, register_user};

    //============= Friend ============ //
    #[test_only]
    friend admin::TestHavenCoin;
    //================================ //

    //============= Errors ============ //
    /// Resource account not exist
    const E_RESOURCE_ACCOUNT_NOT_EXIST: u64 = 1;
    /// User didn't stake anything
    const E_NO_STAKE_FOUND: u64 = 2;
    /// User has insufficient stake
    const E_INSUFFICIENT_STACK: u64 = 3;
    //=================================== //


    struct StakingPool has key, store {
        signer_cap: SignerCapability,
        reward_per_second: u64,
        total_staked: u64,
        min_stake_duration: u64,
        early_unstack_penalty_pct: u64
    }

    struct UserStack has key {
        amount: u64,
        start_time: u64,
        last_reward_claim: u64,
        unclaimed_rewards: u64,
    }

    fun init_module(admin: &signer){
        let admin_addr = address_of(admin);
        asset_is_admin(admin_addr);

        let (resource_signer, resource_signer_cap) = create_stake_resource_account(admin);
        let resource_addr = address_of(&resource_signer);

        register_user(&resource_signer);
        transfer_coin(admin, resource_addr, 90000);

        move_to(&resource_signer, StakingPool{
            signer_cap: resource_signer_cap,
            reward_per_second: 01,
            total_staked: 0,
            min_stake_duration: 60 * 60 * 24 * 1, // One day,
            early_unstack_penalty_pct: 10, // 10%
        });

        EmitEvents::init_stake_mechanism(admin_addr, resource_addr);
    }

    public entry fun stack(user: &signer, amount: u64) acquires StakingPool, UserStack {
        let user_addr = address_of(user);

        if(exists<UserStack>(user_addr)){
            claim_rewards(user);
            let user_stack = borrow_global_mut<UserStack>(user_addr);
            user_stack.amount += amount;

            let res_addr = get_resource_address();
            let stake_pool = borrow_global_mut<StakingPool>(res_addr);
            stake_pool.total_staked += amount;
        }
        else{
            let current_time = timestamp::now_seconds();
            move_to(user,UserStack{
                amount,
                start_time: current_time,
                last_reward_claim: current_time,
                unclaimed_rewards:0
            });
            register_user(user);
        };

        let res_addr = get_resource_address();
        transfer_coin(user, res_addr, amount);

        let stack_pool = borrow_global_mut<StakingPool>(res_addr);
        let total_stack_pool = stack_pool.total_staked + amount;

        stack_pool.total_staked = total_stack_pool;
        EmitEvents::add_stake(user_addr, amount, total_stack_pool);
    }

    public fun calculate_pending_reward(user_addr: address): u64 acquires StakingPool, UserStack {
        assert_is_staked(user_addr);
        let res_account = get_resource_address();

        let staking_pool = borrow_global<StakingPool>(res_account);
        let user_stake = borrow_global<UserStack>(user_addr);

        let current_time = timestamp::now_seconds();
        let time_since_last_claim = current_time - user_stake.last_reward_claim;

        let reward = (user_stake.amount * staking_pool.reward_per_second * time_since_last_claim) / 1000_000;
        reward + user_stake.unclaimed_rewards
    }

    public entry fun claim_rewards(user: &signer) acquires StakingPool, UserStack {
        let user_addr = address_of(user);
        assert_is_staked(user_addr);

        let rewards = calculate_pending_reward(user_addr);

        if(rewards > 0){
            let res_account = get_resource_address();
            let stacking_pool = borrow_global_mut<StakingPool>(res_account);
            let user_stake = borrow_global_mut<UserStack>(user_addr);

            user_stake.last_reward_claim = timestamp::now_seconds();
            user_stake.unclaimed_rewards = 0;

            let res_signer = create_signer_with_capability(&stacking_pool.signer_cap);
            transfer_coin(&res_signer, user_addr, rewards);

            EmitEvents::claim_stake(user_addr, rewards);
        }
    }

    public entry fun withdraw_stack(user: &signer, amount: u64) acquires UserStack, StakingPool {
        let user_addr = address_of(user);
        assert_is_staked(user_addr);

        claim_rewards(user);

        let user_stake = borrow_global_mut<UserStack>(user_addr);
        let user_stake_amount =user_stake.amount;
        asset_is_sufficient_stack(user_stake_amount, amount);

        let current_time = timestamp::now_seconds();
        let staking_duration = current_time - user_stake.start_time;

        let res_addr = get_resource_address();
        let staking_pool = borrow_global_mut<StakingPool>(res_addr);
        let early_unstack_penalty_pct =staking_pool.early_unstack_penalty_pct;
        let actual_amount = amount;
        let min_stake_duration = staking_pool.min_stake_duration;

        if(staking_duration < min_stake_duration){
            let penalty = (amount * early_unstack_penalty_pct) / 100;
            actual_amount = amount - penalty;

            EmitEvents::withdraw_stake_penalty(
                user_addr,
                amount,
                penalty,
                early_unstack_penalty_pct,
                min_stake_duration - staking_duration,
            );
        };

        user_stake.amount = user_stake_amount - actual_amount;
        let total_staked = staking_pool.total_staked - actual_amount;
        staking_pool.total_staked = total_staked;

        let res_signer = create_signer_with_capability(&staking_pool.signer_cap);
        transfer_coin(&res_signer, user_addr, amount);

        if(user_stake_amount == 0){
            let UserStack {
                amount: _,
                start_time: _,
                unclaimed_rewards: _,
                last_reward_claim: _

            } = move_from<UserStack>(user_addr);
        };

        EmitEvents::withdraw_stake(
            user_addr,
            amount,
            total_staked,
        );
    }

    public entry fun add_rewards(admin: &signer, amount: u64) {
        let admin_addr = address_of(admin);
        asset_is_admin(admin_addr);

        let res_addr = get_resource_address();
        transfer_coin(admin, res_addr, amount);
    }

    //============= Helper ============ //
    fun assert_is_resource_account_exists(addr: address){
        assert!(exists<StakingPool>(addr), E_RESOURCE_ACCOUNT_NOT_EXIST);
    }

    fun assert_is_staked(addr: address){
        assert!(exists<UserStack>(addr), E_NO_STAKE_FOUND);
    }

    public fun asset_is_sufficient_stack(user_stake: u64, amount: u64){
        assert!(user_stake >= amount , E_INSUFFICIENT_STACK);
    }

    //================================ //

    //============= Test ============ //
    #[test_only]
    public(friend) fun init_stake_mechanism(admin: &signer){
        init_module(admin);
    }
    //================================ //
}