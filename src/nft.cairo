// TODO: proper safe_transfer_from
//       mint w/ Herodotus
//       token URI - wat do?

// EIP checklist:
//   done:
//     * name
//     * symbol
//     * token_uri
//     * balance_of
//     * owner_of
//     * get_approved
//     * is_approved_for_all
//     * transfer_from
//     * approve
//     * set_approval_for_all
//   pending:
//     * safe_transfer_from

#[contract]
mod NFT {
    use array::ArrayTrait;
    use traits::Into;
    use starknet::contract_address;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;

    type addr = ContractAddress;

    #[event]
    fn Transfer(from: addr, to: addr, token_id: u256) {}

    #[event]
    fn Approval(owner: addr, approved: addr, token_id: u256) {}

    #[event]
    fn ApprovalForAll(owner: addr, operator: addr, approved: bool) {}

    struct Storage {
        token_uris: LegacyMap<u256, felt252>,
        balances: LegacyMap<addr, u256>,
        owners: LegacyMap<u256, addr>,
        token_approvals: LegacyMap<u256, addr>,
        operator_approvals: LegacyMap<(addr, addr), bool>,
    }

    //
    // External
    //

    fn mint(to: addr) {
        assert(to.is_non_zero(), 'minting to zero');

        // TODO: Herodotus Chad Proof here

        let token_id = u256 { low: 1_u128, high: 0_u128 };

        let owner_balance = balances::read(to);
        balances::write(to, owner_balance + 1.into());

        owners::write(token_id, to);
        // TODO: emit Transfer
    }

    //
    // ERC721Metadata
    //

    #[view]
    fn name() -> felt252 {
        'Deez Nuts'
    }

    #[view]
    fn symbol() -> felt252 {
        'DN'
    }

    #[view]
    fn token_uri(token_id: u256) -> felt252 {
        assert_valid_token(token_id);
        // TODO: decide on and serve a proper URI
        token_uris::read(token_id)
    }   

    //
    // ERC721
    //

    #[view]
    fn balance_of(owner: addr) -> u256 {
        assert_valid_address(owner);
        balances::read(owner)
    }

    #[view]
    fn owner_of(token_id: u256) -> addr {
        let owner = owners::read(token_id);
        assert_valid_address(owner);
        owner
    }

    #[view]
    fn get_approved(token_id: u256) -> addr {
        assert_valid_token(token_id);
        token_approvals::read(token_id)
    }

    #[view]
    fn is_approved_for_all(owner: addr, operator: addr) -> bool {
        operator_approvals::read((owner, operator))
    }

    #[external]
    fn safe_transfer_from(from: addr, to: addr, token_id: u256, data: Array<felt252>) {
        transfer(from, to, token_id);
        // TODO: on_erc721_received?
    }

    #[external]
    fn transfer_from(from: addr, to: addr, token_id: u256) {
        transfer(from, to, token_id);
    }

    #[external]
    fn approve(approved: addr, token_id: u256) {
        let owner = owners::read(token_id);
        assert(owner != approved, 'approval to owner');

        let caller = get_caller_address();
        assert(
            caller == owner | operator_approvals::read((owner, caller)), 
            'not approved'
        );

        token_approvals::write(token_id, approved);
        Approval(owner, approved, token_id);
    }

    #[external]
    fn set_approval_for_all(operator: addr, approval: bool) {
        let owner = get_caller_address();
        assert(owner != operator, 'approval to self');
        operator_approvals::write((owner, operator), approval);
        ApprovalForAll(owner, operator, approval);
    }

    //
    // ERC165
    //

    #[view]
    fn supports_interface(interface_id: u32) -> bool {
        // ERC165
        interface_id == 0x01ffc9a7_u32 |
        // ERC721
        interface_id == 0x80ac58cd_u32 |
        // ERC721 Metadata
        interface_id == 0x5b5e139f_u32
    }

    //
    // Internal
    //

    fn assert_approved_or_owner(operator: addr, token_id: u256) {
        let owner = owners::read(token_id);
        let approved = get_approved(token_id);
        assert(
            operator == owner | operator == approved | is_approved_for_all(owner, operator),
            'operation not allowed'
        );
    }

    fn assert_valid_address(address: addr) {
        assert(address.is_non_zero(), 'invalid address');
    }

    fn assert_valid_token(token_id: u256) {
        assert(owners::read(token_id).is_non_zero(), 'invalid token ID')
    }

    fn transfer(from: addr, to: addr, token_id: u256) {
        assert_approved_or_owner(get_caller_address(), token_id);
        assert(owners::read(token_id) == from, 'source not owner');
        assert(to.is_non_zero(), 'transferring to zero');
        assert_valid_token(token_id);

        // reset approvals
        token_approvals::write(token_id, Zeroable::zero());

        // update balances
        let owner_balance = balances::read(from);
        balances::write(from, owner_balance - 1.into());
        let receiver_balance = balances::read(to);
        balances::write(to, receiver_balance + 1.into());

        // update ownership
        owners::write(token_id, to);
        Transfer(from, to, token_id);
    }
}
