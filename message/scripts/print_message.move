script {
    use std::signer;
    use std::debug;
    use owner::message;

    fun print_message(account: &signer){
        let addr = signer::address_of(account);
        debug::print(&addr);

        message::print_message(addr);
    }
}