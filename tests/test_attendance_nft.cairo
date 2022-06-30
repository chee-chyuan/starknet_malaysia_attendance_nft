%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256

from tests.utils.IAttendanceNft import IAttendanceNft

const DEPLOYER_ADDRESS = 12345678
const NON_DEPLOYER_ADDRESS = 3445223
const NFT_MINTER = 986969
const NAME = 'Starknet Malaysia'
const SYMBOL = 'Starknet Malaysia'

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

## owner init correct
## token id init correct
@view
func test_owner_token_id_init{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let (owner) = IAttendanceNft.owner(contract_address=contract_address)
    assert owner = DEPLOYER_ADDRESS

    let (next_token_id) = IAttendanceNft.next_token_id(contract_address=contract_address)
    assert next_token_id = Uint256(1,0)

    return ()
end

## able to pause and unpause by owner only
@view
func test_owner_pause_unpause{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let (is_paused_before) = IAttendanceNft.is_paused(contract_address=contract_address)
    assert is_paused_before = FALSE

    %{
        stop_prank = start_prank(ids.DEPLOYER_ADDRESS, ids.contract_address)
    %}
        IAttendanceNft.pause(contract_address=contract_address)

        let (is_paused_after) = IAttendanceNft.is_paused(contract_address=contract_address)
        assert is_paused_after = TRUE

        IAttendanceNft.unpause(contract_address=contract_address)

        let (is_paused_after_unpause) = IAttendanceNft.is_paused(contract_address=contract_address)
        assert is_paused_after_unpause = FALSE

    %{ stop_prank() %}
    return ()
end

@view
func test_cannot_pause_non_owner{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank = start_prank(ids.NON_DEPLOYER_ADDRESS, ids.contract_address)
    %}

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IAttendanceNft.pause(contract_address=contract_address)

    %{ stop_prank() %}
    return ()
end

@view
func test_cannot_unpause_non_owner{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank = start_prank(ids.NON_DEPLOYER_ADDRESS, ids.contract_address)
    %}

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IAttendanceNft.unpause(contract_address=contract_address)

    %{ stop_prank() %}
    return ()
end


## able to mint when not paused, token id incremented, user balance incremented
## not able to mint when user already has the nft
@view
func test_mint_one_copy_only{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank = start_prank(ids.NFT_MINTER, ids.contract_address)
    %}

    let (is_paused) = IAttendanceNft.is_paused(contract_address=contract_address)
    assert is_paused = FALSE

    let (user_balance_before) = IAttendanceNft.balance_of(contract_address=contract_address, owner=NFT_MINTER)
    assert user_balance_before = Uint256(0,0)

    IAttendanceNft.mint(contract_address=contract_address)

    let (user_balance_after) = IAttendanceNft.balance_of(contract_address=contract_address, owner=NFT_MINTER)
    assert user_balance_after = Uint256(1,0)

    let (next_token_id) = IAttendanceNft.next_token_id(contract_address=contract_address)
    assert next_token_id = Uint256(2,0)

    # only can mint once
    %{ expect_revert(error_message="User already has minted this NFT") %}
    IAttendanceNft.mint(contract_address=contract_address)

    %{ stop_prank() %}
    return ()
end

## not able to mint when paused
@view
func test_not_able_to_mint_when_paused{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        stop_prank_admin = start_prank(ids.DEPLOYER_ADDRESS, ids.contract_address)
    %}
        IAttendanceNft.pause(contract_address=contract_address)

    %{ stop_prank_admin() %}

    let (is_paused) = IAttendanceNft.is_paused(contract_address=contract_address)
    assert is_paused = TRUE
    %{
        stop_prank = start_prank(ids.NFT_MINTER, ids.contract_address)
    %}

    %{ expect_revert(error_message="Pausable: paused") %}
    IAttendanceNft.mint(contract_address=contract_address)

    %{ stop_prank() %}
    return ()
end