%builtins output pedersen range_check ecdsa
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.dict import dict_read, dict_write
from starkware.cairo.common.math import assert_nn_le
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.cairo_builtins import (
    HashBuiltin,
    SignatureBuiltin,
)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.signature import (
    verify_ecdsa_signature,
)
from starkware.cairo.common.dict import dict_update
from starkware.cairo.common.dict import dict_new, dict_squash
from starkware.cairo.common.small_merkle_tree import (
    small_merkle_tree_update,
)

const LOG_N_ACCOUNTS = 10;

struct Account {
    public_key: felt,
    token_a_balance: felt,
    token_b_balance: felt,
    provided_a_balance: felt,
    provided_b_balance: felt,
}

// The maximum amount of each token that belongs to the AMM.
const MAX_BALANCE = 2 ** 64 - 1;

struct AmmState {
    // A dictionary that tracks the accounts' state.
    account_dict_start: DictAccess*,
    account_dict_end: DictAccess*,
    // The amount of the tokens currently in the AMM.
    // Must be in the range [0, MAX_BALANCE].
    token_a_balance: felt,
    token_b_balance: felt,
}

// Represents a swap transaction between a user and the AMM.
struct SwapTransaction {
    tx_type: felt,
    account_id: felt,
    token_a_amount: felt,
    token_b_amount: felt,
    r: felt,
    s: felt,
}

// The output of the AMM program.
struct AmmBatchOutput {
    // The balances of the AMM before applying the batch.
    token_a_before: felt,
    token_b_before: felt,
    // The balances of the AMM after applying the batch.
    token_a_after: felt,
    token_b_after: felt,
    // The account Merkle roots before and after applying
    // the batch.
    account_root_before: felt,
    account_root_after: felt,
}

func modify_account{range_check_ptr}(
    state: AmmState, account_id, diff_a, diff_b, provided_diff_a, provided_diff_b
) -> (state: AmmState, key: felt) {
    alloc_locals;

    // Define a reference to state.account_dict_end so that we
    // can use it as an implicit argument to the dict functions.
    let account_dict_end = state.account_dict_end;

    // Retrieve the pointer to the current state of the account.
    let (local old_account: Account*) = dict_read{
        dict_ptr=account_dict_end
    }(key=account_id);

    // Compute the new account values.
    tempvar new_token_a_balance = (
        old_account.token_a_balance + diff_a
    );
    tempvar new_token_b_balance = (
        old_account.token_b_balance + diff_b
    );
    tempvar new_provided_a_balance = (
        old_account.provided_a_balance + provided_diff_a
    );
    tempvar new_provided_b_balance = (
        old_account.provided_b_balance + provided_diff_b
    );

    // Verify that the new balances are positive.
    assert_nn_le(new_token_a_balance, MAX_BALANCE);
    assert_nn_le(new_token_b_balance, MAX_BALANCE);
    assert_nn_le(new_provided_a_balance, MAX_BALANCE);
    assert_nn_le(new_provided_b_balance, MAX_BALANCE);

    // Create a new Account instance.
    local new_account: Account;
    assert new_account.public_key = old_account.public_key;
    assert new_account.token_a_balance = new_token_a_balance;
    assert new_account.token_b_balance = new_token_b_balance;
    assert new_account.provided_a_balance = new_provided_a_balance;
    assert new_account.provided_b_balance = new_provided_b_balance;

    // Perform the account update.
    // Note that dict_write() will update the 'account_dict_end'
    // reference.
    let (__fp__, _) = get_fp_and_pc();
    dict_write{dict_ptr=account_dict_end}(
        key=account_id, new_value=cast(&new_account, felt)
    );

    // Construct and return the new state with the updated
    // 'account_dict_end'.
    local new_state: AmmState;
    assert new_state.account_dict_start = (
        state.account_dict_start
    );
    assert new_state.account_dict_end = account_dict_end;
    assert new_state.token_a_balance = state.token_a_balance;
    assert new_state.token_b_balance = state.token_b_balance;

    return (state=new_state, key=old_account.public_key);
}

const TX_TYPE_EXCHANGE = 10018;
const TX_TYPE_LIQUIDITY_PROVIDER = 10019;

func verify_vote_signature{
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*
}(
    state: AmmState,
    transaction: SwapTransaction*,
) -> (state: AmmState) {
    alloc_locals;

    let account_dict_end = state.account_dict_end;

    // Retrieve the pointer to the current state of the account.
    let (local account: Account*) = dict_read{
        dict_ptr=account_dict_end
    }(key=transaction.account_id);

    // assert signature for swap
    let (message) = hash2{hash_ptr=pedersen_ptr}(
        x=transaction.tx_type, y=transaction.token_a_amount * MAX_BALANCE + transaction.token_b_amount
    );

    verify_ecdsa_signature(
        message=message,
        public_key=account.public_key,
        signature_r=transaction.r,
        signature_s=transaction.s,
    );

    local new_state: AmmState;
    assert new_state.account_dict_start = (
        state.account_dict_start
    );
    assert new_state.account_dict_end = account_dict_end;
    assert new_state.token_a_balance = state.token_a_balance;
    assert new_state.token_b_balance = state.token_b_balance;

    return (state=new_state);
}

