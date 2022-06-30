%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from tests.utils.IAttendanceNft import IAttendanceNft

const DEPLOYER_ADDRESS = 12345678
const NFT_MINTER = 986969
const NAME = 'Starknet Malaysia'
const SYMBOL = 'Starknet Malaysia'

const TOKEN_URI_1 = 'https://google.com/'
const TOKEN_URI_2 = 'test'

@view
func __setup__():

    %{ 
        context.contract_address = deploy_contract("./src/attendance_nft.cairo", 
                                                    [ids.NAME, 
                                                    ids.SYMBOL, 
                                                    ids.DEPLOYER_ADDRESS]
                                                ).contract_address 
    %}
    return ()
end

# test set token uri by owner only
# get token uri when id exist only
@view
func test_owner_set_token_uri{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    alloc_locals
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank = start_prank(ids.DEPLOYER_ADDRESS, ids.contract_address)
    %}
    IAttendanceNft.mint(contract_address=contract_address)

    let (token_uri_len_before, token_uri_before) = IAttendanceNft.ERC721_Metadata_tokenURI(contract_address=contract_address, token_id=Uint256(1,0))
    assert token_uri_len_before = 0
    # assert token_uri_before[0] = 0

    let (local token_url:felt*) = alloc()
    assert token_url[0] = TOKEN_URI_1
    assert token_url[1] = TOKEN_URI_2
    
    IAttendanceNft.ERC721_Metadata_setTokenURI(contract_address=contract_address, token_uri_len=2, token_uri=token_url)

    # oops contract_address not found, lets get it again
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let (token_uri_len_after, token_uri_after) = IAttendanceNft.ERC721_Metadata_tokenURI(contract_address=contract_address, token_id=Uint256(1,0))
    assert token_uri_len_after = 2
    assert token_uri_after[0] = TOKEN_URI_1
    assert token_uri_after[1] = TOKEN_URI_2
    %{
        stop_prank()
    %}

    # get when id is not available
    %{ expect_revert() %}
    let (token_uri_len_fail, token_uri_fail) = IAttendanceNft.ERC721_Metadata_tokenURI(contract_address=contract_address, token_id=Uint256(5,0))

    return()
end

# non owner not able to set token uri
@view
func test_non_owner_cannot_set_token_uri{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    alloc_locals
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank = start_prank(ids.NFT_MINTER, ids.contract_address)
    %}

    let (local token_url:felt*) = alloc()
    assert token_url[0] = TOKEN_URI_1
    assert token_url[1] = TOKEN_URI_2
    
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IAttendanceNft.ERC721_Metadata_setTokenURI(contract_address=contract_address, token_uri_len=2, token_uri=token_url)


    %{ stop_prank() %}
    return ()
end