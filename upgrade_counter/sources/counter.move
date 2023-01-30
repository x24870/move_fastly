module owner::MyCounter {
    use std::signer;

    struct Counter has key, store {
        value:u64,
        /*
        Uncomment 'name' field and upgrade module.
        Upgrading will fail because the struct been modified
        */ 
        // name: string::String,
    }

    public fun init(account: &signer){
        move_to(account, 
        Counter{
            value: 0,
            /*
            Uncommnet this line to initilize name field
            */
            // name: string::utf8(b"Alice"),
            });
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

    // Upgrade module for this new function
    public entry fun reset_counter(account: signer) acquires Counter {
        let addr = signer::address_of(&account);
        let value = &mut borrow_global_mut<Counter>(addr).value;
        *value = 99;
    }

    
    /*
    Uncomment following 'reset_counter 'funtion and comment above 'reset_counter'
    Upgrade 'reset_counter' for reset the counter with specified value
    Upgrade will fail because the signature if the 'reset_counter' been modified
     */
    // public entry fun reset_counter(account: signer, v: u64) acquires Counter {
    //     let addr = signer::address_of(&account);
    //     let value = &mut borrow_global_mut<Counter>(addr).value;
    //     *value = v;
    // }
}