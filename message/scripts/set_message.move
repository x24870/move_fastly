script {
    use std::string;
    use owner::message;

    fun set_message(account: signer){
        let message = string::utf8(b"ABC123");
        message::set_message(account, message);
    }
}