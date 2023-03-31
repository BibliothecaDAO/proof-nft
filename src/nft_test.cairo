const ERC165_INTERFACE: u32 = 0x01ffc9a7_u32;
const ERC721_INTERFACE: u32 = 0x80ac58cd_u32;
const ERC721_METADATA_INTERFACE: u32 = 0x5b5e139f_u32;

use proof_nft::nft::NFT;

#[test]
fn test_supports_interface() {
    assert(NFT::supports_interface(ERC165_INTERFACE), 'ERC165 interface');
    assert(NFT::supports_interface(ERC721_INTERFACE), 'ERC165 interface');
    assert(NFT::supports_interface(ERC721_METADATA_INTERFACE), 'ERC165 interface');
    assert(NFT::supports_interface(0x1_u32) == false, 'invalid interface');
}
