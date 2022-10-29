module owner::MyCounter {
    use std::signer;

    struct Counter has key, store {
        value:u64,
    }

    public fun init(account: &signer){
        move_to(account, Counter{value:0});
    }

    public fun increase_counter(account: &signer) acquires Counter {
        let counter = borrow_global_mut<Counter>(signer::address_of(account));
        counter.value = counter.value + 1;
    }

    public entry fun init_counter(account: signer){
        init(&account)
    }

    public entry fun incr_counter(account: signer) acquires Counter {
        increase_counter(&account)
    }

    // public entry fun reset_counter(account: signer) acquires Counter {
    //     let addr = signer::address_of(&account);
    //     let value = &mut borrow_global_mut<Counter>(addr).value;
    //     *value = 99;
    // }

    public entry fun reset_counter(account: signer, v: u64) acquires Counter {
        let addr = signer::address_of(&account);
        let value = &mut borrow_global_mut<Counter>(addr).value;
        *value = v;
    }
}