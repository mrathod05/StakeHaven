#[test_only]
module admin::TestHavenCoin{
    use std::signer::address_of;
    use aptos_std::debug::print;
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::coin;
    use aptos_framework::timestamp;
    use admin::StakingMechanism;
    use admin::HavenCoin;
    use admin::StakingMechanism::init_stake_mechanism;
    use admin::Accounts::get_resource_address;
    use admin::HavenCoin::{init_haven_coin, get_balance, mint_coin};

    //============= Errors ============ //
    const E_COIN_MINTED_INCORRECTLY: u64 = 0;
    const E_USER_BALANCE_INCORRECT: u64 = 1;
    const E_REWARD_CALCULATION_INCORRECT: u64 = 2;
    const E_STAKE_AMOUNT_INCORRECT: u64 = 3;
    const E_WITHDRAW_AMOUNT_INCORRECT: u64 = 4;
    const E_TOTAL_STAKE_INCORRECT: u64 = 5;
    const E_PENALTY_CALCULATION_INCORRECT: u64 = 6;
    const E_TOTAL_STAKED_INCORRECT: u64 = 7;
    //================================ //

    fun setup(framework: &signer, admin: &signer){
        create_account_for_test(address_of(admin));
        coin::create_coin_conversion_map(framework);
        timestamp::set_time_has_started_for_testing(framework);

        init_haven_coin(admin);
        init_stake_mechanism(admin);
    }

    fun setup_user(admin: &signer, user_addr: address): signer{
        let user = create_account_for_test(user_addr);
        HavenCoin::register_user(&user);
        HavenCoin::mint_coin(admin, user_addr, 10000);
        timestamp::update_global_time_for_test_secs(1000);
        user
    }

    #[test(framework=@0x1, admin=@admin)]
    fun test_init_modules(framework: &signer, admin: &signer){
        setup(framework,admin);
        assert!(get_balance(get_resource_address())== 90000, E_COIN_MINTED_INCORRECTLY);
    }

    #[test(framework= @0x1, admin= @admin )]
    fun test_staking(framework: &signer, admin: &signer){
        setup(framework, admin);

        let user_addr = @0x123;
        let user = setup_user(admin, user_addr);

        let stake_amount = 1000;
        StakingMechanism::stack(&user, stake_amount);

        let user_balance_after_stake = get_balance(user_addr);
        assert!(user_balance_after_stake == 9000, E_USER_BALANCE_INCORRECT);

        let res_addr = get_resource_address();
        assert!(get_balance(res_addr) == 90000 + stake_amount, E_STAKE_AMOUNT_INCORRECT);
    }

    #[test(framework= @0x1, admin= @admin)]
    fun test_reward_calculation(framework: &signer, admin: &signer) {
        setup(framework, admin);

        let user_addr = @0x123;
        let user = setup_user(admin, user_addr);

        let stake_amount = 1000;
        StakingMechanism::stack(&user, stake_amount);

        timestamp::update_global_time_for_test_secs(86400);

        // Calculated expected reward: (2000 * 1 * 86400) / 1000_000 = 172.8 coins
        let expected_reward = (stake_amount * 1 * 86400) / 1000_000;
        let calculated_reward = StakingMechanism::calculate_pending_reward(user_addr);

        assert!(calculated_reward == expected_reward, E_REWARD_CALCULATION_INCORRECT);
    }

    #[test(framework= @0x1, admin= @admin)]
    fun test_claim_reward(framework: &signer, admin: &signer) {
        setup(framework, admin);

        let user_addr = @0x123;
        let user = setup_user(admin, user_addr);

        let stake_amount = 5000;
        StakingMechanism::stack(&user, stake_amount);

        let initial_balance = get_balance(user_addr);

        // Advance time by 2 days (172800)
        timestamp::update_global_time_for_test_secs(172800);

        // Expected Reward: (5000 * 1 * 172800) / 1000_000 = 864 coins
        let expected_reward = (stake_amount * 1 * 172800) / 1000_000;

        StakingMechanism::claim_rewards(&user);

        let final_balance = get_balance(user_addr);

        assert!(final_balance == initial_balance + expected_reward, E_REWARD_CALCULATION_INCORRECT);
    }

    #[test(framework= @0x1, admin= @admin)]
    fun test_withdraw_stake_after_min_duration(framework: &signer, admin: &signer) {
        setup(framework, admin);

        let user_addr = @0x123;
        let user = setup_user(admin, user_addr);

        let stake_amount = 3000;
        StakingMechanism::stack(&user, stake_amount);

        let initial_balance = get_balance(user_addr);

        // Advance time by 2 days (172800)
        timestamp::update_global_time_for_test_secs(172800);

        // Expected reward: (3000 * 1 * 172800) / 1000_000 = 518.4
        let expected_reward = (stake_amount * 1 * 172800) / 1000_000;

        StakingMechanism::withdraw_stack(&user, stake_amount);

        let final_balance = get_balance(user_addr);
        assert!(final_balance == initial_balance + stake_amount + expected_reward, E_WITHDRAW_AMOUNT_INCORRECT);
    }