func account_diff(
    a: felt,
    b: felt,
    diff_a: felt,
    diff_b: felt,
) -> (account_diff_a: felt, account_diff_b: felt){
    if (b == 0){
        return (
            account_diff_a = -a,
            account_diff_b = diff_b,
        );
    }else{
        return (
            account_diff_a = diff_a,
            account_diff_b = -b,    
        );
    }
}

func account_diff_provider(
    a: felt,
    b: felt,
    diff_a: felt,
    diff_b: felt,
) -> (account_diff_a: felt, account_diff_b: felt){
    if (b == 0){
        return (
            account_diff_a = a,
            account_diff_b = diff_b,
        );
    }else{
        return (
            account_diff_a = diff_a,
            account_diff_b = b,    
        );
    }
}


func swap{
    range_check_ptr,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*
}(
    state: AmmState, transaction: SwapTransaction*
) -> (state: AmmState) {
    alloc_locals;

    tempvar a = transaction.token_a_amount;
    tempvar b = transaction.token_b_amount;
    tempvar x = state.token_a_balance;
    tempvar y = state.token_b_balance;

    assert a*b = 0;

    let (state) = verify_vote_signature(state, transaction);

    // Check that a is in range.
    assert_nn_le(a, MAX_BALANCE);
    assert_nn_le(b, MAX_BALANCE);

    // Compute the amount of token_b the user will get:
    //   b = (y * a) / (x + a).
    let (diff_b, _) = unsigned_div_rem(y * a, x + a);
    let (diff_a, _) = unsigned_div_rem(x * b, y + b);
    // Make sure that b is also in range.
    assert_nn_le(diff_a, MAX_BALANCE);
    assert_nn_le(diff_b, MAX_BALANCE);

    let (account_diff_a, account_diff_b) = account_diff(a, b, diff_a, diff_b);

    // Update the user's account.
    let (state, key) = modify_account(
        state=state,
        account_id=transaction.account_id,
        diff_a=account_diff_a,
        diff_b=account_diff_b,
        provided_diff_a=0,
        provided_diff_b=0,
    );

    // Here you should verify the user has signed on a message
    // specifying that they would like to sell 'a' tokens of
    // type token_a. You should use the public key returned by
    // modify_account().

    // Compute the new balances of the AMM and make sure they
    // are in range.
    tempvar new_x = x - account_diff_a;
    tempvar new_y = y - account_diff_b;
    assert_nn_le(new_x, MAX_BALANCE);
    assert_nn_le(new_y, MAX_BALANCE);

    // Update the state.
    local new_state: AmmState;
    assert new_state.account_dict_start = (
        state.account_dict_start
    );
    assert new_state.account_dict_end = state.account_dict_end;
    assert new_state.token_a_balance = new_x;
    assert new_state.token_b_balance = new_y;

    %{
        # Print the transaction values using a hint, for
        # debugging purposes.
        if (ids.b == 0):
            print(
                f'Swap: Account {ids.transaction.account_id} '
                f'gave {ids.a} tokens of type token_a and '
                f'received {ids.diff_b} tokens of type token_b.'
            )
        else:
            print(
                f'Swap: Account {ids.transaction.account_id} '
                f'gave {ids.b} tokens of type token_b and '
                f'received {ids.diff_a} tokens of type token_a.'
            )
        print(
            f'state token_a_balance: {ids.new_state.token_a_balance}\n'
            f'state token_b_balance: {ids.new_state.token_b_balance}'
        )
    %}

    return (state=new_state);
}

