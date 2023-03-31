// TODO: make sure it's EIP compliant (e.g. events)
//       proper safe_transfer_from
//       more asserts
//       mint w/ Herodotus
//       token URI - wat do?

#[contract]
mod NFT {
    use array::ArrayTrait;
    use starknet::contract_address;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    use traits::Into;

    type addr = ContractAddress;

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
        token_uris::read(token_id)
    }   

    //
    // ERC721
    //

    #[view]
    fn balance_of(owner: addr) -> u256 {
        balances::read(owner)
    }

    #[view]
    fn owner_of(token_id: u256) -> addr {
        owners::read(token_id)
    }

    #[view]
    fn get_approved(token_id: u256) -> addr {
        token_approvals::read(token_id)
    }

    #[view]
    fn is_approved_for_all(owner: addr, operator: addr) -> bool {
        operator_approvals::read((owner, operator))
    }

    // TODO: on_erc721_received?
    #[external]
    fn safe_transfer_from(from: addr, to: addr, token_id: u256, data: Array<felt252>) {
        assert_approved_or_owner(get_caller_address(), token_id);
        transfer(from, to, token_id);
    }

    #[external]
    fn transfer_from(from: addr, to: addr, token_id: u256) {
        assert_approved_or_owner(get_caller_address(), token_id);
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
    }

    #[external]
    fn set_approval_for_all(operator: addr, approval: bool) {
        let caller = get_caller_address();
        assert(caller != operator, 'approval to self');
        operator_approvals::write((caller, operator), approval)
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
            owner == operator | operator == approved | is_approved_for_all(owner, operator),
            'operation not allowed'
        );
    }

    fn assert_valid(token_id: u256) {
        assert(owners::read(token_id).is_non_zero(), 'invalid token ID')
    }

    fn transfer(from: addr, to: addr, token_id: u256) {
        assert(to.is_non_zero(), 'transferring to zero');

        token_approvals::write(token_id, Zeroable::zero()); // TODO: should emit Approval

        let owner_balance = balances::read(from);
        balances::write(from, owner_balance - 1.into());

        let receiver_balance = balances::read(to);
        balances::write(to, receiver_balance + 1.into());

        owners::write(token_id, to);
        // TODO: emit Transfer
    }
}