    #[test(framework= @0x1, admin= @admin)]
    fun test_withdraw_stake_before_min_duration(framework: &signer, admin: &signer) {
        setup(framework, admin);

        let user_addr = @0x123;
        let user = setup_user(admin, user_addr);

        let stake_amount = 4000;
        StakingMechanism::stack(&user, stake_amount);

        let initial_balance = get_balance(user_addr);

        // Advance time by 12 hours (43200) - before min stake duration
        timestamp::update_global_time_for_test_secs(43200);

        // Expected reward: (4200 * 1 * 172800) / 1000_000 = 172.8 coins
        let expected_reward = (stake_amount * 1 * 4200) / 1000_000;

        // Calculate penalty (10% of stake amount)
        let penalty = (stake_amount * 10) / 100;
        let expected_return = stake_amount - penalty;

        StakingMechanism::withdraw_stack(&user, stake_amount);

        let final_balance = get_balance(user_addr);
        assert!(final_balance == initial_balance + expected_return + expected_reward, E_PENALTY_CALCULATION_INCORRECT);
    }

    #[test(framework= @0x1, admin= @admin)]
    fun test_add_to_existing_stake(framework: &signer, admin: &signer) {
        setup(framework, admin);

        let user_addr = @0x123;
        let user = setup_user(admin, user_addr);

        let stake_amount = 2000;
        StakingMechanism::stack(&user, stake_amount);

        let stake_amount_2 = 1000;
        StakingMechanism::stack(&user, stake_amount_2);

        // Expected reward from first stake: (2000 * 1 * 43200) / 1000_000 = 86.4
        let expected_reward_1 = (stake_amount * 1 * 43200) / 1000_000;

        let total_stake = stake_amount + stake_amount_2;
        let calculated_reward = StakingMechanism::calculate_pending_reward(user_addr);
        assert!(calculated_reward== 0, E_REWARD_CALCULATION_INCORRECT); // should be 0

        let res_addr = get_resource_address();
        print(&get_balance(res_addr));
        assert!(get_balance(res_addr) == 90000 + stake_amount + stake_amount_2, E_TOTAL_STAKE_INCORRECT);

        let expected_balance = 10000 - total_stake + expected_reward_1;
        print(&get_balance(user_addr));
        print(&expected_balance);
        assert!(get_balance(user_addr) == expected_balance, E_USER_BALANCE_INCORRECT);
    }

    #[test(framework = @0x1, admin = @admin)]
    fun test_admin_add_reward(framework: &signer, admin: &signer){
        setup(framework, admin);

        let admin_addr = address_of(admin);
        mint_coin(admin, admin_addr, 10000);

        let res_addr = get_resource_address();
        let initial_pool_balance = get_balance(res_addr);

        let reward_amount = 5000;
        StakingMechanism::add_rewards(admin, reward_amount);

        let final_pool_balance = get_balance(res_addr);
        assert!(final_pool_balance == initial_pool_balance + reward_amount, E_COIN_MINTED_INCORRECTLY)
    }

    #[test(framework = @0x1, admin = @admin)]
    fun test_multiple_user_staking(framework: &signer, admin: &signer){
        setup(framework, admin);

        let user_addr = @0x123;
        let user2_addr = @0x456;

        let user = setup_user(admin, user_addr);
        let user2 = setup_user(admin, user2_addr);

        let stake_amount_1 = 2000;
        StakingMechanism::stack(&user, stake_amount_1);

        let stake_amount_2 = 2000;
        StakingMechanism::stack(&user2, stake_amount_2);

        // 86400 sec 1 day
        timestamp::update_global_time_for_test_secs(86400);

        let expected_reward_1 = (stake_amount_1 * 1 * 86400) / 1000_000;
        let expected_reward_2 = (stake_amount_2 * 1 * 86400) / 1000_000;

        let calculate_reward_1 = StakingMechanism::calculate_pending_reward(user_addr);
        let calculate_reward_2 = StakingMechanism::calculate_pending_reward(user2_addr);

        assert!(calculate_reward_1 == expected_reward_1, E_REWARD_CALCULATION_INCORRECT);
        assert!(calculate_reward_2 == expected_reward_2, E_REWARD_CALCULATION_INCORRECT);

        let res_addr = get_resource_address();
        assert!(get_balance(res_addr) == 90000 + stake_amount_1 + stake_amount_2, E_TOTAL_STAKED_INCORRECT);
    }

    #[test(framework= @0x1, admin= @admin)]
    fun test_partial_withdraw_stake(framework: &signer, admin: &signer){
        setup(framework, admin);

        let user_addr = @0x123;
        let user = setup_user(admin, user_addr);

        let stake_amount = 6000;
        StakingMechanism::stack(&user, stake_amount);

        timestamp::update_global_time_for_test_secs(172800);

        let amount = 3000;
        StakingMechanism::withdraw_stack(&user, amount);

        // // 2 days = 172800
        // // (6000 * 1 * 172800) / 1000_000 = 1036.8
        // let expected_reward = (stake_amount * 1 * 172800) / 1000_000;

        let calculated_reward = StakingMechanism::calculate_pending_reward(user_addr);
        assert!(calculated_reward == 0, E_REWARD_CALCULATION_INCORRECT);

        // 1 day
        timestamp::update_global_time_for_test_secs(86400);

        let expected_new_reward  = (3000 * 1 * 86400) / 1000_000;
        let calculate_new_reward = StakingMechanism::calculate_pending_reward(user_addr);

        assert!(calculate_new_reward == expected_new_reward, E_REWARD_CALCULATION_INCORRECT);
    }
}