func provide_liquidity{
    range_check_ptr,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*
}(
    state: AmmState, transaction: SwapTransaction*
) -> (state: AmmState) {
    alloc_locals;

    tempvar a = transaction.token_a_amount;
    tempvar b = transaction.token_b_amount;
    tempvar x = state.token_a_balance;
    tempvar y = state.token_b_balance;

    assert a*b = 0;

    let (state) = verify_vote_signature(state, transaction);

    // Check that a is in range.
    assert_nn_le(a, MAX_BALANCE);
    assert_nn_le(b, MAX_BALANCE);

    // Compute the amount of token_b the user will get:
    //   x/y = (x+a)/(y+b)
    //   => b = y * (x + a) / x - y
    let (tmp_b, _) = unsigned_div_rem(y * (x + a), x);
    let (tmp_a, _) = unsigned_div_rem(x * (y + b), y);
    let diff_a = tmp_a - x;
    let diff_b = tmp_b - y;
    // Make sure that b is also in range.
    if(a == 0){
        assert_nn_le(diff_b, MAX_BALANCE);
    }else{
        assert_nn_le(diff_a, MAX_BALANCE);
    }

    let (account_diff_a, account_diff_b) = account_diff_provider(a, b, diff_a, diff_b);

    // Update the user's account.
    let (state, key) = modify_account(
        state=state,
        account_id=transaction.account_id,
        diff_a=-account_diff_a,
        diff_b=-account_diff_b,
        provided_diff_a=account_diff_a,
        provided_diff_b=account_diff_b,
    );

    // Here you should verify the user has signed on a message
    // specifying that they would like to sell 'a' tokens of
    // type token_a. You should use the public key returned by
    // modify_account().

    // Compute the new balances of the AMM and make sure they
    // are in range.
    tempvar new_x = x + account_diff_a;
    tempvar new_y = y + account_diff_b;
    assert_nn_le(new_x, MAX_BALANCE);
    assert_nn_le(new_y, MAX_BALANCE);

    // Update the state.
    local new_state: AmmState;
    assert new_state.account_dict_start = (
        state.account_dict_start
    );
    assert new_state.account_dict_end = state.account_dict_end;
    assert new_state.token_a_balance = new_x;
    assert new_state.token_b_balance = new_y;

    %{
        # Print the transaction values using a hint, for
        # debugging purposes.
        print(
            f'Provide Liquidity: Account {ids.transaction.account_id} '
            f'added {ids.account_diff_a} tokens of type token_a and '
            f'added {ids.account_diff_b} tokens of type token_b.'
        )
        print(
            f'state token_a_balance: {ids.new_state.token_a_balance}\n'
            f'state token_b_balance: {ids.new_state.token_b_balance}'
        )
    %}

    return (state=new_state);
}

func swap_or_provide{
    range_check_ptr,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*
}(
    state: AmmState,
    transaction: SwapTransaction*,
) -> (state: AmmState) {
    if(transaction.tx_type == TX_TYPE_EXCHANGE){
        return swap(
            state=state, transaction=transaction
        );
    }else{
        return provide_liquidity(
            state=state, transaction=transaction
        );
    }
}

func transaction_loop{
    range_check_ptr,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*
}(
    state: AmmState,
    transactions: SwapTransaction**,
    n_transactions,
) -> (state: AmmState) {
    if (n_transactions == 0) {
        return (state=state);
    }

    let first_transaction: SwapTransaction* = [transactions];

    let (state) = swap_or_provide(state=state, transaction=first_transaction);

    return transaction_loop(
        state=state,
        transactions=transactions + 1,
        n_transactions=n_transactions - 1,
    );
}

// Returns a hash committing to the account's state using the
// following formula:
//   H(H(public_key, token_a_balance), token_b_balance).
// where H is the Pedersen hash function.
func hash_account{pedersen_ptr: HashBuiltin*}(
    account: Account*
) -> (res: felt) {
    let res = account.public_key;
    let (res) = hash2{hash_ptr=pedersen_ptr}(
        res, account.token_a_balance
    );
    let (res) = hash2{hash_ptr=pedersen_ptr}(
        res, account.token_b_balance
    );
    let (res) = hash2{hash_ptr=pedersen_ptr}(
        res, account.provided_a_balance
    );
    let (res) = hash2{hash_ptr=pedersen_ptr}(
        res, account.provided_b_balance
    );
    return (res=res);
}

// For each entry in the input dict (represented by dict_start
// and dict_end) write an entry to the output dict (represented
// by hash_dict_start and hash_dict_end) after applying
// hash_account on prev_value and new_value and keeping the same
// key.
func hash_dict_values{pedersen_ptr: HashBuiltin*}(
    dict_start: DictAccess*,
    dict_end: DictAccess*,
    hash_dict_start: DictAccess*,
) -> (hash_dict_end: DictAccess*) {
    if (dict_start == dict_end) {
        return (hash_dict_end=hash_dict_start);
    }

    // Compute the hash of the account before and after the
    // change.
    let (prev_hash) = hash_account(
        account=cast(dict_start.prev_value, Account*)
    );
    let (new_hash) = hash_account(
        account=cast(dict_start.new_value, Account*)
    );

    // Add an entry to the output dict.
    dict_update{dict_ptr=hash_dict_start}(
        key=dict_start.key,
        prev_value=prev_hash,
        new_value=new_hash,
    );
    return hash_dict_values(
        dict_start=dict_start + DictAccess.SIZE,
        dict_end=dict_end,
        hash_dict_start=hash_dict_start,
    );
}

// Computes the Merkle roots before and after the batch.
// Hint argument: initial_account_dict should be a dictionary
// from account_id to an address in memory of the Account struct.
func compute_merkle_roots{
    pedersen_ptr: HashBuiltin*, range_check_ptr
}(state: AmmState) -> (root_before: felt, root_after: felt) {
    alloc_locals;

    // Squash the account dictionary.
    let (squashed_dict_start, squashed_dict_end) = dict_squash(
        dict_accesses_start=state.account_dict_start,
        dict_accesses_end=state.account_dict_end,
    );

    // Hash the dict values.
    %{
        from starkware.crypto.signature.signature import pedersen_hash

        initial_dict = {}
        for account_id, account in initial_account_dict.items():
            public_key = memory[
                account + ids.Account.public_key]
            token_a_balance = memory[
                account + ids.Account.token_a_balance]
            token_b_balance = memory[
                account + ids.Account.token_b_balance]
            provided_a_balance = memory[
                account + ids.Account.provided_a_balance]
            provided_b_balance = memory[
                account + ids.Account.provided_b_balance]
            initial_dict[account_id] = pedersen_hash(
                    pedersen_hash(
                        pedersen_hash(
                            pedersen_hash(
                                public_key,
                                token_a_balance
                            ),
                            token_b_balance
                        ),
                        provided_a_balance
                    ),
                    provided_b_balance
                )
        %}
    let (local hash_dict_start: DictAccess*) = dict_new();
    let (hash_dict_end) = hash_dict_values(
        dict_start=squashed_dict_start,
        dict_end=squashed_dict_end,
        hash_dict_start=hash_dict_start,
    );

    // Compute the two Merkle roots.
    let (root_before, root_after) = small_merkle_tree_update{
        hash_ptr=pedersen_ptr
    }(
        squashed_dict_start=hash_dict_start,
        squashed_dict_end=hash_dict_end,
        height=LOG_N_ACCOUNTS,
    );

    return (root_before=root_before, root_after=root_after);
}

func get_transactions() -> (
    transactions: SwapTransaction**, n_transactions: felt
) {
    alloc_locals;
    local transactions: SwapTransaction**;
    local n_transactions: felt;
    %{
        transactions = [
            [
                transaction['tx_type'],
                transaction['account_id'],
                transaction['token_a_amount'],
                transaction['token_b_amount'],
                int(transaction['r'], 16),
                int(transaction['s'], 16),
            ]
            for transaction in program_input['transactions']
        ]
        ids.transactions = segments.gen_arg(transactions)
        ids.n_transactions = len(transactions)
    %}
    return (
        transactions=transactions, n_transactions=n_transactions
    );
}

func get_account_dict() -> (account_dict: DictAccess*) {
    alloc_locals;
    %{
        account = program_input['accounts']
        initial_dict = {
            int(account_id_str): segments.gen_arg([
                int(info['public_key'], 16),
                info['token_a_balance'],
                info['token_b_balance'],
                info['provided_a_balance'],
                info['provided_b_balance'],
            ])
            for account_id_str, info in account.items()
        }

        # Save a copy of initial_dict for
        # compute_merkle_roots.
        initial_account_dict = dict(initial_dict)
    %}

    // Initialize the account dictionary.
    let (account_dict) = dict_new();
    return (account_dict=account_dict);
}


func main{
    output_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr: SignatureBuiltin*,
}() {
    alloc_locals;

    // Create the initial state.
    local state: AmmState;
    %{
        # Initialize the balances using a hint.
        # Later we will output them to the output struct,
        # which will allow the verifier to check that they
        # are indeed valid.
        ids.state.token_a_balance = \
            program_input['token_a_balance']
        ids.state.token_b_balance = \
            program_input['token_b_balance']
    %}

    let (account_dict) = get_account_dict();
    assert state.account_dict_start = account_dict;
    assert state.account_dict_end = account_dict;

    // Output the AMM's balances before applying the batch.
    let output = cast(output_ptr, AmmBatchOutput*);
    let output_ptr = output_ptr + AmmBatchOutput.SIZE;

    assert output.token_a_before = state.token_a_balance;
    assert output.token_b_before = state.token_b_balance;

    // Execute the transactions.
    let (transactions, n_transactions) = get_transactions();
    let (state: AmmState) = transaction_loop(
        state=state,
        transactions=transactions,
        n_transactions=n_transactions,
    );

    // Output the AMM's balances after applying the batch.
    assert output.token_a_after = state.token_a_balance;
    assert output.token_b_after = state.token_b_balance;

    // Write the Merkle roots to the output.
    let (root_before, root_after) = compute_merkle_roots(
        state=state
    );
    assert output.account_root_before = root_before;
    assert output.account_root_after = root_after;

    return ();
}